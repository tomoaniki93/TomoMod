-- =====================================================================
-- Ported from Tui: TUI_ActionBars/actionbars/actionbars_flyout.lua
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

do

spellFlyoutSkinHooked = false

do

-- TOMOMOD 3.6.0 P1: leave flyout execution to Blizzard's secure action
-- handler.  SecureActionButtonTemplate already handles action-slot flyouts via
-- SpellFlyout:Toggle(); intercepting them with the custom owned flyout made
-- Mage portal / Hunter trap flyouts fail to open on Midnight 12.1.
-- The native SpellFlyout is still skinned by the TomoMod cosmetic path below.
USE_OWNED_FLYOUT = false
ActionBarsOwned.useOwnedFlyout = USE_OWNED_FLYOUT

env.__declared.ownedFlyout = true
ownedFlyoutButtons = {}
env.__declared.lastOwnedFlyoutSyncPayload = true

function GetOwnedFlyoutSettings(parentButton)
    local barKey = GetBarKeyFromButton(parentButton)
    if barKey then
        local settings = GetEffectiveSettings(barKey)
        if settings then return settings end
    end
    return GetGlobalSettings()
end

function ApplyOwnedFlyoutButtonVisuals(button, spellID)
    if not button then return end
    button._tomomodFlyoutSpellID = spellID
    if button.icon then
        local texture
        if spellID then
            if C_Spell and C_Spell.GetSpellTexture then
                local ok, result = ns.SafeCall("best-effort-style", C_Spell.GetSpellTexture, spellID)
                if ok then texture = result end
            elseif GetSpellTexture then
                local ok, result = ns.SafeCall("best-effort-style", GetSpellTexture, spellID)
                if ok then texture = result end
            end
        end
        button.icon:SetTexture(texture)
        if spellID then
            button.icon:Show()
        else
            button.icon:Hide()
        end
    end
    if button.Name then button.Name:SetText("") end
    if button.Count then button.Count:SetText("") end

    if InCombatLockdown() then return end
    local sourceButton = ownedFlyout and ownedFlyout:GetParent()
    local settings = GetOwnedFlyoutSettings(sourceButton)
    if settings and settings.skinEnabled then
        SkinButton(button, settings)
    end
end

function UpdateOwnedFlyoutButtonCooldown(button)
    if not button then return end
    local cooldown = button.cooldown or button.Cooldown
    if not cooldown then return end

    local spellID = button._tomomodFlyoutSpellID
    if not spellID or not C_Spell or not C_Spell.GetSpellCooldownDuration then
        cooldown:Clear()
        if button.chargeCooldown then button.chargeCooldown:Clear() end
        return
    end

    local cdInfo = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellID)
    local chargeInfo = C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(spellID)

    local cur = Helpers.SafeToNumber(chargeInfo and chargeInfo.currentCharges, 0) -- @secret-safe: SpellChargeInfo container is a plain table-or-nil; the secret-capable field goes to the unwrap
    local max = Helpers.SafeToNumber(chargeInfo and chargeInfo.maxCharges, 0) -- @secret-safe: SpellChargeInfo container is a plain table-or-nil; maxCharges is NeverSecret and goes to the unwrap
    local showCharge = max > 0 and cur < max

    local showNormal = Helpers.SafeValue(cdInfo and cdInfo.isActive, false) -- @secret-safe: SpellCooldownInfo container is a plain table-or-nil; isActive is NeverSecret and goes to the unwrap

    if showNormal then
        local ok, durObj = ns.SafeCall("best-effort-style", C_Spell.GetSpellCooldownDuration, spellID, true)
        if ok and durObj then
            cooldown:SetCooldownFromDurationObject(durObj)
        else
            cooldown:Clear()
        end
    else
        cooldown:Clear()
    end

    if showCharge and C_Spell.GetSpellChargeDuration then
        if not button.chargeCooldown then
            local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            cd:SetHideCountdownNumbers(true)
            cd:SetDrawSwipe(false)
            cd:SetAllPoints(cooldown)
            cd:SetFrameLevel(button:GetFrameLevel())
            button.chargeCooldown = cd
        end
        local ok, durObj = ns.SafeCall("best-effort-style", C_Spell.GetSpellChargeDuration, spellID)
        if ok and durObj then
            button.chargeCooldown:SetCooldownFromDurationObject(durObj)
        else
            button.chargeCooldown:Clear()
        end
    elseif button.chargeCooldown then
        button.chargeCooldown:Clear()
    end
end

function UpdateAllOwnedFlyoutButtonCooldowns()
    if not ownedFlyout or not ownedFlyout:IsShown() then return end
    for i = 1, (ownedFlyout:GetAttribute("numFlyoutButtons") or 0) do
        local btn = ownedFlyoutButtons[i]
        if btn and btn:IsShown() then
            UpdateOwnedFlyoutButtonCooldown(btn)
        end
    end
end

function ClearOwnedFlyoutButtonCooldown(button)
    if not button then return end
    local cooldown = button.cooldown or button.Cooldown
    if cooldown then cooldown:Clear() end
    if button.chargeCooldown then button.chargeCooldown:Clear() end
end

EnsureOwnedFlyoutFrame = function()
    if ownedFlyout or not USE_OWNED_FLYOUT then return ownedFlyout end

    ownedFlyout = CreateFrame("Frame", "TUI_SpellFlyout", UIParent, "SecureHandlerBaseTemplate")
    ownedFlyout:SetFrameStrata("DIALOG")
    if ownedFlyout.SetFixedFrameStrata then
        ownedFlyout:SetFixedFrameStrata(true)
    end
    ownedFlyout:SetClampedToScreen(true)
    ownedFlyout:Hide()
    ownedFlyout.BackgroundTex = ownedFlyout:CreateTexture(nil, "BACKGROUND")
    ownedFlyout.BackgroundTex:SetAllPoints()
    ownedFlyout.BackgroundTex:SetColorTexture(0, 0, 0, 0.35)
    ownedFlyout:SetScript("OnShow", function(self)
        -- TOMOMOD P1 12.1: a flyout can be opened from a keybind while its
        -- source bar is fully faded. The flyout is parented to that button and
        -- therefore inherits alpha 0, leaving an invisible interactive menu.
        -- Force the source bar visible for the lifetime of the flyout while
        -- keeping the secure click path untouched.
        local sourceBarKey = GetSpellFlyoutSourceBarKey(self)
        if sourceBarKey then
            local fadeState = GetOwnedBarFadeState and GetOwnedBarFadeState(sourceBarKey)
            if fadeState then
                fadeState.isFading = false
                if CancelOwnedBarFadeTimers then
                    CancelOwnedBarFadeTimers(fadeState)
                end
            end
            if ActionBarsOwned.SetBarAlpha then
                ActionBarsOwned.SetBarAlpha(sourceBarKey, 1)
            end
        end

        for i = 1, (self:GetAttribute("numFlyoutButtons") or 0) do
            local btn = ownedFlyoutButtons[i]
            if btn and btn:IsShown() then
                ApplyOwnedFlyoutButtonVisuals(btn, btn:GetAttribute("qui-flyout-spell"))
                UpdateOwnedFlyoutButtonCooldown(btn)
            end
        end
    end)
    ownedFlyout:SetScript("OnHide", function(self)
        local sourceBarKey = GetSpellFlyoutSourceBarKey(self)
        for i = 1, (self:GetAttribute("numFlyoutButtons") or 0) do
            local btn = ownedFlyoutButtons[i]
            if btn then
                ApplyOwnedFlyoutButtonVisuals(btn, nil)
                ClearOwnedFlyoutButtonCooldown(btn)
            end
        end

        -- Re-evaluate mouseover only after the flyout no longer participates
        -- in ShouldSuspendMouseoverFade(), otherwise a bar opened by keybind
        -- can remain stuck at alpha 1 indefinitely.
        if sourceBarKey and SetupOwnedBarMouseover then
            SetupOwnedBarMouseover(sourceBarKey)
        end
    end)
    ownedFlyout:SetAttribute("numFlyoutButtons", 0)
    ownedFlyout:Execute([[TUI_FlyoutInfo = newtable()]])
    ownedFlyout:SetAttribute("HandleFlyout", [[
        local parent = self:GetAttribute("flyoutParentHandle")
        if not parent then
            self:SetAttribute("flyoutID", nil)
            self:Hide()
            return
        end

        if self:IsShown() and self:GetParent() == parent then
            self:SetAttribute("flyoutID", nil)
            self:Hide()
            return
        end

        local flyoutID = self:GetAttribute("flyoutID")
        local info = TUI_FlyoutInfo and TUI_FlyoutInfo[flyoutID]
        if not info or not info.slots then
            self:SetAttribute("flyoutID", nil)
            self:Hide()
            return
        end

        local direction = parent:GetAttribute("flyoutDirection") or "UP"
        local width = 45
        local height = 45
        self:SetParent(parent)

        local usedSlots = 0
        local prevButton
        for slotID, slotInfo in ipairs(info.slots) do
            if slotInfo and slotInfo.spellID and slotInfo.isKnown then
                usedSlots = usedSlots + 1
                local slotButton = self:GetFrameRef("flyoutButton" .. usedSlots)
                if slotButton then
                    slotButton:SetAttribute("type", "spell")
                    slotButton:SetAttribute("spell", slotInfo.spellID)
                    slotButton:SetAttribute("qui-flyout-spell", slotInfo.spellID)
                    slotButton:CallMethod("TUI_UpdateOwnedFlyoutVisuals", slotInfo.spellID)
                    slotButton:SetWidth(width)
                    slotButton:SetHeight(height)
                    slotButton:ClearAllPoints()

                    if direction == "DOWN" then
                        if prevButton then
                            slotButton:SetPoint("TOP", prevButton, "BOTTOM", 0, -4)
                        else
                            slotButton:SetPoint("TOP", self, "TOP", 0, -7)
                        end
                    elseif direction == "LEFT" then
                        if prevButton then
                            slotButton:SetPoint("RIGHT", prevButton, "LEFT", -4, 0)
                        else
                            slotButton:SetPoint("RIGHT", self, "RIGHT", -7, 0)
                        end
                    elseif direction == "RIGHT" then
                        if prevButton then
                            slotButton:SetPoint("LEFT", prevButton, "RIGHT", 4, 0)
                        else
                            slotButton:SetPoint("LEFT", self, "LEFT", 7, 0)
                        end
                    else
                        if prevButton then
                            slotButton:SetPoint("BOTTOM", prevButton, "TOP", 0, 4)
                        else
                            slotButton:SetPoint("BOTTOM", self, "BOTTOM", 0, 7)
                        end
                    end

                    slotButton:Show()
                    prevButton = slotButton
                end
            end
        end

        for i = usedSlots + 1, self:GetAttribute("numFlyoutButtons") do
            local slotButton = self:GetFrameRef("flyoutButton" .. i)
            if slotButton then
                slotButton:Hide()
                slotButton:SetAttribute("type", nil)
                slotButton:SetAttribute("spell", nil)
                slotButton:SetAttribute("qui-flyout-spell", nil)
                slotButton:CallMethod("TUI_ClearOwnedFlyoutVisuals")
            end
        end

        if usedSlots == 0 then
            self:SetAttribute("flyoutID", nil)
            self:Hide()
            return
        end

        local extent
        if direction == "LEFT" or direction == "RIGHT" then
            extent = 14 + usedSlots * width + (usedSlots - 1) * 4
            self:SetWidth(extent)
            self:SetHeight(height)
        else
            extent = 14 + usedSlots * height + (usedSlots - 1) * 4
            self:SetWidth(width)
            self:SetHeight(extent)
        end

        self:SetAttribute("flyoutID", flyoutID)
        self:ClearAllPoints()
        if direction == "DOWN" then
            self:SetPoint("TOP", parent, "BOTTOM", 0, -4)
        elseif direction == "LEFT" then
            self:SetPoint("RIGHT", parent, "LEFT", -4, 0)
        elseif direction == "RIGHT" then
            self:SetPoint("LEFT", parent, "RIGHT", 4, 0)
        else
            self:SetPoint("BOTTOM", parent, "TOP", 0, 4)
        end

        self:Show()
    ]])

    return ownedFlyout
end

function EnsureOwnedFlyoutButton(index)
    local btn = ownedFlyoutButtons[index]
    if btn then return btn end

    local flyout = EnsureOwnedFlyoutFrame()
    if not flyout then return nil end

    local name = "TUI_SpellFlyoutButton" .. index
    btn = CreateFrame("CheckButton", name, flyout, "ActionButtonTemplate, SecureActionButtonTemplate")
    btn:RegisterForClicks("AnyDown", "AnyUp")
    do
        local _db = GetDB()
        local _g = _db and _db.global
        btn:SetAttribute("useOnKeyDown", not _g or _g.useOnKeyDown ~= false)
    end
    btn:SetAttribute("checkselfcast", true)
    btn:SetAttribute("checkfocuscast", true)
    btn:SetAttribute("checkmouseovercast", true)
    btn:SetAttribute("type", nil)
    btn._tomomodOwnedFlyout = true

    btn:SetScript("OnDragStart", nil)
    btn:SetScript("OnReceiveDrag", nil)
    btn.TUI_UpdateOwnedFlyoutVisuals = function(self, spellID)
        ApplyOwnedFlyoutButtonVisuals(self, spellID)
        UpdateOwnedFlyoutButtonCooldown(self)
    end
    btn.TUI_ClearOwnedFlyoutVisuals = function(self)
        ApplyOwnedFlyoutButtonVisuals(self, nil)
        ClearOwnedFlyoutButtonCooldown(self)
    end
    btn:SetScript("OnEnter", function(self)
        -- TOMOMOD P1 12.1: never use a forbidden frame as a tooltip owner.
        -- Owned buttons should normally stay accessible, but this guard keeps
        -- a future protected/engine transition from turning hover into taint.
        if self.IsForbidden and self:IsForbidden() then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self._tomomodFlyoutSpellID then
            GameTooltip:SetSpellByID(self._tomomodFlyoutSpellID)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    ApplySpellFlyoutButtonStateTextures(btn)
    if btn.Name then btn.Name:SetText("") end
    if btn.Count then btn.Count:SetText("") end
    SecureHandlerWrapScript(btn, "OnClick", flyout, [[
        if not down then
            owner:SetAttribute("flyoutID", nil)
            owner:Hide()
        end
        if button == "Keybind" then
            return "LeftButton"
        end
    ]])

    flyout:SetFrameRef("flyoutButton" .. index, btn)
    ownedFlyoutButtons[index] = btn
    return btn
end

ownedFlyoutInfo = {}
ownedFlyoutInfoDiscovered = false
ownedFlyoutSeen = {}

function PopulateOwnedFlyoutInfoEntry(info, flyoutID, numSlots, isKnown)
    if not info then return end
    info.isKnown = isKnown and true or false
    info.slots = info.slots or {}

    for slot = 1, numSlots do
        local spellID, _, isKnownSlot = GetFlyoutSlotInfo(flyoutID, slot)
        if GetCallPetSpellInfo and type(spellID) == "number" and spellID > 0 then
            local petIndex, petName = GetCallPetSpellInfo(spellID)
            if petIndex and (not petName or petName == "") then
                isKnownSlot = false
            end
        end

        info.slots[slot] = info.slots[slot] or {}
        info.slots[slot].spellID = spellID
        info.slots[slot].isKnown = isKnownSlot and true or false
    end

    for slot = numSlots + 1, #info.slots do
        info.slots[slot] = nil
    end
end

local ownedFlyoutIDScratch = {}
local function CollectOwnedFlyoutIDs(out)
    wipe(out)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return out end
    local playerBank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    local flyoutType = Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout or 4
    for lineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(lineIndex)
        if lineInfo and lineInfo.numSpellBookItems then
            for i = 1, lineInfo.numSpellBookItems do
                local slotIndex = (lineInfo.itemIndexOffset or 0) + i
                local itemType, actionID = C_SpellBook.GetSpellBookItemType(slotIndex, playerBank)
                if (itemType == flyoutType or itemType == "FLYOUT")
                    and type(actionID) == "number" and actionID > 0 then
                    out[#out + 1] = actionID
                end
            end
        end
    end
    return out
end

function DiscoverOwnedFlyoutInfo()
    wipe(ownedFlyoutInfo)

    CollectOwnedFlyoutIDs(ownedFlyoutIDScratch)
    for i = 1, #ownedFlyoutIDScratch do
        local flyoutID = ownedFlyoutIDScratch[i]
        local ok, _, _, numSlots, isKnown = ns.SafeCall("best-effort-style", GetFlyoutInfo, flyoutID)
        if ok and type(numSlots) == "number" and numSlots > 0 then
            local info = { slots = {} }
            PopulateOwnedFlyoutInfoEntry(info, flyoutID, numSlots, isKnown)
            ownedFlyoutInfo[flyoutID] = info
        end
    end

    ownedFlyoutInfoDiscovered = true
end

function UpdateOwnedFlyoutInfo()
    if not ownedFlyoutInfoDiscovered then
        DiscoverOwnedFlyoutInfo()
        return
    end

    local seen = ownedFlyoutSeen
    wipe(seen)
    CollectOwnedFlyoutIDs(ownedFlyoutIDScratch)
    for i = 1, #ownedFlyoutIDScratch do
        local flyoutID = ownedFlyoutIDScratch[i]
        local ok, _, _, numSlots, isKnown = ns.SafeCall("best-effort-style", GetFlyoutInfo, flyoutID)
        if ok and type(numSlots) == "number" and numSlots > 0 then
            local info = ownedFlyoutInfo[flyoutID] or { slots = {} }
            PopulateOwnedFlyoutInfoEntry(info, flyoutID, numSlots, isKnown)
            ownedFlyoutInfo[flyoutID] = info
            seen[flyoutID] = true
        end
    end

    for flyoutID in pairs(ownedFlyoutInfo) do
        if not seen[flyoutID] then
            ownedFlyoutInfo[flyoutID] = nil
        end
    end
    wipe(seen)
end

HideOwnedFlyout = function()
    if ownedFlyout then
        if InCombatLockdown() then
            return
        end
        ownedFlyout:Hide()
        ownedFlyout:SetAttribute("flyoutID", nil)
    end
end
ActionBarsOwned.HideOwnedFlyout = HideOwnedFlyout

SyncOwnedFlyoutInfoToHandler = function()
    if not USE_OWNED_FLYOUT then return end
    if InCombatLockdown() then
        ActionBarsOwned.pendingOwnedFlyoutSync = true
        return
    end

    local flyout = EnsureOwnedFlyoutFrame()
    if not flyout then return end

    UpdateOwnedFlyoutInfo()
    local maxNumSlots = 0
    local lines = { "TUI_FlyoutInfo = newtable();\n" }
    for flyoutID, info in pairs(ownedFlyoutInfo) do
        if info and info.slots and #info.slots > 0 then
            if #info.slots > maxNumSlots then
                maxNumSlots = #info.slots
            end

            lines[#lines + 1] = ("TUI_FlyoutInfo[%d] = newtable();TUI_FlyoutInfo[%d].slots = newtable();\n"):format(flyoutID, flyoutID)
            for slotID, slotInfo in ipairs(info.slots) do
                local spellID = (slotInfo and type(slotInfo.spellID) == "number" and slotInfo.spellID > 0) and slotInfo.spellID or 0
                lines[#lines + 1] = ("TUI_FlyoutInfo[%d].slots[%d] = newtable();TUI_FlyoutInfo[%d].slots[%d].spellID = %d;TUI_FlyoutInfo[%d].slots[%d].isKnown = %s;\n")
                    :format(flyoutID, slotID, flyoutID, slotID, spellID, flyoutID, slotID, slotInfo and slotInfo.isKnown and "true" or "nil")
            end
        end
    end
    local data = table.concat(lines)

    if maxNumSlots > #ownedFlyoutButtons then
        for i = #ownedFlyoutButtons + 1, maxNumSlots do
            EnsureOwnedFlyoutButton(i)
        end
        flyout:SetAttribute("numFlyoutButtons", #ownedFlyoutButtons)
    end

    if data ~= lastOwnedFlyoutSyncPayload then
        flyout:Execute(data)
        lastOwnedFlyoutSyncPayload = data
    end

    ActionBarsOwned.pendingOwnedFlyoutSync = false
end

do
    local cdEventFrame = CreateFrame("Frame")
    cdEventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    cdEventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    cdEventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    cdEventFrame:SetScript("OnEvent", UpdateAllOwnedFlyoutButtonCooldowns)
end

end

function IsSpellFlyoutButtonFrame(button, flyout)
    if not button then return false end
    if flyout and button.GetParent and button:GetParent() == flyout then
        return true
    end

    local name = button.GetName and button:GetName()
    if not name then return false end

    return name:match("^SpellFlyoutButton%d+$") ~= nil
        or name:match("^SpellFlyoutPopupButton%d+$") ~= nil
end

spellFlyoutButtonsScratch = {}
spellFlyoutSeenScratch = {}

function AddCollectedSpellFlyoutButton(button, flyout, buttons, seen)
    if not button or seen[button] then return end
    if not (button.IsObjectType and button:IsObjectType("Button")) then return end
    if not IsSpellFlyoutButtonFrame(button, flyout) then return end

    seen[button] = true
    buttons[#buttons + 1] = button
end

function CollectSpellFlyoutButtons(flyout)
    local buttons, seen = spellFlyoutButtonsScratch, spellFlyoutSeenScratch
    wipe(buttons)
    wipe(seen)

    if flyout and flyout.GetChildren then
        local nChildren = select('#', flyout:GetChildren())
        for i = 1, nChildren do
            local child = select(i, flyout:GetChildren())
            AddCollectedSpellFlyoutButton(child, flyout, buttons, seen)
            if child and child.GetChildren then
                local nGrand = select('#', child:GetChildren())
                for j = 1, nGrand do
                    local grandChild = select(j, child:GetChildren())
                    AddCollectedSpellFlyoutButton(grandChild, flyout, buttons, seen)
                end
            end
        end
    end

    for i = 1, 40 do
        AddCollectedSpellFlyoutButton(_G["SpellFlyoutButton" .. i], flyout, buttons, seen)
        AddCollectedSpellFlyoutButton(_G["SpellFlyoutPopupButton" .. i], flyout, buttons, seen)
    end

    wipe(seen)
    return buttons
end

function GetSpellFlyoutSkinSettings(flyout)
    local sourceBarKey = GetSpellFlyoutSourceBarKey(flyout)
    if sourceBarKey then
        local sourceSettings = GetEffectiveSettings(sourceBarKey)
        if sourceSettings then
            return sourceSettings
        end
    end

    return GetGlobalSettings()
end

function GetSpellFlyoutSourceButtonSize(flyout)
    local sourceButton = GetSpellFlyoutSourceButton(flyout)
    if not (sourceButton and sourceButton.GetSize) then
        return nil, nil
    end

    local rawW, rawH = sourceButton:GetSize()
    local width = Helpers.SafeToNumber(rawW)
    local height = Helpers.SafeToNumber(rawH)
    if not width or not height or width <= 0 or height <= 0 then
        return nil, nil
    end

    return width, height
end

function SkinSpellFlyoutContainer(flyout)
    if not flyout then return end

    local bg = flyout.Background
    if not bg then return end

    if bg.Start then bg.Start:SetAlpha(0) end
    if bg.End then bg.End:SetAlpha(0) end
    if bg.HorizontalMiddle then bg.HorizontalMiddle:SetAlpha(0) end
    if bg.VerticalMiddle then bg.VerticalMiddle:SetAlpha(0) end
end

ApplySpellFlyoutButtonStateTextures = function(button)
    if not button then return end

    if button.SetHitRectInsets then
        button:SetHitRectInsets(0, 0, 0, 0)
    end

    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then
        normal:SetAlpha(0)
        normal:ClearAllPoints()
        normal:SetAllPoints(button)
    end

    local pushed = button.GetPushedTexture and button:GetPushedTexture()
    if pushed then
        pushed:SetTexture(TEXTURES.pushed)
        pushed:ClearAllPoints()
        pushed:SetAllPoints(button)
    end

    local checked = button.GetCheckedTexture and button:GetCheckedTexture()
    if checked then
        checked:SetTexture(TEXTURES.checked)
        checked:ClearAllPoints()
        checked:SetAllPoints(button)
    end

    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then
        highlight:SetTexture(TEXTURES.highlight)
        highlight:ClearAllPoints()
        highlight:SetAllPoints(button)
    end
end

SkinSpellFlyoutButtons = function()
    if ActionBarsOwned.useOwnedFlyout then return end
    local flyout = _G.SpellFlyout
    if not (flyout and flyout.IsShown and flyout:IsShown()) then return end
    if InCombatLockdown() then
        ActionBarsOwned.pendingFlyoutSkin = true
        return
    end

    SkinSpellFlyoutContainer(flyout)

    local settings = GetSpellFlyoutSkinSettings(flyout)
    if not (settings and settings.skinEnabled) then return end

    local sourceWidth, sourceHeight = GetSpellFlyoutSourceButtonSize(flyout)

    for _, button in ipairs(CollectSpellFlyoutButtons(flyout)) do
        if sourceWidth and sourceHeight and button.SetSize then
            button:SetSize(sourceWidth, sourceHeight)
        end
        ApplySpellFlyoutButtonStateTextures(button)
        SkinButton(button, settings)
    end

    if flyout.Layout then
        flyout:Layout()
    end
end

function HookSpellFlyoutSkinning()
    if spellFlyoutSkinHooked then return end

    local flyout = _G.SpellFlyout
    if not flyout then return end

    spellFlyoutSkinHooked = true
    flyout:HookScript("OnShow", function()
        C_Timer.After(0, SkinSpellFlyoutButtons)
    end)
end

ActionBarsOwned.HookSpellFlyoutSkinning = HookSpellFlyoutSkinning

end

do

-- Blizzard's native page-number/arrow controls belong to MainActionBar.
-- TUI paging does not need them, so the public option handler deliberately
-- avoids touching these controller-owned frames.
ApplyPageArrowVisibility = function(hide)
    return
end

_G.TUI_ApplyPageArrowVisibility = ApplyPageArrowVisibility

end

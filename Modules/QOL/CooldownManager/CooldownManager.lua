-- =====================================
-- CooldownManager.lua
-- Module de reskin des icônes Blizzard CooldownManager
-- Bordures 1px noires, overlay classe, CD texte custom,
-- alignement centré des buffs, hotkeys optionnels
-- =====================================

TomoMod_CooldownManager = TomoMod_CooldownManager or {}
local CDM = TomoMod_CooldownManager

-- =====================================
-- CONSTANTES
-- =====================================
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BORDER_SIZE = 1
local ICON_INSET = 2 -- pixels inset for icon inside border
local SPACING = 1 -- gap between icons
local TICK_RATE = 0.05 -- 20fps for smooth CD text

-- =====================================
-- STATE
-- =====================================
local _, playerClass = UnitClass("player")
local classColor = RAID_CLASS_COLORS[playerClass]
local hotkeys = {}
local viewers = {}
local cdViewers = {} -- Essential + Utility only
local todoList = {}
local isInitialized = false
local mainFrame, updateFrame, tickerFrame

-- =====================================
-- UTILS
-- =====================================
local function GetSettings()
    return TomoModDB and TomoModDB.cooldownManager
end

local function FormatCooldown(remaining)
    if remaining >= 60 then
        return string.format("%dm", math.ceil(remaining / 60))
    elseif remaining >= 10 then
        return string.format("%d", math.floor(remaining))
    elseif remaining >= 0 then
        return string.format("%.1f", remaining)
    end
    return ""
end

local function FormatDuration(remaining)
    if remaining >= 60 then
        return string.format("%dm", math.ceil(remaining / 60))
    elseif remaining >= 10 then
        return string.format("%d", math.floor(remaining))
    else
        return string.format("%.0f", remaining)
    end
end

-- =====================================
-- HOTKEY SYSTEM
-- =====================================
local function CheckKeyName(name)
    name = string.gsub(name, "Num Pad ", "")
    name = string.gsub(name, "Num Pad", "")
    name = string.gsub(name, "Middle Mouse", "M3")
    name = string.gsub(name, "Mouse Button (%d)", "M%1")
    name = string.gsub(name, "Mouse Wheel Up", "MU")
    name = string.gsub(name, "Mouse Wheel Down", "MD")
    name = string.gsub(name, "^s%-", "S")
    name = string.gsub(name, "^a%-", "A")
    name = string.gsub(name, "^c%-", "C")
    name = string.gsub(name, "Delete", "Dt")
    name = string.gsub(name, "Page Down", "Pd")
    name = string.gsub(name, "Page Up", "Pu")
    name = string.gsub(name, "Insert", "In")
    name = string.gsub(name, "Del", "Dt")
    name = string.gsub(name, "Home", "Hm")
    name = string.gsub(name, "Capslock", "Ck")
    name = string.gsub(name, "Num Lock", "Nk")
    name = string.gsub(name, "Scroll Lock", "Sk")
    name = string.gsub(name, "Backspace", "Bs")
    name = string.gsub(name, "Spacebar", "Sb")
    name = string.gsub(name, "End", "Ed")
    name = string.gsub(name, "Up Arrow", "^")
    name = string.gsub(name, "Down Arrow", "V")
    name = string.gsub(name, "Right Arrow", ">")
    name = string.gsub(name, "Left Arrow", "<")
    return name
end

local function ScanKeys(barName, total)
    for i = 1, total do
        local actionButton = _G[barName .. i]
        if not actionButton then break end
        local hotkey = _G[actionButton:GetName() .. "HotKey"]
        if not hotkey then break end
        local text = hotkey:GetText()
        local slot = actionButton.action
        if slot and text then
            hotkeys[slot] = CheckKeyName(text)
        end
    end
end

local function CheckHotkeys()
    wipe(hotkeys)
    ScanKeys("ActionButton", 12)
    ScanKeys("MultiBarBottomLeftButton", 12)
    ScanKeys("MultiBarBottomRightButton", 12)
    ScanKeys("MultiBarRightButton", 12)
    ScanKeys("MultiBarLeftButton", 12)
    ScanKeys("MultiBar5Button", 12)
    ScanKeys("MultiBar6Button", 12)
    ScanKeys("MultiBar7Button", 12)
    ScanKeys("BonusActionButton", 12)
    ScanKeys("ExtraActionButton", 12)
    ScanKeys("VehicleMenuBarActionButton", 12)
    ScanKeys("OverrideActionBarButton", 12)
    ScanKeys("PetActionButton", 10)
end

local function GetSpellHotkey(spellID)
    local slots = C_ActionBar.FindSpellActionButtons(spellID)
    if slots and #slots > 0 then
        for _, slot in ipairs(slots) do
            if hotkeys[slot] then return hotkeys[slot] end
        end
    end
    return nil
end

-- =====================================
-- STYLE: APPLY CLEAN BORDER + ICON CROP
-- =====================================
local function StyleButton(button, isBuff)
    if button._cdm_styled then return end
    button._cdm_styled = true

    local width = button:GetWidth()
    local rate = isBuff and 0.85 or 0.92
    local iconRate = isBuff and 0.12 or 0.07

    -- Resize button slightly rectangular
    button:SetSize(width, width * rate)

    -- Strip mask, crop icon
    if button.Icon then
        local mask = button.Icon:GetMaskTexture(1)
        if mask then button.Icon:RemoveMaskTexture(mask) end
        button.Icon:ClearAllPoints()
        button.Icon:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
        button.Icon:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
        button.Icon:SetTexCoord(0.07, 0.93, iconRate, 1 - iconRate)
    end

    -- 1px black border (4 edge textures)
    button._cdm_borders = {}
    local edges = {
        { "TOPLEFT", "TOPRIGHT", 0, 0, 0, BORDER_SIZE },       -- top
        { "BOTTOMLEFT", "BOTTOMRIGHT", 0, -BORDER_SIZE, 0, 0 }, -- bottom
        { "TOPLEFT", "BOTTOMLEFT", 0, 0, BORDER_SIZE, 0 },     -- left
        { "TOPRIGHT", "BOTTOMRIGHT", -BORDER_SIZE, 0, 0, 0 },  -- right
    }
    for _, e in ipairs(edges) do
        local t = button:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        t:SetPoint(e[1], button, e[1], e[3], e[4])
        t:SetPoint(e[2], button, e[2], e[5], e[6])
        table.insert(button._cdm_borders, t)
    end

    -- Class-colored overlay glow (shown when spell is active/aura)
    button._cdm_classOverlay = button:CreateTexture(nil, "OVERLAY", nil, 6)
    button._cdm_classOverlay:SetPoint("TOPLEFT", 0, 0)
    button._cdm_classOverlay:SetPoint("BOTTOMRIGHT", 0, 0)
    button._cdm_classOverlay:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.25)
    button._cdm_classOverlay:Hide()

    -- Class-colored border overlay (replaces black border when active)
    button._cdm_activeBorders = {}
    local activeEdges = {
        { "TOPLEFT", "TOPRIGHT", 0, 0, 0, BORDER_SIZE },
        { "BOTTOMLEFT", "BOTTOMRIGHT", 0, -BORDER_SIZE, 0, 0 },
        { "TOPLEFT", "BOTTOMLEFT", 0, 0, BORDER_SIZE, 0 },
        { "TOPRIGHT", "BOTTOMRIGHT", -BORDER_SIZE, 0, 0, 0 },
    }
    for _, e in ipairs(activeEdges) do
        local t = button:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(classColor.r, classColor.g, classColor.b, 1)
        t:SetPoint(e[1], button, e[1], e[3], e[4])
        t:SetPoint(e[2], button, e[2], e[5], e[6])
        t:Hide()
        table.insert(button._cdm_activeBorders, t)
    end

    -- Custom CD text (center of icon)
    button._cdm_cdText = button:CreateFontString(nil, "OVERLAY", nil)
    button._cdm_cdText:SetFont(FONT, isBuff and (width / 3) or (width / 2.8), "OUTLINE")
    button._cdm_cdText:SetShadowOffset(1, -1)
    button._cdm_cdText:SetShadowColor(0, 0, 0, 1)
    if isBuff then
        button._cdm_cdText:SetPoint("TOP", button, "TOP", 0, -1)
    else
        button._cdm_cdText:SetPoint("CENTER", 0, 0)
    end

    -- Charge count styling
    if button.ChargeCount then
        for _, r in next, {button.ChargeCount:GetRegions()} do
            if r:GetObjectType() == "FontString" then
                r:SetFont(FONT, width / 3, "OUTLINE")
                r:ClearAllPoints()
                r:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
                r:SetTextColor(0.2, 1, 0.2)
                r:SetDrawLayer("OVERLAY")
                break
            end
        end
    end

    -- Applications (stack count)
    if button.Applications then
        for _, r in next, {button.Applications:GetRegions()} do
            if r:GetObjectType() == "FontString" then
                r:SetFont(FONT, width / 3, "OUTLINE")
                r:ClearAllPoints()
                r:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
                r:SetTextColor(0.2, 1, 0.2)
                r:SetDrawLayer("OVERLAY")
                break
            end
        end
    end

    -- DebuffBorder cleanup
    if button.DebuffBorder then
        button.DebuffBorder:ClearAllPoints()
        button.DebuffBorder:SetPoint("TOPLEFT", -2, 2)
        button.DebuffBorder:SetPoint("BOTTOMRIGHT", 2, -2)
    end

    -- Hide Blizzard's default CD text
    if button.Cooldown then
        button.Cooldown:SetHideCountdownNumbers(true)
        for _, r in next, {button.Cooldown:GetRegions()} do
            if r:GetObjectType() == "FontString" then
                r:SetAlpha(0)
                break
            end
        end
    end

    -- Hotkey text (cooldown viewers only)
    if not isBuff then
        button._cdm_hotkey = button:CreateFontString(nil, "OVERLAY")
        button._cdm_hotkey:SetFont(FONT, math.max(8, width / 4 - 1), "OUTLINE")
        button._cdm_hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
        button._cdm_hotkey:SetTextColor(0.9, 0.9, 0.9, 0.9)
        button._cdm_hotkey:SetShadowOffset(1, -1)
        button._cdm_hotkey:SetShadowColor(0, 0, 0, 1)
        button._cdm_hotkey:Hide()
    end
end

-- =====================================
-- UPDATE ACTIVE STATE + CD TEXT
-- =====================================
local function UpdateButtonState(button, isBuff)
    if not button._cdm_styled then return end

    -- Active state: cooldownUseAuraDisplayTime means spell is currently active/buffed
    local isActive = (button.cooldownUseAuraDisplayTime == true)

    -- Toggle class-colored overlay + border
    if isActive then
        button._cdm_classOverlay:Show()
        for _, t in ipairs(button._cdm_activeBorders) do t:Show() end
        for _, t in ipairs(button._cdm_borders) do t:Hide() end
    else
        button._cdm_classOverlay:Hide()
        for _, t in ipairs(button._cdm_activeBorders) do t:Hide() end
        for _, t in ipairs(button._cdm_borders) do t:Show() end
    end

    -- Custom CD text
    if button.Cooldown then
        local start, duration = button.Cooldown:GetCooldownTimes()
        -- TWW: GetCooldownTimes may return secrets — can't do boolean test or compare
        -- Must use type() first (no boolean test), then issecretvalue() before arithmetic
        if type(start) ~= "nil" and type(duration) ~= "nil"
            and not issecretvalue(start) and not issecretvalue(duration) then
            if start > 0 and duration > 0 then
                local now = GetTime()
                local startSec = start / 1000
                local durSec = duration / 1000
                local remaining = startSec + durSec - now
                if remaining > 0 then
                    if isBuff then
                        button._cdm_cdText:SetText(FormatDuration(remaining))
                        button._cdm_cdText:SetTextColor(1, 1, 1)
                    else
                        button._cdm_cdText:SetText(FormatCooldown(remaining))
                        if remaining < 3 then
                            button._cdm_cdText:SetTextColor(1, 0.8, 0)
                        else
                            button._cdm_cdText:SetTextColor(1, 1, 1)
                        end
                    end
                    button._cdm_cdText:Show()
                    return
                end
            end
        end
    end
    button._cdm_cdText:Hide()
end

-- =====================================
-- HOTKEY UPDATE
-- =====================================
local function UpdateButtonHotkey(button)
    local settings = GetSettings()
    if not settings or not settings.showHotKey or not button._cdm_hotkey then return end

    local spellID = button:GetSpellID()
    if type(spellID) ~= "nil" and not (issecretvalue and issecretvalue(spellID)) then
        button._cdm_spellID = spellID
        local keyText = GetSpellHotkey(spellID)
        if keyText then
            button._cdm_hotkey:SetText(keyText)
            button._cdm_hotkey:Show()
        else
            button._cdm_hotkey:Hide()
        end
    end
end

-- =====================================
-- BUFF BAR RESKIN
-- =====================================
local function StyleBuffBar(item)
    if item._cdm_styled then return end
    item._cdm_styled = true

    if item.Bar then
        local bar = item.Bar
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
        bar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 0.85)
        if bar.BarBG then bar.BarBG:Hide() end
        bar.Name:Hide()

        -- 1px border around bar
        if not bar._cdm_bg then
            bar._cdm_bg = bar:CreateTexture(nil, "BACKGROUND")
            bar._cdm_bg:SetPoint("TOPLEFT", -BORDER_SIZE, BORDER_SIZE)
            bar._cdm_bg:SetPoint("BOTTOMRIGHT", BORDER_SIZE, -BORDER_SIZE)
            bar._cdm_bg:SetColorTexture(0, 0, 0, 1)
        end
    end

    if item.Icon then
        local btn = item.Icon
        local h = item.Bar and item.Bar:GetHeight() or 14
        local w = h * 1.15

        btn:SetSize(w, h)
        if btn.Icon then
            local mask = btn.Icon:GetMaskTexture(1)
            if mask then btn.Icon:RemoveMaskTexture(mask) end
            btn.Icon:ClearAllPoints()
            btn.Icon:SetPoint("TOPLEFT", 1, -1)
            btn.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
            btn.Icon:SetTexCoord(0.07, 0.93, 0.1, 0.9)
        end

        -- Border
        if not btn._cdm_border then
            btn._cdm_border = btn:CreateTexture(nil, "BACKGROUND")
            btn._cdm_border:SetAllPoints(btn)
            btn._cdm_border:SetColorTexture(0, 0, 0, 1)
        end

        if btn.Applications then
            local r = btn.Applications
            if r:GetObjectType() == "FontString" then
                r:SetFont(FONT, h / 2 + 2, "OUTLINE")
                r:SetTextColor(0.2, 1, 0.2)
            end
        end
    end
end

-- =====================================
-- LAYOUT: CENTERED ALIGNMENT
-- Essential/Utility: simple centered rows
-- Buffs: center-outward pattern (1 center, 2 left, 3 right...)
-- =====================================
local function LayoutViewer(viewer, isBuff)
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then return end

    local children = { viewer:GetChildren() }
    local visible = {}
    for _, child in ipairs(children) do
        if child:IsShown() then
            local point, relativeTo, relativePoint, x, y = child:GetPoint(1)
            child._cdm_origX = x or 0
            child._cdm_origY = y or 0
            table.insert(visible, child)
        end
    end

    if #visible == 0 then return end

    -- Style all visible buttons
    local isBar = (viewer == BuffBarCooldownViewer)
    if isBar then
        for _, item in ipairs(visible) do
            StyleBuffBar(item)
        end
        return
    end

    for _, button in ipairs(visible) do
        StyleButton(button, isBuff)
        UpdateButtonHotkey(button)
    end

    -- Only re-layout horizontal viewers
    if not viewer.isHorizontal then return end

    local stride = viewer.stride or 8
    local btnW = visible[1]:GetWidth()
    local btnH = visible[1]:GetHeight()
    local numIcons = #visible

    -- Sort by original position (row then column)
    table.sort(visible, function(a, b)
        if math.abs(a._cdm_origY - b._cdm_origY) < 1 then
            return a._cdm_origX < b._cdm_origX
        end
        return a._cdm_origY > b._cdm_origY
    end)

    if isBuff then
        -- ======================================
        -- BUFF CENTER-OUTWARD PATTERN
        -- 1st: center, 2nd: left, 3rd: right, 4th: further left, 5th: further right...
        -- ======================================
        local gap = SPACING
        local positions = {}

        for i = 1, numIcons do
            if i == 1 then
                positions[i] = 0
            else
                local slot = math.ceil((i - 1) / 2)
                local isRight = ((i - 1) % 2 == 1) -- odd offset = right
                if isRight then
                    positions[i] = slot * (btnW + gap)
                else
                    positions[i] = -slot * (btnW + gap)
                end
            end
        end

        for i, child in ipairs(visible) do
            child:ClearAllPoints()
            child:SetPoint("TOP", viewer, "TOP", positions[i], 0)
        end
    else
        -- ======================================
        -- ESSENTIAL / UTILITY: simple centered rows
        -- ======================================
        local gap = SPACING

        for i, child in ipairs(visible) do
            local index = i - 1
            local row = math.floor(index / stride)
            local col = index % stride

            local rowStart = row * stride + 1
            local rowEnd = math.min(rowStart + stride - 1, numIcons)
            local iconsInRow = rowEnd - rowStart + 1

            local rowWidth = iconsInRow * btnW + (iconsInRow - 1) * gap
            local startX = -rowWidth / 2

            local xOff = startX + col * (btnW + gap)
            local yOff = row * (btnH + gap)

            child:ClearAllPoints()
            child:SetPoint("TOP", viewer, "TOP", xOff + btnW / 2, -yOff)
        end
    end
end

-- =====================================
-- TICKER: Update CD text + active state
-- =====================================
local function TickerUpdate()
    for _, viewer in ipairs(viewers) do
        if viewer and viewer:IsShown() then
            local isBar = (viewer == BuffBarCooldownViewer)
            if not isBar then
                local isBuff = (viewer == BuffIconCooldownViewer)
                local children = { viewer:GetChildren() }
                for _, button in ipairs(children) do
                    if button:IsShown() and button._cdm_styled then
                        UpdateButtonState(button, isBuff)
                    end
                end
            end
        end
    end
end

-- =====================================
-- TODO LIST (deferred layout)
-- =====================================
local function AddToDoList(viewer)
    todoList[viewer] = true
    if updateFrame then updateFrame:Show() end
end

-- =====================================
-- ALPHA MANAGEMENT
-- =====================================
local function UpdateAlpha()
    local settings = GetSettings()
    if not settings or not settings.combatAlpha then return end

    local alpha
    if UnitAffectingCombat("player") then
        alpha = settings.alphaInCombat or 1.0
    elseif UnitExists("target") then
        alpha = settings.alphaWithTarget or 0.8
    else
        alpha = settings.alphaOutOfCombat or 0.5
    end

    for _, viewer in ipairs(viewers) do
        if viewer then viewer:SetAlpha(alpha) end
    end
end

-- =====================================
-- HOTKEY VISIBILITY
-- =====================================
local function RefreshHotkeyVisibility()
    local settings = GetSettings()
    if not settings then return end

    for _, viewer in ipairs(cdViewers) do
        if viewer then
            local children = { viewer:GetChildren() }
            for _, button in ipairs(children) do
                if button._cdm_hotkey then
                    if settings.showHotKey then
                        UpdateButtonHotkey(button)
                    else
                        button._cdm_hotkey:Hide()
                    end
                end
            end
        end
    end
end

-- =====================================
-- INIT
-- =====================================
local function InitViewers()
    if not UtilityCooldownViewer then return false end

    CheckHotkeys()

    viewers = {
        EssentialCooldownViewer,
        UtilityCooldownViewer,
        BuffIconCooldownViewer,
        BuffBarCooldownViewer,
    }

    cdViewers = {
        EssentialCooldownViewer,
        UtilityCooldownViewer,
    }

    -- Hook Layout on each viewer
    for _, viewer in ipairs(viewers) do
        if viewer then
            local isBuff = (viewer == BuffIconCooldownViewer)
            local isBar = (viewer == BuffBarCooldownViewer)

            -- Initial layout
            if isBar then
                local children = { viewer:GetChildren() }
                for _, item in ipairs(children) do
                    if item:IsShown() then StyleBuffBar(item) end
                end
            else
                LayoutViewer(viewer, isBuff)
            end

            -- Hook Layout
            if viewer.Layout then
                hooksecurefunc(viewer, "Layout", function()
                    AddToDoList(viewer)
                end)
            end

            -- Hook child Show/Hide
            local children = { viewer:GetChildren() }
            for _, child in ipairs(children) do
                child:HookScript("OnShow", function() AddToDoList(viewer) end)
                child:HookScript("OnHide", function() AddToDoList(viewer) end)
            end
        end
    end

    -- Ticker for CD text + active state
    tickerFrame = CreateFrame("Frame")
    tickerFrame.elapsed = 0
    tickerFrame:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= TICK_RATE then
            self.elapsed = 0
            TickerUpdate()
        end
    end)

    -- Deferred layout processor
    updateFrame = CreateFrame("Frame")
    updateFrame:Hide()
    updateFrame:SetScript("OnUpdate", function(self)
        self:Hide()
        for viewer in pairs(todoList) do
            todoList[viewer] = nil
            local isBuff = (viewer == BuffIconCooldownViewer)
            LayoutViewer(viewer, isBuff)
        end
    end)

    -- Initial alpha
    UpdateAlpha()

    isInitialized = true
    return true
end

-- =====================================
-- EVENT HANDLER
-- =====================================
local function OnEvent(self, event, arg1)
    local settings = GetSettings()
    if not settings then return end

    if event == "ADDON_LOADED" and arg1 == "Blizzard_CooldownManager" then
        C_Timer.After(0.5, function()
            if not isInitialized then InitViewers() end
        end)

    elseif event == "PLAYER_ENTERING_WORLD" or event == "TRAIT_CONFIG_UPDATED"
        or event == "TRAIT_CONFIG_LIST_UPDATED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        C_Timer.After(0.5, function()
            if not isInitialized then InitViewers() end
            CheckHotkeys()
            RefreshHotkeyVisibility()
            UpdateAlpha()
        end)

    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_TARGET_CHANGED" then
        if settings.combatAlpha then
            UpdateAlpha()
        end

    elseif event == "UPDATE_BONUS_ACTIONBAR" or event == "ACTIONBAR_SLOT_CHANGED" then
        C_Timer.After(0.1, function()
            CheckHotkeys()
            RefreshHotkeyVisibility()
        end)
    end
end

-- =====================================
-- PUBLIC API
-- =====================================
function CDM.Initialize()
    if not TomoModDB or not TomoModDB.cooldownManager then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    mainFrame = CreateFrame("Frame")
    mainFrame:RegisterEvent("ADDON_LOADED")
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    mainFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    mainFrame:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
    mainFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    mainFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    mainFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    mainFrame:SetScript("OnEvent", OnEvent)
end

function CDM.ApplySettings()
    if not isInitialized then return end
    local settings = GetSettings()
    if not settings then return end

    RefreshHotkeyVisibility()

    if settings.combatAlpha then
        UpdateAlpha()
    else
        for _, viewer in ipairs(viewers) do
            if viewer then viewer:SetAlpha(1) end
        end
    end

    -- Re-layout all viewers
    for _, viewer in ipairs(viewers) do
        if viewer then
            local isBuff = (viewer == BuffIconCooldownViewer)
            LayoutViewer(viewer, isBuff)
        end
    end
end

function CDM.SetEnabled(enabled)
    local settings = GetSettings()
    if settings then
        settings.enabled = enabled
        if enabled and not isInitialized then
            InitViewers()
        end
    end
end

-- Export
_G.TomoMod_CooldownManager = CDM

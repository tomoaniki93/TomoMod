-- =====================================
-- CombatInfo.lua
-- Module d'amélioration des buffs/cooldowns
-- =====================================

TomoMod_CombatInfo = TomoMod_CombatInfo or {}
local CI = TomoMod_CombatInfo

-- =====================================
-- CONSTANTES
-- =====================================
local COMBAT_ALPHA = 1
local NORMAL_ALPHA = 0.5
local FONT = STANDARD_TEXT_FONT

-- =====================================
-- VARIABLES DU MODULE
-- =====================================
local _, playerClass = UnitClass("player")
local classColor = RAID_CLASS_COLORS[playerClass]
local hotkeys = {}
local nextSpellID = nil
local mainFrame
local updateFrame
local todoList = {}
local isInitialized = false

-- Viewers Blizzard
local viewers = {}
local keyViewers = {}

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.combatInfo then
        return nil
    end
    return TomoModDB.combatInfo
end

-- =====================================
-- GESTION DES HOTKEYS
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
        if not actionButton then
            break
        end
        
        local hotkey = _G[actionButton:GetName() .. "HotKey"]
        if not hotkey then
            break
        end
        
        local text = hotkey:GetText()
        local slot = actionButton.action
        if slot and text then
            if not hotkeys[slot] then
                hotkeys[slot] = CheckKeyName(text)
            end
        end
    end
end

local function CheckHotkeys()
    local settings = GetSettings()
    if not settings or not settings.showHotKey then
        return
    end
    
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
            local text = hotkeys[slot]
            if text then
                return text
            end
        end
    end
    return nil
end

-- =====================================
-- UPDATE DES BUFF BARS
-- =====================================
local function UpdateBars(viewer)
    local settings = GetSettings()
    if not settings or not settings.changeBuffBar then
        return
    end
    
    local children = {viewer:GetChildren()}
    local visibleChildren = {}
    for _, child in ipairs(children) do
        if child:IsShown() then
            table.insert(visibleChildren, child)
        end
    end
    
    if #visibleChildren == 0 then
        return
    end
    
    for _, item in ipairs(visibleChildren) do
        if settings.hideBarName and item.Bar then
            item.Bar.Name:Hide()
        end
        
        if not item.bconfiged then
            item.bconfiged = true
            
            if item.Bar then
                local bar = item.Bar
                bar:SetStatusBarTexture("RaidFrame-Hp-Fill")
                if settings.buffBarClassColor then
                    bar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
                end
                bar.BarBG:Hide()
                
                bar.bg = bar:CreateTexture(nil, "BACKGROUND")
                bar.bg:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
                bar.bg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
                bar.bg:SetColorTexture(0, 0, 0, 1)
            end
            
            if item.Icon then
                local button = item.Icon
                local height = item.Bar:GetHeight()
                
                local rate = 1.2
                local iconRate = 0.16
                button:SetSize(height * rate, height)
                button.Icon:ClearAllPoints()
                button.Icon:SetPoint("CENTER", 0, 0)
                button.Icon:SetSize(height * rate - 2, height - 2)
                button.Icon:SetTexCoord(0.08, 0.92, iconRate, 1 - iconRate)
                
                if not button.border then
                    button.border = button:CreateTexture(nil, "BACKGROUND")
                    button.border:SetAllPoints(button)
                    button.border:SetColorTexture(0, 0, 0, 1)
                else
                    button.border:SetAlpha(1)
                end
                button.border:Show()
                
                if button.Applications then
                    local r = button.Applications
                    if r:GetObjectType() == "FontString" then
                        r:SetFont(FONT, height / 2 + 3, "OUTLINE")
                        r:SetTextColor(0, 1, 0)
                    end
                end
            end
        end
    end
end

-- =====================================
-- UPDATE DES BUTTONS (BUFFS/COOLDOWNS)
-- =====================================
local function UpdateButtons(viewer)
    -- Ne pas modifier en Edit Mode
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end
    
    local settings = GetSettings()
    if not settings then return end
    
    local isBar = (viewer == BuffBarCooldownViewer)
    if isBar then
        UpdateBars(viewer)
        return
    end
    
    local children = {viewer:GetChildren()}
    local isBuff = (viewer == BuffIconCooldownViewer)
    
    local visibleChildren = {}
    for _, child in ipairs(children) do
        if child:IsShown() then
            local point, relativeTo, relativePoint, x, y = child:GetPoint(1)
            child.originalX = x or 0
            child.originalY = y or 0
            table.insert(visibleChildren, child)
        end
    end
    
    if #visibleChildren == 0 then
        return
    end
    
    for _, button in ipairs(visibleChildren) do
        local rate = 0.9
        local iconRate = 0.088
        
        if isBuff then
            rate = 0.8
            iconRate = 0.16
        end
        
        if not button.bconfiged then
            local width = button:GetWidth()
            button.bconfiged = true
            button:SetSize(width, width * rate)
            
            if button.Icon then
                local mask = button.Icon:GetMaskTexture(1)
                if mask then
                    button.Icon:RemoveMaskTexture(mask)
                end
                button.Icon:ClearAllPoints()
                button.Icon:SetPoint("CENTER", 0, 0)
                button.Icon:SetSize(width - 4, width * rate - 4)
                button.Icon:SetTexCoord(0.08, 0.92, iconRate, 1 - iconRate)
            end
            
            if button.ChargeCount then
                for _, r in next, {button.ChargeCount:GetRegions()} do
                    if r:GetObjectType() == "FontString" then
                        r:SetFont(FONT, width / 3 + 1, "OUTLINE")
                        r:ClearAllPoints()
                        r:SetPoint("CENTER", button, "BOTTOM", 0, 1)
                        r:SetTextColor(0, 1, 0)
                        r:SetDrawLayer("OVERLAY")
                        break
                    end
                end
            end
            
            if button.DebuffBorder then
                button.DebuffBorder:ClearAllPoints()
                button.DebuffBorder:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
                button.DebuffBorder:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4)
            end
            
            if button.Applications then
                for _, r in next, {button.Applications:GetRegions()} do
                    if r:GetObjectType() == "FontString" then
                        r:SetFont(FONT, width / 3 + 2, "OUTLINE")
                        r:ClearAllPoints()
                        r:SetPoint("CENTER", button, "BOTTOM", 0, 1)
                        r:SetTextColor(0, 1, 0)
                        r:SetDrawLayer("OVERLAY")
                        break
                    end
                end
            end
            
            if not button.border then
                button.border = button:CreateTexture(nil, "BACKGROUND")
                button.border:SetAllPoints(button)
                button.border:SetColorTexture(0, 0, 0, 1)
                
                button.nextspell = button:CreateTexture(nil, "OVERLAY")
                button.nextspell:SetDrawLayer("OVERLAY", 7)
                button.nextspell:SetAtlas("talents-node-circle-greenglow")
                button.nextspell:SetPoint("CENTER", button, "CENTER", 0, 0)
                button.nextspell:SetSize(width / 2 + 3, width / 2 + 3)
                button.nextsize = 1
                button.nextspell:Hide()
            else
                button.border:SetAlpha(1)
            end
            button.border:Show()
            
            if button.Cooldown then
                for _, r in next, {button.Cooldown:GetRegions()} do
                    if r:GetObjectType() == "FontString" then
                        r:SetFont(FONT, width / 3 + 1, "OUTLINE")
                        r:ClearAllPoints()
                        if isBuff then
                            r:SetPoint("CENTER", button, "TOP", 0, 0)
                        else
                            r:SetPoint("CENTER", 0, 0)
                        end
                        r:SetDrawLayer("OVERLAY")
                        break
                    end
                end
                
                button.asupdate = function()
                    if button.cooldownUseAuraDisplayTime == true then
                        button.border:SetColorTexture(0, 1, 1)
                    else
                        button.border:SetColorTexture(0, 0, 0)
                    end
                    
                    if settings.alertAssistedSpell then
                        if nextSpellID and nextSpellID == button.asspellid then
                            button.nextspell:Show()
                            if button.nextsize == 1 then
                                button.nextspell:SetSize(width / 3, width / 3)
                                button.nextsize = 0
                            else
                                button.nextspell:SetSize(width, width)
                                button.nextsize = 1
                            end
                        else
                            button.nextspell:Hide()
                        end
                    end
                end
                
                if button.astimer then
                    button.astimer:Cancel()
                end
                
                button.astimer = C_Timer.NewTicker(0.2, button.asupdate)
            end
            
            if not isBuff then
                if not button.hotkey then
                    button.hotkey = button:CreateFontString(nil, "ARTWORK")
                    button.hotkey:SetFont(FONT, width / 3 - 3, "OUTLINE")
                    button.hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
                    button.hotkey:SetTextColor(1, 1, 1, 1)
                end
            end
        end
        
        if not isBuff and settings.showHotKey then
            local spellID = button:GetSpellID()
            
            if spellID and not issecretvalue(spellID) then
                button.asspellid = spellID
                local keyText = GetSpellHotkey(spellID)
                
                if keyText then
                    button.hotkey:SetText(keyText)
                    button.hotkey:Show()
                else
                    button.hotkey:Hide()
                end
            end
        end
    end
    
    -- Repositionnement centré si nécessaire
    local isHorizontal = viewer.isHorizontal
    if not isHorizontal then
        return
    end
    
    local bCentered = true
    if isBuff and not settings.alignedBuff then
        bCentered = false
    end
    
    local stride = viewer.stride or 8
    local overlap = -4
    
    table.sort(visibleChildren, function(a, b)
        if math.abs(a.originalY - b.originalY) < 1 then
            return a.originalX < b.originalX
        end
        return a.originalY > b.originalY
    end)
    
    local buttonWidth = visibleChildren[1]:GetWidth()
    local buttonHeight = visibleChildren[1]:GetHeight()
    local numIcons = #visibleChildren
    
    for i, child in ipairs(visibleChildren) do
        if bCentered then
            local index = i - 1
            local row = math.floor(index / stride)
            local col = index % stride
            
            local rowStart = row * stride + 1
            local rowEnd = math.min(rowStart + stride - 1, numIcons)
            local iconsInRow = rowEnd - rowStart + 1
            
            local rowWidth = iconsInRow * buttonWidth + (iconsInRow - 1) * overlap
            local rowStartX = -rowWidth / 2
            
            local xOffset = rowStartX + col * (buttonWidth + overlap)
            local yOffset = row * (buttonHeight + overlap)
            child:ClearAllPoints()
            child:SetPoint("TOP", viewer, "TOP", xOffset + buttonWidth / 2, -yOffset)
        else
            local point, relativeTo, relativePoint, x, y = child:GetPoint(1)
            child:ClearAllPoints()
            child:SetPoint(point, relativeTo, relativePoint, x, 0)
        end
    end
end

-- =====================================
-- UPDATE DES HOTKEYS
-- =====================================
local function UpdateHotkey(viewer)
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end
    
    local settings = GetSettings()
    if not settings or not settings.showHotKey then
        return
    end
    
    local children = {viewer:GetChildren()}
    local visibleChildren = {}
    for _, child in ipairs(children) do
        if child:IsShown() then
            table.insert(visibleChildren, child)
        end
    end
    
    if #visibleChildren == 0 then
        return
    end
    
    for _, button in ipairs(visibleChildren) do
        if button.asspellid then
            local spellID = button.asspellid
            
            if not issecretvalue(spellID) then
                local keyText = GetSpellHotkey(spellID)
                if keyText then
                    button.hotkey:SetText(keyText)
                    button.hotkey:Show()
                else
                    button.hotkey:Hide()
                end
            end
        end
    end
end

-- =====================================
-- SYSTÈME DE MISE À JOUR
-- =====================================
local function AddToDoList(viewer)
    todoList[viewer] = true
    updateFrame:Show()
end

-- =====================================
-- GESTION DE L'ALPHA
-- =====================================
local function SetViewersAlpha(alpha)
    for _, viewer in ipairs(viewers) do
        if viewer then
            viewer:SetAlpha(alpha)
        end
    end
end

-- =====================================
-- INITIALISATION
-- =====================================
local function InitAddon()
    -- Vérifier que le CooldownManager est chargé
    if not UtilityCooldownViewer then
        return false
    end
    
    CheckHotkeys()
    
    -- Setup viewers
    viewers = {
        UtilityCooldownViewer,
        EssentialCooldownViewer,
        BuffIconCooldownViewer,
        BuffBarCooldownViewer
    }
    
    keyViewers = {
        UtilityCooldownViewer,
        EssentialCooldownViewer,
    }
    
    for _, viewer in ipairs(viewers) do
        if viewer then
            UpdateButtons(viewer)
            
            -- Hook Layout
            if viewer.Layout then
                hooksecurefunc(viewer, "Layout", function()
                    AddToDoList(viewer)
                end)
            end
            
            -- Hook Show/Hide
            local children = {viewer:GetChildren()}
            for _, child in ipairs(children) do
                child:HookScript("OnShow", function()
                    AddToDoList(viewer)
                end)
                child:HookScript("OnHide", function()
                    AddToDoList(viewer)
                end)
            end
        end
    end
    
    isInitialized = true
    return true
end

local function RefreshHotkeys()
    ScanKeys("ActionButton", 12)
    ScanKeys("BonusActionButton", 12)
    for _, viewer in ipairs(keyViewers) do
        if viewer then
            UpdateHotkey(viewer)
        end
    end
end

-- =====================================
-- EVENTS
-- =====================================
local function OnEvent(self, event, arg1)
    local settings = GetSettings()
    if not settings then return end
    
    if event == "ADDON_LOADED" and arg1 == "Blizzard_CooldownManager" then
        C_Timer.After(0.5, InitAddon)
    elseif event == "PLAYER_REGEN_DISABLED" then
        if settings.combatAlphaChange then
            SetViewersAlpha(COMBAT_ALPHA)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if settings.combatAlphaChange then
            SetViewersAlpha(NORMAL_ALPHA)
        end
    elseif event == "UPDATE_BONUS_ACTIONBAR" then
        RefreshHotkeys()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "TRAIT_CONFIG_UPDATED" or 
           event == "TRAIT_CONFIG_LIST_UPDATED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        C_Timer.After(0.5, function()
            if not isInitialized then
                InitAddon()
            end
            
            if settings.combatAlphaChange then
                if UnitAffectingCombat("player") then
                    SetViewersAlpha(COMBAT_ALPHA)
                else
                    SetViewersAlpha(NORMAL_ALPHA)
                end
            end
        end)
    end
end

local function OnUpdate()
    nextSpellID = C_AssistedCombat.GetNextCastSpell(true)
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================
function CI.Initialize()
    if not TomoModDB then
        print("|cffff0000TomoMod CombatInfo:|r TomoModDB non initialisée")
        return
    end
    
    -- Initialiser les settings
    if not TomoModDB.combatInfo then
        TomoModDB.combatInfo = {
            enabled = true,
            alignedBuff = false,
            combatAlphaChange = true,
            changeBuffBar = true,
            buffBarClassColor = true,
            showHotKey = false,
            hideBarName = true,
            alertAssistedSpell = false,
        }
    end
    
    local settings = GetSettings()
    if not settings.enabled then
        print("|cffff9900TomoMod CombatInfo:|r Module désactivé")
        return
    end
    
    -- Créer update frame
    updateFrame = CreateFrame("Frame")
    updateFrame:Hide()
    updateFrame:SetScript("OnUpdate", function()
        updateFrame:Hide()
        for viewer in pairs(todoList) do
            todoList[viewer] = nil
            UpdateButtons(viewer)
        end
    end)
    
    -- Créer main frame
    mainFrame = CreateFrame("Frame")
    mainFrame:RegisterEvent("ADDON_LOADED")
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    mainFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    mainFrame:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
    mainFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    mainFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    mainFrame:SetScript("OnEvent", OnEvent)
    
    -- Timer pour next spell
    C_Timer.NewTicker(0.2, OnUpdate)
    
    print("|cff00ff00TomoMod CombatInfo:|r Module initialisé")
end

function CI.ApplySettings()
    local settings = GetSettings()
    if not settings then return end
    
    -- Réinitialiser et réappliquer
    if isInitialized then
        for _, viewer in ipairs(viewers) do
            if viewer then
                UpdateButtons(viewer)
            end
        end
    end
    
    -- Alpha
    if settings.combatAlphaChange then
        if UnitAffectingCombat("player") then
            SetViewersAlpha(COMBAT_ALPHA)
        else
            SetViewersAlpha(NORMAL_ALPHA)
        end
    else
        SetViewersAlpha(1)
    end
end

function CI.SetEnabled(enabled)
    local settings = GetSettings()
    if settings then
        settings.enabled = enabled
        if enabled and not isInitialized then
            InitAddon()
        end
    end
end

-- Export
_G.TomoMod_CombatInfo = CI

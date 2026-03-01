-- =====================================
-- QOL/Combat/CoTankTracker.lua
-- Surveillance du co-tank (debuffs + cooldowns défensifs)
--
-- Affiche :
--   • Barre de santé du co-tank cliquable (cible au clic)
--   • Debuffs actifs sur le co-tank (icônes avec durée)
--   • Cooldowns défensifs du co-tank (icônes grisées en recharge)
--
-- Visible uniquement : en raid, quand le joueur est tank, et qu'un co-tank existe.
-- Inspiré de NaowhQOL/Modules/CoTankDisplay.lua.
-- =====================================

TomoMod_CoTankTracker = TomoMod_CoTankTracker or {}
local CTK = TomoMod_CoTankTracker

-- =====================================
-- Cooldowns défensifs par classe
-- SpellID référencés dans The War Within (TWW patch 11.x)
-- =====================================
local DEFENSIVE_CDS = {
    -- Death Knight
    [48707]  = true,   -- Anti-Magic Shell
    [49028]  = true,   -- Dancing Rune Weapon
    [55233]  = true,   -- Vampiric Blood
    [194679] = true,   -- Rune Tap
    -- Demon Hunter
    [187827] = true,   -- Metamorphosis (Vengeance)
    [196555] = true,   -- Netherwalk
    -- Druid
    [22812]  = true,   -- Barkskin
    [61336]  = true,   -- Survival Instincts
    -- Evoker (Preservation/Augmentation tanking edge cases)
    [363916] = true,   -- Obsidian Scales
    -- Monk
    [122278] = true,   -- Dampen Harm
    [116849] = true,   -- Life Cocoon
    [243435] = true,   -- Fortifying Brew
    -- Paladin
    [642]    = true,   -- Divine Shield
    [498]    = true,   -- Divine Protection
    [86659]  = true,   -- Guardian of Ancient Kings
    [31850]  = true,   -- Ardent Defender
    -- Warrior
    [871]    = true,   -- Shield Wall
    [12975]  = true,   -- Last Stand
    [23920]  = true,   -- Spell Reflection
    -- Shaman (hors-raid but useful)
    [108271] = true,   -- Astral Shift
}

local MAX_DEBUFFS = 8
local ICON_SIZE   = 24
local ICON_GAP    = 3

-- =====================================
-- DB
-- =====================================
local function GetDB()
    return TomoModDB and TomoModDB.coTankTracker
end

-- =====================================
-- State
-- =====================================
local currentTank = nil   -- unit token du co-tank ("raid1"…)
local isPlayerTank = false

local function FindOtherTank()
    if not IsInRaid() then return nil end
    local count = GetNumGroupMembers()
    for i = 1, count do
        local unit = "raid" .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            if UnitGroupRolesAssigned(unit) == "TANK" then
                return unit
            end
        end
    end
    return nil
end

local function IsPlayerTankSpec()
    if PlayerUtil and PlayerUtil.IsPlayerEffectivelyTank then
        return PlayerUtil.IsPlayerEffectivelyTank()
    end
    return UnitGroupRolesAssigned("player") == "TANK"
end

local function ShouldBeVisible()
    local db = GetDB()
    if not db or not db.enabled then return false end
    if not IsInRaid() then return false end
    if not isPlayerTank then return false end
    return FindOtherTank() ~= nil
end

-- =====================================
-- Main frame — SecureUnitButton (click-to-target)
-- =====================================
local mainFrame = CreateFrame("Button", "TomoMod_CoTankTrackerFrame", UIParent,
                              "SecureUnitButtonTemplate, BackdropTemplate")
mainFrame:SetSize(200, 20)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 300, 100)
mainFrame:SetFrameStrata("MEDIUM")
mainFrame:RegisterForClicks("AnyUp")
mainFrame:SetAttribute("type1", "target")
mainFrame:Hide()

-- Fond de la barre de santé
local healthBg = mainFrame:CreateTexture(nil, "BACKGROUND")
healthBg:SetAllPoints()
healthBg:SetColorTexture(0.08, 0.08, 0.08, 0.85)

-- Barre de santé (StatusBar — respecte les secret values TWW)
local healthBar = CreateFrame("StatusBar", nil, mainFrame)
healthBar:SetAllPoints()
healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
healthBar:SetStatusBarColor(0.2, 0.85, 0.2)
healthBar:SetMinMaxValues(0, 1)
healthBar:SetValue(1)

-- Texte nom + santé
local nameText = healthBar:CreateFontString(nil, "OVERLAY")
nameText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 11, "OUTLINE")
nameText:SetPoint("LEFT", healthBar, "LEFT", 4, 0)
nameText:SetTextColor(1, 1, 1)

local hpText = healthBar:CreateFontString(nil, "OVERLAY")
hpText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 10, "OUTLINE")
hpText:SetPoint("RIGHT", healthBar, "RIGHT", -4, 0)
hpText:SetTextColor(0.9, 0.9, 0.9)

-- Bordure 1px noire
local borderFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
borderFrame:SetPoint("TOPLEFT", -1, 1)
borderFrame:SetPoint("BOTTOMRIGHT", 1, -1)
borderFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
borderFrame:SetBackdropBorderColor(0, 0, 0, 1)

-- =====================================
-- Debuff icons row (below health bar)
-- =====================================
local debuffFrame = CreateFrame("Frame", nil, mainFrame)
debuffFrame:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", 0, -3)
debuffFrame:SetHeight(ICON_SIZE)
debuffFrame:SetWidth(200)

local debuffIcons = {}
for i = 1, MAX_DEBUFFS do
    local icon = CreateFrame("Frame", nil, debuffFrame)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", debuffFrame, "LEFT", (i - 1) * (ICON_SIZE + ICON_GAP), 0)
    icon:Hide()

    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.tex = tex

    local cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(false)
    cd:SetReverse(false)
    icon.cd = cd

    local dur = icon:CreateFontString(nil, "OVERLAY")
    dur:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 8, "OUTLINE")
    dur:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, 1)
    icon.dur = dur

    debuffIcons[i] = icon
end

-- =====================================
-- Defensive CD icons row (below debuffs)
-- =====================================
local MAX_CDS = 6
local cdFrame = CreateFrame("Frame", nil, mainFrame)
cdFrame:SetPoint("TOPLEFT", debuffFrame, "BOTTOMLEFT", 0, -3)
cdFrame:SetHeight(ICON_SIZE)
cdFrame:SetWidth(200)

local cdIcons = {}
for i = 1, MAX_CDS do
    local icon = CreateFrame("Frame", nil, cdFrame)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", cdFrame, "LEFT", (i - 1) * (ICON_SIZE + ICON_GAP), 0)
    icon:Hide()

    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.tex = tex

    -- Overlay grisé si en recharge
    local overlay = icon:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints()
    overlay:SetColorTexture(0, 0, 0, 0.6)
    overlay:Hide()
    icon.overlay = overlay

    local cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(false)
    icon.cd = cd

    local dur = icon:CreateFontString(nil, "OVERLAY")
    dur:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 8, "OUTLINE")
    dur:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, 1)
    icon.dur = dur

    cdIcons[i] = icon
end

-- =====================================
-- Update health bar
-- =====================================
local function UpdateHealth()
    if not currentTank or not UnitExists(currentTank) then
        healthBar:SetValue(0)
        nameText:SetText("")
        hpText:SetText("")
        return
    end

    local db = GetDB()

    -- Couleur de barre
    if db and db.useClassColor then
        local _, class = UnitClass(currentTank)
        if class and RAID_CLASS_COLORS[class] then
            local c = RAID_CLASS_COLORS[class]
            healthBar:SetStatusBarColor(c.r, c.g, c.b)
        end
    else
        healthBar:SetStatusBarColor(0.2, 0.85, 0.2)
    end

    -- StatusBar — compatible TWW secret values
    local hpMax = UnitHealthMax(currentTank)
    local hp    = UnitHealth(currentTank)
    healthBar:SetMinMaxValues(0, hpMax)
    healthBar:SetValue(hp)

    -- Texte nom
    local name = UnitName(currentTank) or "?"
    if db and db.abbreviateName and #name > 10 then
        name = name:sub(1, 10) .. "."
    end
    nameText:SetText(name)

    -- Texte HP %
    if db and db.showHPPercent then
        local pct = hpMax > 0 and math.floor(hp / hpMax * 100) or 0
        hpText:SetText(pct .. "%")
    else
        hpText:SetText("")
    end
end

-- =====================================
-- Update debuff icons
-- =====================================
local function UpdateDebuffs()
    for _, icon in ipairs(debuffIcons) do icon:Hide() end
    if not currentTank or not UnitExists(currentTank) then return end

    local db = GetDB()
    local showOnlyMine = db and db.showOnlyMineDebuffs

    local slot = 1
    local auraIndex = 1
    while slot <= MAX_DEBUFFS do
        local aura = C_UnitAuras.GetDebuffDataByIndex(currentTank, auraIndex)
        if not aura then break end
        auraIndex = auraIndex + 1

        if not showOnlyMine or aura.sourceUnit == "player" then
            local icon = debuffIcons[slot]
            icon.tex:SetTexture(aura.icon)
            if aura.duration and aura.duration > 0 then
                icon.cd:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                -- Durée restante en secondes
                local remaining = aura.expirationTime - GetTime()
                if remaining < 60 then
                    icon.dur:SetText(math.ceil(remaining))
                else
                    icon.dur:SetText(math.floor(remaining / 60) .. "m")
                end
            else
                icon.cd:Clear()
                icon.dur:SetText("")
            end
            -- Couleur de bordure par type de debuff
            if aura.dispelName == "Magic" then
                icon.tex:SetVertexColor(0.2, 0.4, 1.0)
            elseif aura.dispelName == "Poison" then
                icon.tex:SetVertexColor(0.2, 0.9, 0.2)
            elseif aura.dispelName == "Disease" then
                icon.tex:SetVertexColor(0.7, 0.6, 0.0)
            elseif aura.dispelName == "Curse" then
                icon.tex:SetVertexColor(0.7, 0.0, 1.0)
            else
                icon.tex:SetVertexColor(1, 1, 1)
            end
            icon:Show()
            slot = slot + 1
        end
    end
end

-- =====================================
-- Update defensive CD icons
-- =====================================
local function UpdateDefensiveCDs()
    for _, icon in ipairs(cdIcons) do icon:Hide() end
    if not currentTank or not UnitExists(currentTank) then return end

    local _, class = UnitClass(currentTank)
    if not class then return end

    local slot = 1
    for spellID in pairs(DEFENSIVE_CDS) do
        if slot > MAX_CDS then break end

        local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        if not spellInfo then goto continue end

        -- Vérifier si le sort existe pour cette classe (pas de filtre par classe en API retail)
        -- On affiche les CDs actifs sur l'unité via UNIT_AURA
        local aura = C_UnitAuras.GetBuffDataByIndex and nil
        -- Chercher le buff actif
        local auraIdx = 1
        local found = false
        while true do
            local buffData = C_UnitAuras.GetBuffDataByIndex(currentTank, auraIdx)
            if not buffData then break end
            if buffData.spellId == spellID then
                aura = buffData
                found = true
                break
            end
            auraIdx = auraIdx + 1
        end

        if found and aura then
            local icon = cdIcons[slot]
            icon.tex:SetTexture(aura.icon or spellInfo.iconID)
            icon.tex:SetVertexColor(1, 0.8, 0.1)   -- doré = actif
            icon.overlay:Hide()
            if aura.duration and aura.duration > 0 then
                icon.cd:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                local remaining = aura.expirationTime - GetTime()
                icon.dur:SetText(math.ceil(remaining))
            else
                icon.cd:Clear()
                icon.dur:SetText("")
            end
            icon:Show()
            slot = slot + 1
        end

        ::continue::
    end
end

-- =====================================
-- UpdateDisplay complet
-- =====================================
local function UpdateDisplay()
    if not ShouldBeVisible() then
        if not InCombatLockdown() then
            mainFrame:Hide()
        end
        return
    end

    currentTank = FindOtherTank()
    if not currentTank then
        if not InCombatLockdown() then mainFrame:Hide() end
        return
    end

    -- Click-to-target (hors combat uniquement — restriction SecureFrame)
    if not InCombatLockdown() then
        mainFrame:SetAttribute("unit", currentTank)
    end

    local db = GetDB()
    if not InCombatLockdown() then
        mainFrame:SetSize(db.width or 200, db.height or 20)
    end

    -- Restaurer la position sauvegardée
    if not mainFrame.posInitialized then
        if db.posX and db.posY then
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
        end
        mainFrame.posInitialized = true
    end

    UpdateHealth()
    UpdateDebuffs()
    UpdateDefensiveCDs()

    if not InCombatLockdown() then mainFrame:Show() end
end

-- =====================================
-- Drag support (hors combat)
-- =====================================
local function EnableDrag()
    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(true)
    if not InCombatLockdown() then
        mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        mainFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local _, _, _, x, y = self:GetPoint()
            local db = GetDB()
            if db then db.posX = x; db.posY = y end
        end)
        mainFrame:RegisterForDrag("LeftButton")
    end
end

-- =====================================
-- Health update ticker (0.1 s)
-- =====================================
local updateFrame = CreateFrame("Frame")
local updateElapsed = 0
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if not mainFrame:IsShown() then return end
    updateElapsed = updateElapsed + elapsed
    if updateElapsed < 0.1 then return end
    updateElapsed = 0
    UpdateHealth()
end)

-- =====================================
-- Aura update ticker (0.5 s)
-- =====================================
local auraFrame = CreateFrame("Frame")
local auraElapsed = 0
auraFrame:SetScript("OnUpdate", function(self, elapsed)
    if not mainFrame:IsShown() then return end
    auraElapsed = auraElapsed + elapsed
    if auraElapsed < 0.5 then return end
    auraElapsed = 0
    UpdateDebuffs()
    UpdateDefensiveCDs()
end)

-- =====================================
-- Events
-- =====================================
local eventFrame = CreateFrame("Frame", "TomoMod_CoTankTrackerEvents")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        if TomoModDB and not TomoModDB.coTankTracker then
            TomoModDB.coTankTracker = {
                enabled          = false,
                useClassColor    = true,
                showHPPercent    = true,
                abbreviateName   = true,
                showOnlyMineDebuffs = false,
                width            = 200,
                height           = 20,
            }
        end
        local db = GetDB()
        if not db or not db.enabled then return end
        isPlayerTank = IsPlayerTankSpec()
        EnableDrag()
        UpdateDisplay()
        return
    end

    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED"
       or event == "ROLE_CHANGED_INFORM" or event == "PLAYER_ENTERING_WORLD" then
        isPlayerTank = IsPlayerTankSpec()
        currentTank  = FindOtherTank()
        UpdateDisplay()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        isPlayerTank = IsPlayerTankSpec()
        UpdateDisplay()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        currentTank = FindOtherTank()
        if not InCombatLockdown() then
            mainFrame:SetAttribute("unit", currentTank)
        end
        UpdateDisplay()
        return
    end
end)

-- =====================================
-- API publique
-- =====================================
function CTK.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if v then UpdateDisplay()
    else
        if not InCombatLockdown() then mainFrame:Hide() end
    end
end

function CTK.ApplySettings()
    mainFrame.posInitialized = false
    UpdateDisplay()
end

TomoMod_RegisterModule("coTankTracker", CTK)

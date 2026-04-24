-- =====================================
-- RaidFrame/Core.lua — Raid Group Frames
-- Secure frames with health, absorb, heal prediction, HoTs,
-- dispel highlight, role icons, raid markers, range check
-- Power bar for healers only, defensive CD tracking
-- NO COMBAT_LOG_EVENT_UNFILTERED
-- =====================================

TomoMod_RaidFrames = TomoMod_RaidFrames or {}
local RF = TomoMod_RaidFrames

-- [PERF] Local API cache
local UnitExists          = UnitExists
local UnitIsConnected     = UnitIsConnected
local UnitIsDeadOrGhost   = UnitIsDeadOrGhost
local UnitHealth          = UnitHealth
local UnitHealthMax       = UnitHealthMax
local UnitName            = UnitName
local UnitClass           = UnitClass
local UnitPowerType       = UnitPowerType
local UnitPower           = UnitPower
local UnitPowerMax        = UnitPowerMax
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitInRange         = UnitInRange
local GetRaidTargetIndex  = GetRaidTargetIndex
local GetReadyCheckStatus = GetReadyCheckStatus
local IsInRaid            = IsInRaid
local IsInGroup           = IsInGroup
local GetNumGroupMembers  = GetNumGroupMembers
local UnitIsUnit          = UnitIsUnit
local InCombatLockdown    = InCombatLockdown
local pairs, ipairs, wipe, pcall = pairs, ipairs, wipe, pcall
local issecretvalue       = issecretvalue
local math_abs            = math.abs

local ADDON_FONT    = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local ROLE_TEXTURE  = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"

-- State
RF.frames       = {}      -- [unit] = frame
RF.groupHeaders = {}      -- group headers for layout
RF.anchor       = nil
RF.isLocked     = true
RF.initialized  = false

-- =====================================
-- ROLE SORT ORDER
-- =====================================
local ROLE_ORDER = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }

-- =====================================
-- RAID ICON COORDS
-- =====================================
local raidIconCoords = {
    [1] = { 0,    0.25, 0,    0.25 },
    [2] = { 0.25, 0.5,  0,    0.25 },
    [3] = { 0.5,  0.75, 0,    0.25 },
    [4] = { 0.75, 1,    0,    0.25 },
    [5] = { 0,    0.25, 0.25, 0.5  },
    [6] = { 0.25, 0.5,  0.25, 0.5  },
    [7] = { 0.5,  0.75, 0.25, 0.5  },
    [8] = { 0.75, 1,    0.25, 0.5  },
}

-- =====================================
-- POWER COLORS
-- =====================================
local POWER_COLORS = {
    [0]  = { r = 0.00, g = 0.00, b = 1.00 },  -- Mana
    [1]  = { r = 1.00, g = 0.00, b = 0.00 },  -- Rage
    [3]  = { r = 1.00, g = 1.00, b = 0.00 },  -- Energy
    [6]  = { r = 0.00, g = 0.82, b = 1.00 },  -- Runic Power
}

-- =====================================
-- HEALER SPEC IDs (for fallback detection)
-- =====================================
local HEALER_SPECS = {
    [65]   = true,  -- Paladin: Holy
    [105]  = true,  -- Druid: Restoration
    [256]  = true,  -- Priest: Discipline
    [257]  = true,  -- Priest: Holy
    [264]  = true,  -- Shaman: Restoration
    [270]  = true,  -- Monk: Mistweaver
    [1468] = true,  -- Evoker: Preservation
}

-- Returns true if unit is a healer (role assignment + spec fallback)
local function IsUnitHealer(unit)
    if not unit or not UnitExists(unit) then return false end
    local role = UnitGroupRolesAssigned(unit)
    if role == "HEALER" then return true end
    if role == "TANK" or role == "DAMAGER" then return false end
    -- role == "NONE": fall back to spec ID
    local specID = GetInspectSpecialization and GetInspectSpecialization(unit)
    if specID and specID > 0 then
        return HEALER_SPECS[specID] == true
    end
    return false
end

-- =====================================
-- DEBUFF TYPE COLORS (for dispel highlight)
-- =====================================
local DEBUFF_TYPE_COLORS = {
    Magic   = { r = 0.20, g = 0.60, b = 1.00 },
    Curse   = { r = 0.60, g = 0.00, b = 1.00 },
    Disease = { r = 0.60, g = 0.40, b = 0.00 },
    Poison  = { r = 0.00, g = 0.60, b = 0.00 },
}

-- =====================================
-- CLASS COLOR HELPER
-- =====================================
local function GetClassColor(unit)
    if not unit or not UnitExists(unit) then return 1, 1, 1 end
    local _, cls = UnitClass(unit)
    if cls then
        local c = RAID_CLASS_COLORS[cls]
        if c then return c.r, c.g, c.b end
    end
    return 0.5, 0.5, 0.5
end

-- =====================================
-- HEALTH COLOR
-- =====================================
local function GetHealthColor(unit, db)
    local mode = db.healthColor or "class"
    if mode == "class" then
        return GetClassColor(unit)
    elseif mode == "gradient" then
        local cur = UnitHealth(unit)
        local max = UnitHealthMax(unit)
        if issecretvalue(cur) or issecretvalue(max) then return 0.1, 0.82, 0.1 end
        local pct = (max > 0) and (cur / max) or 1
        return 1 - pct, pct, 0
    else
        return 0.1, 0.82, 0.1
    end
end

-- =====================================
-- FORMAT HEALTH TEXT
-- =====================================
local function FormatHealth(cur, max, fmt)
    if max <= 0 then return "" end
    local pct = cur / max * 100
    if fmt == "current" then
        if cur >= 1e6 then return string.format("%.1fM", cur / 1e6) end
        if cur >= 1e3 then return string.format("%.1fK", cur / 1e3) end
        return tostring(cur)
    elseif fmt == "deficit" then
        local def = max - cur
        if def <= 0 then return "" end
        if def >= 1e6 then return string.format("-%.1fM", def / 1e6) end
        if def >= 1e3 then return string.format("-%.1fK", def / 1e3) end
        return "-" .. def
    else
        return string.format("%.0f%%", pct)
    end
end

-- =====================================
-- DEFENSIVE CD SPELLS (tracked on raid frames)
-- =====================================
local DEFENSIVE_SPELLS = {
    -- Death Knight
    [48707]  = true,  -- Anti-Magic Shell
    [48792]  = true,  -- Icebound Fortitude
    [49028]  = true,  -- Dancing Rune Weapon
    -- Demon Hunter
    [187827] = true,  -- Metamorphosis (Vengeance)
    [196555] = true,  -- Netherwalk
    -- Druid
    [22812]  = true,  -- Barkskin
    [61336]  = true,  -- Survival Instincts
    [102342] = true,  -- Ironbark
    -- Evoker
    [363916] = true,  -- Obsidian Scales
    [374348] = true,  -- Renewing Blaze
    -- Hunter
    [186265] = true,  -- Aspect of the Turtle
    -- Mage
    [45438]  = true,  -- Ice Block
    -- Monk
    [115176] = true,  -- Zen Meditation
    [116849] = true,  -- Life Cocoon
    [122278] = true,  -- Dampen Harm
    -- Paladin
    [498]    = true,  -- Divine Protection
    [642]    = true,  -- Divine Shield
    [1022]   = true,  -- Blessing of Protection
    [6940]   = true,  -- Blessing of Sacrifice
    [31850]  = true,  -- Ardent Defender
    [86659]  = true,  -- Guardian of Ancient Kings
    -- Priest
    [47585]  = true,  -- Dispersion
    [33206]  = true,  -- Pain Suppression
    [47788]  = true,  -- Guardian Spirit
    -- Rogue
    [5277]   = true,  -- Evasion
    [31224]  = true,  -- Cloak of Shadows
    -- Shaman
    [108271] = true,  -- Astral Shift
    [325174] = true,  -- Spirit Link Totem (buff)
    -- Warlock
    [104773] = true,  -- Unending Resolve
    -- Warrior
    [12975]  = true,  -- Last Stand
    [871]    = true,  -- Shield Wall
    [184364] = true,  -- Enraged Regeneration
    [97462]  = true,  -- Rallying Cry
}

-- =====================================
-- CREATE A SINGLE RAID FRAME
-- =====================================
function RF.CreateFrame(unit)
    local db = TomoModDB and TomoModDB.raidFrames
    if not db then return end

    local frameName = "TomoMod_Raid_" .. unit
    local f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    f:SetSize(db.width, db.height)
    f.unit = unit

    -- Secure unit attribute
    f:SetAttribute("unit", unit)
    f:SetAttribute("type1", "target")
    f:SetAttribute("type2", "togglemenu")
    f:RegisterForClicks("AnyUp")

    -- ClickCast support
    if ClickCastFrames then
        ClickCastFrames[f] = true
    end

    -- Tooltip on hover
    f:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetUnit(self.unit)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.04, 0.04, 0.06, 0.92)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    -- Content overlay (non-secure, pass-through mouse)
    local content = CreateFrame("Frame", nil, f)
    content:SetAllPoints()
    content:SetFrameLevel(f:GetFrameLevel() + 2)
    content:EnableMouse(false)
    f.content = content

    -- ---- HEALTH BAR ----
    local powerH = db.showPower and db.powerHeight or 0
    local healthH = db.height - powerH

    local health = CreateFrame("StatusBar", nil, f)
    health:SetPoint("TOPLEFT", 0, 0)
    health:SetPoint("TOPRIGHT", 0, 0)
    health:SetHeight(healthH)
    health:SetStatusBarTexture(db.texture or ADDON_TEXTURE)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    health:SetFrameLevel(f:GetFrameLevel() + 1)
    f.health = health

    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints()
    healthBG:SetColorTexture(0.08, 0.08, 0.10, 0.90)
    f.healthBG = healthBG

    -- ---- ABSORB BAR ----
    local absorb = CreateFrame("StatusBar", nil, health)
    absorb:SetAllPoints()
    absorb:SetStatusBarTexture(db.texture or ADDON_TEXTURE)
    absorb:SetMinMaxValues(0, 1)
    absorb:SetValue(0)
    absorb:SetFrameLevel(health:GetFrameLevel() + 1)
    local ac = db.absorbColor or { r = 0.5, g = 0.5, b = 1.0, a = 0.5 }
    absorb:SetStatusBarColor(ac.r, ac.g, ac.b, ac.a or 0.5)
    absorb:Hide()
    f.absorb = absorb

    -- ---- HEAL PREDICTION BAR ----
    local healPred = CreateFrame("StatusBar", nil, health)
    healPred:SetAllPoints()
    healPred:SetStatusBarTexture(db.texture or ADDON_TEXTURE)
    healPred:SetMinMaxValues(0, 1)
    healPred:SetValue(0)
    healPred:SetFrameLevel(health:GetFrameLevel() + 2)
    healPred:SetStatusBarColor(0.0, 0.8, 0.2, 0.4)
    healPred:Hide()
    f.healPred = healPred

    if db.showHealPrediction and CreateUnitHealPredictionCalculator then
        local ok, calculator = pcall(CreateUnitHealPredictionCalculator)
        if ok and calculator then
            f.healCalculator = calculator
        end
    end

    -- ---- POWER BAR ----
    if db.showPower and powerH > 0 then
        local power = CreateFrame("StatusBar", nil, f)
        power:SetPoint("BOTTOMLEFT", 0, 0)
        power:SetPoint("BOTTOMRIGHT", 0, 0)
        power:SetHeight(powerH)
        power:SetStatusBarTexture(db.texture or ADDON_TEXTURE)
        power:SetMinMaxValues(0, 1)
        power:SetValue(1)
        power:SetFrameLevel(f:GetFrameLevel() + 1)
        f.power = power

        local powerBG = power:CreateTexture(nil, "BACKGROUND")
        powerBG:SetAllPoints()
        powerBG:SetColorTexture(0.04, 0.04, 0.06, 0.90)
        f.powerBG = powerBG
    end

    -- ---- NAME TEXT ----
    local nameText = content:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(db.font or ADDON_FONT, db.fontSize or 10, db.fontOutline or "OUTLINE")
    nameText:SetPoint("TOP", content, "TOP", 0, -2)
    nameText:SetJustifyH("CENTER")
    nameText:SetWordWrap(false)
    nameText:SetNonSpaceWrap(false)
    nameText:SetMaxLines(1)
    f.nameText = nameText

    -- ---- HEALTH TEXT (below name) ----
    if db.showHealthText then
        local healthText = content:CreateFontString(nil, "OVERLAY")
        healthText:SetFont(db.font or ADDON_FONT, (db.fontSize or 10) - 2, db.fontOutline or "OUTLINE")
        healthText:SetPoint("BOTTOM", content, "BOTTOM", 0, 1)
        healthText:SetJustifyH("CENTER")
        f.healthText = healthText
    end

    -- ---- ROLE ICON ----
    if db.showRoleIcon then
        local roleIcon = content:CreateTexture(nil, "OVERLAY")
        local rSize = db.roleIconSize or 10
        roleIcon:SetSize(rSize, rSize)
        roleIcon:SetPoint("TOPLEFT", content, "TOPLEFT", 1, -1)
        roleIcon:Hide()
        f.roleIcon = roleIcon
    end

    -- ---- RAID MARKER ----
    if db.showRaidMarker then
        local markerFrame = CreateFrame("Frame", nil, content)
        local mSize = db.raidMarkerSize or 12
        markerFrame:SetSize(mSize, mSize)
        markerFrame:SetPoint("TOP", f, "TOP", 0, 2)
        markerFrame:SetFrameLevel(content:GetFrameLevel() + 5)
        markerFrame:Hide()
        local markerTex = markerFrame:CreateTexture(nil, "OVERLAY")
        markerTex:SetAllPoints()
        markerTex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        markerTex:SetDrawLayer("OVERLAY", 6)
        markerFrame.texture = markerTex
        f.raidMarker = markerFrame
    end

    -- ---- READY CHECK ICON ----
    local rcFrame = CreateFrame("Frame", nil, content)
    rcFrame:SetSize(db.readyCheckSize or 20, db.readyCheckSize or 20)
    rcFrame:SetPoint("CENTER", f, "CENTER", 0, 0)
    rcFrame:SetFrameLevel(content:GetFrameLevel() + 5)
    rcFrame:Hide()
    local rcTex = rcFrame:CreateTexture(nil, "OVERLAY")
    rcTex:SetAllPoints()
    rcTex:SetDrawLayer("OVERLAY", 7)
    rcFrame.texture = rcTex
    f.readyCheck = rcFrame

    -- ---- DISPEL HIGHLIGHT ----
    if db.showDispel then
        local dispel = CreateFrame("Frame", nil, content, "BackdropTemplate")
        dispel:SetPoint("TOPLEFT", -1, 1)
        dispel:SetPoint("BOTTOMRIGHT", 1, -1)
        dispel:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        dispel:SetBackdropBorderColor(0, 0, 0, 0)
        dispel:SetFrameLevel(content:GetFrameLevel() + 5)
        dispel:EnableMouse(false)
        dispel:Hide()
        f.dispelHighlight = dispel
    end

    -- ---- DEFENSIVE BUFF ICON ----
    if db.showDefensives then
        local defIcon = CreateFrame("Frame", nil, content, "BackdropTemplate")
        local dSize = db.defensiveIconSize or 14
        defIcon:SetSize(dSize, dSize)
        defIcon:SetPoint("TOPRIGHT", content, "TOPRIGHT", -1, -1)
        defIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        defIcon:SetBackdropBorderColor(0.1, 0.8, 0.1, 1)
        local defTex = defIcon:CreateTexture(nil, "ARTWORK")
        defTex:SetPoint("TOPLEFT", 1, -1)
        defTex:SetPoint("BOTTOMRIGHT", -1, 1)
        defTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        defIcon.texture = defTex
        defIcon:Hide()
        f.defensiveIcon = defIcon
    end

    -- ---- AURA CONTAINER (debuffs) ----
    if db.showDebuffs then
        local debuffSize = db.debuffSize or 14
        local maxDebuffs = db.maxDebuffs or 3
        local debuffContainer = CreateFrame("Frame", nil, content)
        debuffContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -1, 1)
        debuffContainer:SetSize(debuffSize * maxDebuffs + (maxDebuffs - 1), debuffSize)
        debuffContainer.icons = {}
        for i = 1, maxDebuffs do
            local icon = CreateFrame("Frame", nil, debuffContainer, "BackdropTemplate")
            icon:SetSize(debuffSize, debuffSize)
            icon:SetPoint("RIGHT", debuffContainer, "RIGHT", -(i - 1) * (debuffSize + 1), 0)
            icon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            icon:SetBackdropBorderColor(0.8, 0, 0, 1)
            local tex = icon:CreateTexture(nil, "ARTWORK")
            tex:SetPoint("TOPLEFT", 1, -1)
            tex:SetPoint("BOTTOMRIGHT", -1, 1)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon.texture = tex
            local dur = icon:CreateFontString(nil, "OVERLAY")
            dur:SetFont(db.font or ADDON_FONT, 8, "OUTLINE")
            dur:SetPoint("BOTTOM", icon, "BOTTOM", 0, -1)
            icon.duration = dur
            local stacks = icon:CreateFontString(nil, "OVERLAY")
            stacks:SetFont(db.font or ADDON_FONT, 8, "OUTLINE")
            stacks:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 1, 1)
            icon.stacks = stacks
            icon:Hide()
            debuffContainer.icons[i] = icon
        end
        f.debuffContainer = debuffContainer
    end

    -- ---- HOT CONTAINER ----
    if db.showHoTs then
        local hotSize = db.hotSize or 10
        local maxHoTs = db.maxHoTs or 3
        local hotContainer = CreateFrame("Frame", nil, content)
        hotContainer:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 1, 1)
        hotContainer:SetSize(hotSize * maxHoTs + (maxHoTs - 1), hotSize)
        hotContainer.icons = {}
        for i = 1, maxHoTs do
            local icon = CreateFrame("Frame", nil, hotContainer, "BackdropTemplate")
            icon:SetSize(hotSize, hotSize)
            icon:SetPoint("LEFT", (i - 1) * (hotSize + 1), 0)
            icon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            icon:SetBackdropBorderColor(0, 0, 0, 1)
            local tex = icon:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon.texture = tex
            local dur = icon:CreateFontString(nil, "OVERLAY")
            dur:SetFont(db.font or ADDON_FONT, 7, "OUTLINE")
            dur:SetPoint("CENTER", 0, 0)
            icon.duration = dur
            icon:Hide()
            hotContainer.icons[i] = icon
        end
        f.hotContainer = hotContainer
    end

    f:SetFrameLevel(10)
    f:Hide()

    RF.frames[unit] = f
    return f
end

-- =====================================
-- UPDATE: HEALTH
-- =====================================
function RF.UpdateHealth(f)
    if not f or not f.health or not f.unit then return end
    if not UnitExists(f.unit) then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db then return end

    local cur = UnitHealth(f.unit)
    local max = UnitHealthMax(f.unit)

    f.health:SetMinMaxValues(0, max)
    f.health:SetValue(cur)

    local r, g, b = GetHealthColor(f.unit, db)
    f.health:SetStatusBarColor(r, g, b, 1)

    if UnitIsDeadOrGhost(f.unit) then
        f.health:SetStatusBarColor(0.5, 0.5, 0.5, 0.6)
    end

    local connected = UnitIsConnected(f.unit)
    if connected and not issecretvalue(connected) and not connected then
        f.health:SetStatusBarColor(0.3, 0.3, 0.3, 0.5)
    end

    if f.healthText then
        if issecretvalue(cur) or issecretvalue(max) then
            f.healthText:SetText("")
        else
            f.healthText:SetFormattedText("%s", FormatHealth(cur, max, db.healthTextFormat or "percent"))
        end
    end
end

-- =====================================
-- UPDATE: ABSORB
-- =====================================
function RF.UpdateAbsorb(f)
    if not f or not f.absorb then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.showAbsorb then f.absorb:Hide(); return end
    if not UnitExists(f.unit) then f.absorb:Hide(); return end

    local val = UnitGetTotalAbsorbs(f.unit)
    local max = UnitHealthMax(f.unit)

    if issecretvalue(val) or issecretvalue(max) then
        f.absorb:SetMinMaxValues(0, max)
        f.absorb:SetValue(val)
        f.absorb:Show()
    elseif val and max and max > 0 and val > 0 then
        f.absorb:SetMinMaxValues(0, max)
        f.absorb:SetValue(val)
        f.absorb:Show()
    else
        f.absorb:Hide()
    end
end

-- =====================================
-- UPDATE: HEAL PREDICTION
-- =====================================
function RF.UpdateHealPrediction(f)
    if not f or not f.healPred then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.showHealPrediction then f.healPred:Hide(); return end
    if not UnitExists(f.unit) then f.healPred:Hide(); return end

    if f.healCalculator then
        local ok, incoming = pcall(f.healCalculator.Calculate, f.healCalculator, f.unit)
        if ok and incoming and not issecretvalue(incoming) and incoming > 0 then
            local max = UnitHealthMax(f.unit)
            local cur = UnitHealth(f.unit)
            if issecretvalue(max) or issecretvalue(cur) then
                f.healPred:Hide()
                return
            end
            local pred = cur + incoming
            if pred > max then pred = max end
            f.healPred:SetMinMaxValues(0, max)
            f.healPred:SetValue(pred)
            f.healPred:Show()
            return
        end
    end
    f.healPred:Hide()
end

-- =====================================
-- UPDATE: POWER (healers only)
-- =====================================
function RF.UpdatePower(f)
    if not f or not f.power then return end
    if not UnitExists(f.unit) then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.showPower then
        f.power:Hide()
        if f.powerBG then f.powerBG:Hide() end
        return
    end

    if not IsUnitHealer(f.unit) then
        f.power:Hide()
        if f.powerBG then f.powerBG:Hide() end
        return
    end

    f.power:Show()
    if f.powerBG then f.powerBG:Show() end

    local pType = UnitPowerType(f.unit)
    local cur = UnitPower(f.unit)
    local max = UnitPowerMax(f.unit)

    f.power:SetMinMaxValues(0, max)
    f.power:SetValue(cur)

    local pc = POWER_COLORS[pType]
    if pc then
        f.power:SetStatusBarColor(pc.r, pc.g, pc.b, 1)
    else
        f.power:SetStatusBarColor(0.5, 0.5, 0.5, 1)
    end
end

-- =====================================
-- UPDATE: NAME
-- =====================================
function RF.UpdateName(f)
    if not f or not f.nameText then return end
    if not UnitExists(f.unit) then f.nameText:SetText(""); return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.showName then f.nameText:SetText(""); return end

    local name = UnitName(f.unit)
    if not name then f.nameText:SetText(""); return end

    local maxLen = db.nameMaxLength or 0
    if maxLen > 0 and #name > maxLen then
        name = string.sub(name, 1, maxLen) .. "…"
    end

    local r, g, b = GetClassColor(f.unit)
    f.nameText:SetTextColor(r, g, b, 1)
    f.nameText:SetText(name)
end

-- =====================================
-- UPDATE: ROLE ICON
-- =====================================
local ROLE_TEX_COORDS = {
    TANK    = { 0, 19/64, 22/64, 41/64 },
    HEALER  = { 20/64, 39/64, 1/64, 20/64 },
    DAMAGER = { 20/64, 39/64, 22/64, 41/64 },
}

function RF.UpdateRole(f)
    if not f or not f.roleIcon then return end
    if not UnitExists(f.unit) then f.roleIcon:Hide(); return end

    local role = UnitGroupRolesAssigned(f.unit)
    local coords = ROLE_TEX_COORDS[role]
    if coords then
        f.roleIcon:SetTexture(ROLE_TEXTURE)
        f.roleIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        f.roleIcon:Show()
    else
        f.roleIcon:Hide()
    end
end

-- =====================================
-- UPDATE: RAID MARKER
-- =====================================
function RF.UpdateRaidMarker(f)
    if not f or not f.raidMarker then return end
    if not f.unit or not UnitExists(f.unit) then f.raidMarker:Hide(); return end

    local ok, idx = pcall(GetRaidTargetIndex, f.unit)
    if not ok then f.raidMarker:Hide(); return end
    if issecretvalue(idx) then
        pcall(SetRaidTargetIconTexture, f.raidMarker.texture, idx)
        f.raidMarker:Show()
        return
    end
    if idx and SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(f.raidMarker.texture, idx)
        f.raidMarker:Show()
    else
        f.raidMarker:Hide()
    end
end

-- =====================================
-- UPDATE: READY CHECK
-- =====================================
function RF.UpdateReadyCheck(f)
    if not f or not f.readyCheck then return end
    if not f.unit or not UnitExists(f.unit) then f.readyCheck:Hide(); return end

    local status = GetReadyCheckStatus(f.unit)
    if status == "ready" then
        f.readyCheck.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        f.readyCheck:Show()
    elseif status == "notready" then
        f.readyCheck.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        f.readyCheck:Show()
    elseif status == "waiting" then
        f.readyCheck.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
        f.readyCheck:Show()
    else
        f.readyCheck:Hide()
    end
end

function RF.FinishReadyCheck()
    C_Timer.After(6, function()
        for _, f in pairs(RF.frames) do
            if f and f.readyCheck then
                f.readyCheck:Hide()
            end
        end
    end)
end

-- =====================================
-- UPDATE: DISPEL HIGHLIGHT
-- =====================================
function RF.UpdateDispel(f)
    if not f or not f.dispelHighlight then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.showDispel then f.dispelHighlight:Hide(); return end
    if not UnitExists(f.unit) then f.dispelHighlight:Hide(); return end

    local foundType = nil
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local auraIndex = 1
        while auraIndex <= 40 do
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, f.unit, auraIndex, "HARMFUL")
            if not ok or not auraData then break end

            local dispelType = auraData.dispelName
            if dispelType and not issecretvalue(dispelType) then
                if dispelType == "Magic" then
                    foundType = "Magic"
                    break
                elseif not foundType then
                    foundType = dispelType
                end
            end
            auraIndex = auraIndex + 1
        end
    end

    if foundType and DEBUFF_TYPE_COLORS[foundType] then
        local c = DEBUFF_TYPE_COLORS[foundType]
        f.dispelHighlight:SetBackdropBorderColor(c.r, c.g, c.b, 0.90)
        f.dispelHighlight:Show()
    else
        f.dispelHighlight:Hide()
    end
end

-- =====================================
-- UPDATE: DEFENSIVE BUFF ICON
-- =====================================
function RF.UpdateDefensive(f)
    if not f or not f.defensiveIcon then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.showDefensives then f.defensiveIcon:Hide(); return end
    if not UnitExists(f.unit) then f.defensiveIcon:Hide(); return end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local idx = 1
        while idx <= 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, f.unit, idx, "HELPFUL")
            if not ok or not aura then break end
            local sid = aura.spellId
            if sid and not issecretvalue(sid) and DEFENSIVE_SPELLS[sid] then
                f.defensiveIcon.texture:SetTexture(aura.icon)
                f.defensiveIcon:Show()
                return
            end
            idx = idx + 1
        end
    end

    f.defensiveIcon:Hide()
end

-- =====================================
-- FULL UPDATE (per frame)
-- =====================================
function RF.UpdateFrame(f)
    if not f or not f.unit then return end
    RF.UpdateHealth(f)
    RF.UpdateAbsorb(f)
    RF.UpdateHealPrediction(f)
    RF.UpdatePower(f)
    RF.UpdateName(f)
    RF.UpdateRole(f)
    RF.UpdateRaidMarker(f)
    RF.UpdateDispel(f)
    RF.UpdateDefensive(f)
    if TomoMod_RaidAuras then TomoMod_RaidAuras.UpdateUnit(f) end
end

-- =====================================
-- RANGE CHECK
-- =====================================
function RF.UpdateRange(f)
    if not f or not f.unit then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.showRange then f:SetAlpha(1); return end

    if UnitIsUnit(f.unit, "player") then f:SetAlpha(1); return end
    if not UnitExists(f.unit) then f:SetAlpha(1); return end

    if UnitPhaseReason and UnitPhaseReason(f.unit) then
        f:SetAlpha(db.oorAlpha or 0.40)
        return
    end

    -- UnitInRange may return a secret boolean in Midnight+ for raid units.
    -- Do NOT bail on issecretvalue — pass the value directly to
    -- SetAlphaFromBoolean which is designed to handle secret booleans safely.
    local inRange = UnitInRange(f.unit)
    f:SetAlphaFromBoolean(inRange, 1, db.oorAlpha or 0.40)
end

local rangeEventFrame = nil
local rangeTicker = nil

local function GetFrameForUnit(unit)
    return RF.frames[unit]
end

function RF.StartRangeChecker()
    if rangeEventFrame then return end

    rangeEventFrame = CreateFrame("Frame")
    rangeEventFrame:RegisterEvent("UNIT_IN_RANGE_UPDATE")
    rangeEventFrame:SetScript("OnEvent", function(_, _, unit)
        local f = GetFrameForUnit(unit)
        if f and f:IsShown() then
            RF.UpdateRange(f)
        end
    end)

    rangeTicker = C_Timer.NewTicker(0.5, function()
        local db = TomoModDB and TomoModDB.raidFrames
        if not db or not db.showRange then return end
        for _, f in pairs(RF.frames) do
            if f and f:IsShown() and f.unit then
                RF.UpdateRange(f)
            end
        end
    end)
end

function RF.StopRangeChecker()
    if rangeEventFrame then
        rangeEventFrame:UnregisterAllEvents()
        rangeEventFrame:SetScript("OnEvent", nil)
        rangeEventFrame = nil
    end
    if rangeTicker then
        rangeTicker:Cancel()
        rangeTicker = nil
    end
end

-- =====================================
-- LAYOUT: Arrange frames in grid or list
-- =====================================
function RF.LayoutFrames()
    local db = TomoModDB and TomoModDB.raidFrames
    if not db then return end
    if not RF.anchor then return end

    -- Gather visible units sorted by group then role
    local units = {}
    for unit, f in pairs(RF.frames) do
        if f and UnitExists(unit) then
            local _, _, subgroup = GetRaidRosterInfo(RF.GetRaidIndex(unit) or 0)
            units[#units + 1] = {
                frame = f,
                unit = unit,
                group = subgroup or 1,
                role = ROLE_ORDER[UnitGroupRolesAssigned(unit) or "NONE"] or 4,
            }
        end
    end

    if db.sortByRole then
        table.sort(units, function(a, b)
            if a.group ~= b.group then return a.group < b.group end
            if a.role ~= b.role then return a.role < b.role end
            return a.unit < b.unit
        end)
    else
        table.sort(units, function(a, b)
            if a.group ~= b.group then return a.group < b.group end
            return a.unit < b.unit
        end)
    end

    local layout = db.layout or "grid"
    local spacing = db.spacing or 2
    local groupSpacing = db.groupSpacing or 6
    local w = db.width
    local h = db.height

    if layout == "grid" then
        -- Grid: groups as columns, members as rows
        local groups = {}
        for _, data in ipairs(units) do
            local g = data.group
            if not groups[g] then groups[g] = {} end
            groups[g][#groups[g] + 1] = data
        end

        local sortedGroups = {}
        for g in pairs(groups) do
            sortedGroups[#sortedGroups + 1] = g
        end
        table.sort(sortedGroups)

        local colOffset = 0
        local maxRows = 0
        for _, g in ipairs(sortedGroups) do
            local members = groups[g]
            for row, data in ipairs(members) do
                data.frame:ClearAllPoints()
                data.frame:SetPoint("TOPLEFT", RF.anchor, "TOPLEFT", colOffset, -((row - 1) * (h + spacing)))
                data.frame:SetSize(w, h)
                if row > maxRows then maxRows = row end
            end
            colOffset = colOffset + w + groupSpacing
        end

        local totalW = colOffset - groupSpacing
        if totalW < w then totalW = w end
        local totalH = maxRows * h + (maxRows - 1) * spacing
        if totalH < h then totalH = h end
        RF.anchor:SetSize(totalW, totalH)

    else
        -- List: all members in one column
        for i, data in ipairs(units) do
            data.frame:ClearAllPoints()
            data.frame:SetPoint("TOPLEFT", RF.anchor, "TOPLEFT", 0, -((i - 1) * (h + spacing)))
            data.frame:SetSize(w, h)
        end

        local totalH = #units * h + (#units - 1) * spacing
        if totalH < h then totalH = h end
        RF.anchor:SetSize(w, totalH)
    end
end

-- =====================================
-- HELPER: Get raid index for a unit
-- =====================================
function RF.GetRaidIndex(unit)
    if not unit then return nil end
    for i = 1, 40 do
        local raidUnit = "raid" .. i
        if UnitExists(raidUnit) and UnitIsUnit(raidUnit, unit) then
            return i
        end
    end
    return nil
end

-- =====================================
-- HIDE BLIZZARD RAID FRAMES
-- =====================================
local blizzardHidden = false

-- Hidden parent used to safely suppress Blizzard frames without tainting them.
-- SetAlpha(0)+SetScale(0.001) suppresses Blizzard frames without tainting them.
-- SetParent(), Hide(), and .Show=function() overrides all propagate taint into
-- CompactRaidFrameManager's call chain → CompactPartyFrame:SetShown() blocked.
local _rfManagerHookInstalled = false

function RF.HideBlizzardFrames()
    if blizzardHidden then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.hideBlizzardFrames then return end

    -- Container: scale near-zero + zero alpha makes it invisible.
    -- Must not be in combat (SetScale is blocked in lockdown).
    if CompactRaidFrameContainer and not InCombatLockdown() then
        pcall(function()
            CompactRaidFrameContainer:SetAlpha(0)
            CompactRaidFrameContainer:SetScale(0.001)
        end)
    end

    if CompactRaidFrameManager then
        pcall(function()
            CompactRaidFrameManager:SetAlpha(0)
            CompactRaidFrameManager:EnableMouse(false)
        end)
        -- One-time post-hook: re-apply alpha after Blizzard tries to re-show.
        -- Calls SetAlpha, NOT Hide(), to avoid taint propagation.
        if not _rfManagerHookInstalled then
            _rfManagerHookInstalled = true
            hooksecurefunc(CompactRaidFrameManager, "Show", function(self)
                if blizzardHidden then
                    pcall(function() self:SetAlpha(0) end)
                end
            end)
        end
    end

    blizzardHidden = true
end

-- =====================================
-- REFRESH GROUP
-- =====================================
function RF.RefreshGroup()
    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.enabled then return end

    if InCombatLockdown() then
        RF._pendingRefresh = true
        return
    end

    if not IsInRaid() then
        -- Hide all real raid frames when not in raid
        for unit, f in pairs(RF.frames) do
            f:Hide()
        end
        return
    end

    -- In a real raid: hide any preview
    RF.HidePreview()

    local numMembers = GetNumGroupMembers()

    -- Create/show frames for existing raid members
    local activeUnits = {}
    for i = 1, numMembers do
        local unit = "raid" .. i
        if UnitExists(unit) then
            activeUnits[unit] = true
            if not RF.frames[unit] then
                RF.CreateFrame(unit)
            end
            RF.frames[unit]:Show()
            RF.UpdateFrame(RF.frames[unit])
        end
    end

    -- Hide frames for members no longer in raid
    for unit, f in pairs(RF.frames) do
        if not activeUnits[unit] then
            f:Hide()
        end
    end

    RF.LayoutFrames()
end

-- =====================================
-- PREVIEW SYSTEM (shown when not in raid)
-- =====================================
-- Fake names and class colors for preview frames
local PREVIEW_NAMES = {
    "Tomoyuki", "Aelindra", "Broxtar", "Cynara", "Draleth",
    "Elowen",   "Fyrath",   "Garissa", "Helyon", "Isolde",
    "Jaxren",   "Kelvara",  "Luneth",  "Mordak", "Nyssara",
    "Orvyn",    "Pyrael",   "Quelith", "Ryndra", "Sylvar",
}
local PREVIEW_CLASSES = {
    { r=0.00, g=0.44, b=0.87 },  -- Paladin (gold)
    { r=0.04, g=1.00, b=0.96 },  -- Shaman
    { r=0.12, g=1.00, b=0.00 },  -- Hunter
    { r=1.00, g=0.49, b=0.04 },  -- Druid
    { r=0.78, g=0.61, b=0.43 },  -- Monk
    { r=0.63, g=0.20, b=0.90 },  -- Warlock
    { r=0.77, g=0.12, b=0.23 },  -- Warrior
    { r=1.00, g=0.96, b=0.41 },  -- Mage
    { r=1.00, g=1.00, b=1.00 },  -- Priest
    { r=0.90, g=0.09, b=0.17 },  -- Death Knight
}
local PREVIEW_HEALTH_PCT = { 1.0, 0.85, 0.72, 0.60, 0.95, 0.50, 0.88, 0.40, 0.78, 0.65,
                             1.0, 0.92, 0.55, 0.80, 0.70, 0.45, 0.98, 0.62, 0.87, 0.75 }

RF.previewFrames = {}
RF._previewActive = false

function RF.ShowPreview(count)
    if not RF.anchor then return end
    local db = TomoModDB and TomoModDB.raidFrames
    if not db then return end

    RF.HidePreview()
    RF._previewActive = true

    count = math.min(count or 20, 40)
    local w = db.width
    local h = db.height
    local powerH = db.showPower and db.powerHeight or 0
    local healthH = h - powerH

    for i = 1, count do
        local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        f:SetSize(w, h)
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.04, 0.04, 0.06, 0.92)
        f:SetBackdropBorderColor(0, 0, 0, 1)

        -- Health bar
        local health = CreateFrame("StatusBar", nil, f)
        health:SetPoint("TOPLEFT", 1, -1)
        health:SetPoint("TOPRIGHT", -1, -1)
        health:SetHeight(healthH - 2)
        health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        local ci = ((i - 1) % #PREVIEW_CLASSES) + 1
        local c = PREVIEW_CLASSES[ci]
        health:SetStatusBarColor(c.r, c.g, c.b, 0.85)
        health:SetMinMaxValues(0, 100)
        health:SetValue((PREVIEW_HEALTH_PCT[i] or 0.75) * 100)

        -- Power bar (show only for first 4 = "healers")
        if powerH > 0 and i <= 4 then
            local power = CreateFrame("StatusBar", nil, f)
            power:SetPoint("BOTTOMLEFT", 1, 1)
            power:SetPoint("BOTTOMRIGHT", -1, 1)
            power:SetHeight(powerH - 1)
            power:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            power:SetStatusBarColor(0.00, 0.00, 1.00, 0.80)
            power:SetMinMaxValues(0, 100)
            power:SetValue(60 + (i * 8) % 40)
        end

        -- Name text
        if db.showName then
            local txt = f:CreateFontString(nil, "OVERLAY")
            txt:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", db.fontSize or 10, "OUTLINE")
            txt:SetPoint("TOP", 0, -2)
            txt:SetJustifyH("CENTER")
            txt:SetWordWrap(false)
            txt:SetMaxLines(1)
            local name = PREVIEW_NAMES[i] or ("Player" .. i)
            local maxLen = db.nameMaxLength or 0
            if maxLen > 0 and #name > maxLen then
                name = string.sub(name, 1, maxLen)
            end
            txt:SetText(name)
            txt:SetTextColor(1, 1, 1, 0.9)
        end

        f.previewIndex = i
        f:Show()
        RF.previewFrames[i] = f
    end

    -- Layout preview frames using the same LayoutFrames logic
    RF._layoutPreview(count)
end

function RF._layoutPreview(count)
    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not RF.anchor then return end

    local layout = db.layout or "grid"
    local spacing = db.spacing or 2
    local groupSpacing = db.groupSpacing or 6
    local w = db.width
    local h = db.height
    local membersPerGroup = 5

    if layout == "grid" then
        local numGroups = math.ceil(count / membersPerGroup)
        local colOffset = 0
        local maxRows = 0
        for g = 1, numGroups do
            local startIdx = (g - 1) * membersPerGroup + 1
            local endIdx   = math.min(g * membersPerGroup, count)
            for row = startIdx, endIdx do
                local f = RF.previewFrames[row]
                if f then
                    f:ClearAllPoints()
                    f:SetPoint("TOPLEFT", RF.anchor, "TOPLEFT", colOffset, -((row - startIdx) * (h + spacing)))
                    f:SetSize(w, h)
                    local rowNum = row - startIdx + 1
                    if rowNum > maxRows then maxRows = rowNum end
                end
            end
            colOffset = colOffset + w + groupSpacing
        end
        local totalW = colOffset - groupSpacing
        if totalW < w then totalW = w end
        local totalH = maxRows * h + (maxRows - 1) * spacing
        if totalH < h then totalH = h end
        RF.anchor:SetSize(totalW, totalH)
    else
        for i, f in ipairs(RF.previewFrames) do
            if f then
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", RF.anchor, "TOPLEFT", 0, -((i - 1) * (h + spacing)))
                f:SetSize(w, h)
            end
        end
        local totalH = count * h + (count - 1) * spacing
        if totalH < h then totalH = h end
        RF.anchor:SetSize(w, totalH)
    end
end

function RF.HidePreview()
    RF._previewActive = false
    for i, f in ipairs(RF.previewFrames) do
        if f then
            f:Hide()
            f:SetParent(nil)
            RF.previewFrames[i] = nil
        end
    end
    wipe(RF.previewFrames)
end

-- =====================================
-- MOVER SYSTEM
-- =====================================
function RF.ToggleLock()
    RF.isLocked = not RF.isLocked
    if RF.anchor then
        RF.anchor:SetMovable(not RF.isLocked)
        RF.anchor:EnableMouse(not RF.isLocked)
        if not RF.isLocked then
            RF.anchor.moverOverlay:Show()
            -- Show preview when unlocking if not in a real raid
            if not IsInRaid() then
                RF.ShowPreview(20)
            end
        else
            RF.anchor.moverOverlay:Hide()
            -- Hide preview when locking
            RF.HidePreview()
            local db = TomoModDB and TomoModDB.raidFrames
            if db and RF.anchor then
                local p, _, rp, x, y = RF.anchor:GetPoint()
                db.position = { point = p, relativePoint = rp, x = x, y = y }
            end
        end
    end
end

function RF.IsLocked()
    return RF.isLocked
end

-- =====================================
-- CREATE ANCHOR
-- =====================================
function RF.CreateAnchor()
    local db = TomoModDB and TomoModDB.raidFrames
    if not db then return end

    local anchor = CreateFrame("Frame", "TomoMod_RaidAnchor", UIParent)
    anchor:SetSize(db.width * 5, db.height * 8)

    local pos = db.position
    if pos and pos.point then
        anchor:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
    else
        anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
    end

    anchor:SetMovable(false)
    anchor:EnableMouse(false)

    local mover = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
    mover:SetAllPoints()
    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    mover:SetBackdropColor(0.047, 0.624, 0.824, 0.3)
    mover:SetBackdropBorderColor(0.047, 0.624, 0.824, 0.8)
    mover:SetFrameLevel(500)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetScript("OnDragStart", function() anchor:StartMoving() end)
    mover:SetScript("OnDragStop", function()
        anchor:StopMovingOrSizing()
        local p, _, rp, x, y = anchor:GetPoint()
        if db then
            db.position = { point = p, relativePoint = rp, x = x, y = y }
        end
    end)
    local label = mover:CreateFontString(nil, "OVERLAY")
    label:SetFont(ADDON_FONT, 11, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetText("Raid Frames")
    label:SetTextColor(0.047, 0.624, 0.824, 1)
    mover:Hide()
    anchor.moverOverlay = mover

    RF.anchor = anchor
end

-- =====================================
-- EVENT HANDLER
-- =====================================
local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, arg1, ...)
    if not RF.initialized then return end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local f = GetFrameForUnit(arg1)
        if f then
            RF.UpdateHealth(f)
            RF.UpdateAbsorb(f)
            RF.UpdateHealPrediction(f)
        end

    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        local f = GetFrameForUnit(arg1)
        if f then RF.UpdateAbsorb(f) end

    elseif event == "UNIT_HEAL_PREDICTION" then
        local f = GetFrameForUnit(arg1)
        if f then RF.UpdateHealPrediction(f) end

    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        local f = GetFrameForUnit(arg1)
        if f then RF.UpdatePower(f) end

    elseif event == "UNIT_NAME_UPDATE" then
        local f = GetFrameForUnit(arg1)
        if f then RF.UpdateName(f) end

    elseif event == "UNIT_AURA" then
        local f = GetFrameForUnit(arg1)
        if f then
            RF.UpdateDispel(f)
            RF.UpdateDefensive(f)
            if TomoMod_RaidAuras then TomoMod_RaidAuras.UpdateUnit(f) end
        end

    elseif event == "RAID_TARGET_UPDATE" then
        for _, f in pairs(RF.frames) do
            if f then RF.UpdateRaidMarker(f) end
        end

    elseif event == "READY_CHECK" or event == "READY_CHECK_CONFIRM" then
        for _, f in pairs(RF.frames) do
            if f then RF.UpdateReadyCheck(f) end
        end

    elseif event == "READY_CHECK_FINISHED" then
        RF.FinishReadyCheck()

    elseif event == "GROUP_ROSTER_UPDATE" then
        RF.RefreshGroup()

    elseif event == "PLAYER_ROLES_ASSIGNED" then
        for _, f in pairs(RF.frames) do
            if f then RF.UpdateRole(f) end
        end
        if InCombatLockdown() then
            RF._pendingLayout = true
        else
            RF.LayoutFrames()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            RF.RefreshGroup()
            RF.HideBlizzardFrames()
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        if RF._pendingRefresh then
            RF._pendingRefresh = nil
            RF.RefreshGroup()
        end
        if RF._pendingLayout then
            RF._pendingLayout = nil
            RF.LayoutFrames()
        end
    end
end

-- =====================================
-- INITIALIZE
-- =====================================
function RF.Initialize()
    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.enabled then return end

    RF.CreateAnchor()
    RF.HideBlizzardFrames()

    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    eventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    eventFrame:RegisterEvent("UNIT_HEAL_PREDICTION")
    eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    eventFrame:RegisterEvent("UNIT_MAXPOWER")
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    eventFrame:RegisterEvent("READY_CHECK")
    eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
    eventFrame:RegisterEvent("READY_CHECK_FINISHED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", OnEvent)

    RF.initialized = true
    RF.StartRangeChecker()
    C_Timer.After(0.1, function() RF.RefreshGroup() end)

    -- Register with the unified mover system (/tm layout)
    if TomoMod_Movers and TomoMod_Movers.RegisterEntry then
        TomoMod_Movers.RegisterEntry({
            label    = (TomoMod_L and TomoMod_L["mover_raidframes"]) or "Raid Frames",
            unlock   = function()
                if RF.IsLocked() then RF.ToggleLock() end
            end,
            lock     = function()
                if not RF.IsLocked() then RF.ToggleLock() end
            end,
            isActive = function()
                return TomoModDB and TomoModDB.raidFrames and TomoModDB.raidFrames.enabled
            end,
        })
    end
end

-- =====================================
-- APPLY SETTINGS (for config live-update)
-- =====================================
function RF.ApplySettings()
    local db = TomoModDB and TomoModDB.raidFrames
    if not db then return end

    if RF.anchor then
        local pos = db.position
        if pos and pos.point then
            RF.anchor:ClearAllPoints()
            RF.anchor:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
        end
    end

    for _, f in pairs(RF.frames) do
        if f then
            f:SetSize(db.width, db.height)

            local powerH = db.showPower and db.powerHeight or 0
            local healthH = db.height - powerH

            if f.health then
                f.health:SetHeight(healthH)
            end

            if db.showPower and powerH > 0 then
                if f.power then
                    f.power:SetHeight(powerH)
                    f.power:Show()
                    if f.powerBG then f.powerBG:Show() end
                end
            else
                if f.power then f.power:Hide() end
                if f.powerBG then f.powerBG:Hide() end
            end

            if f:IsShown() then
                RF.UpdateFrame(f)
            end
        end
    end

    RF.LayoutFrames()
end

-- =====================================
-- SET ENABLED
-- =====================================
function RF.SetEnabled(v)
    local db = TomoModDB and TomoModDB.raidFrames
    if db then db.enabled = v end
end

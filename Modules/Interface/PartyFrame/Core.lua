-- =====================================
-- PartyFrame/Core.lua — Party & Group Frames
-- Secure frames with health, absorb, heal prediction, HoTs,
-- interrupt/brez CD tracking, dispel highlight, range check
-- Arena enemy frames with PvP trinket CD
-- NO COMBAT_LOG_EVENT_UNFILTERED
-- =====================================

TomoMod_PartyFrames = TomoMod_PartyFrames or {}
local PF = TomoMod_PartyFrames

-- [PERF] Local API cache
local UnitExists       = UnitExists
local UnitIsConnected  = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitHealth       = UnitHealth
local UnitHealthMax    = UnitHealthMax
local UnitName         = UnitName
local UnitClass        = UnitClass
local UnitPowerType    = UnitPowerType
local UnitPower        = UnitPower
local UnitPowerMax     = UnitPowerMax
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGetTotalAbsorbs    = UnitGetTotalAbsorbs
local UnitIsVisible    = UnitIsVisible
local GetRaidTargetIndex = GetRaidTargetIndex
local IsInGroup        = IsInGroup
local IsInRaid         = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local pairs, ipairs, wipe, pcall = pairs, ipairs, wipe, pcall
local issecretvalue    = issecretvalue

local ADDON_FONT    = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local ROLE_TEXTURE  = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"

-- State
PF.frames      = {}        -- [0]=player, [1..4]=party1..party4
PF.anchor      = nil       -- anchor frame for layout
PF.isLocked    = true
PF.initialized = false

-- =====================================
-- ROLE SORT ORDER
-- =====================================
local ROLE_ORDER = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }

-- =====================================
-- RAID ICON COORDS
-- =====================================
local raidIconCoords = {
    [1] = { 0,    0.25, 0,    0.25 },  -- Star
    [2] = { 0.25, 0.5,  0,    0.25 },  -- Circle
    [3] = { 0.5,  0.75, 0,    0.25 },  -- Diamond
    [4] = { 0.75, 1,    0,    0.25 },  -- Triangle
    [5] = { 0,    0.25, 0.25, 0.5  },  -- Moon
    [6] = { 0.25, 0.5,  0.25, 0.5  },  -- Square
    [7] = { 0.5,  0.75, 0.25, 0.5  },  -- Cross
    [8] = { 0.75, 1,    0.25, 0.5  },  -- Skull
}

-- =====================================
-- POWER COLORS
-- =====================================
local POWER_COLORS = {
    [0]  = { r = 0.00, g = 0.00, b = 1.00 },  -- Mana
    [1]  = { r = 1.00, g = 0.00, b = 0.00 },  -- Rage
    [2]  = { r = 1.00, g = 0.50, b = 0.25 },  -- Focus
    [3]  = { r = 1.00, g = 1.00, b = 0.00 },  -- Energy
    [6]  = { r = 0.00, g = 0.82, b = 1.00 },  -- Runic Power
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
        return 0.1, 0.82, 0.1  -- green
    end
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
-- GROUP BUFF SPELL IDS (major class buffs)
-- =====================================
local GROUP_BUFF_SPELLS = {
    [1459]   = true,  -- Mage: Arcane Intellect
    [6673]   = true,  -- Warrior: Battle Shout
    [1126]   = true,  -- Druid: Mark of the Wild
    [21562]  = true,  -- Priest: Power Word: Fortitude
    [462854] = true,  -- Shaman: Skyfury (Fureur-du-ciel)
    [381732] = true,  -- Evoker: Blessing of the Bronze
    [200025] = true,  -- Paladin: Beacon of Virtue (Guide de vertu)
}

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
    elseif fmt == "current_percent" then
        local hp
        if cur >= 1e6 then hp = string.format("%.1fM", cur / 1e6)
        elseif cur >= 1e3 then hp = string.format("%.1fK", cur / 1e3)
        else hp = tostring(cur) end
        return string.format("%s | %.0f%%", hp, pct)
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
-- CREATE A SINGLE PARTY FRAME
-- =====================================
function PF.CreateFrame(index, unit)
    local db = TomoModDB and TomoModDB.partyFrames
    if not db then return end

    local frameName = "TomoMod_Party_" .. unit
    local f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    f:SetSize(db.width, db.height)
    f.unit = unit
    f.index = index

    -- Secure unit attribute
    f:SetAttribute("unit", unit)
    f:SetAttribute("type1", "target")       -- Left-click: target
    f:SetAttribute("type2", "togglemenu")   -- Right-click: menu
    f:RegisterForClicks("AnyUp")
    RegisterUnitWatch(f)

    -- Backdrop (dark background)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.04, 0.04, 0.06, 0.92)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    -- Content overlay (for non-secure elements — pass through mouse to secure button)
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

    -- Health background
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

    -- Heal prediction calculator (Blizzard built-in)
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
    nameText:SetFont(db.font or ADDON_FONT, db.fontSize or 11, db.fontOutline or "OUTLINE")
    nameText:SetPoint("TOP", content, "TOP", 0, -2)
    nameText:SetPoint("LEFT", content, "LEFT", 4, 0)
    nameText:SetPoint("RIGHT", content, "RIGHT", -4, 0)
    nameText:SetJustifyH("CENTER")
    nameText:SetWordWrap(false)
    nameText:SetNonSpaceWrap(false)
    nameText:SetMaxLines(1)
    f.nameText = nameText

    -- ---- HEALTH TEXT ----
    if db.showHealthText then
        local healthText = content:CreateFontString(nil, "OVERLAY")
        healthText:SetFont(db.font or ADDON_FONT, (db.fontSize or 11) - 1, db.fontOutline or "OUTLINE")
        healthText:SetPoint("BOTTOM", content, "BOTTOM", 0, 2)
        healthText:SetJustifyH("CENTER")
        f.healthText = healthText
    end

    -- ---- ROLE ICON ----
    if db.showRoleIcon then
        local roleIcon = content:CreateTexture(nil, "OVERLAY")
        local rSize = db.roleIconSize or 14
        roleIcon:SetSize(rSize, rSize)
        roleIcon:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -2)
        roleIcon:Hide()
        f.roleIcon = roleIcon
    end

    -- ---- RAID MARKER ----
    if db.showRaidMarker then
        local marker = content:CreateTexture(nil, "OVERLAY")
        local mSize = db.raidMarkerSize or 16
        marker:SetSize(mSize, mSize)
        marker:SetPoint("TOP", content, "TOP", 0, -2)
        marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        marker:Hide()
        f.raidMarker = marker
    end

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

    -- ---- GROUP BUFF ICON ----
    local gbIcon = CreateFrame("Frame", nil, content, "BackdropTemplate")
    local gbSize = 14
    gbIcon:SetSize(gbSize, gbSize)
    gbIcon:SetPoint("LEFT", content, "LEFT", 2, 0)
    gbIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    gbIcon:SetBackdropBorderColor(0, 0, 0, 0.8)
    local gbTex = gbIcon:CreateTexture(nil, "ARTWORK")
    gbTex:SetPoint("TOPLEFT", 1, -1)
    gbTex:SetPoint("BOTTOMRIGHT", -1, 1)
    gbTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    gbIcon.texture = gbTex
    gbIcon:Hide()
    f.groupBuff = gbIcon

    -- ---- HOT CONTAINER ----
    if db.showHoTs then
        local hotContainer = CreateFrame("Frame", nil, content)
        hotContainer:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 2, 2)
        local hotSize = db.hotSize or 12
        hotContainer:SetSize(hotSize * (db.maxHoTs or 3) + 4, hotSize)
        hotContainer.icons = {}
        for i = 1, (db.maxHoTs or 3) do
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
            dur:SetFont(db.font or ADDON_FONT, 8, "OUTLINE")
            dur:SetPoint("CENTER", 0, 0)
            icon.duration = dur
            -- Class-colored border (set during update)
            icon.border = icon
            icon:Hide()
            hotContainer.icons[i] = icon
        end
        f.hotContainer = hotContainer
    end

    -- ---- CD TRACKER CONTAINER ----
    if db.showInterruptCD or db.showBrezCD then
        local cdSize = db.cdIconSize or 18
        local cdContainer = CreateFrame("Frame", nil, f)
        cdContainer:SetFrameLevel(f:GetFrameLevel() + 10)

        -- Use horizontal CD layout when growDirection is RIGHT/LEFT
        local dir = db.growDirection or "DOWN"
        local effectiveCDLayout = db.cdLayout
        if dir == "RIGHT" or dir == "LEFT" then
            effectiveCDLayout = "horizontal"
        end

        if effectiveCDLayout == "horizontal" then
            cdContainer:SetPoint("TOP", f, "BOTTOM", 0, -1)
            cdContainer:SetSize(cdSize * 2 + 4, cdSize)
        else
            cdContainer:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
            cdContainer:SetSize(cdSize, cdSize * 2 + 2)
        end

        cdContainer.icons = {}
        -- Interrupt icon
        if db.showInterruptCD then
            local kickIcon = CreateFrame("Frame", nil, cdContainer, "BackdropTemplate")
            kickIcon:SetSize(cdSize, cdSize)
            kickIcon:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            kickIcon:SetBackdropColor(0.05, 0.05, 0.05, 0.90)
            kickIcon:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)
            local tex = kickIcon:CreateTexture(nil, "ARTWORK")
            tex:SetPoint("TOPLEFT", 1, -1)
            tex:SetPoint("BOTTOMRIGHT", -1, 1)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            kickIcon.texture = tex
            local cd = CreateFrame("Cooldown", nil, kickIcon, "CooldownFrameTemplate")
            cd:SetAllPoints()
            cd:SetDrawEdge(false)
            cd:SetSwipeColor(0, 0, 0, 0.6)
            kickIcon.cooldown = cd
            local dur = kickIcon:CreateFontString(nil, "OVERLAY")
            dur:SetFont(db.font or ADDON_FONT, 9, "OUTLINE")
            dur:SetPoint("CENTER", 0, 0)
            kickIcon.durationText = dur
            kickIcon:Hide()
            cdContainer.kickIcon = kickIcon
            cdContainer.icons[#cdContainer.icons + 1] = kickIcon
        end

        -- Brez icon
        if db.showBrezCD then
            local brezIcon = CreateFrame("Frame", nil, cdContainer, "BackdropTemplate")
            brezIcon:SetSize(cdSize, cdSize)
            brezIcon:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            brezIcon:SetBackdropColor(0.05, 0.05, 0.05, 0.90)
            brezIcon:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)
            local tex = brezIcon:CreateTexture(nil, "ARTWORK")
            tex:SetPoint("TOPLEFT", 1, -1)
            tex:SetPoint("BOTTOMRIGHT", -1, 1)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            brezIcon.texture = tex
            local cd = CreateFrame("Cooldown", nil, brezIcon, "CooldownFrameTemplate")
            cd:SetAllPoints()
            cd:SetDrawEdge(false)
            cd:SetSwipeColor(0, 0, 0, 0.6)
            brezIcon.cooldown = cd
            local dur = brezIcon:CreateFontString(nil, "OVERLAY")
            dur:SetFont(db.font or ADDON_FONT, 9, "OUTLINE")
            dur:SetPoint("CENTER", 0, 0)
            brezIcon.durationText = dur
            brezIcon:Hide()
            cdContainer.brezIcon = brezIcon
            cdContainer.icons[#cdContainer.icons + 1] = brezIcon
        end

        -- Layout CD icons
        local function LayoutCDs()
            local idx = 0
            for _, icon in ipairs(cdContainer.icons) do
                icon:ClearAllPoints()
                if effectiveCDLayout == "horizontal" then
                    icon:SetPoint("LEFT", cdContainer, "LEFT", idx * (cdSize + 2), 0)
                else
                    icon:SetPoint("TOP", cdContainer, "TOP", 0, -idx * (cdSize + 2))
                end
                idx = idx + 1
            end
        end
        LayoutCDs()
        f.cdContainer = cdContainer
    end

    f:SetFrameLevel(10)
    f:Hide()  -- RegisterUnitWatch handles visibility

    PF.frames[index] = f
    return f
end

-- =====================================
-- UPDATE: HEALTH
-- =====================================
function PF.UpdateHealth(f)
    if not f or not f.health or not f.unit then return end
    if not UnitExists(f.unit) then return end

    local db = TomoModDB and TomoModDB.partyFrames
    if not db then return end

    local cur = UnitHealth(f.unit)
    local max = UnitHealthMax(f.unit)

    -- StatusBar C-API handles secret values natively
    f.health:SetMinMaxValues(0, max)
    f.health:SetValue(cur)

    local r, g, b = GetHealthColor(f.unit, db)
    f.health:SetStatusBarColor(r, g, b, 1)

    -- Dead/disconnected
    if UnitIsDeadOrGhost(f.unit) then
        f.health:SetStatusBarColor(0.5, 0.5, 0.5, 0.6)
    end

    local connected = UnitIsConnected(f.unit)
    if connected and not issecretvalue(connected) and not connected then
        f.health:SetStatusBarColor(0.3, 0.3, 0.3, 0.5)
    end

    -- Health text (Lua arithmetic needs taint guard)
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
function PF.UpdateAbsorb(f)
    if not f or not f.absorb then return end

    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.showAbsorb then f.absorb:Hide(); return end
    if not UnitExists(f.unit) then f.absorb:Hide(); return end

    local val = UnitGetTotalAbsorbs(f.unit)
    local max = UnitHealthMax(f.unit)

    if issecretvalue(val) or issecretvalue(max) then
        -- Can't evaluate condition; pass raw values to C-API
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
function PF.UpdateHealPrediction(f)
    if not f or not f.healPred then return end

    local db = TomoModDB and TomoModDB.partyFrames
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
-- UPDATE: POWER
-- =====================================
function PF.UpdatePower(f)
    if not f or not f.power then return end
    if not UnitExists(f.unit) then return end

    -- Only show power bar for healers
    local role = UnitGroupRolesAssigned(f.unit)
    if role ~= "HEALER" then
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
function PF.UpdateName(f)
    if not f or not f.nameText then return end
    if not UnitExists(f.unit) then f.nameText:SetText(""); return end

    local db = TomoModDB and TomoModDB.partyFrames
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

function PF.UpdateRole(f)
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
function PF.UpdateRaidMarker(f)
    if not f or not f.raidMarker then return end
    if not UnitExists(f.unit) then f.raidMarker:Hide(); return end

    local idx = GetRaidTargetIndex(f.unit)
    if issecretvalue(idx) then f.raidMarker:Hide(); return end
    if idx and raidIconCoords[idx] then
        local c = raidIconCoords[idx]
        f.raidMarker:SetTexCoord(c[1], c[2], c[3], c[4])
        f.raidMarker:Show()
    else
        f.raidMarker:Hide()
    end
end

-- =====================================
-- UPDATE: DISPEL HIGHLIGHT
-- =====================================
function PF.UpdateDispel(f)
    if not f or not f.dispelHighlight then return end

    local db = TomoModDB and TomoModDB.partyFrames
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
-- UPDATE: GROUP BUFF ICON
-- =====================================
function PF.UpdateGroupBuff(f)
    if not f or not f.groupBuff then return end
    if not f.unit or not UnitExists(f.unit) then f.groupBuff:Hide(); return end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local idx = 1
        while idx <= 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, f.unit, idx, "HELPFUL")
            if not ok or not aura then break end
            local sid = aura.spellId
            if sid and not issecretvalue(sid) and GROUP_BUFF_SPELLS[sid] then
                f.groupBuff.texture:SetTexture(aura.icon)
                f.groupBuff:Show()
                return
            end
            idx = idx + 1
        end
    end

    f.groupBuff:Hide()
end

-- =====================================
-- FULL UPDATE (per frame)
-- =====================================
function PF.UpdateFrame(f)
    if not f or not f.unit then return end
    PF.UpdateHealth(f)
    PF.UpdateAbsorb(f)
    PF.UpdateHealPrediction(f)
    PF.UpdatePower(f)
    PF.UpdateName(f)
    PF.UpdateRole(f)
    PF.UpdateRaidMarker(f)
    PF.UpdateDispel(f)
    PF.UpdateGroupBuff(f)
    -- HoTs and CDs are updated by their own modules
    if TomoMod_PartyHoTs then TomoMod_PartyHoTs.UpdateUnit(f) end
    if TomoMod_PartyCooldowns then TomoMod_PartyCooldowns.UpdateFrame(f) end
end

-- =====================================
-- RANGE CHECK (event + timer fallback)
-- =====================================

function PF.UpdateRange(f)
    if not f or not f.unit then return end

    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.showRange then f:SetAlpha(1); return end

    if f.unit == "player" then f:SetAlpha(1); return end
    if not UnitExists(f.unit) then f:SetAlpha(1); return end

    -- Phased units are always out of range
    if UnitPhaseReason and UnitPhaseReason(f.unit) then
        f:SetAlpha(db.oorAlpha or 0.40)
        return
    end

    -- Disconnected units
    local connected = UnitIsConnected(f.unit)
    if not IsPlayerSpell and not connected then
        f:SetAlpha(db.oorAlpha or 0.40)
        return
    end

    local inRange = UnitInRange(f.unit)
    f:SetAlphaFromBoolean(inRange, 1, db.oorAlpha or 0.40)
end

local rangeEventFrame = nil
local rangeTicker = nil

function PF.StartRangeChecker()
    if rangeEventFrame then return end

    -- Event-driven: instant response
    rangeEventFrame = CreateFrame("Frame")
    rangeEventFrame:RegisterEvent("UNIT_IN_RANGE_UPDATE")
    rangeEventFrame:SetScript("OnEvent", function(_, _, unit)
        local f = GetFrameForUnit(unit)
        if f and f:IsShown() then
            PF.UpdateRange(f)
        end
    end)

    -- Timer fallback: catches edge cases (phased, disconnect, zone changes)
    rangeTicker = C_Timer.NewTicker(0.5, function()
        local db = TomoModDB and TomoModDB.partyFrames
        if not db or not db.showRange then return end
        for _, f in pairs(PF.frames) do
            if f and f:IsShown() and f.unit then
                PF.UpdateRange(f)
            end
        end
    end)

    -- Initial pass for all visible frames
    for _, f in pairs(PF.frames) do
        if f and f:IsShown() and f.unit then
            PF.UpdateRange(f)
        end
    end
end

function PF.StopRangeChecker()
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
-- LAYOUT: Arrange frames
-- =====================================
function PF.LayoutFrames()
    local db = TomoModDB and TomoModDB.partyFrames
    if not db then return end
    if not PF.anchor then return end

    -- Gather active units and sort
    local units = {}
    for idx, f in pairs(PF.frames) do
        if f and f.unit and UnitExists(f.unit) then
            units[#units + 1] = f
        end
    end

    if db.sortByRole then
        table.sort(units, function(a, b)
            local ra = ROLE_ORDER[UnitGroupRolesAssigned(a.unit) or "NONE"] or 4
            local rb = ROLE_ORDER[UnitGroupRolesAssigned(b.unit) or "NONE"] or 4
            if ra ~= rb then return ra < rb end
            return (a.index or 0) < (b.index or 0)
        end)
    end

    local dir = db.growDirection or "DOWN"
    local spacing = db.spacing or 2

    -- Resize anchor to match layout direction
    if dir == "RIGHT" or dir == "LEFT" then
        PF.anchor:SetSize(db.width * 5 + spacing * 4, db.height)
    else
        PF.anchor:SetSize(db.width, db.height * 5 + spacing * 4)
    end

    for i, f in ipairs(units) do
        f:ClearAllPoints()
        local offset = (i - 1) * (db.height + spacing)
        if dir == "DOWN" then
            f:SetPoint("TOPLEFT", PF.anchor, "TOPLEFT", 0, -offset)
        elseif dir == "UP" then
            f:SetPoint("BOTTOMLEFT", PF.anchor, "BOTTOMLEFT", 0, offset)
        elseif dir == "RIGHT" then
            offset = (i - 1) * (db.width + spacing)
            f:SetPoint("TOPLEFT", PF.anchor, "TOPLEFT", offset, 0)
        elseif dir == "LEFT" then
            offset = (i - 1) * (db.width + spacing)
            f:SetPoint("TOPRIGHT", PF.anchor, "TOPRIGHT", -offset, 0)
        end
        f:SetSize(db.width, db.height)
    end
end

-- =====================================
-- HIDE BLIZZARD PARTY FRAMES
-- =====================================
local blizzardHidden = false

function PF.HideBlizzardFrames()
    if blizzardHidden then return end

    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.hideBlizzardFrames then return end

    -- CompactPartyFrame (Retail)
    if CompactPartyFrame then
        pcall(function()
            CompactPartyFrame:UnregisterAllEvents()
            CompactPartyFrame:Hide()
            CompactPartyFrame.Show = function() end
        end)
    end

    -- Legacy PartyMemberFrame 1-4
    for i = 1, 4 do
        local pmf = _G["PartyFrame"] and _G["PartyFrame"]["MemberFrame" .. i]
        if pmf then
            pcall(function()
                pmf:UnregisterAllEvents()
                pmf:Hide()
                pmf.Show = function() end
            end)
        end
    end

    -- PartyFrame container
    if PartyFrame then
        pcall(function()
            PartyFrame:UnregisterAllEvents()
            PartyFrame:Hide()
            PartyFrame.Show = function() end
        end)
    end

    blizzardHidden = true
end

-- =====================================
-- EVENT HANDLER
-- =====================================
local eventFrame = CreateFrame("Frame")

local function GetFrameForUnit(unit)
    for _, f in pairs(PF.frames) do
        if f and f.unit == unit then return f end
    end
    return nil
end

local function OnEvent(self, event, arg1, ...)
    if not PF.initialized then return end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local f = GetFrameForUnit(arg1)
        if f then
            PF.UpdateHealth(f)
            PF.UpdateAbsorb(f)
            PF.UpdateHealPrediction(f)
        end

    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        local f = GetFrameForUnit(arg1)
        if f then PF.UpdateAbsorb(f) end

    elseif event == "UNIT_HEAL_PREDICTION" then
        local f = GetFrameForUnit(arg1)
        if f then PF.UpdateHealPrediction(f) end

    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        local f = GetFrameForUnit(arg1)
        if f then PF.UpdatePower(f) end

    elseif event == "UNIT_NAME_UPDATE" then
        local f = GetFrameForUnit(arg1)
        if f then PF.UpdateName(f) end

    elseif event == "UNIT_AURA" then
        local f = GetFrameForUnit(arg1)
        if f then
            PF.UpdateDispel(f)
            PF.UpdateGroupBuff(f)
            if TomoMod_PartyHoTs then TomoMod_PartyHoTs.UpdateUnit(f) end
        end

    elseif event == "RAID_TARGET_UPDATE" then
        for _, f in pairs(PF.frames) do
            if f then PF.UpdateRaidMarker(f) end
        end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBER_ENABLE"
        or event == "PARTY_MEMBER_DISABLE" then
        PF.RefreshGroup()

    elseif event == "PLAYER_ROLES_ASSIGNED" then
        for _, f in pairs(PF.frames) do
            if f then PF.UpdateRole(f) end
        end
        if InCombatLockdown() then
            PF._pendingLayout = true
        else
            PF.LayoutFrames()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            PF.RefreshGroup()
            PF.HideBlizzardFrames()
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        if PF._pendingRefresh then
            PF._pendingRefresh = nil
            PF.RefreshGroup()
        end
        if PF._pendingLayout then
            PF._pendingLayout = nil
            PF.LayoutFrames()
        end
    end
end

-- =====================================
-- REFRESH GROUP: create/show/hide frames based on group
-- =====================================
function PF.RefreshGroup()
    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.enabled then return end

    -- RegisterUnitWatch calls SetAttribute (protected) — defer if in combat
    if InCombatLockdown() then
        PF._pendingRefresh = true
        return
    end

    -- In a raid, hide party frames (Blizzard raid frames handle raids)
    if IsInRaid() then
        for _, f in pairs(PF.frames) do
            if f then
                UnregisterUnitWatch(f)
                f:Hide()
            end
        end
        return
    end

    -- Solo or in party
    local inGroup = IsInGroup()
    local numMembers = inGroup and GetNumGroupMembers() or 0

    -- Player frame (index 0)
    if not PF.frames[0] then
        PF.CreateFrame(0, "player")
    end
    if inGroup then
        RegisterUnitWatch(PF.frames[0])
    else
        UnregisterUnitWatch(PF.frames[0])
        PF.frames[0]:Hide()
    end

    -- Party1..4
    for i = 1, 4 do
        local unit = "party" .. i
        if not PF.frames[i] then
            PF.CreateFrame(i, unit)
        end
        if inGroup and i < numMembers then
            RegisterUnitWatch(PF.frames[i])
        else
            UnregisterUnitWatch(PF.frames[i])
            PF.frames[i]:Hide()
        end
    end

    -- Full update all visible
    for _, f in pairs(PF.frames) do
        if f and f:IsShown() then
            PF.UpdateFrame(f)
        end
    end

    PF.LayoutFrames()
end

-- =====================================
-- MOVER SYSTEM
-- =====================================
function PF.ToggleLock()
    PF.isLocked = not PF.isLocked
    if PF.anchor then
        PF.anchor:SetMovable(not PF.isLocked)
        PF.anchor:EnableMouse(not PF.isLocked)
        if not PF.isLocked then
            PF.anchor.moverOverlay:Show()
        else
            PF.anchor.moverOverlay:Hide()
            -- Save position
            local db = TomoModDB and TomoModDB.partyFrames
            if db and PF.anchor then
                local p, _, rp, x, y = PF.anchor:GetPoint()
                db.position = { point = p, relativePoint = rp, x = x, y = y }
            end
        end
    end
end

function PF.IsLocked()
    return PF.isLocked
end

-- =====================================
-- CREATE ANCHOR
-- =====================================
function PF.CreateAnchor()
    local db = TomoModDB and TomoModDB.partyFrames
    if not db then return end

    local anchor = CreateFrame("Frame", "TomoMod_PartyAnchor", UIParent)

    -- Size based on grow direction
    local dir = db.growDirection or "DOWN"
    if dir == "RIGHT" or dir == "LEFT" then
        anchor:SetSize(db.width * 5 + db.spacing * 4, db.height)
    else
        anchor:SetSize(db.width, db.height * 5 + db.spacing * 4)
    end

    local pos = db.position
    if pos and pos.point then
        anchor:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
    else
        anchor:SetPoint("LEFT", UIParent, "LEFT", 20, 0)
    end

    anchor:SetMovable(false)
    anchor:EnableMouse(false)

    -- Mover overlay
    local mover = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
    mover:SetAllPoints()
    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    mover:SetBackdropColor(0.047, 0.824, 0.624, 0.3)
    mover:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.8)
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
    label:SetText("Party Frames")
    label:SetTextColor(0.047, 0.824, 0.624, 1)
    mover:Hide()
    anchor.moverOverlay = mover

    PF.anchor = anchor
end

-- =====================================
-- INITIALIZE
-- =====================================
function PF.Initialize()
    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.enabled then return end

    PF.CreateAnchor()
    PF.HideBlizzardFrames()

    -- Register events
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    eventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    eventFrame:RegisterEvent("UNIT_HEAL_PREDICTION")
    eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    eventFrame:RegisterEvent("UNIT_MAXPOWER")
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
    eventFrame:RegisterEvent("PARTY_MEMBER_DISABLE")
    eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", OnEvent)

    PF.initialized = true

    -- Start range checker
    PF.StartRangeChecker()

    -- Initial group refresh
    C_Timer.After(0.1, function() PF.RefreshGroup() end)
end

-- =====================================
-- APPLY SETTINGS (for config live-update)
-- =====================================
function PF.ApplySettings()
    local db = TomoModDB and TomoModDB.partyFrames
    if not db then return end

    if PF.anchor then
        local pos = db.position
        if pos and pos.point then
            PF.anchor:ClearAllPoints()
            PF.anchor:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
        end
    end

    -- Resize and update all frames
    for _, f in pairs(PF.frames) do
        if f then
            f:SetSize(db.width, db.height)

            -- Recalc power / health heights
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

            -- Resize CD tracker icons
            if f.cdContainer then
                local cdSize = db.cdIconSize or 18
                local dir = db.growDirection or "DOWN"
                local effectiveCDLayout = db.cdLayout
                if dir == "RIGHT" or dir == "LEFT" then
                    effectiveCDLayout = "horizontal"
                end

                f.cdContainer:ClearAllPoints()
                if effectiveCDLayout == "horizontal" then
                    f.cdContainer:SetPoint("TOP", f, "BOTTOM", 0, -1)
                    f.cdContainer:SetSize(cdSize * 2 + 4, cdSize)
                else
                    f.cdContainer:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
                    f.cdContainer:SetSize(cdSize, cdSize * 2 + 2)
                end

                local idx = 0
                for _, icon in ipairs(f.cdContainer.icons) do
                    icon:SetSize(cdSize, cdSize)
                    icon:ClearAllPoints()
                    if effectiveCDLayout == "horizontal" then
                        icon:SetPoint("LEFT", f.cdContainer, "LEFT", idx * (cdSize + 2), 0)
                    else
                        icon:SetPoint("TOP", f.cdContainer, "TOP", 0, -idx * (cdSize + 2))
                    end
                    idx = idx + 1
                end
            end

            if f:IsShown() then
                PF.UpdateFrame(f)
            end
        end
    end

    PF.LayoutFrames()
end

-- =====================================
-- SET ENABLED
-- =====================================
function PF.SetEnabled(v)
    local db = TomoModDB and TomoModDB.partyFrames
    if db then db.enabled = v end
end

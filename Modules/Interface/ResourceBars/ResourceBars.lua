-- =====================================
-- ResourceBars.lua — Class Resource Bars System
-- Primary, Secondary, Tertiary resource display per class/spec
-- Supports: all classes, Druid form-adaptive, DK runes, Monk stagger
-- =====================================

TomoMod_ResourceBars = TomoMod_ResourceBars or {}
local RB = TomoMod_ResourceBars

local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

-- =====================================
-- POWER TYPE CONSTANTS (Enum.PowerType)
-- =====================================
local POWER_MANA          = 0
local POWER_RAGE          = 1
local POWER_FOCUS         = 2
local POWER_ENERGY        = 3
local POWER_COMBO_POINTS  = 4
local POWER_RUNES         = 5
local POWER_RUNIC_POWER   = 6
local POWER_SOUL_SHARDS   = 7
local POWER_LUNAR_POWER   = 8  -- Astral Power
local POWER_HOLY_POWER    = 9
local POWER_MAELSTROM     = 11
local POWER_CHI           = 12
local POWER_INSANITY      = 13
local POWER_ARCANE_CHARGES = 16
local POWER_FURY          = 17
local POWER_ESSENCE       = 19

-- =====================================
-- AURA BAR HELPERS (Devourer Soul Fragments, etc.)
-- =====================================
-- Generic function to read an aura-based resource as current/max for bar display
-- def fields: spellIDs (table), talentSpellID (optional), maxDefault, maxWithTalent
local function GetAuraBarValues(def)
    local current = 0
    if def.spellIDs then
        for _, sid in ipairs(def.spellIDs) do
            local auraData = C_UnitAuras.GetPlayerAuraBySpellID(sid)
            if auraData then
                current = auraData.applications or 0
                break
            end
        end
    end

    local max = def.maxDefault or 50
    if def.talentSpellID and C_SpellBook.IsSpellKnown(def.talentSpellID) then
        max = def.maxWithTalent or max
    end

    return current, max
end

-- =====================================
-- CLASS / SPEC RESOURCE DEFINITIONS
-- =====================================
local CLASS_RESOURCES = {
    SHAMAN = {
        [1] = { -- Elemental
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "bar", powerType = POWER_MAELSTROM, label = "Maelstrom" },
        },
        [2] = { -- Enhancement
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "aura", spellID = 344179, label = "Maelstrom Weapon", maxStacks = 10 },
        },
        [3] = { -- Restoration
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
        },
    },
    HUNTER = {
        [1] = { -- Beast Mastery
            primary   = { display = "bar", powerType = POWER_FOCUS, label = "Focus" },
        },
        [2] = { -- Marksmanship
            primary   = { display = "bar", powerType = POWER_FOCUS, label = "Focus" },
        },
        [3] = { -- Survival
            primary   = { display = "bar", powerType = POWER_FOCUS, label = "Focus" },
            secondary = { display = "aura", spellID = 260286, label = "Tip of the Spear", maxStacks = 3 },
        },
    },
    DEMONHUNTER = {
        [1] = { -- Havoc
            primary   = { display = "bar", powerType = POWER_FURY, label = "Fury" },
        },
        [2] = { -- Vengeance
            primary   = { display = "bar", powerType = POWER_FURY, label = "Fury" },
            secondary = { display = "aura", spellID = 203981, label = "Soul Fragments", maxStacks = 6 },
        },
        [3] = { -- Devourer - Soul Fragments / Collapsing Star / Soul Glutton adaptive display
            primary   = { display = "bar", powerType = POWER_FURY, label = "Fury" },
            secondary = { display = "aura_bar", label = "Soul Fragments", colorKey = "soulFragments", spellIDs = { 1225789, 1227702 }, talentSpellID = 1247534, maxDefault = 50, maxWithTalent = 35 },
        },
    },
    DEATHKNIGHT = {
        [1] = { -- Blood
            primary   = { display = "bar", powerType = POWER_RUNIC_POWER, label = "Runic Power" },
            secondary = { display = "runes", label = "Runes" },
        },
        [2] = { -- Frost
            primary   = { display = "bar", powerType = POWER_RUNIC_POWER, label = "Runic Power" },
            secondary = { display = "runes", label = "Runes" },
        },
        [3] = { -- Unholy
            primary   = { display = "bar", powerType = POWER_RUNIC_POWER, label = "Runic Power" },
            secondary = { display = "runes", label = "Runes" },
        },
    },
    WARLOCK = {
        [1] = { -- Affliction
            primary   = { display = "points", powerType = POWER_SOUL_SHARDS, label = "Soul Shards", maxPoints = 5, showPartial = true },
        },
        [2] = { -- Demonology
            primary   = { display = "points", powerType = POWER_SOUL_SHARDS, label = "Soul Shards", maxPoints = 5, showPartial = true },
        },
        [3] = { -- Destruction
            primary   = { display = "points", powerType = POWER_SOUL_SHARDS, label = "Soul Shards", maxPoints = 5, showPartial = true },
        },
    },
    DRUID = {
        [1] = { -- Balance
            primary   = { display = "bar", powerType = POWER_LUNAR_POWER, label = "Astral Power" },
            druidMana = true,
        },
        [2] = { -- Feral
            primary   = { display = "bar", powerType = POWER_ENERGY, label = "Energy" },
            secondary = { display = "points", powerType = POWER_COMBO_POINTS, label = "Combo Points", maxPoints = 5 },
            druidMana = true,
        },
        [3] = { -- Guardian
            primary   = { display = "bar", powerType = POWER_RAGE, label = "Rage" },
            druidMana = true,
        },
        [4] = { -- Restoration
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
        },
    },
    EVOKER = {
        [1] = { -- Devastation
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "points", powerType = POWER_ESSENCE, label = "Essence", maxPoints = 6 },
        },
        [2] = { -- Preservation
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "points", powerType = POWER_ESSENCE, label = "Essence", maxPoints = 6 },
        },
        [3] = { -- Augmentation
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "points", powerType = POWER_ESSENCE, label = "Essence", maxPoints = 6 },
        },
    },
    WARRIOR = {
        [1] = { primary = { display = "bar", powerType = POWER_RAGE, label = "Rage" } },
        [2] = { primary = { display = "bar", powerType = POWER_RAGE, label = "Rage" } },
        [3] = { primary = { display = "bar", powerType = POWER_RAGE, label = "Rage" } },
    },
    MAGE = {
        [1] = { -- Arcane
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "points", powerType = POWER_ARCANE_CHARGES, label = "Arcane Charges", maxPoints = 4 },
        },
        [2] = { primary = { display = "bar", powerType = POWER_MANA, label = "Mana" } },
        [3] = { primary = { display = "bar", powerType = POWER_MANA, label = "Mana" } },
    },
    MONK = {
        [1] = { -- Brewmaster
            primary   = { display = "bar", powerType = POWER_ENERGY, label = "Energy" },
            secondary = { display = "stagger", label = "Stagger" },
        },
        [2] = { primary = { display = "bar", powerType = POWER_MANA, label = "Mana" } },
        [3] = { -- Windwalker
            primary   = { display = "bar", powerType = POWER_ENERGY, label = "Energy" },
            secondary = { display = "points", powerType = POWER_CHI, label = "Chi", maxPoints = 6 },
        },
    },
    PALADIN = {
        [1] = {
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "points", powerType = POWER_HOLY_POWER, label = "Holy Power", maxPoints = 5 },
        },
        [2] = {
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "points", powerType = POWER_HOLY_POWER, label = "Holy Power", maxPoints = 5 },
        },
        [3] = {
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "points", powerType = POWER_HOLY_POWER, label = "Holy Power", maxPoints = 5 },
        },
    },
    PRIEST = {
        [1] = { primary = { display = "bar", powerType = POWER_MANA, label = "Mana" } },
        [2] = { primary = { display = "bar", powerType = POWER_MANA, label = "Mana" } },
        [3] = { -- Shadow
            primary   = { display = "bar", powerType = POWER_MANA, label = "Mana" },
            secondary = { display = "bar", powerType = POWER_INSANITY, label = "Insanity" },
        },
    },
    ROGUE = {
        [1] = {
            primary   = { display = "bar", powerType = POWER_ENERGY, label = "Energy" },
            secondary = { display = "points", powerType = POWER_COMBO_POINTS, label = "Combo Points", maxPoints = 7 },
        },
        [2] = {
            primary   = { display = "bar", powerType = POWER_ENERGY, label = "Energy" },
            secondary = { display = "points", powerType = POWER_COMBO_POINTS, label = "Combo Points", maxPoints = 7 },
        },
        [3] = {
            primary   = { display = "bar", powerType = POWER_ENERGY, label = "Energy" },
            secondary = { display = "points", powerType = POWER_COMBO_POINTS, label = "Combo Points", maxPoints = 7 },
        },
    },
}

-- =====================================
-- POWER → COLOR KEY MAP
-- =====================================
local POWER_COLOR_KEYS = {
    [POWER_MANA]           = "mana",
    [POWER_RAGE]           = "rage",
    [POWER_FOCUS]          = "focus",
    [POWER_ENERGY]         = "energy",
    [POWER_COMBO_POINTS]   = "comboPoints",
    [POWER_RUNES]          = "runes",
    [POWER_RUNIC_POWER]    = "runicPower",
    [POWER_SOUL_SHARDS]    = "soulShards",
    [POWER_LUNAR_POWER]    = "astralPower",
    [POWER_HOLY_POWER]     = "holyPower",
    [POWER_MAELSTROM]      = "maelstrom",
    [POWER_CHI]            = "chi",
    [POWER_INSANITY]       = "insanity",
    [POWER_ARCANE_CHARGES] = "arcaneCharges",
    [POWER_FURY]           = "fury",
    [POWER_ESSENCE]        = "essence",
}

-- =====================================
-- MODULE STATE
-- =====================================
local _, playerClass = UnitClass("player")
local mainFrame
local container
local primaryBar
local secondaryContainer
local druidManaBar
local currentResources
local currentSpec = 0
local isInitialized = false

-- =====================================
-- HELPERS
-- =====================================
local function GetSettings()
    return TomoModDB and TomoModDB.resourceBars
end

local function GetColor(colorKey)
    local s = GetSettings()
    if s and s.colors and s.colors[colorKey] then
        local c = s.colors[colorKey]
        return c.r, c.g, c.b
    end
    return 0.5, 0.5, 0.5
end

local function GetFont()
    local s = GetSettings()
    if s and s.font and s.font ~= "" then return s.font end
    return FONT
end

local function GetFontSize()
    local s = GetSettings()
    return s and s.fontSize or 11
end

local function GetTextAlignment()
    local s = GetSettings()
    return s and s.textAlignment or "CENTER"
end

-- =====================================
-- BORDER (mirrors UF_Elements.CreateBorder)
-- =====================================
local function CreateBorder(frame)
    local function Edge(p1, p2, w, h)
        local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, 1)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    Edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
end

-- =====================================
-- CREATE: PRIMARY BAR (continuous StatusBar)
-- =====================================
local function CreatePrimaryBar(parent, width, height)
    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE

    local bar = CreateFrame("StatusBar", "TomoMod_RB_Primary", parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetTexture(tex)
    bg:SetVertexColor(0.06, 0.06, 0.08, 0.8)
    bar.bg = bg
    CreateBorder(bar)

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(GetFont(), GetFontSize(), "OUTLINE")
    text:SetTextColor(1, 1, 1, 0.9)
    bar.text = text

    local align = GetTextAlignment()
    if align == "LEFT" then
        text:SetPoint("LEFT", 4, 0); text:SetJustifyH("LEFT")
    elseif align == "RIGHT" then
        text:SetPoint("RIGHT", -4, 0); text:SetJustifyH("RIGHT")
    else
        text:SetPoint("CENTER"); text:SetJustifyH("CENTER")
    end

    return bar
end

-- =====================================
-- CREATE: POINT DISPLAY (Combo, Holy Power, Chi, etc.)
-- =====================================
local function CreatePointDisplay(parent, maxPoints, width, height, colorKey)
    local frame = CreateFrame("Frame", "TomoMod_RB_Points", parent)
    frame:SetSize(width, height)

    local spacing = 2
    local pw = (width - (maxPoints - 1) * spacing) / maxPoints
    frame.points = {}
    frame.maxPoints = maxPoints
    frame.colorKey = colorKey

    for i = 1, maxPoints do
        local pt = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        pt:SetSize(pw, height)
        pt:SetPoint("LEFT", frame, "LEFT", (i - 1) * (pw + spacing), 0)

        local bg = pt:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(0.06, 0.06, 0.08, 0.8)
        pt.bg = bg

        local fill = pt:CreateTexture(nil, "ARTWORK")
        fill:SetAllPoints()
        fill:SetColorTexture(GetColor(colorKey))
        fill:Hide()
        pt.fill = fill

        -- Partial fill (for Soul Shards)
        local partial = pt:CreateTexture(nil, "ARTWORK")
        partial:SetPoint("BOTTOMLEFT"); partial:SetPoint("TOPLEFT")
        partial:SetWidth(0)
        partial:SetColorTexture(GetColor(colorKey))
        partial:SetAlpha(0.5)
        partial:Hide()
        pt.partial = partial

        CreateBorder(pt)
        frame.points[i] = pt
    end

    return frame
end

-- =====================================
-- CREATE: RUNE DISPLAY (DK: 6 runes with cooldown)
-- =====================================
local function CreateRuneDisplay(parent, width, height)
    local frame = CreateFrame("Frame", "TomoMod_RB_Runes", parent)
    frame:SetSize(width, height)

    local spacing = 2
    local rw = (width - 5 * spacing) / 6
    frame.runes = {}
    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE

    for i = 1, 6 do
        local rune = CreateFrame("StatusBar", nil, frame)
        rune:SetSize(rw, height)
        rune:SetPoint("LEFT", frame, "LEFT", (i - 1) * (rw + spacing), 0)
        rune:SetStatusBarTexture(tex)
        rune:GetStatusBarTexture():SetHorizTile(false)
        rune:SetMinMaxValues(0, 1); rune:SetValue(1)

        local bg = rune:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetTexture(tex)
        bg:SetVertexColor(0.06, 0.06, 0.08, 0.8)
        rune.bg = bg

        local cd = rune:CreateFontString(nil, "OVERLAY")
        cd:SetFont(GetFont(), math.max(GetFontSize() - 2, 7), "OUTLINE")
        cd:SetPoint("CENTER"); cd:SetTextColor(1, 1, 1, 0.8)
        rune.cdText = cd

        CreateBorder(rune)
        frame.runes[i] = rune
    end

    return frame
end

-- =====================================
-- CREATE: STAGGER BAR (Monk Brewmaster)
-- =====================================
local function CreateStaggerBar(parent, width, height)
    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE
    local bar = CreateFrame("StatusBar", "TomoMod_RB_Stagger", parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(0)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetTexture(tex)
    bg:SetVertexColor(0.06, 0.06, 0.08, 0.8)
    bar.bg = bg
    CreateBorder(bar)

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(GetFont(), GetFontSize(), "OUTLINE")
    text:SetPoint("CENTER"); text:SetTextColor(1, 1, 1, 0.9)
    bar.text = text

    return bar
end

-- =====================================
-- CREATE: DRUID MANA BAR (secondary when in form)
-- =====================================
local function CreateDruidManaBar(parent, width, height)
    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE
    local bar = CreateFrame("StatusBar", "TomoMod_RB_DruidMana", parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(100)

    local r, g, b = GetColor("mana")
    bar:SetStatusBarColor(r, g, b, 1)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetTexture(tex)
    bg:SetVertexColor(0.06, 0.06, 0.08, 0.8)
    bar.bg = bg
    CreateBorder(bar)

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(GetFont(), math.max(GetFontSize() - 1, 7), "OUTLINE")
    text:SetPoint("CENTER"); text:SetTextColor(1, 1, 1, 0.7)
    bar.text = text

    return bar
end

-- =====================================
-- UPDATE: PRIMARY BAR
-- =====================================
local function UpdatePrimaryBar(resDef)
    if not primaryBar or not resDef then return end
    local pType = resDef.powerType
    local current = UnitPower("player", pType)
    local max = UnitPowerMax("player", pType)

    primaryBar:SetMinMaxValues(0, max)
    primaryBar:SetValue(current)

    local colorKey = POWER_COLOR_KEYS[pType] or "mana"
    local r, g, b = GetColor(colorKey)
    primaryBar:SetStatusBarColor(r, g, b, 1)

    local s = GetSettings()
    if s and s.showText and primaryBar.text then
        primaryBar.text:SetFormattedText("%s / %s", AbbreviateLargeNumbers(current), AbbreviateLargeNumbers(max))
    elseif primaryBar.text then
        primaryBar.text:SetText("")
    end
end

-- =====================================
-- UPDATE: POINTS / AURA DISPLAY
-- =====================================
local function UpdatePoints(pointFrame, resDef)
    if not pointFrame or not pointFrame.points then return end

    local current, max, partialFrac
    if resDef.display == "aura" then
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(resDef.spellID)
        current = aura and aura.applications or 0
        max = resDef.maxStacks or #pointFrame.points
        partialFrac = 0
    else
        current = UnitPower("player", resDef.powerType)
        max = UnitPowerMax("player", resDef.powerType)
        partialFrac = 0

        if resDef.showPartial then
            local rawCur = UnitPower("player", resDef.powerType, true)
            local modifier = UnitPowerDisplayMod(resDef.powerType)
            if modifier and modifier > 0 then
                local full = math.floor(rawCur / modifier)
                local rem = rawCur - (full * modifier)
                current = full
                partialFrac = rem / modifier
            end
        end
    end

    local colorKey = pointFrame.colorKey or "comboPoints"
    local r, g, b = GetColor(colorKey)
    local displayMax = math.min(max, #pointFrame.points)

    for i = 1, #pointFrame.points do
        local pt = pointFrame.points[i]
        if i > displayMax then
            pt:Hide()
        else
            pt:Show()
            if i <= current then
                pt.fill:SetColorTexture(r, g, b); pt.fill:Show()
                pt.partial:Hide()
            elseif i == current + 1 and partialFrac > 0 then
                pt.fill:Hide()
                pt.partial:SetColorTexture(r, g, b)
                pt.partial:SetWidth(math.max(pt:GetWidth() * partialFrac, 1))
                pt.partial:Show()
            else
                pt.fill:Hide(); pt.partial:Hide()
            end
        end
    end
end

-- =====================================
-- UPDATE: RUNES (DK)
-- =====================================
local function UpdateRunes(runeFrame)
    if not runeFrame or not runeFrame.runes then return end
    local now = GetTime()
    local rR, gR, bR = GetColor("runesReady")
    local rC, gC, bC = GetColor("runes")

    for i = 1, 6 do
        local rune = runeFrame.runes[i]
        if rune then
            local start, duration, runeReady = GetRuneCooldown(i)
            if runeReady then
                rune:SetValue(1)
                rune:SetStatusBarColor(rR, gR, bR, 1)
                rune.cdText:SetText("")
            else
                local elapsed = now - start
                local progress = math.min(elapsed / duration, 1)
                rune:SetValue(progress)
                rune:SetStatusBarColor(rC, gC, bC, 0.6)
                local remaining = duration - elapsed
                if remaining > 0 then
                    rune.cdText:SetFormattedText("%.1f", remaining)
                else
                    rune.cdText:SetText("")
                end
            end
        end
    end
end

-- =====================================
-- UPDATE: STAGGER (Monk)
-- =====================================
local function UpdateStagger(bar)
    if not bar then return end
    local stagger = UnitStagger("player") or 0
    local maxHP = UnitHealthMax("player")

    -- C-side widget methods — accept secret numbers natively
    bar:SetMinMaxValues(0, maxHP)
    bar:SetValue(stagger)

    -- TWW: UnitStagger returns a secret value — cannot compute percentage in Lua
    -- Use default stagger color (visual bar still shows correct proportion)
    local r, g, b = GetColor("stagger")
    bar:SetStatusBarColor(r, g, b, 1)

    local s = GetSettings()
    if s and s.showText and bar.text then
        bar.text:SetFormattedText("%s", AbbreviateLargeNumbers(stagger))
    elseif bar.text then
        bar.text:SetText("")
    end
end

-- =====================================
-- UPDATE: DRUID MANA
-- =====================================
local function UpdateDruidMana()
    if not druidManaBar then return end
    if UnitPowerType("player") == POWER_MANA then
        druidManaBar:Hide(); return
    end
    druidManaBar:Show()
    local current = UnitPower("player", POWER_MANA)
    local max = UnitPowerMax("player", POWER_MANA)
    druidManaBar:SetMinMaxValues(0, max)
    druidManaBar:SetValue(current)
    local r, g, b = GetColor("mana")
    druidManaBar:SetStatusBarColor(r, g, b, 1)

    local s = GetSettings()
    if s and s.showText and druidManaBar.text then
        druidManaBar.text:SetFormattedText("%s", AbbreviateLargeNumbers(current))
    elseif druidManaBar.text then
        druidManaBar.text:SetText("")
    end
end

-- =====================================
-- DRUID ADAPTIVE PRIMARY
-- =====================================
local function GetDruidAdaptivePrimary()
    local pType = UnitPowerType("player")
    if pType == POWER_RAGE then
        return { display = "bar", powerType = POWER_RAGE, label = "Rage" }
    elseif pType == POWER_ENERGY then
        return { display = "bar", powerType = POWER_ENERGY, label = "Energy" }
    elseif pType == POWER_LUNAR_POWER then
        return { display = "bar", powerType = POWER_LUNAR_POWER, label = "Astral Power" }
    else
        return { display = "bar", powerType = POWER_MANA, label = "Mana" }
    end
end

-- =====================================
-- AURA COLOR KEY RESOLVER
-- =====================================
local function GetAuraColorKey(label)
    if label == "Soul Fragments" then return "soulFragments" end
    if label == "Tip of the Spear" then return "tipOfTheSpear" end
    if label == "Maelstrom Weapon" then return "maelstromWeapon" end
    return "comboPoints"
end

-- =====================================
-- BUILD/REBUILD RESOURCE DISPLAY
-- =====================================
local function BuildResourceDisplay()
    local s = GetSettings()
    if not s or not s.enabled then return end

    local specIndex = GetSpecialization()
    if not specIndex or specIndex == 0 then return end

    local classData = CLASS_RESOURCES[playerClass]
    if not classData then return end

    local resources = classData[specIndex]
    if not resources then return end

    currentResources = resources
    currentSpec = specIndex

    local width = s.width or 260
    local pH = s.primaryHeight or 16
    local sH = s.secondaryHeight or 12
    local gap = 2

    -- Clear old
    if primaryBar then primaryBar:Hide(); primaryBar = nil end
    if secondaryContainer then secondaryContainer:Hide(); secondaryContainer = nil end
    if druidManaBar then druidManaBar:Hide(); druidManaBar = nil end

    -- Container
    if not container then
        container = CreateFrame("Frame", "TomoMod_ResourceBars_Container", UIParent)
        container:SetClampedToScreen(true)
        TomoMod_Utils.SetupDraggable(container, function()
            local point, _, relativePoint, x, y = container:GetPoint()
            s.position = s.position or {}
            s.position.point = point
            s.position.relativePoint = relativePoint
            s.position.x = x
            s.position.y = y
        end)
    end

    -- Apply scale
    container:SetScale(s.scale or 1.0)

    -- Position
    local pos = s.position
    container:ClearAllPoints()
    if pos then
        container:SetPoint(pos.point or "BOTTOM", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or -230)
    else
        container:SetPoint("BOTTOM", UIParent, "CENTER", 0, -230)
    end

    local totalH, nextY = 0, 0

    -- === PRIMARY ===
    local primaryDef = resources.primary
    if playerClass == "DRUID" then
        primaryDef = GetDruidAdaptivePrimary()
    end

    if primaryDef then
        if primaryDef.display == "bar" then
            primaryBar = CreatePrimaryBar(container, width, pH)
            primaryBar:ClearAllPoints()
            primaryBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
            nextY = nextY + pH + gap
            totalH = totalH + pH + gap
        elseif primaryDef.display == "points" then
            local ck = POWER_COLOR_KEYS[primaryDef.powerType] or "soulShards"
            primaryBar = CreatePointDisplay(container, primaryDef.maxPoints or 5, width, pH, ck)
            primaryBar:ClearAllPoints()
            primaryBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
            primaryBar.isPrimaryPoints = true
            nextY = nextY + pH + gap
            totalH = totalH + pH + gap
        end
    end

    -- === DRUID MANA BAR ===
    if playerClass == "DRUID" and resources.druidMana then
        druidManaBar = CreateDruidManaBar(container, width, sH)
        druidManaBar:ClearAllPoints()
        druidManaBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
        nextY = nextY + sH + gap
        totalH = totalH + sH + gap
    end

    -- === SECONDARY ===
    local secDef = resources.secondary
    if secDef then
        if secDef.display == "points" then
            local ck = POWER_COLOR_KEYS[secDef.powerType] or "comboPoints"
            secondaryContainer = CreatePointDisplay(container, secDef.maxPoints or 5, width, sH, ck)
        elseif secDef.display == "bar" then
            secondaryContainer = CreatePrimaryBar(container, width, sH)
        elseif secDef.display == "runes" then
            secondaryContainer = CreateRuneDisplay(container, width, sH)
        elseif secDef.display == "stagger" then
            secondaryContainer = CreateStaggerBar(container, width, sH)
        elseif secDef.display == "aura" then
            local ck = GetAuraColorKey(secDef.label)
            secondaryContainer = CreatePointDisplay(container, secDef.maxStacks or 5, width, sH, ck)
        elseif secDef.display == "aura_bar" then
            secondaryContainer = CreatePrimaryBar(container, width, sH)
        end

        if secondaryContainer then
            secondaryContainer:ClearAllPoints()
            secondaryContainer:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
            nextY = nextY + sH + gap
            totalH = totalH + sH + gap
        end
    end

    container:SetSize(width, math.max(totalH, 1))
    container:Show()
end

-- =====================================
-- MASTER UPDATE
-- =====================================
local function UpdateAll()
    if not container or not container:IsShown() then return end
    if not currentResources then return end

    local resources = currentResources
    local primaryDef = resources.primary
    if playerClass == "DRUID" then primaryDef = GetDruidAdaptivePrimary() end

    -- Primary
    if primaryBar then
        if primaryBar.isPrimaryPoints then
            UpdatePoints(primaryBar, resources.primary)
        elseif primaryDef and primaryDef.display == "bar" then
            UpdatePrimaryBar(primaryDef)
        end
    end

    -- Druid Mana
    if druidManaBar then UpdateDruidMana() end

    -- Secondary
    if secondaryContainer and resources.secondary then
        local sec = resources.secondary
        if sec.display == "points" or sec.display == "aura" then
            UpdatePoints(secondaryContainer, sec)
        elseif sec.display == "aura_bar" then
            local cur, max = GetAuraBarValues(sec)
            secondaryContainer:SetMinMaxValues(0, max)
            secondaryContainer:SetValue(cur)
            local ck = sec.colorKey or "soulFragments"
            local r, g, b = GetColor(ck)
            secondaryContainer:SetStatusBarColor(r, g, b, 1)
            local s = GetSettings()
            if s and s.showText and secondaryContainer.text then
                secondaryContainer.text:SetFormattedText("%d / %d", cur, max)
            elseif secondaryContainer.text then
                secondaryContainer.text:SetText("")
            end
        elseif sec.display == "bar" then
            local pType = sec.powerType
            local cur = UnitPower("player", pType)
            local max = UnitPowerMax("player", pType)
            secondaryContainer:SetMinMaxValues(0, max)
            secondaryContainer:SetValue(cur)
            local ck = POWER_COLOR_KEYS[pType] or "insanity"
            local r, g, b = GetColor(ck)
            secondaryContainer:SetStatusBarColor(r, g, b, 1)
            local s = GetSettings()
            if s and s.showText and secondaryContainer.text then
                secondaryContainer.text:SetFormattedText("%s", AbbreviateLargeNumbers(cur))
            elseif secondaryContainer.text then
                secondaryContainer.text:SetText("")
            end
        elseif sec.display == "runes" then
            UpdateRunes(secondaryContainer)
        elseif sec.display == "stagger" then
            UpdateStagger(secondaryContainer)
        end
    end
end

-- =====================================
-- ALPHA MANAGEMENT
-- =====================================
local function UpdateAlpha()
    if not container then return end
    local s = GetSettings()
    if not s then return end

    local mode = s.visibilityMode or "always"
    if mode == "hidden" then container:SetAlpha(0); return end

    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target")
    local cAlpha = s.combatAlpha or 1.0
    local oAlpha = s.oocAlpha or 0.5

    if mode == "combat" then
        container:SetAlpha(inCombat and cAlpha or 0)
    elseif mode == "target" then
        container:SetAlpha((inCombat or hasTarget) and cAlpha or oAlpha)
    else
        container:SetAlpha(inCombat and cAlpha or oAlpha)
    end
end

-- =====================================
-- EVENT HANDLER
-- =====================================
local function OnEvent(self, event, arg1)
    local s = GetSettings()
    if not s or not s.enabled then return end

    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function() BuildResourceDisplay(); UpdateAlpha(); if RB._refreshOnUpdate then RB._refreshOnUpdate() end end)
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        C_Timer.After(0.5, function()
            local newSpec = GetSpecialization()
            if newSpec ~= currentSpec then
                currentSpec = newSpec
                BuildResourceDisplay()
                if RB._refreshOnUpdate then RB._refreshOnUpdate() end
            end
        end)
    elseif event == "UNIT_POWER_FREQUENT" or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        if arg1 == "player" then UpdateAll() end
    elseif event == "RUNE_POWER_UPDATE" then
        if secondaryContainer and currentResources and currentResources.secondary
           and currentResources.secondary.display == "runes" then
            UpdateRunes(secondaryContainer)
        end
    elseif event == "UNIT_AURA" then
        if arg1 == "player" then UpdateAll() end
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        if playerClass == "DRUID" then BuildResourceDisplay(); if RB._refreshOnUpdate then RB._refreshOnUpdate() end end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_TARGET_CHANGED" then
        UpdateAlpha()
    elseif event == "UNIT_HEALTH" then
        if arg1 == "player" and secondaryContainer and currentResources
           and currentResources.secondary and currentResources.secondary.display == "stagger" then
            UpdateStagger(secondaryContainer)
        end
    end
end

-- OnUpdate only needed for smooth rune CDs (DK) — all other resources use events
local updateTimer = 0
local function OnUpdate(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.05 then
        updateTimer = 0
        -- [PERF] Only update runes here; other resources are event-driven
        if secondaryContainer and currentResources and currentResources.secondary
           and currentResources.secondary.display == "runes" then
            UpdateRunes(secondaryContainer)
        elseif secondaryContainer and currentResources and currentResources.secondary
           and currentResources.secondary.display == "stagger" then
            UpdateStagger(secondaryContainer)
        end
    end
end

-- =====================================
-- SYNC WIDTH WITH ESSENTIAL COOLDOWNS
-- =====================================
local function SyncWithEssentialCooldowns()
    local s = GetSettings()
    if not s or not s.syncWidthWithCooldowns then return end
    if not container then return end
    local ecv = EssentialCooldownViewer
    if ecv then
        local w = ecv:GetWidth()
        if w and w > 0 then
            s.width = w
            BuildResourceDisplay()
            print("|cff0cd29fTomoMod ResourceBars:|r " .. string.format(TomoMod_L["msg_rb_width_synced"], math.floor(w)))
        end
    end
end

-- =====================================
-- PUBLIC API
-- =====================================
function RB.Initialize()
    if isInitialized then return end
    if not TomoModDB then return end
    local s = GetSettings()
    if not s or not s.enabled then return end

    mainFrame = CreateFrame("Frame")
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mainFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    mainFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    -- Use RegisterUnitEvent for player-only events to avoid tainting
    -- Blizzard's BuffFrame/arena frames in the same dispatch context
    mainFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    mainFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    mainFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    mainFrame:RegisterEvent("RUNE_POWER_UPDATE")
    mainFrame:RegisterUnitEvent("UNIT_AURA", "player")
    mainFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    mainFrame:RegisterUnitEvent("UNIT_HEALTH", "player")
    mainFrame:SetScript("OnEvent", OnEvent)

    -- [PERF] Only attach OnUpdate for specs that need frame-level updates (runes, stagger)
    local function RefreshOnUpdate()
        if currentResources and currentResources.secondary then
            local d = currentResources.secondary.display
            if d == "runes" or d == "stagger" then
                mainFrame:SetScript("OnUpdate", OnUpdate)
                return
            end
        end
        mainFrame:SetScript("OnUpdate", nil)
    end
    RB._refreshOnUpdate = RefreshOnUpdate
    RefreshOnUpdate()

    isInitialized = true
end

function RB.ApplySettings()
    if not isInitialized then return end
    BuildResourceDisplay()
    UpdateAlpha()
end

function RB.SetEnabled(enabled)
    local s = GetSettings()
    if not s then return end
    s.enabled = enabled
    if enabled then
        if not isInitialized then RB.Initialize() end
        BuildResourceDisplay(); UpdateAlpha()
    else
        if container then container:Hide() end
    end
end

function RB.ToggleLock()
    if not container then return end
    if container.SetLocked then
        local locked = container:IsLocked()
        container:SetLocked(not locked)
        if not locked then
            print("|cff0cd29fTomoMod ResourceBars:|r " .. TomoMod_L["msg_rb_locked"])
        else
            print("|cff0cd29fTomoMod ResourceBars:|r " .. TomoMod_L["msg_rb_unlocked"])
        end
    end
end

function RB.SyncWidth()
    SyncWithEssentialCooldowns()
end

_G.TomoMod_ResourceBars = RB
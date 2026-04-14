-- =====================================
-- ResourceBars.lua — Class Power Display System
-- Displays class-specific resources: combo points, holy power,
-- soul shards, chi, essence, arcane charges, runes, stagger, etc.
-- Primary power (mana/rage/energy/etc.) is shown in UnitFrame info bar.
-- Inspired by GW2_UI classpower architecture.
-- =====================================

TomoMod_ResourceBars = TomoMod_ResourceBars or {}
local RB = TomoMod_ResourceBars

local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

-- =====================================
-- POWER TYPE CONSTANTS (Enum.PowerType)
-- =====================================
local POWER_MANA           = 0
local POWER_COMBO_POINTS   = 4
local POWER_RUNES          = 5
local POWER_SOUL_SHARDS    = 7
local POWER_HOLY_POWER     = 9
local POWER_CHI            = 12
local POWER_ARCANE_CHARGES = 16
local POWER_ESSENCE        = 19

-- =====================================
-- CLASS POWER TEXTURES (GW2_UI-inspired)
-- =====================================
local TEX_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\ClassPower\\"
local CP_TEXTURES = {
    comboPoints   = { fill = TEX_PATH .. "combopoints",    flash = TEX_PATH .. "combo-flash" },
    holyPower     = { fill = TEX_PATH .. "holypower",      flash = TEX_PATH .. "holypower-flare" },
    soulShards    = { fill = TEX_PATH .. "soulshard",       flash = TEX_PATH .. "soulshardflare",
                      fragBg = TEX_PATH .. "soulshardfragmentbarbg", fragFill = TEX_PATH .. "soulshardfragmentbarfill" },
    chi           = { fill = TEX_PATH .. "chi",             flash = TEX_PATH .. "chi-flare" },
    essence       = { fill = TEX_PATH .. "evoker" },
    arcaneCharges = { fill = TEX_PATH .. "arcane",          flash = TEX_PATH .. "arcane-flash" },
    runes         = { frost = TEX_PATH .. "runes",          blood = TEX_PATH .. "runes-blood",
                      unholy = TEX_PATH .. "runes-unholy",  flash = TEX_PATH .. "runeflash" },
    maelstromWeapon = { fill = TEX_PATH .. "enchantmentbars" },
    stagger       = { bg   = TEX_PATH .. "monk\\stagger-bg",
                      low  = TEX_PATH .. "monk\\stagger-yellow",
                      med  = TEX_PATH .. "monk\\stagger-blue",
                      high = TEX_PATH .. "monk\\stagger-red" },
}

-- =====================================
-- ICON TEXCOORDS (per-point spritesheets)
-- =====================================
local ICON_TEXCOORDS = {
    comboPoints = {
        empty   = {0, 0.5, 0.5, 0},
        filled  = {0.5, 1, 0.5, 0},
        charged = {0, 0.5, 0.5, 1},
    },
    soulShards = {
        empty  = {0.5, 1, 1, 0},
        filled = {0, 0.5, 1, 0},
    },
    runes = {
        empty  = {0, 0.5, 0, 1},
        filled = {0.5, 1, 0, 1},
    },
    essence = {
        empty  = {0.5, 1, 0, 1},
        filled = {0, 0.5, 0, 1},
    },
}

-- =====================================
-- BAND TEXCOORDS (row-based spritesheets: chi, holypower, arcane)
-- =====================================
local BAND_CONFIG = {
    chi = {
        texture    = CP_TEXTURES.chi.fill,
        multiplier = 0.111,          -- 9 rows
        bgRow      = function(max) return max + 2 end,
    },
    holyPower = {
        texture    = CP_TEXTURES.holyPower.fill,
        multiplier = 0.125,          -- 8 rows
        bgRow      = function(max) return max - 1 end,
        desaturateBg = true,         -- show all symbols greyed out, fill saturates them
    },
    arcaneCharges = {
        texture    = CP_TEXTURES.arcaneCharges.fill,
        multiplier = 0.125,          -- 8 rows
        bgRow      = function(max) return max - 1 end,
        desaturateBg = true,         -- show all symbols greyed out, fill saturates them
    },
}

-- =====================================
-- POWER TYPE → TEXTURE TYPE MAP
-- =====================================
local POWER_TEXTURE_TYPE = {
    [POWER_COMBO_POINTS]   = "comboPoints",
    [POWER_SOUL_SHARDS]    = "soulShards",
    [POWER_HOLY_POWER]     = "holyPower",
    [POWER_CHI]            = "chi",
    [POWER_ARCANE_CHARGES] = "arcaneCharges",
    [POWER_ESSENCE]        = "essence",
}

-- =====================================
-- STAGGER LEVEL DETECTION (via auras, avoids secret number math)
-- =====================================
local STAGGER_HEAVY  = 124273
local STAGGER_MEDIUM = 124274
local function GetStaggerLevel()
    if C_UnitAuras.GetPlayerAuraBySpellID(STAGGER_HEAVY) then return "high" end
    if C_UnitAuras.GetPlayerAuraBySpellID(STAGGER_MEDIUM) then return "med" end
    return "low"
end

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
-- CLASS / SPEC — CLASS POWER DEFINITIONS
-- Only class-specific resources (not shown in UnitFrame info bar)
-- =====================================
local CLASS_RESOURCES = {
    SHAMAN = {
        -- [1] Elemental: Maelstrom in UF info bar
        [2] = { -- Enhancement
            classPower = { display = "aura", spellID = 344179, label = "Maelstrom Weapon", maxStacks = 10 },
        },
        -- [3] Restoration: Mana in UF info bar
    },
    HUNTER = {
        -- [1] BM: Focus in UF info bar
        -- [2] MM: Focus in UF info bar
        [3] = { -- Survival
            classPower = { display = "aura", spellID = 260286, label = "Tip of the Spear", maxStacks = 3 },
        },
    },
    DEMONHUNTER = {
        -- [1] Havoc: Fury in UF info bar
        [2] = { -- Vengeance
            classPower = { display = "aura", spellID = 203981, label = "Soul Fragments", maxStacks = 6 },
        },
        [3] = { -- Devourer
            classPower = { display = "aura_bar", label = "Soul Fragments", colorKey = "soulFragments", spellIDs = { 1225789, 1227702 }, talentSpellID = 1247534, maxDefault = 50, maxWithTalent = 35 },
        },
    },
    DEATHKNIGHT = {
        [1] = { classPower = { display = "runes", label = "Runes" } },
        [2] = { classPower = { display = "runes", label = "Runes" } },
        [3] = { classPower = { display = "runes", label = "Runes" } },
    },
    WARLOCK = {
        [1] = { classPower = { display = "points", powerType = POWER_SOUL_SHARDS, label = "Soul Shards", maxPoints = 5, showPartial = true } },
        [2] = { classPower = { display = "points", powerType = POWER_SOUL_SHARDS, label = "Soul Shards", maxPoints = 5, showPartial = true } },
        [3] = { classPower = { display = "points", powerType = POWER_SOUL_SHARDS, label = "Soul Shards", maxPoints = 5, showPartial = true } },
    },
    DRUID = {
        [1] = { druidMana = true }, -- Balance: Astral Power in UF info bar
        [2] = { -- Feral
            classPower = { display = "points", powerType = POWER_COMBO_POINTS, label = "Combo Points", maxPoints = 5 },
            druidMana = true,
        },
        [3] = { druidMana = true }, -- Guardian: Rage in UF info bar
        -- [4] Restoration: Mana in UF info bar
    },
    EVOKER = {
        [1] = { classPower = { display = "points", powerType = POWER_ESSENCE, label = "Essence", maxPoints = 6 } },
        [2] = { classPower = { display = "points", powerType = POWER_ESSENCE, label = "Essence", maxPoints = 6 } },
        [3] = { classPower = { display = "points", powerType = POWER_ESSENCE, label = "Essence", maxPoints = 6 } },
    },
    -- WARRIOR: all specs — Rage in UF info bar, no class power
    MAGE = {
        [1] = { -- Arcane
            classPower = { display = "points", powerType = POWER_ARCANE_CHARGES, label = "Arcane Charges", maxPoints = 4 },
        },
        -- [2] Fire, [3] Frost: Mana in UF info bar
    },
    MONK = {
        [1] = { -- Brewmaster
            classPower = { display = "stagger", label = "Stagger" },
        },
        -- [2] Mistweaver: Mana in UF info bar
        [3] = { -- Windwalker
            classPower = { display = "points", powerType = POWER_CHI, label = "Chi", maxPoints = 6 },
        },
    },
    PALADIN = {
        [1] = { classPower = { display = "points", powerType = POWER_HOLY_POWER, label = "Holy Power", maxPoints = 5 } },
        [2] = { classPower = { display = "points", powerType = POWER_HOLY_POWER, label = "Holy Power", maxPoints = 5 } },
        [3] = { classPower = { display = "points", powerType = POWER_HOLY_POWER, label = "Holy Power", maxPoints = 5 } },
    },
    -- PRIEST: all specs — Mana/Insanity in UF info bar, no class power
    ROGUE = {
        [1] = { classPower = { display = "points", powerType = POWER_COMBO_POINTS, label = "Combo Points", maxPoints = 7 } },
        [2] = { classPower = { display = "points", powerType = POWER_COMBO_POINTS, label = "Combo Points", maxPoints = 7 } },
        [3] = { classPower = { display = "points", powerType = POWER_COMBO_POINTS, label = "Combo Points", maxPoints = 7 } },
    },
}

-- =====================================
-- POWER → COLOR KEY MAP (class powers only)
-- =====================================
local POWER_COLOR_KEYS = {
    [POWER_MANA]           = "mana",
    [POWER_COMBO_POINTS]   = "comboPoints",
    [POWER_RUNES]          = "runes",
    [POWER_SOUL_SHARDS]    = "soulShards",
    [POWER_HOLY_POWER]     = "holyPower",
    [POWER_CHI]            = "chi",
    [POWER_ARCANE_CHARGES] = "arcaneCharges",
    [POWER_ESSENCE]        = "essence",
}

-- =====================================
-- MODULE STATE
-- =====================================
local _, playerClass = UnitClass("player")
local mainFrame
local container
local classPowerFrame
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

local function UseTextures()
    local s = GetSettings()
    return s and s.displayMode == "icons"
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
-- CREATE: BAR DISPLAY (used for aura_bar class powers)
-- =====================================
local function CreateBarDisplay(parent, width, height)
    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE

    local bar = CreateFrame("StatusBar", "TomoMod_RB_AuraBar", parent)
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
-- CREATE: POINT DISPLAY (Combo, Soul Shards, Essence, auras)
-- Supports both icon textures and flat color bars
-- =====================================
local function CreatePointDisplay(parent, maxPoints, width, height, colorKey, texType)
    local frame = CreateFrame("Frame", "TomoMod_RB_Points", parent)
    frame:SetSize(width, height)

    local useTex = UseTextures() and texType and ICON_TEXCOORDS[texType]
    local tc = useTex and ICON_TEXCOORDS[texType]
    local texPath = useTex and CP_TEXTURES[texType] and CP_TEXTURES[texType].fill

    local spacing = useTex and 4 or 2
    local pw = useTex and height or (width - (maxPoints - 1) * spacing) / maxPoints
    local totalW = maxPoints * pw + (maxPoints - 1) * spacing
    local offsetX = useTex and math.max((width - totalW) / 2, 0) or 0

    frame.points = {}
    frame.maxPoints = maxPoints
    frame.colorKey = colorKey
    frame.useTextures = useTex and true or false

    for i = 1, maxPoints do
        local pt = CreateFrame("Frame", nil, frame)
        pt:SetSize(pw, height)
        pt:SetPoint("LEFT", frame, "LEFT", offsetX + (i - 1) * (pw + spacing), 0)

        local bg = pt:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        if useTex and texPath and tc then
            bg:SetTexture(texPath)
            bg:SetTexCoord(unpack(tc.empty))
        else
            bg:SetColorTexture(0.06, 0.06, 0.08, 0.8)
        end
        pt.bg = bg

        local fill = pt:CreateTexture(nil, "ARTWORK")
        fill:SetAllPoints()
        if useTex and texPath and tc then
            fill:SetTexture(texPath)
            fill:SetTexCoord(unpack(tc.filled))
        else
            fill:SetColorTexture(GetColor(colorKey))
        end
        fill:Hide()
        pt.fill = fill

        -- Partial fill (for Soul Shards)
        local partial = pt:CreateTexture(nil, "ARTWORK")
        partial:SetPoint("BOTTOMLEFT"); partial:SetPoint("TOPLEFT")
        partial:SetWidth(0)
        if useTex and texPath and tc then
            partial:SetTexture(texPath)
            partial:SetTexCoord(unpack(tc.filled))
        else
            partial:SetColorTexture(GetColor(colorKey))
        end
        partial:SetAlpha(0.5)
        partial:Hide()
        pt.partial = partial

        if not useTex then CreateBorder(pt) end
        frame.points[i] = pt
    end

    return frame
end

-- =====================================
-- CREATE: BAND DISPLAY (Chi, Holy Power, Arcane — row-based spritesheet)
-- =====================================
local function CreateBandDisplay(parent, width, height, texType)
    local frame = CreateFrame("Frame", "TomoMod_RB_Band", parent)
    frame:SetSize(width, height)
    frame.texType = texType
    frame.isBand = true

    local cfg = BAND_CONFIG[texType]
    if not cfg then return frame end

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(cfg.texture)
    if cfg.desaturateBg then
        bg:SetDesaturated(true)
        bg:SetAlpha(0.5)
    end
    frame.bg = bg

    local fill = frame:CreateTexture(nil, "ARTWORK")
    fill:SetAllPoints()
    fill:SetTexture(cfg.texture)
    fill:Hide()
    frame.fill = fill

    return frame
end

-- =====================================
-- CREATE: RUNE DISPLAY (DK: 6 runes with cooldown)
-- =====================================
local function CreateRuneDisplay(parent, width, height)
    local frame = CreateFrame("Frame", "TomoMod_RB_Runes", parent)
    frame:SetSize(width, height)

    local useTex = UseTextures()
    local tc = useTex and ICON_TEXCOORDS.runes
    local texPath = useTex and CP_TEXTURES.runes.frost

    local spacing = useTex and 4 or 2
    local rw = useTex and height or (width - 5 * spacing) / 6
    local totalW = 6 * rw + 5 * spacing
    local offsetX = useTex and math.max((width - totalW) / 2, 0) or 0
    frame.runes = {}
    frame.useTextures = useTex and true or false

    if useTex and tc and texPath then
        -- Icon mode: per-rune frames with texture + height-based fill
        for i = 1, 6 do
            local runeF = CreateFrame("Frame", nil, frame)
            runeF:SetSize(rw, height)
            runeF:SetPoint("LEFT", frame, "LEFT", offsetX + (i - 1) * (rw + spacing), 0)

            local bg = runeF:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(texPath)
            bg:SetTexCoord(unpack(tc.empty))
            runeF.bg = bg

            local fill = runeF:CreateTexture(nil, "ARTWORK")
            fill:SetPoint("BOTTOMLEFT")
            fill:SetPoint("BOTTOMRIGHT")
            fill:SetHeight(height)
            fill:SetTexture(texPath)
            fill:SetTexCoord(unpack(tc.filled))
            runeF.fill = fill

            local cd = runeF:CreateFontString(nil, "OVERLAY")
            cd:SetFont(GetFont(), math.max(GetFontSize() - 2, 7), "OUTLINE")
            cd:SetPoint("CENTER"); cd:SetTextColor(1, 1, 1, 0.8)
            runeF.cdText = cd

            frame.runes[i] = runeF
        end
    else
        -- Bar mode: StatusBar per rune
        local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE
        for i = 1, 6 do
            local rune = CreateFrame("StatusBar", nil, frame)
            rune:SetSize(rw, height)
            rune:SetPoint("LEFT", frame, "LEFT", (i - 1) * (rw + spacing), 0)
            rune:SetStatusBarTexture(tex)
            rune:GetStatusBarTexture():SetHorizTile(false)
            rune:SetMinMaxValues(0, 1); rune:SetValue(1)

            local bg = rune:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.06, 0.06, 0.08, 0.8)
            rune.bg = bg

            local cd = rune:CreateFontString(nil, "OVERLAY")
            cd:SetFont(GetFont(), math.max(GetFontSize() - 2, 7), "OUTLINE")
            cd:SetPoint("CENTER"); cd:SetTextColor(1, 1, 1, 0.8)
            rune.cdText = cd

            CreateBorder(rune)
            frame.runes[i] = rune
        end
    end

    return frame
end

-- =====================================
-- CREATE: STAGGER BAR (Monk Brewmaster)
-- =====================================
local function CreateStaggerBar(parent, width, height)
    local useTex = UseTextures()
    local staggerTex = useTex and CP_TEXTURES.stagger
    local barTex = (staggerTex and staggerTex.low) or (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE
    local bgTex  = (staggerTex and staggerTex.bg)  or barTex

    local bar = CreateFrame("StatusBar", "TomoMod_RB_Stagger", parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(barTex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(0)
    bar.useTextures = useTex and true or false

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetTexture(bgTex)
    if not useTex then bg:SetVertexColor(0.06, 0.06, 0.08, 0.8) end
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
-- (Primary bar update removed — main power is in UnitFrame info bar)
-- =====================================

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
        if max == 0 then max = 1 end
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

    local useTex = pointFrame.useTextures
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
                if not useTex then pt.fill:SetColorTexture(r, g, b) end
                pt.fill:Show()
                pt.partial:Hide()
            elseif i == current + 1 and partialFrac > 0 then
                pt.fill:Hide()
                if not useTex then pt.partial:SetColorTexture(r, g, b) end
                pt.partial:SetWidth(math.max(pt:GetWidth() * partialFrac, 1))
                pt.partial:Show()
            else
                pt.fill:Hide(); pt.partial:Hide()
            end
        end
    end
end

-- =====================================
-- UPDATE: BAND DISPLAY (Chi, Holy Power, Arcane)
-- =====================================
local function UpdateBandDisplay(bandFrame, resDef)
    if not bandFrame or not bandFrame.fill then return end

    local texType = bandFrame.texType
    local cfg = BAND_CONFIG[texType]
    if not cfg then return end

    local current = UnitPower("player", resDef.powerType)
    local max = UnitPowerMax("player", resDef.powerType)
    if max == 0 then max = 1 end

    local m = cfg.multiplier

    -- Background: empty state showing full capacity
    local bgRow = cfg.bgRow(max)
    bandFrame.bg:SetTexCoord(0, 1, m * bgRow, m * (bgRow + 1))

    -- Fill: current count
    if current > 0 then
        local fillRow = current - 1
        bandFrame.fill:SetTexCoord(0, 1, m * fillRow, m * (fillRow + 1))
        bandFrame.fill:Show()
    else
        bandFrame.fill:Hide()
    end
end

-- =====================================
-- UPDATE: RUNES (DK)
-- =====================================
local function UpdateRunes(runeFrame)
    if not runeFrame or not runeFrame.runes then return end
    local now = GetTime()
    local useTex = runeFrame.useTextures

    if useTex then
        -- Icon mode: height-based fill animation
        for i = 1, 6 do
            local rune = runeFrame.runes[i]
            if rune and rune.fill then
                local start, duration, runeReady = GetRuneCooldown(i)
                local maxH = rune:GetHeight()
                if runeReady then
                    rune.fill:SetTexCoord(0.5, 1, 0, 1)
                    rune.fill:SetHeight(maxH)
                    rune.fill:SetAlpha(1)
                    rune.cdText:SetText("")
                else
                    local elapsed = now - start
                    local progress = math.min(elapsed / duration, 1)
                    rune.fill:SetTexCoord(0.5, 1, 1 - progress, 1)
                    rune.fill:SetHeight(math.max(maxH * progress, 0.1))
                    rune.fill:SetAlpha(0.7)
                    local remaining = duration - elapsed
                    if remaining > 0 then
                        rune.cdText:SetFormattedText("%.1f", remaining)
                    else
                        rune.cdText:SetText("")
                    end
                end
            end
        end
    else
        -- Bar mode: StatusBar fill
        local rR, gR, bR = GetColor("runesReady")
        local rC, gC, bC = GetColor("runes")
        for i = 1, 6 do
            local rune = runeFrame.runes[i]
            if rune then
                local start, duration, runeReady = GetRuneCooldown(i)
                if not start or not duration then
                    rune:SetValue(1)
                    rune:SetStatusBarColor(rC, gC, bC, 0.6)
                    rune.cdText:SetText("")
                elseif runeReady then
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

    if bar.useTextures then
        -- Swap texture by stagger level (light/moderate/heavy)
        local level = GetStaggerLevel()
        local stTex = CP_TEXTURES.stagger
        if level == "high" then
            bar:SetStatusBarTexture(stTex.high)
        elseif level == "med" then
            bar:SetStatusBarTexture(stTex.med)
        else
            bar:SetStatusBarTexture(stTex.low)
        end
        bar:GetStatusBarTexture():SetHorizTile(false)
    else
        local r, g, b = GetColor("stagger")
        bar:SetStatusBarColor(r, g, b, 1)
    end

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
    if max == 0 then max = 1 end
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
-- (Druid adaptive primary removed — power is in UnitFrame info bar)
-- =====================================

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
-- BUILD/REBUILD CLASS POWER DISPLAY
-- =====================================
local function BuildResourceDisplay()
    local s = GetSettings()
    if not s or not s.enabled then return end

    local specIndex = GetSpecialization()
    if not specIndex or specIndex == 0 then return end

    local classData = CLASS_RESOURCES[playerClass]
    local resources = classData and classData[specIndex]

    -- Specs with no class power at all (e.g. Warrior, Hunter BM/MM, Priest, etc.)
    currentResources = resources
    currentSpec = specIndex

    local width = s.width or 260
    local cpH = s.primaryHeight or 16     -- height for class power display
    local dmH = s.secondaryHeight or 12   -- height for druid mana bar
    local gap = 2

    -- Clear old
    if classPowerFrame then classPowerFrame:Hide(); classPowerFrame = nil end
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
    local hasContent = false

    -- === CLASS POWER ===
    if resources and resources.classPower then
        local cpDef = resources.classPower
        if cpDef.display == "points" then
            local ck = POWER_COLOR_KEYS[cpDef.powerType] or "comboPoints"
            local texType = POWER_TEXTURE_TYPE[cpDef.powerType]
            -- Band textures (chi, holypower, arcane) use a single wide spritesheet
            if UseTextures() and texType and BAND_CONFIG[texType] then
                classPowerFrame = CreateBandDisplay(container, width, cpH, texType)
            else
                classPowerFrame = CreatePointDisplay(container, cpDef.maxPoints or 5, width, cpH, ck, texType)
            end
        elseif cpDef.display == "runes" then
            classPowerFrame = CreateRuneDisplay(container, width, cpH)
        elseif cpDef.display == "stagger" then
            classPowerFrame = CreateStaggerBar(container, width, cpH)
        elseif cpDef.display == "aura" then
            local ck = GetAuraColorKey(cpDef.label)
            classPowerFrame = CreatePointDisplay(container, cpDef.maxStacks or 5, width, cpH, ck, nil)
        elseif cpDef.display == "aura_bar" then
            classPowerFrame = CreateBarDisplay(container, width, cpH)
        end

        if classPowerFrame then
            classPowerFrame:ClearAllPoints()
            classPowerFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
            nextY = nextY + cpH + gap
            totalH = totalH + cpH + gap
            hasContent = true
        end
    end

    -- === DRUID MANA BAR ===
    if resources and resources.druidMana then
        druidManaBar = CreateDruidManaBar(container, width, dmH)
        druidManaBar:ClearAllPoints()
        druidManaBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
        nextY = nextY + dmH + gap
        totalH = totalH + dmH + gap
        hasContent = true
    end

    if hasContent then
        container:SetSize(width, math.max(totalH, 1))
        container:Show()
    else
        container:SetSize(width, 1)
        container:Hide()
    end
end

-- =====================================
-- MASTER UPDATE
-- =====================================
local function UpdateAll()
    if not container or not container:IsShown() then return end
    if not currentResources then return end

    local resources = currentResources

    -- Class Power
    if classPowerFrame and resources.classPower then
        local cpDef = resources.classPower
        if classPowerFrame.isBand then
            UpdateBandDisplay(classPowerFrame, cpDef)
        elseif cpDef.display == "points" or cpDef.display == "aura" then
            UpdatePoints(classPowerFrame, cpDef)
        elseif cpDef.display == "aura_bar" then
            local cur, max = GetAuraBarValues(cpDef)
            classPowerFrame:SetMinMaxValues(0, max)
            classPowerFrame:SetValue(cur)
            local ck = cpDef.colorKey or "soulFragments"
            local r, g, b = GetColor(ck)
            classPowerFrame:SetStatusBarColor(r, g, b, 1)
            local s = GetSettings()
            if s and s.showText and classPowerFrame.text then
                classPowerFrame.text:SetFormattedText("%d / %d", cur, max)
            elseif classPowerFrame.text then
                classPowerFrame.text:SetText("")
            end
        elseif cpDef.display == "runes" then
            UpdateRunes(classPowerFrame)
        elseif cpDef.display == "stagger" then
            UpdateStagger(classPowerFrame)
        end
    end

    -- Druid Mana
    if druidManaBar then UpdateDruidMana() end
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
        if classPowerFrame and currentResources and currentResources.classPower
           and currentResources.classPower.display == "runes" then
            UpdateRunes(classPowerFrame)
        end
    elseif event == "UNIT_AURA" then
        if arg1 == "player" then UpdateAll() end
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        if playerClass == "DRUID" then UpdateDruidMana() end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_TARGET_CHANGED" then
        UpdateAlpha()
    elseif event == "UNIT_HEALTH" then
        if arg1 == "player" and classPowerFrame and currentResources
           and currentResources.classPower and currentResources.classPower.display == "stagger" then
            UpdateStagger(classPowerFrame)
        end
    end
end

-- OnUpdate only needed for smooth rune CDs (DK) — all other resources use events
local updateTimer = 0
local function OnUpdate(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.05 then
        updateTimer = 0
        -- [PERF] Only update runes/stagger here; other resources are event-driven
        if classPowerFrame and currentResources and currentResources.classPower then
            local d = currentResources.classPower.display
            if d == "runes" then
                UpdateRunes(classPowerFrame)
            elseif d == "stagger" then
                UpdateStagger(classPowerFrame)
            end
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
        if currentResources and currentResources.classPower then
            local d = currentResources.classPower.display
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

function RB.IsLocked()
    if not container then return true end
    if container.IsLocked then return container:IsLocked() end
    return true
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
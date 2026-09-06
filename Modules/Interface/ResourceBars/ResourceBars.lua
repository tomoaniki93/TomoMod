-- =====================================
-- ResourceBars.lua v3.0 — Class Power Display System
-- Displays class-specific resources: combo points, holy power,
-- soul shards, chi, essence, arcane charges, runes, stagger, etc.
-- Primary power (mana/rage/energy/etc.) is shown in UnitFrame info bar.
-- Inspired by GW2_UI classpower architecture.
-- v2.8 :
--   * Barre de vie HUD optionnelle (class color, texte valeur/%, seuil de
--     couleur) — pattern Midnight-safe : UnitHealthPercent + ColorCurve
--     évaluées côté C, jamais d'arithmétique Lua sur les secretvalues.
--   * Animations fluides (lerp) sur les barres — valeurs non secrètes
--     uniquement, sinon SetValue direct.
--   * Ticks (marques) sur la barre de puissance centrée, en % du max.
--   * Seuil de couleur « ressource basse » sur la barre de puissance.
-- =====================================

TomoMod_ResourceBars = TomoMod_ResourceBars or {}
local RB = TomoMod_ResourceBars
local Glow = TomoMod_NativeGlow  -- optional full-state glow

local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
-- Flat 1x1 fill. The shared bar texture (tomoaniki) bakes in a vertical
-- gradient, which reads as a gloss highlight on tall bars but just muddies
-- the six small DK rune segments -- they want a solid block of colour.
local TEXTURE_FLAT = "Interface\\Buttons\\WHITE8X8"
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
        -- Bottom-left sprite of the atlas: the spiked diamond used for
        -- supercharged points. Written but never wired until now, and the V
        -- axis was the wrong way round -- empty/filled are both flipped
        -- (ULy > LRy) and this one was not, so the sprite came out upside
        -- down relative to its neighbours.
        charged = {0, 0.5, 1, 0.5},
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
        [3] = { druidMana = true, primaryPower = true }, -- Guardian: Rage centered, mana secondary
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
        -- [2] Fire: Mana in UF info bar
        [3] = { -- Frost
            classPower = { display = "aura", spellID = 205473, label = "Icicles", maxStacks = 5, glowOnMax = true },
        },
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
local primaryPowerBar
local healthBar
local currentResources
local currentSpec = 0
local isInitialized = false

-- v2.8 : smoothing (barres enregistrées pour l'animation lerp)
local smoothFrames = {}
local BAR_SMOOTH_SPEED = 12
local issecret = issecretvalue or function() return false end

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
-- v3.0 : DEDICATED VISUAL LAYER
-- ResourceBars no longer has to inherit its continuous-bar texture from
-- UnitFrames. Rebuilds are cheap configuration-time operations, so these
-- values are read when widgets are created rather than cached on the event path.
-- =====================================
local function GetStyle(styleKey)
    local s = GetSettings()
    local st = s and s.styles and s.styles[styleKey]
    if st then return st end
    -- Smooth migration for profiles created before V3.1.
    return s or {}
end

local function GetBarTexture(styleKey)
    local s = GetSettings()
    local st = GetStyle(styleKey)
    local key = st.barTexture or (s and s.barTexture) or "tomo"
    if key == "flat" then return TEXTURE_FLAT end
    if key == "blizzard" then return "Interface\\TargetingFrame\\UI-StatusBar" end
    return TEXTURE
end

local function GetBackgroundAlpha(styleKey)
    local s = GetSettings()
    local st = GetStyle(styleKey)
    return tonumber(st.backgroundAlpha or (s and s.backgroundAlpha)) or 0.80
end

local function GetClassConfig()
    local s = GetSettings()
    return s and s.classResource or {}
end

local function GetClassOrientation()
    local cfg = GetClassConfig()
    return cfg.orientation == "VERTICAL" and "VERTICAL" or "HORIZONTAL"
end

local function GetSegmentSpacing()
    local s = GetSettings()
    return math.max(0, (s and tonumber(s.segmentSpacing)) or 2)
end

local function StyleBarBackground(bg, tex, styleKey)
    if not bg then return end
    bg:SetTexture(tex)
    bg:SetVertexColor(0.06, 0.06, 0.08, GetBackgroundAlpha(styleKey))
end

local function SetEmptyPointBackground(tex)
    if not tex then return end
    local cfg = GetClassConfig()
    local c = cfg.emptyColor or { r = 0.06, g = 0.06, b = 0.08 }
    tex:SetColorTexture(c.r or 0.06, c.g or 0.06, c.b or 0.08, GetBackgroundAlpha("class"))
end

local function ClassUsesSegmentBorders()
    local mode = GetClassConfig().borderMode or "segments"
    return mode == "segments" or mode == "both"
end

local function ClassUsesOuterBorder()
    local mode = GetClassConfig().borderMode or "segments"
    return mode == "outer" or mode == "both"
end

local function ResolveClassThreshold(current, maxValue, baseR, baseG, baseB)
    local s = GetSettings()
    local cfg = s and s.thresholds and s.thresholds.class
    local textR, textG, textB = 1, 1, 1
    if not (cfg and cfg.enabled) or issecret(current) or issecret(maxValue)
       or not maxValue or maxValue <= 0 then
        return baseR, baseG, baseB, textR, textG, textB, false
    end

    local metric = current
    if cfg.mode ~= "value" then metric = current / maxValue * 100 end

    local c
    if metric <= (tonumber(cfg.low) or 30) then
        c = cfg.lowColor
    elseif metric >= (tonumber(cfg.high) or 80) then
        c = cfg.highColor
    end
    if not c then
        return baseR, baseG, baseB, textR, textG, textB, false
    end

    local target = cfg.target or "both"
    local r, g, b = c.r or baseR, c.g or baseG, c.b or baseB
    local barR, barG, barB = baseR, baseG, baseB
    if target == "bar" or target == "both" then barR, barG, barB = r, g, b end
    if target == "text" or target == "both" then textR, textG, textB = r, g, b end
    return barR, barG, barB, textR, textG, textB, true
end

local function ParseHashValues(str)
    if not str or str == "" then return nil end
    local vals = {}
    for token in string.gmatch(str, "[%d%.]+") do
        local n = tonumber(token)
        if n and n >= 0 then vals[#vals + 1] = n end
    end
    return #vals > 0 and vals or nil
end

local function ApplyAdvancedHashLines(bar, cfg, maxValue, orientation)
    if not bar then return end
    bar._rbHashLines = bar._rbHashLines or {}
    for i = 1, #bar._rbHashLines do bar._rbHashLines[i]:Hide() end
    if not (cfg and cfg.enabled) then return end

    local vals = ParseHashValues(cfg.values)
    if not vals then return end

    local mode = cfg.mode or "percent"
    if mode == "value" and (issecret(maxValue) or not maxValue or maxValue <= 0) then return end
    orientation = orientation or "HORIZONTAL"

    local c = cfg.color or { r = 1, g = 1, b = 1, a = 0.75 }
    local thickness = math.max(1, math.min(5, tonumber(cfg.width) or 1))
    local width, height = bar:GetWidth(), bar:GetHeight()
    local maxSig = issecret(maxValue) and "secret" or tostring(maxValue)
    local signature = table.concat({
        tostring(cfg.values), mode, tostring(thickness),
        string.format("%.3f,%.3f,%.3f,%.3f", c.r or 1, c.g or 1, c.b or 1, c.a or 0.75),
        orientation, tostring(width), tostring(height), maxSig
    }, "|")
    if bar._rbHashSignature == signature then
        for i = 1, #vals do
            if bar._rbHashLines[i] then bar._rbHashLines[i]:Show() end
        end
        return
    end
    bar._rbHashSignature = signature

    for i, value in ipairs(vals) do
        local pct = mode == "value" and (value / maxValue * 100) or value
        if pct > 0 and pct < 100 then
            local t = bar._rbHashLines[i]
            if not t then
                t = bar:CreateTexture(nil, "OVERLAY", nil, 6)
                bar._rbHashLines[i] = t
            end
            t:ClearAllPoints()
            t:SetColorTexture(c.r or 1, c.g or 1, c.b or 1, c.a or 0.75)
            if orientation == "VERTICAL" then
                local y = height * (pct / 100)
                t:SetHeight(thickness)
                t:SetPoint("LEFT", bar, "BOTTOMLEFT", 0, y)
                t:SetPoint("RIGHT", bar, "BOTTOMRIGHT", 0, y)
            else
                t:SetWidth(thickness)
                t:SetPoint("TOP")
                t:SetPoint("BOTTOM")
                t:SetPoint("LEFT", bar, "LEFT", width * (pct / 100), 0)
            end
            t:Show()
        end
    end
end

-- =====================================
-- v2.8 : SMOOTHING (lerp — valeurs non secrètes uniquement)
-- =====================================
local function SetBarValueSmooth(bar, value)
    local s = GetSettings()
    if not (s and s.smoothBars) or issecret(value) then
        bar._smoothCur, bar._smoothTarget = nil, nil
        smoothFrames[bar] = nil
        bar:SetValue(value)
        return
    end
    bar._smoothTarget = value
    if bar._smoothCur == nil then
        bar._smoothCur = value
        bar:SetValue(value)
        return
    end
    smoothFrames[bar] = true
end

local function SmoothStep(elapsed)
    local k = math.min(elapsed * BAR_SMOOTH_SPEED, 1)
    for bar in pairs(smoothFrames) do
        local tgt = bar._smoothTarget
        if not tgt or not bar:IsShown() then
            smoothFrames[bar] = nil
        else
            local cur = bar._smoothCur or tgt
            local diff = tgt - cur
            if diff > -0.5 and diff < 0.5 then
                bar._smoothCur = tgt
                bar:SetValue(tgt)
                smoothFrames[bar] = nil
            else
                cur = cur + diff * k
                bar._smoothCur = cur
                bar:SetValue(cur)
            end
        end
    end
end

-- =====================================
-- v2.8 : COLOR CURVE DE SEUIL
-- =====================================
local _thresholdCurve, _thresholdCurveHash
local function GetThresholdColorCurve(baseR, baseG, baseB, threshR, threshG, threshB, threshPct)
    if not C_CurveUtil or not C_CurveUtil.CreateColorCurve then return nil end

    local hash = string.format("%.3f,%.3f,%.3f|%.3f,%.3f,%.3f|%.1f",
        baseR, baseG, baseB, threshR, threshG, threshB, threshPct)
    if _thresholdCurveHash == hash then return _thresholdCurve end

    local curve = C_CurveUtil.CreateColorCurve()
    local t = math.max(0, math.min(1, threshPct / 100))
    local EPSILON = 0.0001

    -- Sous le seuil → couleur d'alerte ; au-dessus → couleur de base
    curve:AddPoint(0.0, CreateColor(threshR, threshG, threshB, 1))
    if t > EPSILON then
        curve:AddPoint(t, CreateColor(threshR, threshG, threshB, 1))
    end
    if t < 1.0 then
        curve:AddPoint(math.min(1.0, t + EPSILON), CreateColor(baseR, baseG, baseB, 1))
    end
    curve:AddPoint(1.0, CreateColor(baseR, baseG, baseB, 1))

    _thresholdCurve = curve
    _thresholdCurveHash = hash
    return curve
end

-- =====================================
-- v2.8 : TICKS (marques verticales sur une barre, positions en % du max
-- → aucune dépendance à la valeur max, zéro souci secretvalue)
-- =====================================
local function ParseTickPercents(str)
    if not str or str == "" then return nil end
    local vals = {}
    for token in string.gmatch(str, "[%d%.]+") do
        local n = tonumber(token)
        if n and n > 0 and n < 100 then vals[#vals + 1] = n end
    end
    if #vals == 0 then return nil end
    return vals
end

local function ApplyBarTicks(bar, tickStr)
    if not bar then return end
    -- Cache : UNIT_POWER_FREQUENT spamme (énergie) — ne re-layout que si
    -- la config ou la largeur de barre a changé.
    local w = bar:GetWidth()
    if bar._tickStr == tickStr and bar._tickW == w then return end
    bar._tickStr, bar._tickW = tickStr, w

    bar._ticks = bar._ticks or {}
    for i = 1, #bar._ticks do bar._ticks[i]:Hide() end

    local vals = ParseTickPercents(tickStr)
    if not vals then return end

    while #bar._ticks < #vals do
        local t = bar:CreateTexture(nil, "OVERLAY", nil, 6)
        t:SetColorTexture(1, 1, 1, 0.75)
        bar._ticks[#bar._ticks + 1] = t
    end

    local barW = bar:GetWidth()
    local barH = bar:GetHeight()
    if not barW or barW <= 0 then return end
    for i, pct in ipairs(vals) do
        local t = bar._ticks[i]
        t:ClearAllPoints()
        t:SetSize(1, barH)
        t:SetPoint("LEFT", bar, "LEFT", barW * (pct / 100), 0)
        t:Show()
    end
end

-- =====================================
-- BORDER (mirrors UF_Elements.CreateBorder)
-- =====================================
local function CreateBorder(frame, styleKey, enabledForElement)
    local s = GetSettings()
    local st = GetStyle(styleKey)
    local enabled = st.borderEnabled
    if enabled == nil then enabled = not (s and s.borderEnabled == false) end
    if enabled == false or enabledForElement == false then return end

    local size = math.max(1, math.min(4,
        tonumber(st.borderSize or (s and s.borderSize)) or 1))
    local c = st.borderColor or (s and s.borderColor) or nil
    local r, g, b = c and c.r or 0, c and c.g or 0, c and c.b or 0

    local function Edge(p1, p2, w, h)
        local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(r, g, b, 1)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, size)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, size)
    Edge("TOPLEFT", "BOTTOMLEFT", size, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", size, nil)
end

-- =====================================
-- CREATE: BAR DISPLAY (used for aura_bar class powers)
-- =====================================
local function CreateBarDisplay(parent, width, height)
    local tex = GetBarTexture("class")
    local orientation = GetClassOrientation()

    local bar = CreateFrame("StatusBar", nil, parent)
    if orientation == "VERTICAL" then
        bar:SetSize(height, width)
        bar:SetOrientation("VERTICAL")
        bar._resourceOrientation = "VERTICAL"
        bar._layerHeight = width
    else
        bar:SetSize(width, height)
        bar:SetOrientation("HORIZONTAL")
        bar._resourceOrientation = "HORIZONTAL"
        bar._layerHeight = height
    end
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    StyleBarBackground(bg, tex, "class")
    bar.bg = bg
    CreateBorder(bar, "class", (GetClassConfig().borderMode or "segments") ~= "none")

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(GetFont(), GetFontSize(), "OUTLINE")
    text:SetTextColor(1, 1, 1, 0.9)
    bar.text = text

    local align = GetTextAlignment()
    if align == "LEFT" and orientation ~= "VERTICAL" then
        text:SetPoint("LEFT", 4, 0); text:SetJustifyH("LEFT")
    elseif align == "RIGHT" and orientation ~= "VERTICAL" then
        text:SetPoint("RIGHT", -4, 0); text:SetJustifyH("RIGHT")
    else
        text:SetPoint("CENTER"); text:SetJustifyH("CENTER")
    end

    return bar
end

local function CreateCountResourceBar(parent, width, height, colorKey)
    local bar = CreateBarDisplay(parent, width, height)
    bar.isCountResource = true
    bar.colorKey = colorKey
    return bar
end

-- =====================================
-- CREATE: POINT DISPLAY (Combo, Soul Shards, Essence, auras)
-- Supports both icon textures and flat color bars
-- =====================================
-- Flat-mode empty slot fill is styled through SetEmptyPointBackground so
-- opacity changes apply to both fresh and restored combo-point slots.
local function CreatePointDisplay(parent, maxPoints, width, height, colorKey, texType)
    local frame = CreateFrame("Frame", nil, parent)
    local orientation = GetClassOrientation()
    if orientation == "VERTICAL" then
        frame:SetSize(height, width)
        frame._layerHeight = width
    else
        frame:SetSize(width, height)
        frame._layerHeight = height
    end
    frame._resourceOrientation = orientation

    local useTex = UseTextures() and texType and ICON_TEXCOORDS[texType]
    local tc = useTex and ICON_TEXCOORDS[texType]
    local texPath = useTex and CP_TEXTURES[texType] and CP_TEXTURES[texType].fill

    local spacing = GetSegmentSpacing()
    local length = width
    local extent = useTex and height or (length - (maxPoints - 1) * spacing) / maxPoints
    local totalExtent = maxPoints * extent + (maxPoints - 1) * spacing
    local offset = useTex and math.max((length - totalExtent) / 2, 0) or 0

    frame.points = {}
    frame.maxPoints = maxPoints
    frame.colorKey = colorKey
    frame.useTextures = useTex and true or false

    for i = 1, maxPoints do
        local pt = CreateFrame("Frame", nil, frame)
        if orientation == "VERTICAL" then
            pt:SetSize(height, extent)
            pt:SetPoint("BOTTOM", frame, "BOTTOM", 0, offset + (i - 1) * (extent + spacing))
        else
            pt:SetSize(extent, height)
            pt:SetPoint("LEFT", frame, "LEFT", offset + (i - 1) * (extent + spacing), 0)
        end

        local bg = pt:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        if useTex and texPath and tc then
            bg:SetTexture(texPath)
            bg:SetTexCoord(unpack(tc.empty))
            bg:SetAlpha(GetBackgroundAlpha("class"))
        else
            SetEmptyPointBackground(bg)
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

        local partial = pt:CreateTexture(nil, "ARTWORK")
        if orientation == "VERTICAL" then
            partial:SetPoint("BOTTOMLEFT"); partial:SetPoint("BOTTOMRIGHT")
            partial:SetHeight(0)
        else
            partial:SetPoint("BOTTOMLEFT"); partial:SetPoint("TOPLEFT")
            partial:SetWidth(0)
        end
        if useTex and texPath and tc then
            partial:SetTexture(texPath)
            partial:SetTexCoord(unpack(tc.filled))
        else
            partial:SetColorTexture(GetColor(colorKey))
        end
        partial:SetAlpha(0.60)
        partial:Hide()
        pt.partial = partial

        CreateBorder(pt, "class", ClassUsesSegmentBorders())
        frame.points[i] = pt
    end

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont(GetFont(), GetFontSize(), "OUTLINE")
    text:SetPoint("CENTER")
    text:SetTextColor(1, 1, 1, 0.90)
    frame.text = text

    CreateBorder(frame, "class", ClassUsesOuterBorder())
    return frame
end

-- =====================================
-- CREATE: BAND DISPLAY (Chi, Holy Power, Arcane — row-based spritesheet)
-- =====================================
local function CreateBandDisplay(parent, width, height, texType)
    local frame = CreateFrame("Frame", nil, parent)
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
    end
    bg:SetAlpha(GetBackgroundAlpha("class"))
    frame.bg = bg

    local fill = frame:CreateTexture(nil, "ARTWORK")
    fill:SetAllPoints()
    fill:SetTexture(cfg.texture)
    fill:Hide()
    frame.fill = fill
    CreateBorder(frame, "class", (GetClassConfig().borderMode or "segments") ~= "none")

    return frame
end

-- =====================================
-- CREATE: RUNE DISPLAY (DK: 6 runes with cooldown)
-- =====================================
local function CreateRuneDisplay(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    local orientation = GetClassOrientation()
    if orientation == "VERTICAL" then
        frame:SetSize(height, width)
        frame._layerHeight = width
    else
        frame:SetSize(width, height)
        frame._layerHeight = height
    end
    frame._resourceOrientation = orientation

    local useTex = UseTextures()
    local tc = useTex and ICON_TEXCOORDS.runes
    local texPath = useTex and CP_TEXTURES.runes.frost

    local spacing = GetSegmentSpacing()
    local extent = useTex and height or (width - 5 * spacing) / 6
    local totalExtent = 6 * extent + 5 * spacing
    local offset = useTex and math.max((width - totalExtent) / 2, 0) or 0
    frame.runes = {}
    frame.useTextures = useTex and true or false

    if useTex and tc and texPath then
        -- Icon mode: per-rune frames with texture + height-based fill
        for i = 1, 6 do
            local runeF = CreateFrame("Frame", nil, frame)
            if orientation == "VERTICAL" then
                runeF:SetSize(height, extent)
                runeF:SetPoint("BOTTOM", frame, "BOTTOM", 0, offset + (i - 1) * (extent + spacing))
            else
                runeF:SetSize(extent, height)
                runeF:SetPoint("LEFT", frame, "LEFT", offset + (i - 1) * (extent + spacing), 0)
            end

            local bg = runeF:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(texPath)
            bg:SetTexCoord(unpack(tc.empty))
            bg:SetAlpha(GetBackgroundAlpha("class"))
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
            CreateBorder(runeF, "class", ClassUsesSegmentBorders())

            frame.runes[i] = runeF
        end
    else
        -- Bar mode: StatusBar per rune, flat fill (no gradient)
        local tex = TEXTURE_FLAT
        for i = 1, 6 do
            local rune = CreateFrame("StatusBar", nil, frame)
            if orientation == "VERTICAL" then
                rune:SetSize(height, extent)
                rune:SetPoint("BOTTOM", frame, "BOTTOM", 0, (i - 1) * (extent + spacing))
                rune:SetOrientation("VERTICAL")
            else
                rune:SetSize(extent, height)
                rune:SetPoint("LEFT", frame, "LEFT", (i - 1) * (extent + spacing), 0)
                rune:SetOrientation("HORIZONTAL")
            end
            rune:SetStatusBarTexture(tex)
            rune:GetStatusBarTexture():SetHorizTile(false)
            rune:SetMinMaxValues(0, 1); rune:SetValue(1)

            local bg = rune:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            SetEmptyPointBackground(bg)
            rune.bg = bg

            local cd = rune:CreateFontString(nil, "OVERLAY")
            cd:SetFont(GetFont(), math.max(GetFontSize() - 2, 7), "OUTLINE")
            cd:SetPoint("CENTER"); cd:SetTextColor(1, 1, 1, 0.8)
            rune.cdText = cd

            CreateBorder(rune, "class", ClassUsesSegmentBorders())
            frame.runes[i] = rune
        end
    end

    CreateBorder(frame, "class", ClassUsesOuterBorder())
    return frame
end

-- =====================================
-- CREATE: STAGGER BAR (Monk Brewmaster)
-- =====================================
local function CreateStaggerBar(parent, width, height)
    local orientation = GetClassOrientation()
    local useTex = UseTextures() and orientation ~= "VERTICAL"
    local staggerTex = useTex and CP_TEXTURES.stagger
    local barTex = (staggerTex and staggerTex.low) or GetBarTexture("class")
    local bgTex  = (staggerTex and staggerTex.bg)  or barTex

    local bar = CreateFrame("StatusBar", nil, parent)
    if orientation == "VERTICAL" then
        bar:SetSize(height, width)
        bar:SetOrientation("VERTICAL")
        bar._layerHeight = width
    else
        bar:SetSize(width, height)
        bar:SetOrientation("HORIZONTAL")
        bar._layerHeight = height
    end
    bar._resourceOrientation = orientation
    bar:SetStatusBarTexture(barTex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(0)
    bar.useTextures = useTex and true or false

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetTexture(bgTex)
    if useTex then bg:SetAlpha(GetBackgroundAlpha("class"))
    else bg:SetVertexColor(0.06, 0.06, 0.08, GetBackgroundAlpha("class")) end
    bar.bg = bg
    CreateBorder(bar, "class", (GetClassConfig().borderMode or "segments") ~= "none")

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
    local tex = GetBarTexture("power")
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(100)

    local r, g, b = GetColor("mana")
    bar:SetStatusBarColor(r, g, b, 1)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    StyleBarBackground(bg, tex, "power")
    bar.bg = bg
    CreateBorder(bar, "power")

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(GetFont(), math.max(GetFontSize() - 1, 7), "OUTLINE")
    text:SetPoint("CENTER"); text:SetTextColor(1, 1, 1, 0.7)
    bar.text = text

    return bar
end

-- =====================================
-- PRIMARY POWER BAR (centered on screen, replaces UF power bar)
-- =====================================
local function CreatePrimaryPowerBar(parent, width, height)
    local tex = GetBarTexture("power")
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(100)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    StyleBarBackground(bg, tex, "power")
    bar.bg = bg
    CreateBorder(bar, "power")

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(GetFont(), math.max(GetFontSize() - 1, 7), "OUTLINE")
    text:SetPoint("CENTER"); text:SetTextColor(1, 1, 1, 0.85)
    bar.text = text

    return bar
end

local function UpdatePrimaryPower()
    if not primaryPowerBar then return end
    if not UnitExists("player") then return end

    local powerType = UnitPowerType("player") or 0
    local current = UnitPower("player", powerType)
    local max = UnitPowerMax("player", powerType)

    primaryPowerBar:SetMinMaxValues(0, max)
    SetBarValueSmooth(primaryPowerBar, current)

    -- Color by power type (reuse TomoMod_Utils if available, fallback to PowerBarColor)
    local r, g, b
    if TomoMod_Utils and TomoMod_Utils.GetPowerColor then
        r, g, b = TomoMod_Utils.GetPowerColor(powerType)
    else
        local info = PowerBarColor[powerType]
        if info then r, g, b = info.r, info.g, info.b
        else r, g, b = 0.00, 0.00, 1.00 end
    end

    -- v2.8 : seuil « ressource basse » — player power non secret en pratique,
    -- garde issecretvalue par sécurité (skip la couleur d'alerte si secret)
    local s = GetSettings()
    if s and s.powerThresholdEnabled
       and not issecret(current) and not issecret(max) and max and max > 0 then
        local pct = current / max * 100
        if pct <= (s.powerThresholdPct or 25) then
            local c = (s.colors and s.colors.powerLow) or { r = 1, g = 0.25, b = 0.25 }
            r, g, b = c.r, c.g, c.b
        end
    end
    primaryPowerBar:SetStatusBarColor(r, g, b, 1)

    -- V3.1 Hash Lines V2. Keep the old preset string as a fallback for
    -- existing profiles until the advanced editor is explicitly enabled.
    local hashCfg = s and s.hashLines and s.hashLines.power
    if hashCfg and hashCfg.enabled then
        ApplyBarTicks(primaryPowerBar, "")
        ApplyAdvancedHashLines(primaryPowerBar, hashCfg, max, "HORIZONTAL")
    else
        ApplyAdvancedHashLines(primaryPowerBar, nil, max, "HORIZONTAL")
        ApplyBarTicks(primaryPowerBar, s and s.powerTicks)
    end

    -- Text (AbbreviateLargeNumbers is C-side, accepts secret numbers)
    if s and s.showText and primaryPowerBar.text then
        primaryPowerBar.text:SetFormattedText("%s", AbbreviateLargeNumbers(current))
    elseif primaryPowerBar.text then
        primaryPowerBar.text:SetText("")
    end
end

-- =====================================
-- v2.8 : HEALTH BAR (HUD)
-- Valeurs → SetMinMaxValues/SetValue directs (C-side accepte les secrets).
-- Texte % → UnitHealthPercent(..., ScaleTo100), passé UNIQUEMENT à format().
-- Couleur seuil → ColorCurve évaluée par UnitHealthPercent côté C.
-- =====================================
local function CreateHealthBar(parent, width, height)
    local tex = GetBarTexture("health")
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(100)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    StyleBarBackground(bg, tex, "health")
    bar.bg = bg
    CreateBorder(bar, "health")

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(GetFont(), math.max(GetFontSize() - 1, 7), "OUTLINE")
    text:SetPoint("CENTER"); text:SetTextColor(1, 1, 1, 0.9)
    bar.text = text

    return bar
end

local function GetHealthBaseColor(s)
    if s and s.healthClassColored ~= false then
        local cc = RAID_CLASS_COLORS[playerClass]
        if cc then return cc.r, cc.g, cc.b end
    end
    local c = (s and s.colors and s.colors.health) or { r = 0.15, g = 0.75, b = 0.30 }
    return c.r, c.g, c.b
end

local function UpdateHealthBar()
    if not healthBar then return end
    if not UnitExists("player") then return end
    local s = GetSettings()

    local cur = UnitHealth("player")
    local mx  = UnitHealthMax("player")
    if not cur or not mx then return end

    healthBar:SetMinMaxValues(0, mx)
    SetBarValueSmooth(healthBar, cur)

    local baseR, baseG, baseB = GetHealthBaseColor(s)

    -- Couleur : seuil via ColorCurve (C-side) si dispo, sinon fallback
    -- arithmétique classique uniquement quand les valeurs ne sont pas secrètes.
    local colored = false
    if s and s.healthThresholdEnabled then
        local c = (s.colors and s.colors.healthLow) or { r = 1, g = 0.2, b = 0.2 }
        if UnitHealthPercent then
            local curve = GetThresholdColorCurve(baseR, baseG, baseB, c.r, c.g, c.b, s.healthThresholdPct or 30)
            if curve then
                local ok, colorResult = pcall(UnitHealthPercent, "player", false, curve)
                if ok and colorResult and colorResult.GetRGBA then
                    healthBar:SetStatusBarColor(colorResult:GetRGBA())
                    colored = true
                end
            end
        elseif not issecret(cur) and not issecret(mx) and mx > 0 then
            if (cur / mx * 100) <= (s.healthThresholdPct or 30) then
                healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
                colored = true
            end
        end
    end
    if not colored then
        healthBar:SetStatusBarColor(baseR, baseG, baseB, 1)
    end

    -- Texte : % via UnitHealthPercent (résultat potentiellement secret →
    -- passé uniquement à format/SetFormattedText, jamais d'arithmétique Lua)
    local fmt = (s and s.healthTextFormat) or "both"
    if fmt == "none" or not healthBar.text then
        if healthBar.text then healthBar.text:SetText("") end
        return
    end

    local pctRaw
    if UnitHealthPercent then
        pctRaw = UnitHealthPercent("player", true, CurveConstants and CurveConstants.ScaleTo100)
    elseif not issecret(cur) and not issecret(mx) and mx > 0 then
        pctRaw = cur / mx * 100
    end

    if fmt == "value" then
        healthBar.text:SetFormattedText("%s", AbbreviateLargeNumbers(cur))
    elseif fmt == "percent" then
        if pctRaw then healthBar.text:SetFormattedText("%d%%", pctRaw)
        else healthBar.text:SetFormattedText("%s", AbbreviateLargeNumbers(cur)) end
    else -- both
        if pctRaw then healthBar.text:SetFormattedText("%s | %d%%", AbbreviateLargeNumbers(cur), pctRaw)
        else healthBar.text:SetFormattedText("%s", AbbreviateLargeNumbers(cur)) end
    end
end

-- =====================================
-- UPDATE: POINTS / AURA DISPLAY
-- =====================================
-- =====================================
-- SUPERCHARGED COMBO POINTS (Rogue "Supercharger")
-- =====================================
-- Blizzard flags individual combo points as supercharged: a finisher that
-- spends one behaves as if it had spent 2 more, so the player needs to see
-- WHICH slot is charged, filled or not. The charged indices come from
-- GetUnitChargedPowerPoints("player") and UNIT_POWER_POINT_CHARGE fires
-- whenever the set changes.
--
-- The list is cached instead of being read inside UpdatePoints: that runs on
-- UNIT_POWER_FREQUENT, which spams for energy, and allocating a table every
-- tick for a value that only moves on its own event would be pure garbage.
local chargedPoints = {}

local function RefreshChargedPoints()
    wipe(chargedPoints)
    if type(GetUnitChargedPowerPoints) ~= "function" then return end
    local ok, list = pcall(GetUnitChargedPowerPoints, "player")
    if not ok or type(list) ~= "table" then return end
    for _, idx in ipairs(list) do
        idx = tonumber(idx)
        if idx then chargedPoints[idx] = true end
    end
end

local function UpdatePoints(pointFrame, resDef)
    if not pointFrame or not pointFrame.points then return end
    local s = GetSettings()

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

        if resDef.showPartial and GetClassConfig().partialFill ~= false then
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
    local fillR, fillG, fillB, textR, textG, textB, thresholdActive =
        ResolveClassThreshold(current + partialFrac, max, r, g, b)

    if pointFrame.text then
        local s2 = GetSettings()
        if s2 and s2.showText then
            if partialFrac > 0 then
                pointFrame.text:SetFormattedText("%.1f / %d", current + partialFrac, max)
            else
                pointFrame.text:SetFormattedText("%d / %d", current, max)
            end
            pointFrame.text:SetTextColor(textR, textG, textB, 0.95)
        else
            pointFrame.text:SetText("")
        end
    end

    -- Supercharged points are a Rogue combo-point mechanic. Keep resource
    -- detection separate from the visual toggle so disabling the effect also
    -- actively restores normal art on already-created point frames.
    local isComboPointResource = (resDef.display == "points")
                                 and (resDef.powerType == POWER_COMBO_POINTS)
    local showSupercharged = (not s) or (s.showSuperchargedComboPoints ~= false)
    local chargeable = isComboPointResource and showSupercharged
    local cpTC = ICON_TEXCOORDS.comboPoints
    local cr, cg, cb = GetColor("chargedComboPoints")

    for i = 1, #pointFrame.points do
        local pt = pointFrame.points[i]
        if i > displayMax then
            pt:Hide()
        else
            pt:Show()

            local charged = chargeable and chargedPoints[i] or false
            local fr, fg, fb = fillR, fillG, fillB
            if charged then fr, fg, fb = cr, cg, cb end

            -- Empty slots matter here: a charged slot has to read as charged
            -- BEFORE it is filled, that is the whole point of showing it.
            -- Textures are built once and reused, so every branch must also
            -- restore the normal art when a slot stops being charged.
            if isComboPointResource then
                if useTex then
                    pt.bg:SetTexCoord(unpack(charged and cpTC.charged or cpTC.empty))
                    pt.fill:SetTexCoord(unpack(charged and cpTC.charged or cpTC.filled))
                    if charged then
                        pt.bg:SetVertexColor(cr, cg, cb, 0.45)
                        pt.fill:SetVertexColor(cr, cg, cb, 1)
                    else
                        pt.bg:SetVertexColor(1, 1, 1, GetBackgroundAlpha("class"))
                        if thresholdActive then
                            pt.fill:SetVertexColor(fillR, fillG, fillB, 1)
                        else
                            pt.fill:SetVertexColor(1, 1, 1, 1)
                        end
                    end
                elseif charged then
                    pt.bg:SetColorTexture(cr * 0.35, cg * 0.35, cb * 0.35, 0.85)
                else
                    SetEmptyPointBackground(pt.bg)
                end
            end

            if useTex and not isComboPointResource then
                if thresholdActive then
                    pt.fill:SetVertexColor(fillR, fillG, fillB, 1)
                else
                    pt.fill:SetVertexColor(1, 1, 1, 1)
                end
            end

            if i <= current then
                if not useTex then pt.fill:SetColorTexture(fr, fg, fb) end
                pt.fill:Show()
                pt.partial:Hide()
            elseif i == current + 1 and partialFrac > 0 then
                pt.fill:Hide()
                if not useTex then pt.partial:SetColorTexture(fillR, fillG, fillB) end
                if pointFrame._resourceOrientation == "VERTICAL" then
                    pt.partial:SetHeight(math.max(pt:GetHeight() * partialFrac, 1))
                else
                    pt.partial:SetWidth(math.max(pt:GetWidth() * partialFrac, 1))
                end
                pt.partial:Show()
            else
                pt.fill:Hide(); pt.partial:Hide()
            end
        end
    end

    -- Full-state highlight: e.g. 5 Icicles -> Glacial Spike ready.
    local showFullGlow = (not s) or (s.showFullResourceGlow ~= false)
    if resDef.glowOnMax and showFullGlow then
        local full = (displayMax > 0 and current >= displayMax)
        if Glow and Glow.PixelGlow_Start then
            if full and not pointFrame._glowing then
                pointFrame._glowing = true
                Glow.PixelGlow_Start(pointFrame, { r, g, b, 1 }, 8, 0.20, nil, 2, 1, 1, false, "TomoMod_RB_FullGlow")
            elseif (not full) and pointFrame._glowing then
                pointFrame._glowing = false
                Glow.PixelGlow_Stop(pointFrame, "TomoMod_RB_FullGlow")
            end
        elseif full and not useTex then
            -- Fallback when the native glow engine is unavailable: brighten the filled segments.
            local br, bgc, bb = math.min(r + 0.30, 1), math.min(g + 0.30, 1), math.min(b + 0.30, 1)
            for i = 1, displayMax do
                local pt = pointFrame.points[i]
                if pt and pt.fill then pt.fill:SetColorTexture(br, bgc, bb) end
            end
        end
    elseif pointFrame._glowing and Glow and Glow.PixelGlow_Stop then
        pointFrame._glowing = false
        Glow.PixelGlow_Stop(pointFrame, "TomoMod_RB_FullGlow")
    end
end

local function UpdateCountResourceBar(bar, resDef)
    if not bar then return end
    local current, maxValue, partialFrac = 0, 1, 0

    if resDef.display == "aura" then
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(resDef.spellID)
        current = aura and aura.applications or 0
        maxValue = resDef.maxStacks or 1
    else
        current = UnitPower("player", resDef.powerType)
        maxValue = UnitPowerMax("player", resDef.powerType)
        if maxValue == 0 then maxValue = 1 end
        if resDef.showPartial and GetClassConfig().partialFill ~= false then
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

    local value = current + partialFrac
    bar:SetMinMaxValues(0, maxValue)
    SetBarValueSmooth(bar, value)

    local r, g, b = GetColor(bar.colorKey or "comboPoints")
    local fillR, fillG, fillB, textR, textG, textB =
        ResolveClassThreshold(value, maxValue, r, g, b)
    bar:SetStatusBarColor(fillR, fillG, fillB, 1)

    local s = GetSettings()
    if s and s.showText and bar.text then
        if partialFrac > 0 then
            bar.text:SetFormattedText("%.1f / %d", value, maxValue)
        else
            bar.text:SetFormattedText("%d / %d", current, maxValue)
        end
        bar.text:SetTextColor(textR, textG, textB, 0.95)
    elseif bar.text then
        bar.text:SetText("")
    end

    local hashCfg = s and s.hashLines and s.hashLines.class
    ApplyAdvancedHashLines(bar, hashCfg, maxValue, bar._resourceOrientation)

    local showFullGlow = (not s) or (s.showFullResourceGlow ~= false)
    local full = not issecret(value) and not issecret(maxValue) and value >= maxValue
    if resDef.glowOnMax and showFullGlow and Glow and Glow.PixelGlow_Start then
        if full and not bar._glowing then
            bar._glowing = true
            Glow.PixelGlow_Start(bar, { r, g, b, 1 }, 8, 0.20, nil, 2, 1, 1, false, "TomoMod_RB_FullGlow")
        elseif (not full) and bar._glowing then
            bar._glowing = false
            Glow.PixelGlow_Stop(bar, "TomoMod_RB_FullGlow")
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

    local ck = POWER_COLOR_KEYS[resDef.powerType] or "comboPoints"
    local r, g, b = GetColor(ck)
    local fillR, fillG, fillB = ResolveClassThreshold(current, max, r, g, b)

    local m = cfg.multiplier

    -- Background: empty state showing full capacity
    local bgRow = cfg.bgRow(max)
    bandFrame.bg:SetTexCoord(0, 1, m * bgRow, m * (bgRow + 1))

    -- Fill: current count
    if current > 0 then
        local fillRow = current - 1
        bandFrame.fill:SetTexCoord(0, 1, m * fillRow, m * (fillRow + 1))
        bandFrame.fill:SetVertexColor(fillR, fillG, fillB, 1)
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
        local fillR, fillG, fillB = ResolveClassThreshold(stagger, maxHP, r, g, b)
        bar:SetStatusBarColor(fillR, fillG, fillB, 1)
    end

    local s = GetSettings()
    local _, _, _, textR, textG, textB =
        ResolveClassThreshold(stagger, maxHP, GetColor("stagger"))
    if s and s.showText and bar.text then
        bar.text:SetFormattedText("%s", AbbreviateLargeNumbers(stagger))
        bar.text:SetTextColor(textR, textG, textB, 0.95)
    elseif bar.text then
        bar.text:SetText("")
    end
    ApplyAdvancedHashLines(bar, s and s.hashLines and s.hashLines.class,
        maxHP, bar._resourceOrientation)
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
    SetBarValueSmooth(druidManaBar, current)
    local r, g, b = GetColor("mana")
    druidManaBar:SetStatusBarColor(r, g, b, 1)

    local s = GetSettings()
    ApplyAdvancedHashLines(druidManaBar, s and s.hashLines and s.hashLines.power,
        max, "HORIZONTAL")
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
    if label == "Icicles" then return "icicles" end
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

    RefreshChargedPoints()

    -- Specs with no class power at all (e.g. Warrior, Hunter BM/MM, Priest, etc.)
    currentResources = resources
    currentSpec = specIndex

    local width = s.width or 260
    local cpH = s.primaryHeight or 16     -- height for class power display
    local dmH = s.secondaryHeight or 12   -- height for druid mana bar
    local gap = math.max(0, tonumber(s.barSpacing) or 2)
    local stackUp = s.stackDirection == "UP"
    local classCfg = GetClassConfig()
    local classMode = classCfg.mode or "segments"
    local classOrientation = GetClassOrientation()

    -- Clear old
    if classPowerFrame then
        if classPowerFrame._glowing and Glow and Glow.PixelGlow_Stop then
            Glow.PixelGlow_Stop(classPowerFrame, "TomoMod_RB_FullGlow")
            classPowerFrame._glowing = false
        end
        classPowerFrame:Hide()
        classPowerFrame = nil
    end
    if druidManaBar then druidManaBar:Hide(); druidManaBar = nil end
    if primaryPowerBar then primaryPowerBar:Hide(); primaryPowerBar = nil end
    if healthBar then healthBar:Hide(); healthBar = nil end
    wipe(smoothFrames)

    -- Container
    if not container then
        container = CreateFrame("Frame", "TomoMod_ResourceBars_Container", UIParent)
        container:SetClampedToScreen(true)
        TomoMod_Utils.SetupDraggable(container, function()
            s.position = s.position or {}
            if TomoMod_Layout and TomoMod_Layout.Save
                and TomoMod_Layout.Save(s.position, container) then
                return
            end

            -- Legacy fallback.
            local left, bottom = container:GetLeft(), container:GetBottom()
            if left and bottom then
                local scale = container:GetEffectiveScale() / UIParent:GetEffectiveScale()
                s.position.point = "BOTTOMLEFT"
                s.position.relativePoint = "BOTTOMLEFT"
                s.position.x = left * scale
                s.position.y = bottom * scale
            end
        end, TomoMod_Layout and TomoMod_Layout.Label("resourceBars"))
    end

    -- Apply scale before position: Layout.Apply converts UIParent-space offsets
    -- back into this frame's scaled coordinate space.
    container:SetScale(s.scale or 1.0)

    -- Position
    local pos = s.position
    if pos then
        if TomoMod_Layout and TomoMod_Layout.Apply then
            TomoMod_Layout.Apply(pos, container)
        else
            local point = pos.point or pos.anchor or "BOTTOM"
            local anchor = pos.anchor or pos.relativePoint or pos.relPoint or pos.relTo or "CENTER"
            container:ClearAllPoints()
            container:SetPoint(point, UIParent, anchor, pos.x or 0, pos.y or -230)
        end
    else
        container:ClearAllPoints()
        container:SetPoint("BOTTOM", UIParent, "CENTER", 0, -230)
    end

    local totalH, nextY = 0, 0
    local hasContent = false

    local function PlaceLayer(layer, height)
        layer:ClearAllPoints()
        local centered = layer._resourceOrientation == "VERTICAL"
        if stackUp then
            if centered then layer:SetPoint("BOTTOM", container, "BOTTOM", 0, nextY)
            else layer:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, nextY) end
        else
            if centered then layer:SetPoint("TOP", container, "TOP", 0, -nextY)
            else layer:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY) end
        end
        nextY = nextY + height + gap
        totalH = totalH + height + gap
        hasContent = true
    end

    -- === v2.8 : HEALTH BAR (HUD, optionnelle — toujours en haut) ===
    if s.healthBarEnabled then
        local hbH = s.healthBarHeight or 14
        healthBar = CreateHealthBar(container, width, hbH)
        PlaceLayer(healthBar, hbH)
        UpdateHealthBar()
    end

    -- === CLASS POWER ===
    if resources and resources.classPower then
        local cpDef = resources.classPower
        if cpDef.display == "points" then
            local ck = POWER_COLOR_KEYS[cpDef.powerType] or "comboPoints"
            local texType = POWER_TEXTURE_TYPE[cpDef.powerType]
            if classMode == "bar" then
                classPowerFrame = CreateCountResourceBar(container, width, cpH, ck)
            -- Band spritesheets remain a high-quality icon-mode option when
            -- horizontal. Vertical designer mode uses individual segments.
            elseif UseTextures() and texType and BAND_CONFIG[texType]
               and classOrientation == "HORIZONTAL" then
                classPowerFrame = CreateBandDisplay(container, width, cpH, texType)
            else
                classPowerFrame = CreatePointDisplay(container,
                    cpDef.maxPoints or 5, width, cpH, ck, texType)
            end
        elseif cpDef.display == "runes" then
            classPowerFrame = CreateRuneDisplay(container, width, cpH)
        elseif cpDef.display == "stagger" then
            classPowerFrame = CreateStaggerBar(container, width, cpH)
        elseif cpDef.display == "aura" then
            local ck = GetAuraColorKey(cpDef.label)
            if classMode == "bar" then
                classPowerFrame = CreateCountResourceBar(container, width, cpH, ck)
            else
                classPowerFrame = CreatePointDisplay(container,
                    cpDef.maxStacks or 5, width, cpH, ck, nil)
            end
        elseif cpDef.display == "aura_bar" then
            classPowerFrame = CreateBarDisplay(container, width, cpH)
        end

        if classPowerFrame then
            PlaceLayer(classPowerFrame, classPowerFrame._layerHeight or cpH)
        end
    end

    local ppH = s.primaryPowerBarHeight or 14
    local specNeedsPrimary = resources and resources.primaryPower

    -- === PRIMARY POWER BAR (spec default — e.g. Guardian Druid Rage, shown first) ===
    if specNeedsPrimary then
        primaryPowerBar = CreatePrimaryPowerBar(container, width, ppH)
        PlaceLayer(primaryPowerBar, ppH)
        UpdatePrimaryPower()
        if TomoMod_ResourceBars then
            TomoMod_ResourceBars._primaryPowerCentered = true
        end
    end

    -- === DRUID MANA BAR ===
    if resources and resources.druidMana then
        druidManaBar = CreateDruidManaBar(container, width, dmH)
        PlaceLayer(druidManaBar, dmH)
    end

    -- === PRIMARY POWER BAR (user setting, for specs without a spec-default primary power) ===
    if s.primaryPowerCentered and not specNeedsPrimary then
        primaryPowerBar = CreatePrimaryPowerBar(container, width, ppH)
        PlaceLayer(primaryPowerBar, ppH)
        -- Immediate update
        UpdatePrimaryPower()
        -- Notify UnitFrames to hide player power bar
        if TomoMod_ResourceBars then
            TomoMod_ResourceBars._primaryPowerCentered = true
        end
    elseif not specNeedsPrimary then
        if TomoMod_ResourceBars then
            TomoMod_ResourceBars._primaryPowerCentered = false
        end
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

    -- No early return on a nil currentResources. Specs with no class power at
    -- all (Warrior, Priest, Fire Mage, Mistweaver, Havoc, BM/MM Hunter,
    -- Ele/Resto Shaman, Resto Druid) have no CLASS_RESOURCES entry, so bailing
    -- here skipped the centered power bar and the health bar too -- both of
    -- which are spec-agnostic. They kept whatever value BuildResourceDisplay
    -- gave them, which on a fresh login is 0 rage / 0 energy.
    local resources = currentResources

    -- Class Power
    if classPowerFrame and resources and resources.classPower then
        local cpDef = resources.classPower
        if classPowerFrame.isCountResource then
            UpdateCountResourceBar(classPowerFrame, cpDef)
        elseif classPowerFrame.isBand then
            UpdateBandDisplay(classPowerFrame, cpDef)
        elseif cpDef.display == "points" or cpDef.display == "aura" then
            UpdatePoints(classPowerFrame, cpDef)
        elseif cpDef.display == "aura_bar" then
            local cur, max = GetAuraBarValues(cpDef)
            classPowerFrame:SetMinMaxValues(0, max)
            SetBarValueSmooth(classPowerFrame, cur)
            local ck = cpDef.colorKey or "soulFragments"
            local r, g, b = GetColor(ck)
            local fillR, fillG, fillB, textR, textG, textB =
                ResolveClassThreshold(cur, max, r, g, b)
            classPowerFrame:SetStatusBarColor(fillR, fillG, fillB, 1)
            local s = GetSettings()
            ApplyAdvancedHashLines(classPowerFrame,
                s and s.hashLines and s.hashLines.class,
                max, classPowerFrame._resourceOrientation)
            if s and s.showText and classPowerFrame.text then
                classPowerFrame.text:SetFormattedText("%d / %d", cur, max)
                classPowerFrame.text:SetTextColor(textR, textG, textB, 0.95)
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

    -- v2.8 : Health bar
    if healthBar then UpdateHealthBar() end

    -- Primary Power (centered bar)
    if primaryPowerBar then UpdatePrimaryPower() end
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
    elseif event == "UNIT_POWER_POINT_CHARGE" then
        -- The unit payload can come through as nil, and RegisterUnitEvent
        -- would swallow those fires outright, so this one is registered
        -- broadly and filtered here instead.
        if arg1 == nil or arg1 == "player" then
            RefreshChargedPoints()
            UpdateAll()
        end
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
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if arg1 == "player" then
            if healthBar then UpdateHealthBar() end
            if classPowerFrame and currentResources
               and currentResources.classPower and currentResources.classPower.display == "stagger" then
                UpdateStagger(classPowerFrame)
            end
        end
    end
end

-- OnUpdate only needed for smooth rune CDs (DK) — all other resources use events
local updateTimer = 0
local function OnUpdate(self, elapsed)
    -- v2.8 : pas de smoothing à chaque frame (1-3 barres max, lerp trivial)
    if next(smoothFrames) then SmoothStep(elapsed) end

    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.1 then  -- [PERF] 0.1s (10fps) au lieu de 0.05s — suffisant pour "%.1f" runes/stagger
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
            print("|cff2e9dd8TomoMod ResourceBars:|r " .. string.format(TomoMod_L["msg_rb_width_synced"], math.floor(w)))
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
    mainFrame:RegisterEvent("UNIT_POWER_POINT_CHARGE")
    mainFrame:RegisterUnitEvent("UNIT_AURA", "player")
    mainFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    mainFrame:RegisterUnitEvent("UNIT_HEALTH", "player")
    mainFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
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
        -- v2.8 : le smoothing a besoin d'un OnUpdate même sans runes/stagger
        local s = GetSettings()
        if s and s.smoothBars then
            mainFrame:SetScript("OnUpdate", OnUpdate)
            return
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
    if RB._refreshOnUpdate then RB._refreshOnUpdate() end
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
            print("|cff2e9dd8TomoMod ResourceBars:|r " .. TomoMod_L["msg_rb_locked"])
        else
            print("|cff2e9dd8TomoMod ResourceBars:|r " .. TomoMod_L["msg_rb_unlocked"])
        end
    end
end

function RB.SyncWidth()
    SyncWithEssentialCooldowns()
end

_G.TomoMod_ResourceBars = RB

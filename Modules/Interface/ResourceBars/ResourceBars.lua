-- =====================================
-- ResourceBars.lua v2.8 — Class Power Display System
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

    local bar = CreateFrame("StatusBar", nil, parent)
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
-- Flat-mode empty slot fill. Shared with UpdatePoints, which has to restore
-- it when a point stops being supercharged.
local EMPTY_POINT_BG = { 0.06, 0.06, 0.08, 0.8 }

local function CreatePointDisplay(parent, maxPoints, width, height, colorKey, texType)
    local frame = CreateFrame("Frame", nil, parent)
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
            bg:SetColorTexture(unpack(EMPTY_POINT_BG))
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
    local frame = CreateFrame("Frame", nil, parent)
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

    local bar = CreateFrame("StatusBar", nil, parent)
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
    local bar = CreateFrame("StatusBar", nil, parent)
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
-- PRIMARY POWER BAR (centered on screen, replaces UF power bar)
-- =====================================
local function CreatePrimaryPowerBar(parent, width, height)
    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(100)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetTexture(tex)
    bg:SetVertexColor(0.06, 0.06, 0.08, 0.8)
    bar.bg = bg
    CreateBorder(bar)

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

    -- v2.8 : ticks (positions en % — indépendantes du max)
    ApplyBarTicks(primaryPowerBar, s and s.powerTicks)

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
    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(tex)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:SetMinMaxValues(0, 100); bar:SetValue(100)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetTexture(tex)
    bg:SetVertexColor(0.06, 0.06, 0.08, 0.8)
    bar.bg = bg
    CreateBorder(bar)

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
            local fr, fg, fb = r, g, b
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
                        pt.bg:SetVertexColor(1, 1, 1, 1)
                        pt.fill:SetVertexColor(1, 1, 1, 1)
                    end
                elseif charged then
                    pt.bg:SetColorTexture(cr * 0.35, cg * 0.35, cb * 0.35, 0.85)
                else
                    pt.bg:SetColorTexture(unpack(EMPTY_POINT_BG))
                end
            end

            if i <= current then
                if not useTex then pt.fill:SetColorTexture(fr, fg, fb) end
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
    SetBarValueSmooth(druidManaBar, current)
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
    local gap = 2

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
            -- [DRAG] screen-absolute coords instead of GetPoint
            local left, bottom = container:GetLeft(), container:GetBottom()
            if left and bottom then
                local scale = container:GetEffectiveScale() / UIParent:GetEffectiveScale()
                s.position = s.position or {}
                s.position.point = "BOTTOMLEFT"
                s.position.relativePoint = "BOTTOMLEFT"
                s.position.x = left * scale
                s.position.y = bottom * scale
            end
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

    -- === v2.8 : HEALTH BAR (HUD, optionnelle — toujours en haut) ===
    if s.healthBarEnabled then
        local hbH = s.healthBarHeight or 14
        healthBar = CreateHealthBar(container, width, hbH)
        healthBar:ClearAllPoints()
        healthBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
        nextY = nextY + hbH + gap
        totalH = totalH + hbH + gap
        hasContent = true
        UpdateHealthBar()
    end

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

    local ppH = s.primaryPowerBarHeight or 14
    local specNeedsPrimary = resources and resources.primaryPower

    -- === PRIMARY POWER BAR (spec default — e.g. Guardian Druid Rage, shown first) ===
    if specNeedsPrimary then
        primaryPowerBar = CreatePrimaryPowerBar(container, width, ppH)
        primaryPowerBar:ClearAllPoints()
        primaryPowerBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
        nextY = nextY + ppH + gap
        totalH = totalH + ppH + gap
        hasContent = true
        UpdatePrimaryPower()
        if TomoMod_ResourceBars then
            TomoMod_ResourceBars._primaryPowerCentered = true
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

    -- === PRIMARY POWER BAR (user setting, for specs without a spec-default primary power) ===
    if s.primaryPowerCentered and not specNeedsPrimary then
        primaryPowerBar = CreatePrimaryPowerBar(container, width, ppH)
        primaryPowerBar:ClearAllPoints()
        primaryPowerBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -nextY)
        nextY = nextY + ppH + gap
        totalH = totalH + ppH + gap
        hasContent = true
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
        if classPowerFrame.isBand then
            UpdateBandDisplay(classPowerFrame, cpDef)
        elseif cpDef.display == "points" or cpDef.display == "aura" then
            UpdatePoints(classPowerFrame, cpDef)
        elseif cpDef.display == "aura_bar" then
            local cur, max = GetAuraBarValues(cpDef)
            classPowerFrame:SetMinMaxValues(0, max)
            SetBarValueSmooth(classPowerFrame, cur)
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
            print("|cff2ed884TomoMod ResourceBars:|r " .. string.format(TomoMod_L["msg_rb_width_synced"], math.floor(w)))
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
            print("|cff2ed884TomoMod ResourceBars:|r " .. TomoMod_L["msg_rb_locked"])
        else
            print("|cff2ed884TomoMod ResourceBars:|r " .. TomoMod_L["msg_rb_unlocked"])
        end
    end
end

function RB.SyncWidth()
    SyncWithEssentialCooldowns()
end

_G.TomoMod_ResourceBars = RB
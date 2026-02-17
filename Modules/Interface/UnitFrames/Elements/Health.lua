-- =====================================
-- Elements/Health.lua — Health Bar + Absorb
-- Uses oUF-style C-side APIs to handle TWW "secret numbers"
-- =====================================

UF_Elements = UF_Elements or {}

local TEXTURE = "Interface\\AddOns\\TomoModMini\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoModMini\\Assets\\Fonts\\Tomo.ttf"

-- =====================================
-- HEALTH COLOR
-- =====================================

-- Darken a color (same as Nameplates — dimmed when out-of-combat)
local function DarkenColor(r, g, b, factor)
    factor = factor or 0.60
    return r * factor, g * factor, b * factor
end

-- Check if in real instanced content (dungeon/raid)
local function InRealInstancedContent()
    local _, instanceType, difficultyID = GetInstanceInfo()
    difficultyID = tonumber(difficultyID) or 0
    if difficultyID == 0 then return false end
    if C_Garrison and C_Garrison.IsOnGarrisonMap and C_Garrison.IsOnGarrisonMap() then return false end
    if instanceType == "party" or instanceType == "raid" then return true end
    return false
end

-- Nameplate-style color logic for enemy units (caster, miniboss, threat, darken OOC)
local function GetNameplateStyleColor(unit)
    local npDB = TomoModMiniDB and TomoModMiniDB.nameplates
    if not npDB then return nil end
    local colors = npDB.colors
    if not colors then return nil end

    -- Tapped
    if UnitIsTapDenied(unit) then
        local c = colors.tapped
        if c then return c.r, c.g, c.b end
        return 0.5, 0.5, 0.5
    end

    -- Neutral
    local reaction = UnitReaction(unit, "player")
    if reaction and reaction == 4 then
        local c = colors.neutral; return c.r, c.g, c.b
    end
    if UnitCanAttack("player", unit) and not UnitIsEnemy(unit, "player") then
        local c = colors.neutral; return c.r, c.g, c.b
    end

    -- Friendly NPC
    if reaction and reaction >= 5 and not UnitIsPlayer(unit) then
        local c = colors.friendly; return c.r, c.g, c.b
    end

    -- Focus
    if colors.focus and UnitIsUnit(unit, "focus") then
        local c = colors.focus; return c.r, c.g, c.b
    end

    -- Enemy players: handled by useClassColor, skip here
    if UnitIsPlayer(unit) then return nil end

    -- From here: hostile NPCs only
    local inCombat = UnitAffectingCombat(unit)

    -- Miniboss: elite/worldboss with higher level
    if npDB.useClassificationColors then
        local classification = UnitClassification(unit)
        if classification == "elite" or classification == "worldboss" or classification == "rareelite" then
            local level = UnitLevel(unit)
            local playerLevel = UnitLevel("player")
            local isMiniboss = false
            if type(level) == "number" and type(playerLevel) == "number" then
                isMiniboss = (level == -1) or (level >= playerLevel + 1)
            elseif classification == "worldboss" then
                isMiniboss = true
            end
            if isMiniboss and colors.miniboss then
                local c = colors.miniboss
                if type(inCombat) == "boolean" and inCombat then
                    return c.r, c.g, c.b
                else
                    return DarkenColor(c.r, c.g, c.b)
                end
            end
        end
    end

    -- Caster NPC
    if colors.caster then
        local unitClass = UnitClassBase and UnitClassBase(unit)
        if unitClass == "PALADIN" then
            local c = colors.caster
            if type(inCombat) == "boolean" and inCombat then
                return c.r, c.g, c.b
            else
                return DarkenColor(c.r, c.g, c.b)
            end
        end
    end

    -- Tank/DPS threat coloring (instanced content)
    if npDB.tankMode and InRealInstancedContent() then
        local tankColors = npDB.tankColors
        if tankColors then
            local isTanking, status = UnitDetailedThreatSituation("player", unit)
            if status then
                local role = UnitGroupRolesAssigned("player")
                local isTankRole = (role == "TANK")
                if isTankRole then
                    if isTanking then
                        local c = tankColors.hasThreat; return c.r, c.g, c.b
                    elseif status >= 2 then
                        local c = tankColors.lowThreat; return c.r, c.g, c.b
                    else
                        local c = tankColors.noThreat; return c.r, c.g, c.b
                    end
                else
                    if isTanking then
                        local c = tankColors.dpsHasAggro or tankColors.noThreat; return c.r, c.g, c.b
                    elseif status >= 2 then
                        local c = tankColors.dpsNearAggro or tankColors.lowThreat; return c.r, c.g, c.b
                    end
                end
            end
        end
    end

    -- Default enemy: in-combat vs out-of-combat dimming
    local c = colors.enemyInCombat or colors.normal or colors.hostile
    if c then
        if type(inCombat) == "boolean" and inCombat then
            return c.r, c.g, c.b
        else
            return DarkenColor(c.r, c.g, c.b)
        end
    end

    return nil
end

function UF_Elements.GetHealthColor(unit, settings)
    if not settings then return 0.5, 0.5, 0.5 end

    -- Class color for players
    if settings.useClassColor and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class and RAID_CLASS_COLORS[class] then
            local c = RAID_CLASS_COLORS[class]
            return c.r, c.g, c.b
        end
    end

    -- Nameplate-style colors for NPCs (caster, miniboss, threat, focus, darken OOC)
    if settings.useNameplateColors then
        local r, g, b = GetNameplateStyleColor(unit)
        if r then return r, g, b end
    end

    -- Fallback: faction color
    if settings.useFactionColor and not UnitIsPlayer(unit) then
        return TomoModMini_Utils.GetReactionColor(unit)
    end

    -- Default: player class color
    if unit == "player" or unit == "pet" then
        return TomoModMini_Utils.GetClassColor("player")
    end

    return 0.5, 0.5, 0.5
end

-- =====================================
-- FORMAT HEALTH TEXT
-- Uses ONLY C-side APIs to avoid creating tainted Lua strings:
--   FontString:SetFormattedText() — C-side, formats secret values without Lua taint
--   UnitHealthPercent()           — TWW C-side percentage
--   AbbreviateLargeNumbers()      — C-side abbreviation
--   UnitHealthMissing()           — C-side deficit
-- =====================================

-- Cache the scale constant (TWW 11.0.5+)
local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

-- Sets health text directly on a FontString using C-side SetFormattedText.
-- This avoids creating any tainted Lua strings that could propagate taint
-- to Blizzard secure frames (CompactUnitFrame, arena frames, etc).
function UF_Elements.SetHealthText(fontString, current, max, format, unit)
    if not fontString then return end

    -- Status check
    if unit then
        if UnitIsDead(unit) then fontString:SetText("Dead"); return
        elseif UnitIsGhost(unit) then fontString:SetText("Ghost"); return
        elseif not UnitIsConnected(unit) then fontString:SetText("Offline"); return
        end
    end
    if not unit then fontString:SetText(""); return end

    if format == "percent" then
        -- "%d%%" → "75%"  (SetFormattedText handles secret number C-side)
        fontString:SetFormattedText("%d%%", UnitHealthPercent(unit, true, ScaleTo100))
    elseif format == "current" then
        -- "%s" → "25.3K"
        fontString:SetFormattedText("%s", AbbreviateLargeNumbers(current))
    elseif format == "current_percent" then
        -- "%s  |cffcccccc%d%%|r" → "25.3K  75%"
        fontString:SetFormattedText("%s  |cffcccccc%d%%|r", AbbreviateLargeNumbers(current), UnitHealthPercent(unit, true, ScaleTo100))
    elseif format == "current_max" then
        -- "%s / %s" → "25.3K / 33.8K"
        fontString:SetFormattedText("%s / %s", AbbreviateLargeNumbers(current), AbbreviateLargeNumbers(max))
    elseif format == "deficit" then
        -- "-%s" → "-8.5K" (or "-0" at full HP, acceptable)
        fontString:SetFormattedText("-%s", AbbreviateLargeNumbers(UnitHealthMissing(unit)))
    else
        -- Default: current + percent
        fontString:SetFormattedText("%s  |cffcccccc%d%%|r", AbbreviateLargeNumbers(current), UnitHealthPercent(unit, true, ScaleTo100))
    end
end

-- =====================================
-- CREATE HEALTH BAR
-- =====================================

function UF_Elements.CreateHealth(parent, unit, settings)
    local tex = (TomoModMiniDB and TomoModMiniDB.unitFrames and TomoModMiniDB.unitFrames.texture) or TEXTURE
    local font = (TomoModMiniDB and TomoModMiniDB.unitFrames and TomoModMiniDB.unitFrames.font) or FONT
    local fontSize = (TomoModMiniDB and TomoModMiniDB.unitFrames and TomoModMiniDB.unitFrames.fontSize) or 12

    local health = CreateFrame("StatusBar", nil, parent)
    health:SetSize(settings.width, settings.healthHeight)
    health:SetPoint("TOP", parent, "TOP", 0, 0)
    health:SetStatusBarTexture(tex)
    health:GetStatusBarTexture():SetHorizTile(false)
    health:SetMinMaxValues(0, 100)
    health:SetValue(100)

    -- Background
    local bg = health:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(tex)
    bg:SetVertexColor(0.12, 0.12, 0.15, 0.8)
    health.bg = bg

    -- Border
    UF_Elements.CreateBorder(health)

    -- Health text
    local text = health:CreateFontString(nil, "OVERLAY")
    text:SetFont(font, fontSize, "OUTLINE")
    text:SetPoint("CENTER", 0, 0)
    text:SetTextColor(1, 1, 1, 1)
    health.text = text

    -- Name text (top-left of health bar, for "90 - Name" format)
    local nameText = health:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(font, fontSize - 1, "OUTLINE")
    nameText:SetPoint("TOPLEFT", 4, -2)
    nameText:SetTextColor(1, 1, 1, 0.95)
    nameText:SetJustifyH("LEFT")
    health.nameText = nameText

    -- Level text (right side, inside)
    local levelText = health:CreateFontString(nil, "OVERLAY")
    levelText:SetFont(font, fontSize - 2, "OUTLINE")
    levelText:SetPoint("RIGHT", -6, 0)
    levelText:SetTextColor(1, 1, 0.6, 0.9)
    health.levelText = levelText

    -- Raid icon
    local raidIcon = health:CreateTexture(nil, "OVERLAY")
    raidIcon:SetSize(18, 18)
    raidIcon:SetPoint("LEFT", health, "LEFT", -22, 0)
    raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    raidIcon:Hide()
    health.raidIcon = raidIcon

    -- Leader icon (crown)
    local leaderOfs = settings.leaderIconOffset or { x = -2, y = 0 }
    local leaderIcon = health:CreateTexture(nil, "OVERLAY")
    leaderIcon:SetSize(16, 16)
    leaderIcon:SetPoint("BOTTOMLEFT", health, "TOPLEFT", leaderOfs.x, leaderOfs.y)
    leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    leaderIcon:Hide()
    health.leaderIcon = leaderIcon

    health.unit = unit
    health:EnableMouse(false)  -- Let clicks pass through to parent SecureUnitButtonTemplate
    return health
end

-- =====================================
-- CREATE ABSORB BAR (overlay)
-- =====================================

function UF_Elements.CreateAbsorb(parent, healthBar, settings)
    local tex = (TomoModMiniDB and TomoModMiniDB.unitFrames and TomoModMiniDB.unitFrames.texture) or TEXTURE

    local absorb = CreateFrame("StatusBar", nil, parent)
    absorb:SetSize(settings.width, settings.healthHeight)
    absorb:SetAllPoints(healthBar)
    absorb:SetStatusBarTexture(tex)
    absorb:GetStatusBarTexture():SetHorizTile(false)
    absorb:SetMinMaxValues(0, 100)
    absorb:SetValue(0)
    absorb:SetStatusBarColor(1, 1, 1, 0.35)
    absorb:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    absorb:EnableMouse(false)  -- Let clicks pass through

    return absorb
end

-- =====================================
-- THREAT INDICATOR (thin border glow)
-- =====================================

function UF_Elements.CreateThreatIndicator(parent)
    local threat = CreateFrame("Frame", nil, parent)
    threat:SetPoint("TOPLEFT", -2, 2)
    threat:SetPoint("BOTTOMRIGHT", 2, -2)
    threat:SetFrameLevel(parent:GetFrameLevel() + 5)

    local edges = {}
    local function MakeEdge(p1, p2, w, h)
        local t = threat:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(1, 0, 0, 0.8)
        if p1 and p2 then
            t:SetPoint(p1)
            t:SetPoint(p2)
        end
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        table.insert(edges, t)
        return t
    end

    local top = MakeEdge("TOPLEFT", "TOPRIGHT", nil, 2)
    local bot = MakeEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
    local left = MakeEdge("TOPLEFT", "BOTTOMLEFT", 2, nil)
    local right = MakeEdge("TOPRIGHT", "BOTTOMRIGHT", 2, nil)

    threat.edges = edges
    threat:Hide()

    threat.SetThreatColor = function(self, r, g, b)
        for _, e in ipairs(self.edges) do
            e:SetColorTexture(r, g, b, 0.9)
        end
    end

    threat:EnableMouse(false)  -- Let clicks pass through
    return threat
end

-- =====================================
-- GENERIC BORDER HELPER
-- =====================================

function UF_Elements.CreateBorder(frame)
    local function Edge(point1, point2, w, h)
        local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        t:SetPoint(point1)
        t:SetPoint(point2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, 1)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    Edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
end

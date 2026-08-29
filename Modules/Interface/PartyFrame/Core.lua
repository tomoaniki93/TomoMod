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
local GetReadyCheckStatus = GetReadyCheckStatus
local RegisterStateDriver = RegisterStateDriver
local pairs, ipairs, wipe, pcall = pairs, ipairs, wipe, pcall
local issecretvalue    = issecretvalue

local ADDON_FONT    = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local ROLE_TEXTURE  = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"

-- State
PF.frames      = {}        -- [0]=player, [1..4]=party1..party4
-- Parallel lookup, [unitToken] = frame. PF.frames stays keyed by slot index
-- because several call sites address it numerically (PF.frames[0], the
-- creation loop, the idx-aware layout pass), so re-keying it would be a much
-- wider change than this needs to be. A unit token never moves between
-- frames -- frame i is always "party"..i -- so this map is written once at
-- creation and never invalidated.
PF.byUnit      = {}
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
    -- [12.1] The class token can be secret, and indexing RAID_CLASS_COLORS
    -- with one throws inside Blizzard's own table.
    -- Hoisted rather than `TomoMod_Utils and ...`: `and` keeps only the
    -- first return value, which would drop green and blue.
    local cr, cg, cb
    if TomoMod_Utils then cr, cg, cb = TomoMod_Utils.TryClassColor(unit) end
    if cr then return cr, cg, cb end
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

    -- [COMBAT] Secure visibility driver instead of RegisterUnitWatch.
    -- The driver lives on Blizzard's secure side, so joins, leaves,
    -- solo<->group and party<->raid transitions show/hide the frame
    -- correctly even while in combat. RegisterUnitWatch alone cannot
    -- express the "hide in raid" rule, which previously forced a
    -- deferred watch re-registration on every roster change.
    local visibility
    if index == 0 then
        visibility = "[group:raid] hide; [group] show; hide"
    else
        visibility = "[group:raid] hide; [@" .. unit .. ",exists] show; hide"
    end
    RegisterStateDriver(f, "visibility", visibility)

    -- Repaint as soon as the secure driver reveals the frame (mid-combat
    -- join): child regions are not protected, so a full element refresh
    -- is combat-safe.
    f:HookScript("OnShow", function(self)
        PF.UpdateFrame(self)
    end)

    -- Tooltip on hover
    f:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetUnit(self.unit)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

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

    -- ---- LEADER ICON ----
    -- Above the frame, top-left corner. Nothing else lives there: the role
    -- icon sits INSIDE content at TOPLEFT and the raid marker is centred
    -- above, so the crown collides with neither.
    -- Created unconditionally, unlike the role icon: PF.ApplySettings updates
    -- existing frames in place and never rebuilds them, so gating creation on
    -- the option would make the checkbox need a /reload. UpdateLeader reads
    -- the option instead, and the size follows the slider live.
    local leaderIcon = content:CreateTexture(nil, "OVERLAY")
    local lSize = db.leaderIconSize or 14
    leaderIcon:SetSize(lSize, lSize)
    leaderIcon:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 1)
    leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    leaderIcon:SetDrawLayer("OVERLAY", 6)
    leaderIcon:Hide()
    f.leaderIcon = leaderIcon

    -- ---- RAID MARKER ----
    if db.showRaidMarker then
        local markerFrame = CreateFrame("Frame", nil, content)
        local mSize = db.raidMarkerSize or 16
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
    rcFrame:SetSize(db.readyCheckSize or 24, db.readyCheckSize or 24)
    rcFrame:SetPoint("CENTER", f, "CENTER", 0, 0)
    rcFrame:SetFrameLevel(content:GetFrameLevel() + 5)
    rcFrame:Hide()
    local rcTex = rcFrame:CreateTexture(nil, "OVERLAY")
    rcTex:SetAllPoints()
    rcTex:SetDrawLayer("OVERLAY", 7)
    rcFrame.texture = rcTex
    f.readyCheck = rcFrame

    -- ---- SUMMON INDICATOR ----
    local sumFrame = CreateFrame("Frame", nil, content)
    local sSize = db.summonSize or 18
    sumFrame:SetSize(sSize, sSize)
    sumFrame:SetPoint("BOTTOM", f, "BOTTOM", 0, 2)
    sumFrame:SetFrameLevel(content:GetFrameLevel() + 5)
    sumFrame:Hide()
    local sumTex = sumFrame:CreateTexture(nil, "OVERLAY")
    sumTex:SetAllPoints()
    sumTex:SetDrawLayer("OVERLAY", 7)
    sumFrame.texture = sumTex
    f.summonIndicator = sumFrame

    -- ---- DEBUFF-TYPE ALERT ----
    -- Five engine-side AuraSlots (Magic / Curse / Disease / Poison / Bleed).
    -- Lua never reads aura data, so the full-frame outline + real aura icon
    -- keep working while 12.1 aura values are secret in combat.
    local AC = TomoMod_AuraContainer
    if AC and AC.CreateDispelIndicator then
        local dispelHost = CreateFrame("Frame", nil, content)
        dispelHost:SetAllPoints(content)
        dispelHost:SetFrameLevel(content:GetFrameLevel() + 5)
        dispelHost:EnableMouse(false)
        f.dispelHost = dispelHost
        dispelHost.engine = AC.CreateDispelIndicator(dispelHost, {
            unit       = nil,
            iconSize   = db.dispelSize or 22,
            borderSize = db.dispelBorderSize or 2,
            showIcon   = db.showDispelIcon ~= false,
            showBorder = db.showDispelBorder ~= false,
            showBleed  = db.showDispelBleed ~= false,
            font       = db.font or ADDON_FONT,
        })
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

    -- ---- DEFENSIVE CD CONTAINER ----
    if db.showDefensives then
        f.defensiveContainer = TomoMod_DefensiveTrack and TomoMod_DefensiveTrack.Create(content, {
            size     = db.defensiveIconSize or 16,
            count    = db.maxDefensives or 2,
            point    = "BOTTOMRIGHT",
            relPoint = "BOTTOMRIGHT",
            x        = -2,
            y        = 2,
            grow     = "LEFT",
            font     = db.font or ADDON_FONT,
        })
    end

    -- ---- HOT CONTAINER ----
    if db.showHoTs then
        local hotContainer = CreateFrame("Frame", nil, content)
        hotContainer:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 2, 2)
        local hotSize = db.hotSize or 12
        hotContainer:SetSize(hotSize * (db.maxHoTs or 3) + 4, hotSize)
        -- [12.1] The engine fills this container. includeSpellIDs narrows
        -- the group to the HoTs we track, which is what the spellId match
        -- did before the client withheld it.
        local AD = TomoMod_AuraData
        local AC = TomoMod_AuraContainer
        if AC then
            hotContainer.engine = AC.Create(hotContainer, {
                key             = "hots",
                size            = hotSize,
                max             = db.maxHoTs or 3,
                font            = db.font or ADDON_FONT,
                harmful         = false,
                tooltips        = false,
                -- Digits off leaves the cooldown swipe, which is the point:
                -- the icon still shows time passing, just without a number
                -- printed over art that may only be a few pixels wide.
                showDuration    = db.hotShowDuration ~= false,
                includeSpellIDs = AD and AD.HOT_SPELL_TO_CLASS or nil,
                durationPoint   = "CENTER",
                durationX       = 0,
                durationY       = 0,
                durationColor   = { 1, 1, 1, 1 },
                point           = { "TOPLEFT", hotContainer, "TOPLEFT", 0, 0 },
            })
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
    f:Hide()  -- the secure visibility driver takes over from here

    PF.frames[index] = f
    PF.byUnit[unit] = f
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

    -- [12.1] Try the C-side class colour first. It is the only path that
    -- keeps the class colour when the client hides the class token: the
    -- token goes into a C function and the channels come straight back out
    -- into another one, never touching Lua. It only works right here, at
    -- the setter -- the r, g, b return below has to be tested, and testing
    -- a secret channel is what throws.
    local classMode = ((db.healthColor or "class") == "class")
    local painted = classMode and TomoMod_Utils and TomoMod_Utils.ApplyClassColor
        and TomoMod_Utils.ApplyClassColor(f.health, f.unit, "SetStatusBarColor")
    if not painted then
        local r, g, b = GetHealthColor(f.unit, db)
        f.health:SetStatusBarColor(r, g, b, 1)
    end

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
    local role = TomoMod_Utils.SafeGroupRole(f.unit)
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

    local role = TomoMod_Utils.SafeGroupRole(f.unit)
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
-- UPDATE: LEADER ICON
-- =====================================
-- Party frames include the player at index 0, so this covers "I am the
-- leader" as well without a special case. Assistants are deliberately not
-- handled: they only exist in raids, and these are party frames.
function PF.UpdateLeader(f)
    if not f or not f.leaderIcon then return end
    local db = TomoModDB and TomoModDB.partyFrames
    if not db or db.showLeaderIcon == false then f.leaderIcon:Hide(); return end
    if not f.unit or not UnitExists(f.unit) then f.leaderIcon:Hide(); return end

    local ok, isLeader = pcall(UnitIsGroupLeader, f.unit)
    if ok and isLeader == true then
        f.leaderIcon:Show()
    else
        f.leaderIcon:Hide()
    end
end

-- =====================================
-- UPDATE: RAID MARKER
-- =====================================
function PF.UpdateRaidMarker(f)
    if not f or not f.raidMarker then return end
    if not f.unit or not UnitExists(f.unit) then f.raidMarker:Hide(); return end

    local ok, idx = pcall(GetRaidTargetIndex, f.unit)
    if not ok then f.raidMarker:Hide(); return end
    if issecretvalue(idx) then
        -- Midnight secret path: try SetRaidTargetIconTexture via pcall
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
function PF.UpdateReadyCheck(f)
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

function PF.FinishReadyCheck()
    -- Keep icons visible for 6 seconds after check finishes, then hide
    C_Timer.After(6, function()
        for _, f in pairs(PF.frames) do
            if f and f.readyCheck then
                f.readyCheck:Hide()
            end
        end
    end)
end

-- =====================================
-- UPDATE: SUMMON INDICATOR
-- All state handling lives in Interface/Shared/GroupSummon.lua so party and
-- raid can no longer drift apart. Notably it gates on HasIncomingSummon(),
-- without which IncomingSummonStatus keeps reporting Accepted / Declined for
-- a summon the server has already closed — the icon then stayed up until the
-- player reloaded.
-- =====================================
function PF.RefreshSummonAll()
    for _, f in pairs(PF.frames) do
        if f then PF.UpdateSummon(f) end
    end
end

function PF.UpdateSummon(f)
    if not f or not f.summonIndicator then return end

    local GS = TomoMod_GroupSummon
    if not GS then f.summonIndicator:Hide(); return end

    GS.Apply(f.summonIndicator, f.unit, PF.RefreshSummonAll)
end

-- =====================================
-- UPDATE: DEFENSIVE CDs
-- Module-scope tables: rebuilt in place, never reallocated per update.
-- =====================================
local PF_DEF_WANT = { external = true, raidwide = false, personal = false }
local PF_DEF_RESULTS = {}

function PF.UpdateDefensive(f)
    if not f or not f.defensiveContainer then return end

    local db = TomoModDB and TomoModDB.partyFrames
    local DT = TomoMod_DefensiveTrack
    if not DT then return end

    if not db or not db.showDefensives then DT.Clear(f.defensiveContainer); return end
    if not f.unit or not UnitExists(f.unit) then DT.Clear(f.defensiveContainer); return end

    PF_DEF_WANT.external = db.defensiveShowExternals ~= false
    PF_DEF_WANT.raidwide = db.defensiveShowRaidWide == true
    PF_DEF_WANT.personal = db.defensiveShowPersonals == true

    DT.Update(f.defensiveContainer, f.unit, PF_DEF_WANT, db.maxDefensives or 2, PF_DEF_RESULTS)
end

-- =====================================
-- DEBUFF-TYPE ALERT VISUALS
-- =====================================
function PF.ApplyDispelBorderSize(f)
    if not f or not f.dispelHost or not f.dispelHost.engine then return end
    local db = TomoModDB and TomoModDB.partyFrames
    if not db then return end
    local AC = TomoMod_AuraContainer
    if AC and AC.UpdateDispelIndicator then
        AC.UpdateDispelIndicator(f.dispelHost.engine, {
            iconSize   = db.dispelSize or 22,
            borderSize = db.dispelBorderSize or 2,
            showIcon   = db.showDispelIcon ~= false,
            showBorder = db.showDispelBorder ~= false,
            showBleed  = db.showDispelBleed ~= false,
            font       = db.font or ADDON_FONT,
        })
    end
end

-- =====================================
-- UPDATE: DEBUFF-TYPE ALERT
-- =====================================
function PF.UpdateDispel(f)
    if not f or not f.dispelHost then return end
    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.showDispel then f.dispelHost:Hide(); return end
    local unit = f.unit
    if not unit or not UnitExists(unit) then f.dispelHost:Hide(); return end
    f.dispelHost:Show()
    -- The client owns selection/presence for all five typed AuraSlots.
    if f.dispelHost.engine and TomoMod_AuraContainer then
        TomoMod_AuraContainer.SetUnit(f.dispelHost.engine, unit)
    end
end

-- =====================================
-- UPDATE: GROUP BUFF ICON
-- =====================================
function PF.UpdateGroupBuff(f)
    if not f or not f.groupBuff then return end
    if not f.unit or not UnitExists(f.unit) then f.groupBuff:Hide(); return end

    -- [12.1] One question per frame instead of forty protected calls that
    -- would all fail together. The visible result is unchanged -- a scan that
    -- can read nothing found nothing before either -- so what this buys is
    -- the cost, not the outcome.
    if not (TomoMod_Utils and TomoMod_Utils.AurasRestricted and TomoMod_Utils.AurasRestricted())
        and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
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
    PF.UpdateLeader(f)
    PF.UpdateRaidMarker(f)
    PF.UpdateDispel(f)
    PF.UpdateGroupBuff(f)
    PF.UpdateSummon(f)
    PF.UpdateDefensive(f)
    -- HoTs and CDs are updated by their own modules
    if TomoMod_PartyHoTs then TomoMod_PartyHoTs.UpdateUnit(f) end
    if TomoMod_PartyCooldowns then TomoMod_PartyCooldowns.UpdateFrame(f) end
end

-- =====================================
-- RANGE CHECK (event + timer fallback)
-- =====================================

function PF.UpdateRange(f, db)
    if not f or not f.unit then return end

    -- Callers that already hold the settings table pass it in; the event
    -- path and any other caller still gets the lookup.
    db = db or (TomoModDB and TomoModDB.partyFrames)
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

-- Forward-declared: also defined in EVENT HANDLER section
local function GetFrameForUnit(unit)
    -- Was a linear pairs() scan. The UNIT_* events below are registered
    -- globally, so this ran for every unit token the client emits --
    -- nameplate1..40, raid1..40, boss1..8, arena, pets -- and returned nil
    -- almost every time.
    return PF.byUnit[unit]
end

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
    -- UNIT_IN_RANGE_UPDATE above covers the nominal case instantly. This
    -- ticker is only a safety net for transitions that fire no event
    -- (phasing, disconnect, zone change), none of which is perceptible at
    -- half a second -- so it ran forty frames a second in a 40-man for
    -- nothing. Two seconds keeps the net and divides the cost by four.
    rangeTicker = C_Timer.NewTicker(2.0, function()
        local db = TomoModDB and TomoModDB.partyFrames
        if not db or not db.showRange then return end
        -- db passed down so UpdateRange does not re-read it per frame.
        for _, f in pairs(PF.frames) do
            if f and f:IsShown() and f.unit then
                PF.UpdateRange(f, db)
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
            local ra = ROLE_ORDER[TomoMod_Utils.SafeGroupRole(a.unit) or "NONE"] or 4
            local rb = ROLE_ORDER[TomoMod_Utils.SafeGroupRole(b.unit) or "NONE"] or 4
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

    -- Midnight 12.1 / Edit Mode taint hardening:
    -- Do not Hide(), SetParent(), UnregisterAllEvents() or install an OnShow
    -- re-hide hook on CompactPartyFrame/PartyFrame from this module. Blizzard's
    -- Edit Mode previews those frames inside secure execution and any inline
    -- addon work there can poison RefreshTargetAndFocus/RefreshPartyFrames.
    --
    -- The bundled oUF suppression path is shared with Player/Target/Focus and
    -- now uses the engine-side roleset block. Calling it here keeps the stock
    -- party frames suppressed without a TomoMod HookScript on Blizzard frames.
    local ouf = _G.TomoMod_oUF
    if ouf and type(ouf.DisableBlizzard) == "function" then
        ouf:DisableBlizzard("party")
        blizzardHidden = true
        return
    end

    -- Extremely defensive fallback if oUF failed to load. Alpha is visual
    -- only; most importantly this path installs no callback that can execute
    -- inline from Edit Mode's secure Show/SetParent chain.
    if CompactPartyFrame and not InCombatLockdown() then
        pcall(CompactPartyFrame.SetAlpha, CompactPartyFrame, 0)
    end
    if PartyFrame and not InCombatLockdown() then
        pcall(PartyFrame.SetAlpha, PartyFrame, 0)
    end

    blizzardHidden = true
end

-- =====================================
-- EVENT HANDLER
-- =====================================
local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, arg1, ...)
    if not PF.initialized then return end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local f = GetFrameForUnit(arg1)
        if f then
            PF.UpdateHealth(f)
            PF.UpdateAbsorb(f)
            PF.UpdateHealPrediction(f)
        end

    elseif event == "UNIT_FLAGS" or event == "UNIT_CONNECTION" then
        -- UNIT_HEALTH can fire before the dead/ghost flag is cleared during
        -- a resurrection. Repaint on the authoritative unit-state change so
        -- the temporary grey death colour cannot remain stuck until /reload.
        local f = GetFrameForUnit(arg1)
        if f then
            PF.UpdateHealth(f)
            PF.UpdateRange(f)
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
        -- A roster shift can move a different player onto this token
        -- (party2 leaves -> old party3 becomes party2): repaint the whole
        -- frame, not just the name, so class color/absorbs/dispel match
        -- the new occupant even while in combat.
        local f = GetFrameForUnit(arg1)
        if f then PF.UpdateFrame(f) end

    elseif event == "UNIT_AURA" then
        local f = GetFrameForUnit(arg1)
        if f then
            PF.UpdateDispel(f)
            PF.UpdateGroupBuff(f)
            PF.UpdateDefensive(f)
            if TomoMod_PartyHoTs then TomoMod_PartyHoTs.UpdateUnit(f) end
        end

    elseif event == "RAID_TARGET_UPDATE" then
        for _, f in pairs(PF.frames) do
            if f then PF.UpdateRaidMarker(f) end
        end

    elseif event == "READY_CHECK" or event == "READY_CHECK_CONFIRM" then
        for _, f in pairs(PF.frames) do
            if f then PF.UpdateReadyCheck(f) end
        end

    elseif event == "READY_CHECK_FINISHED" then
        PF.FinishReadyCheck()

    elseif event == "INCOMING_SUMMON_CHANGED" then
        PF.RefreshSummonAll()

    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBER_ENABLE"
        or event == "PARTY_MEMBER_DISABLE" then
        PF.RefreshGroup()
        -- A roster shift moves a different player onto a token: re-read the
        -- summon state instead of leaving the previous occupant's icon up.
        PF.RefreshSummonAll()

    elseif event == "PARTY_LEADER_CHANGED" then
        for _, f in pairs(PF.frames) do
            if f then PF.UpdateLeader(f) end
        end

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
            PF.RefreshSummonAll()
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
-- UPDATE ALL VISIBLE FRAMES (combat-safe: non-protected children only)
-- =====================================
function PF.UpdateAllFrames()
    for _, f in pairs(PF.frames) do
        if f and f:IsShown() then
            PF.UpdateFrame(f)
        end
    end
end

-- =====================================
-- REFRESH GROUP: create frames + repaint + layout.
-- Visibility itself is owned by the secure state drivers set in
-- PF.CreateFrame, so it needs no work here — in or out of combat.
-- =====================================
-- The UNIT_* events below are registered globally, so the handler is invoked
-- for every unit token the client emits: nameplate1..40, raid1..40, boss1..8,
-- arena, pets. In a 40-man the party frames are not even shown, and every one
-- of those fired a lookup that returned nothing.
--
-- RegisterUnitEvent per token would be tighter still, but party tokens are
-- reused as the roster shifts and a mis-scoped registration silently stops
-- updating a frame -- a worse failure than the cost it saves. Dropping the
-- whole set while in raid removes the cost exactly where it hurts, and does
-- so with one flag.
local UNIT_EVENTS = {
    "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_HEAL_PREDICTION", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
    "UNIT_NAME_UPDATE", "UNIT_AURA", "UNIT_FLAGS", "UNIT_CONNECTION",
}

function PF.SetUnitEventsEnabled(enabled)
    enabled = enabled and true or false
    if PF._unitEventsOn == enabled then return end
    PF._unitEventsOn = enabled
    for i = 1, #UNIT_EVENTS do
        if enabled then
            eventFrame:RegisterEvent(UNIT_EVENTS[i])
        else
            eventFrame:UnregisterEvent(UNIT_EVENTS[i])
        end
    end
end

function PF.RefreshGroup()
    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.enabled then return end

    -- In a raid the party frames are hidden and the raid module takes over,
    -- so nothing here needs unit updates. GROUP_ROSTER_UPDATE fires on both
    -- transitions, which is what makes this the right place for the gate.
    PF.SetUnitEventsEnabled(not IsInRaid())

    -- [COMBAT] Only frame creation (SetAttribute on secure buttons) and
    -- layout (SetPoint/SetSize on protected frames) must wait for regen.
    -- Repainting already-shown frames is safe: their elements are
    -- non-protected children, and a roster shift can put a different
    -- player behind an existing token.
    if InCombatLockdown() then
        PF._pendingRefresh = true
        PF.UpdateAllFrames()
        return
    end

    -- Lazy creation (out of combat only)
    if not PF.frames[0] then
        PF.CreateFrame(0, "player")
    end
    for i = 1, 4 do
        if not PF.frames[i] then
            PF.CreateFrame(i, "party" .. i)
        end
    end

    PF.UpdateAllFrames()
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
                -- [DRAG] screen-absolute coords instead of GetPoint
                local left, bottom = PF.anchor:GetLeft(), PF.anchor:GetBottom()
                if left and bottom then
                    local scale = PF.anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
                    db.position = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT",
                                    x = left * scale, y = bottom * scale }
                end
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
        -- [DRAG] screen-absolute coords instead of GetPoint
        local left, bottom = anchor:GetLeft(), anchor:GetBottom()
        if db and left and bottom then
            local scale = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
            db.position = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT",
                            x = left * scale, y = bottom * scale }
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

    -- Register events. Logging in already inside a raid must not subscribe:
    -- RefreshGroup would only correct it on the next roster event.
    PF.SetUnitEventsEnabled(not IsInRaid())
    eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    eventFrame:RegisterEvent("READY_CHECK")
    eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
    eventFrame:RegisterEvent("READY_CHECK_FINISHED")
    eventFrame:RegisterEvent("INCOMING_SUMMON_CHANGED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
    eventFrame:RegisterEvent("PARTY_MEMBER_DISABLE")
    eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
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

            -- HoT row. Size and count are live settings, so both the host
            -- frame and the engine group have to follow: without this the
            -- sliders only landed on cells built after the next /reload.
            if f.hotContainer then
                local hotSize = db.hotSize or 12
                local maxHoTs = db.maxHoTs or 3
                f.hotContainer:SetSize(hotSize * maxHoTs + 4, hotSize)
                if f.hotContainer.engine and TomoMod_AuraContainer then
                    TomoMod_AuraContainer.Relayout(f.hotContainer.engine, {
                        size = hotSize, max = maxHoTs,
                        showDuration = db.hotShowDuration ~= false,
                    })
                end
            end

            local lSize = db.leaderIconSize or 14
            if f.leaderIcon then f.leaderIcon:SetSize(lSize, lSize) end
            local rcSize = db.readyCheckSize or 24
            if f.readyCheck then f.readyCheck:SetSize(rcSize, rcSize) end
            local sSize = db.summonSize or 18
            if f.summonIndicator then f.summonIndicator:SetSize(sSize, sSize) end
            PF.ApplyDispelBorderSize(f)
            if f.defensiveContainer and TomoMod_DefensiveTrack then
                TomoMod_DefensiveTrack.Resize(f.defensiveContainer, db.defensiveIconSize or 16, "LEFT")
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

-------------------------------------------------------------------------------
-- BattleText.lua – TomoMod module
-- Scrolling battle text : dégâts et soins entrants/sortants
-- Adapté de TomoBattletext v1.0.0 (standalone → module intégré)
-- Commande : /tm bt
-------------------------------------------------------------------------------

TomoMod_BattleText = TomoMod_BattleText or {}
local BT = TomoMod_BattleText
local L  -- assigné dans Initialize()

-------------------------------------------------------------------------------
-- STATE
-------------------------------------------------------------------------------
local isInitialized = false
local playerGUID
local petGUID_cache = {}

-- Pool de frames réutilisables
local POOL_SIZE = 40
local framePool  = {}
local poolIndex  = 0

-- Conteneurs de défilement
local zones = {}

-------------------------------------------------------------------------------
-- SETTINGS
-------------------------------------------------------------------------------
local function GetDB()
    if TomoModDB and TomoModDB.battleText then
        return TomoModDB.battleText
    end
    return {}
end

local function IsEnabled()
    return GetDB().enabled ~= false
end

-------------------------------------------------------------------------------
-- COULEURS – palette orange & doré, distincte du vert TomoMod
-- (les couleurs des chiffres de combat doivent rester lisibles sur fond sombre)
-------------------------------------------------------------------------------
local COLOR = {
    DMG_OUT       = "|cffFF8C00",   -- orange vif      (dégâts sortants)
    DMG_OUT_CRIT  = "|cffFFD700",   -- or pur           (crit sortant)
    DMG_OUT_DOT   = "|cffFF6600",   -- orange brûlé     (DoT sortant)
    DMG_IN        = "|cffFF4500",   -- orange-rouge     (dégâts entrants)
    DMG_IN_CRIT   = "|cffFF0000",   -- rouge vif        (crit entrant)
    DMG_IN_DOT    = "|cffCC3300",   -- rouge sombre     (DoT entrant)
    HEAL_OUT      = "|cffFFAA00",   -- or ambré         (soin sortant)
    HEAL_OUT_CRIT = "|cffFFE566",   -- or clair         (crit soin sortant)
    HEAL_OUT_HOT  = "|cffFFCC44",   -- or chaud         (HoT sortant)
    HEAL_IN       = "|cffFFCC00",   -- jaune-or         (soin reçu)
    HEAL_IN_CRIT  = "|cffFFFF88",   -- jaune pâle       (crit soin reçu)
    HEAL_IN_HOT   = "|cffFFDD66",   -- dorée            (HoT reçu)
    MISS          = "|cffAAAAAA",   -- gris             (esquive, paré…)
    SPELL         = "|cffFFE4B5",   -- blé              (nom du sort)
    SUFFIX_CRIT   = "|cffFFD700",   -- "!" dorée
}

-------------------------------------------------------------------------------
-- ZONES DE DÉFILEMENT
-------------------------------------------------------------------------------
local ZONE_DEFS = {
    OUTGOING = { width = 220, height = 280, direction = "UP" },
    INCOMING = { width = 220, height = 280, direction = "UP" },
    HEAL_OUT = { width = 200, height = 200, direction = "UP" },
    HEAL_IN  = { width = 200, height = 200, direction = "UP" },
}

-- Positions par défaut (offset depuis CENTER de UIParent)
local ZONE_DEFAULTS = {
    OUTGOING = { x =  250, y =   0 },
    INCOMING = { x = -250, y =   0 },
    HEAL_OUT = { x =  250, y = -290 },
    HEAL_IN  = { x = -250, y = -290 },
}

-------------------------------------------------------------------------------
-- UTILITAIRES
-------------------------------------------------------------------------------
local function FormatNumber(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fk", n / 1000)
    else
        return tostring(n)
    end
end

local function IsPlayerOrPet(guid)
    return guid == playerGUID or petGUID_cache[guid]
end

-------------------------------------------------------------------------------
-- POOL DE FRAMES
-------------------------------------------------------------------------------
local function CreateScrollEntry()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(220, 30)
    f:Hide()

    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER", f, "CENTER", 0, 0)
    fs:SetJustifyH("CENTER")
    f.text = fs

    local ag = f:CreateAnimationGroup()
    ag:SetLooping("NONE")

    local move = ag:CreateAnimation("Translation")
    move:SetOffset(0, 80)
    move:SetDuration(2.0)
    move:SetSmoothing("OUT")

    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.15)
    fadeIn:SetOrder(1)

    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetStartDelay(1.5)
    fadeOut:SetOrder(2)

    f.anim = ag

    ag:SetScript("OnFinished", function()
        f:Hide()
        poolIndex = poolIndex + 1
        framePool[poolIndex] = f
    end)

    return f
end

local function GetPooledFrame()
    if poolIndex > 0 then
        local f = framePool[poolIndex]
        framePool[poolIndex] = nil
        poolIndex = poolIndex - 1
        return f
    end
    return CreateScrollEntry()
end

local function PreFillPool()
    for i = 1, POOL_SIZE do
        poolIndex = poolIndex + 1
        framePool[poolIndex] = CreateScrollEntry()
    end
end

-------------------------------------------------------------------------------
-- ZONES
-------------------------------------------------------------------------------
local function CreateZoneFrame(key)
    local def      = ZONE_DEFS[key]
    local defaults = ZONE_DEFAULTS[key]
    local db       = GetDB()

    -- Assurer que la clé existe en DB
    if not db.zones then db.zones = {} end
    if not db.zones[key] then
        db.zones[key] = { x = defaults.x, y = defaults.y }
    end
    local saved = db.zones[key]

    local f = CreateFrame("Frame", "TomoMod_BTZone_" .. key, UIParent)
    f:SetSize(def.width, def.height)
    f:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
    f:SetFrameStrata("HIGH")
    f:SetClipsChildren(false)

    -- Fond visible uniquement en mode déverrouillé
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.3)
    f.bg = bg

    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOP", f, "TOP", 0, 0)
    lbl:SetText("|cffFFD700" .. (L and L["bt_zone_" .. key:lower()] or key) .. "|r")
    f.label = lbl

    -- Drag
    f:SetMovable(true)
    f:EnableMouse(false)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local sx = UIParent:GetWidth()  / 2
        local sy = UIParent:GetHeight() / 2
        local zdb = GetDB()
        if zdb.zones and zdb.zones[key] then
            zdb.zones[key].x = cx - sx
            zdb.zones[key].y = cy - sy
        end
    end)

    f.key = key

    zones[key] = f
    return f
end

local function ApplyLockVisual(locked)
    for _, zone in pairs(zones) do
        zone.bg:SetShown(not locked)
        zone.label:SetShown(not locked)
        zone:EnableMouse(not locked)
    end
end

-------------------------------------------------------------------------------
-- SCROLL
-------------------------------------------------------------------------------
local function ScrollText(zoneKey, text, isCrit)
    if not IsEnabled() then return end
    local zone = zones[zoneKey]
    if not zone then return end

    local f = GetPooledFrame()
    f:SetParent(zone)

    local spread = (zone:GetWidth() or 220) * 0.35
    local rx = math.random(-spread * 10, spread * 10) / 10
    local ry = math.random(-20, 20)

    f:ClearAllPoints()
    f:SetPoint("BOTTOM", zone, "BOTTOM", rx, ry)

    local db   = GetDB()
    local size = (db.fontSize or 14) + (isCrit and 4 or 0)
    f.text:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    f.text:SetText(text)
    f:SetSize(zone:GetWidth(), size + 8)

    f:Show()
    f:SetAlpha(1)
    f.anim:Stop()
    f.anim:Play()
end

-------------------------------------------------------------------------------
-- FORMATAGE
-------------------------------------------------------------------------------
local function FormatMiss(missType, absorb)
    local label = (L and L["bt_miss_" .. missType:lower()]) or missType
    if missType == "ABSORB" and absorb and absorb > 0 then
        label = label .. " (" .. FormatNumber(absorb) .. ")"
    end
    return COLOR.MISS .. label .. "|r"
end

local function FormatDamage(amount, spellName, isCrit, isDoT, outgoing)
    local col
    if outgoing then
        col = isDoT and COLOR.DMG_OUT_DOT or (isCrit and COLOR.DMG_OUT_CRIT or COLOR.DMG_OUT)
    else
        col = isDoT and COLOR.DMG_IN_DOT  or (isCrit and COLOR.DMG_IN_CRIT  or COLOR.DMG_IN)
    end

    local str = col .. FormatNumber(amount) .. "|r"
    if isCrit then
        str = str .. COLOR.SUFFIX_CRIT .. (L and L["bt_crit"] or "!") .. "|r"
    end
    if spellName then
        str = COLOR.SPELL .. spellName .. "|r " .. str
    end
    return str, isCrit
end

local function FormatHeal(amount, spellName, isCrit, isHoT, outgoing)
    local col
    if outgoing then
        col = isHoT and COLOR.HEAL_OUT_HOT or (isCrit and COLOR.HEAL_OUT_CRIT or COLOR.HEAL_OUT)
    else
        col = isHoT and COLOR.HEAL_IN_HOT  or (isCrit and COLOR.HEAL_IN_CRIT  or COLOR.HEAL_IN)
    end

    local str = col .. "+" .. FormatNumber(amount) .. "|r"
    if isCrit then
        str = str .. COLOR.SUFFIX_CRIT .. (L and L["bt_crit"] or "!") .. "|r"
    end
    if spellName then
        str = COLOR.SPELL .. spellName .. "|r " .. str
    end
    return str, isCrit
end

-------------------------------------------------------------------------------
-- COMBAT LOG
-------------------------------------------------------------------------------
local CLEU_EVENTS = {
    SWING_DAMAGE           = true,
    RANGE_DAMAGE           = true,
    SPELL_DAMAGE           = true,
    SPELL_PERIODIC_DAMAGE  = true,
    ENVIRONMENTAL_DAMAGE   = true,
    SPELL_HEAL             = true,
    SPELL_PERIODIC_HEAL    = true,
    SWING_MISSED           = true,
    RANGE_MISSED           = true,
    SPELL_MISSED           = true,
    SPELL_PERIODIC_MISSED  = true,
}

local function OnCombatLogEvent()
    if not IsEnabled() then return end

    local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _,
          p1, p2, p3, p4, p5, p6, p7, p8, p9, p10 = CombatLogGetCurrentEventInfo()

    if not CLEU_EVENTS[event] then return end

    local srcIsPlayerOrPet = IsPlayerOrPet(sourceGUID)
    local dstIsPlayerOrPet = IsPlayerOrPet(destGUID)
    if not srcIsPlayerOrPet and not dstIsPlayerOrPet then return end

    local db = GetDB()

    -- SWING DAMAGE ─────────────────────────────────────────────────────
    if event == "SWING_DAMAGE" then
        local amount, _, _, _, _, _, crit = p1, p2, p3, p4, p5, p6, p7
        if srcIsPlayerOrPet and db.showOutgoing then
            ScrollText("OUTGOING", FormatDamage(amount, nil, crit, false, true))
        elseif dstIsPlayerOrPet and db.showIncoming then
            ScrollText("INCOMING", FormatDamage(amount, nil, crit, false, false))
        end

    -- RANGE / SPELL DAMAGE ─────────────────────────────────────────────
    elseif event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" then
        local _, spellName, _, amount, _, _, _, _, _, crit = p1, p2, p3, p4, p5, p6, p7, p8, p9, p10
        if srcIsPlayerOrPet and db.showOutgoing then
            ScrollText("OUTGOING", FormatDamage(amount, spellName, crit, false, true))
        elseif dstIsPlayerOrPet and db.showIncoming then
            ScrollText("INCOMING", FormatDamage(amount, spellName, crit, false, false))
        end

    -- PERIODIC DAMAGE (DoT) ────────────────────────────────────────────
    elseif event == "SPELL_PERIODIC_DAMAGE" then
        local _, spellName, _, amount, _, _, _, _, _, crit = p1, p2, p3, p4, p5, p6, p7, p8, p9, p10
        if srcIsPlayerOrPet and db.showOutgoing then
            ScrollText("OUTGOING", FormatDamage(amount, spellName, crit, true, true))
        elseif dstIsPlayerOrPet and db.showIncoming then
            ScrollText("INCOMING", FormatDamage(amount, spellName, crit, true, false))
        end

    -- ENVIRONMENTAL DAMAGE ─────────────────────────────────────────────
    elseif event == "ENVIRONMENTAL_DAMAGE" then
        local hazard, amount = p1, p2
        if dstIsPlayerOrPet and db.showIncoming then
            ScrollText("INCOMING", FormatDamage(amount, hazard, false, false, false))
        end

    -- SPELL HEAL ───────────────────────────────────────────────────────
    elseif event == "SPELL_HEAL" then
        local _, spellName, _, amount, _, _, crit = p1, p2, p3, p4, p5, p6, p7
        if srcIsPlayerOrPet and db.showOutgoing then
            ScrollText("HEAL_OUT", FormatHeal(amount, spellName, crit, false, true))
        end
        if dstIsPlayerOrPet and db.showIncoming then
            ScrollText("HEAL_IN",  FormatHeal(amount, spellName, crit, false, false))
        end

    -- PERIODIC HEAL (HoT) ──────────────────────────────────────────────
    elseif event == "SPELL_PERIODIC_HEAL" then
        local _, spellName, _, amount, _, _, crit = p1, p2, p3, p4, p5, p6, p7
        if srcIsPlayerOrPet and db.showOutgoing then
            ScrollText("HEAL_OUT", FormatHeal(amount, spellName, crit, true, true))
        end
        if dstIsPlayerOrPet and db.showIncoming then
            ScrollText("HEAL_IN",  FormatHeal(amount, spellName, crit, true, false))
        end

    -- SWING MISSED ─────────────────────────────────────────────────────
    elseif event == "SWING_MISSED" then
        local missType, _, absorbed = p1, p2, p3
        if srcIsPlayerOrPet and db.showOutgoing then
            ScrollText("OUTGOING", FormatMiss(missType, absorbed))
        elseif dstIsPlayerOrPet and db.showIncoming then
            ScrollText("INCOMING", FormatMiss(missType, absorbed))
        end

    -- RANGE / SPELL MISSED ─────────────────────────────────────────────
    elseif event == "RANGE_MISSED" or event == "SPELL_MISSED" or event == "SPELL_PERIODIC_MISSED" then
        local _, spellName, _, missType, absorbed = p1, p2, p3, p4, p5
        local missStr = FormatMiss(missType, absorbed)
        if spellName then
            missStr = COLOR.SPELL .. spellName .. "|r " .. missStr
        end
        if srcIsPlayerOrPet and db.showOutgoing then
            ScrollText("OUTGOING", missStr)
        elseif dstIsPlayerOrPet and db.showIncoming then
            ScrollText("INCOMING", missStr)
        end
    end
end

-------------------------------------------------------------------------------
-- SOUS-COMMANDE /tm bt …
-------------------------------------------------------------------------------
local function HandleSubCmd(arg)
    local cmd, val = arg:match("^(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    local db = GetDB()

    if cmd == "" or cmd == "help" then
        print("|cff0cd29fTomoMod BattleText|r — " .. (L and L["bt_cmd_help"] or "/tm bt <cmd>"))
        print("  toggle · lock · reset · incoming · outgoing · size <n>")

    elseif cmd == "toggle" then
        db.enabled = not db.enabled
        print("|cff0cd29fTomoMod BattleText|r " .. (db.enabled
            and (L and L["bt_enabled"]  or "enabled")
            or  (L and L["bt_disabled"] or "disabled")))

    elseif cmd == "lock" then
        BT.ToggleLock()

    elseif cmd == "reset" then
        db.zones = {}
        for key, def in pairs(ZONE_DEFAULTS) do
            db.zones[key] = { x = def.x, y = def.y }
        end
        for key, zone in pairs(zones) do
            local z = db.zones[key]
            zone:ClearAllPoints()
            zone:SetPoint("CENTER", UIParent, "CENTER", z.x, z.y)
        end
        print("|cff0cd29fTomoMod BattleText|r " .. (L and L["bt_reset_done"] or "positions reset."))

    elseif cmd == "incoming" then
        db.showIncoming = not db.showIncoming
        print("|cff0cd29fTomoMod BattleText|r incoming " .. (db.showIncoming and "ON" or "OFF"))

    elseif cmd == "outgoing" then
        db.showOutgoing = not db.showOutgoing
        print("|cff0cd29fTomoMod BattleText|r outgoing " .. (db.showOutgoing and "ON" or "OFF"))

    elseif cmd == "size" then
        local n = tonumber(val)
        if n and n >= 8 and n <= 32 then
            db.fontSize = n
            print("|cff0cd29fTomoMod BattleText|r font size → " .. n)
        else
            print("|cffFF4444Invalid size.|r Use 8–32.")
        end
    else
        print("|cffFF4444Unknown BattleText command.|r Type /tm bt help")
    end
end

-------------------------------------------------------------------------------
-- API PUBLIQUE
-------------------------------------------------------------------------------
function BT.Initialize()
    L = TomoMod_L
    if isInitialized then return end
    isInitialized = true

    -- Pré-remplir le pool (différé au login, pas au chargement du fichier)
    PreFillPool()

    playerGUID = UnitGUID("player")
    local petG = UnitGUID("pet")
    if petG then petGUID_cache[petG] = true end

    -- Créer les quatre zones
    for key in pairs(ZONE_DEFS) do
        if not zones[key] then
            CreateZoneFrame(key)
        end
    end

    -- Restaurer les positions sauvegardées
    local db = GetDB()
    for key, zone in pairs(zones) do
        local z = db.zones and db.zones[key]
        if z then
            zone:ClearAllPoints()
            zone:SetPoint("CENTER", UIParent, "CENTER", z.x, z.y)
        end
        -- Mettre à jour le label maintenant que L est dispo
        local labelKey = "bt_zone_" .. key:lower()
        if L and L[labelKey] then
            zone.label:SetText("|cffFFD700" .. L[labelKey] .. "|r")
        end
    end

    ApplyLockVisual(db.locked ~= false)

    -- Écouter le combat log
    local evFrame = CreateFrame("Frame", "TomoMod_BattleTextEvents")
    evFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    evFrame:RegisterEvent("UNIT_PET")
    evFrame:RegisterEvent("PLAYER_LOGIN")
    evFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            OnCombatLogEvent()
        elseif event == "UNIT_PET" and arg1 == "player" then
            wipe(petGUID_cache)
            local g = UnitGUID("pet")
            if g then petGUID_cache[g] = true end
        elseif event == "PLAYER_LOGIN" then
            playerGUID = UnitGUID("player")
            local g = UnitGUID("pet")
            if g then petGUID_cache[g] = true end
        end
    end)
end

-- Appelé quand les options changent depuis ConfigUI
function BT.ApplySettings()
    local db = GetDB()
    ApplyLockVisual(db.locked ~= false)
end

-- Intégration Movers (Layout Mode)
function BT.ToggleLock()
    local db = GetDB()
    db.locked = not (db.locked ~= false)
    ApplyLockVisual(db.locked)
    if L then
        print("|cff0cd29fTomoMod BattleText|r " ..
            (db.locked and L["bt_zones_locked"] or L["bt_zones_unlocked"]))
    end
end

function BT.IsLocked()
    return GetDB().locked ~= false
end

-- Point d'entrée slash depuis Init.lua (/tm bt …)
function BT.HandleSlash(arg)
    HandleSubCmd(arg or "")
end

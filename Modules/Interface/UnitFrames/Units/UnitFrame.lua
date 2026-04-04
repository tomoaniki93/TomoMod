-- =====================================
-- Units/UnitFrame.lua — Moteur UnitFrame basé sur oUF
-- TomoMod v2.6.0 — Remplace le moteur hardcodé par oUF
-- Supports: player, target, targettarget, pet, focus
-- =====================================

TomoMod_UnitFrames = TomoMod_UnitFrames or {}
local UF = TomoMod_UnitFrames
local E  = UF_Elements

-- [PERF] Local caching des API WoW hot-path
local UnitExists                  = UnitExists
local UnitHealth                  = UnitHealth
local UnitHealthMax               = UnitHealthMax
local UnitGetTotalAbsorbs         = UnitGetTotalAbsorbs
local UnitName                    = UnitName
local UnitLevel                   = UnitLevel
local UnitIsPlayer                = UnitIsPlayer
local UnitIsGroupLeader           = UnitIsGroupLeader
local UnitThreatSituation         = UnitThreatSituation
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitThreatPercentageOfLead  = UnitThreatPercentageOfLead
local GetRaidTargetIndex          = GetRaidTargetIndex
local SetRaidTargetIconTexture    = SetRaidTargetIconTexture
local GetThreatStatusColor        = GetThreatStatusColor
local pairs, wipe                 = pairs, wipe

-- Table des frames par unit (remplie dans Initialize)
local frames   = {}
local isLocked = true

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
-- UPDATE FUNCTIONS
-- Inchangées vs v2.5 — utilisent frame.health / frame.power (aliases oUF).
-- SetMinMaxValues/SetValue sont C-side et acceptent les secret numbers TWW.
-- =====================================

local function UpdateHealth(frame)
    if not frame or not frame.health or not frame.unit then return end
    if not UnitExists(frame.unit) then return end

    local unit     = frame.unit
    local settings = TomoModDB.unitFrames[unit]
    if not settings then return end

    local current = UnitHealth(unit)
    local max     = UnitHealthMax(unit)

    -- C-side — acceptent les secret numbers nativement
    frame.health:SetMinMaxValues(0, max)
    frame.health:SetValue(current)

    -- Couleur
    local r, g, b = E.GetHealthColor(unit, settings)
    frame.health:SetStatusBarColor(r, g, b, 1)

    -- Texte de santé (SetFormattedText est C-side — zéro taint Lua)
    if settings.showHealthText and frame.health.text then
        E.SetHealthText(frame.health.text, current, max, settings.healthTextFormat, unit)
        if frame.health.nameText then
            frame.health.nameText:Show()
        end
    else
        frame.health.text:SetText("")
    end
end

local function UpdateAbsorb(frame)
    if not frame or not frame.absorb then return end
    if not UnitExists(frame.unit) then return end

    local absorb = UnitGetTotalAbsorbs(frame.unit)
    local max    = UnitHealthMax(frame.unit)

    frame.absorb:SetMinMaxValues(0, max)
    frame.absorb:SetValue(absorb)
    frame.absorb:Show()
end

local function UpdateName(frame)
    if not frame or not frame.health or not frame.health.nameText then return end
    if not UnitExists(frame.unit) then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showName then
        frame.health.nameText:SetText("")
        return
    end

    -- Couleur
    if UnitIsPlayer(frame.unit) then
        local r, g, b = TomoMod_Utils.GetClassColor(frame.unit)
        frame.health.nameText:SetTextColor(r, g, b, 1)
    else
        frame.health.nameText:SetTextColor(1, 1, 1, 0.95)
    end

    -- TWW: name = secret string → troncature via clip C-side (SetWidth)
    local name = UnitName(frame.unit)
    if not name then frame.health.nameText:SetText(""); return end

    local nameFS = frame.health.nameText
    if settings.nameTruncate and settings.nameTruncateLength then
        local dbFontSize = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.fontSize) or 12
        local maxWidth   = settings.nameTruncateLength * dbFontSize * 0.55
        nameFS:SetWidth(maxWidth)
        nameFS:SetWordWrap(false)
        nameFS:SetNonSpaceWrap(false)
    else
        nameFS:SetWidth(settings.width - 12)
        nameFS:SetWordWrap(false)
        nameFS:SetNonSpaceWrap(false)
    end

    if settings.showLevel then
        local level = UnitLevel(frame.unit)
        frame.health.nameText:SetFormattedText("%d - %s", level, name)
        if frame.health.levelText then
            frame.health.levelText:SetText("")
        end
    else
        frame.health.nameText:SetFormattedText("%s", name)
    end
end

local function UpdateLevel(frame)
    if not frame or not frame.health or not frame.health.levelText then return end
    if not UnitExists(frame.unit) then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showLevel then
        frame.health.levelText:SetText("")
        return
    end

    -- Si showName aussi, le niveau est affiché combiné dans nameText
    if settings.showName then
        frame.health.levelText:SetText("")
        return
    end

    local level = UnitLevel(frame.unit)
    frame.health.levelText:SetTextColor(1, 0.82, 0, 0.9)
    frame.health.levelText:SetFormattedText("%d", level)
end

local function UpdateThreat(frame)
    if not frame or not frame.threat then return end
    if not UnitExists(frame.unit) then
        frame.threat:Hide()
        return
    end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showThreat then
        frame.threat:Hide()
        return
    end

    local status = UnitThreatSituation("player", frame.unit)
    if status and status >= 2 then
        local r, g, b = GetThreatStatusColor(status)
        frame.threat:SetThreatColor(r, g, b)
        frame.threat:Show()
    else
        frame.threat:Hide()
    end
end

-- =====================================
-- UPDATE THREAT TEXT
-- TWW: UnitDetailedThreatSituation / UnitThreatPercentageOfLead
-- retournent des secret floats — passés UNIQUEMENT à SetFormattedText (C-side).
-- =====================================
local function UpdateThreatText(frame, forcePreview)
    if not frame or not frame.threatText then return end

    local unit     = frame.unit
    local settings = TomoModDB.unitFrames[unit]
    local tt       = settings and settings.threatText
    if not tt or not tt.enabled then
        frame.threatText:Hide()
        return
    end

    if forcePreview then
        frame.threatText:SetTextColor(0.6, 0.6, 0.6, 1)
        frame.threatText:SetText("0%")
        frame.threatText:Show()
        return
    end

    if not UnitExists(unit) or UnitIsPlayer(unit) then
        frame.threatText:Hide()
        return
    end

    local status = UnitThreatSituation("player", unit)
    if not status or status == 0 then
        frame.threatText:Hide()
        return
    end

    local r, g, b = GetThreatStatusColor(status)
    frame.threatText:SetTextColor(r, g, b, 1)

    if status >= 3 then
        local lead = UnitThreatPercentageOfLead("player", unit)
        if lead then
            frame.threatText:SetFormattedText("+%1.0f%%", lead)
        else
            local _, _, pct = UnitDetailedThreatSituation("player", unit)
            frame.threatText:SetFormattedText("%1.0f%%", pct or 0)
        end
    else
        local _, _, pct = UnitDetailedThreatSituation("player", unit)
        frame.threatText:SetFormattedText("%1.0f%%", pct or 0)
    end

    frame.threatText:Show()
end

local function UpdateRaidIcon(frame)
    if not frame or not frame.health or not frame.health.raidIcon then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showRaidIcon then
        frame.health.raidIcon:Hide()
        return
    end
    if not UnitExists(frame.unit) then
        frame.health.raidIcon:Hide()
        return
    end

    -- TWW: GetRaidTargetIndex retourne un secret number — SetRaidTargetIconTexture est C-side
    local index = GetRaidTargetIndex(frame.unit)
    if index then
        SetRaidTargetIconTexture(frame.health.raidIcon, index)
        frame.health.raidIcon:Show()
    else
        frame.health.raidIcon:Hide()
    end
end

local function UpdateLeaderIcon(frame)
    if not frame or not frame.health or not frame.health.leaderIcon then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showLeaderIcon then
        frame.health.leaderIcon:Hide()
        return
    end
    if not UnitExists(frame.unit) then
        frame.health.leaderIcon:Hide()
        return
    end

    if UnitIsGroupLeader(frame.unit) then
        frame.health.leaderIcon:Show()
    else
        frame.health.leaderIcon:Hide()
    end
end

-- =====================================
-- HIDE BLIZZARD EXTRA
-- oUF:DisableBlizzard(unit) est appelé AUTOMATIQUEMENT par oUF:Spawn
-- et gère: PlayerFrame, TargetFrame, FocusFrame, PetFrame.
-- On gère ici les castbars Blizzard et l'overlay d'action bar.
-- =====================================
local function HideBlizzardExtra()
    -- Castbars Blizzard (TWW: PlayerCastingBarFrame, PetCastingBarFrame)
    for _, castName in ipairs({ "PlayerCastingBarFrame", "PetCastingBarFrame" }) do
        local castFrame = _G[castName]
        if castFrame then
            castFrame:UnregisterAllEvents()
            castFrame:Hide()
            castFrame:ClearAllPoints()
            castFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -9999, 9999)
            castFrame:SetAlpha(0)
        end
    end

    -- TWW: ActionBarActionEventsFrame affiche un overlay de cast sur les boutons d'action
    if ActionBarActionEventsFrame then
        local castEvents = {
            "UNIT_SPELLCAST_START",         "UNIT_SPELLCAST_STOP",
            "UNIT_SPELLCAST_FAILED",        "UNIT_SPELLCAST_INTERRUPTED",
            "UNIT_SPELLCAST_DELAYED",       "UNIT_SPELLCAST_CHANNEL_START",
            "UNIT_SPELLCAST_CHANNEL_STOP",  "UNIT_SPELLCAST_CHANNEL_UPDATE",
            "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
        }
        for _, ev in ipairs(castEvents) do
            ActionBarActionEventsFrame:UnregisterEvent(ev)
        end
    end
end

-- =====================================
-- oUF STYLE FUNCTION
-- Appelée par oUF:Spawn pour chaque frame créée.
-- self = frame oUF (SecureUnitButtonTemplate)
-- unit = unité ("player", "target", etc.)
-- =====================================
local function StyleTomoMod(self, unit)
    local db = TomoModDB
    if not db or not db.unitFrames then return end
    local settings = db.unitFrames[unit]
    if not settings then return end

    self:SetSize(settings.width, settings.healthHeight + (settings.powerHeight or 0))
    self:SetAttribute("type1", "target")
    self:SetAttribute("type2", "togglemenu")
    self:RegisterForClicks("AnyDown", "AnyUp")

    -- ── Health (élément oUF géré) ────────────────────────────────
    local health = E.CreateHealth(self, unit, settings)
    -- oUF canonique + alias TomoMod (garde toutes les fonctions Update* intactes)
    self.Health = health
    self.health = health

    -- Override oUF : remplace le handler par défaut de l'élément Health.
    -- Signature : (parentFrame, event, unit) — self ici = parent frame.
    self.Health.Override = function(oufFrame, event, u)
        UpdateHealth(oufFrame)
        UpdateAbsorb(oufFrame)
        UpdateName(oufFrame)
        UpdateLevel(oufFrame)
        UpdateRaidIcon(oufFrame)
        UpdateLeaderIcon(oufFrame)
    end

    -- ── Power (élément oUF géré) ─────────────────────────────────
    if settings.powerHeight and settings.powerHeight > 0 then
        local power = E.CreatePower(self, unit, settings)
        if power then
            power:SetPoint("TOP", health, "BOTTOM", 0, 0)
            self.Power = power
            self.power = power  -- alias TomoMod
            self.Power.Override = function(oufFrame, event, u)
                E.UpdatePower(oufFrame)
            end
        end
    end

    -- ── Absorb (custom — pas un élément oUF) ────────────────────
    if settings.showAbsorb then
        self.absorb = E.CreateAbsorb(self, health, settings)
    end

    -- ── Indicateur de menace glow (custom) ──────────────────────
    if settings.showThreat then
        self.threat = E.CreateThreatIndicator(health)
    end

    -- ── Texte de menace % (custom) ───────────────────────────────
    if settings.threatText and settings.threatText.enabled then
        self.threatText = E.CreateThreatText(health, settings)
    end

    -- ── Castbar (custom — entièrement auto-géré) ─────────────────
    if settings.castbar and settings.castbar.enabled then
        self.castbar = E.CreateCastbar(self, unit, settings)
    end

    -- ── Auras (custom) ───────────────────────────────────────────
    if settings.auras and settings.auras.enabled then
        self.auraContainer = E.CreateAuraContainer(self, unit, settings)
    end

    -- ── Buffs ennemis (custom) ───────────────────────────────────
    if settings.enemyBuffs and settings.enemyBuffs.enabled then
        self.enemyBuffContainer = E.CreateEnemyBuffContainer(self, unit, settings)
    end

    -- ── Drag ─────────────────────────────────────────────────────
    -- La position est appliquée dans Initialize après tous les Spawns.
    TomoMod_Utils.SetupDraggable(self, function()
        if settings.anchorTo and frames[settings.anchorTo] then
            local anchor   = frames[settings.anchorTo]
            local sx, sy   = self:GetCenter()
            local ax, ay   = anchor:GetCenter()
            if sx and sy and ax and ay then
                local dx = sx - ax
                local dy = sy - ay
                self:ClearAllPoints()
                self:SetPoint("CENTER", anchor, "CENTER", dx, dy)
                settings.position = { point = "CENTER", relativePoint = "CENTER", x = dx, y = dy }
            end
        else
            local point, _, relativePoint, x, y = self:GetPoint()
            settings.position               = settings.position or {}
            settings.position.point         = point
            settings.position.relativePoint = relativePoint
            settings.position.x             = x
            settings.position.y             = y
        end
    end)
end

-- =====================================
-- ÉVÉNEMENTS SUPPLÉMENTAIRES
-- oUF gère automatiquement:
--   UNIT_HEALTH, UNIT_MAXHEALTH         → Health.Override
--   UNIT_POWER_UPDATE, UNIT_MAXPOWER    → Power.Override
--   PLAYER_TARGET_CHANGED               → UpdateAllElements sur target
--   PLAYER_FOCUS_CHANGED                → UpdateAllElements sur focus
--   UNIT_PET                            → UpdateAllElements sur pet
--   PLAYER_ENTERING_WORLD               → UpdateAllElements sur tous
--   RegisterUnitWatch                   → visibilité automatique
-- On complète ici: menace, absorbs, auras, icônes.
-- =====================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_TARGET_CHANGED" then
        local f = frames.target
        if f then
            UpdateThreat(f)
            UpdateThreatText(f)
            E.UpdateAuras(f)
            E.UpdateEnemyBuffs(f)
        end

    elseif event == "PLAYER_FOCUS_CHANGED" then
        local f = frames.focus
        if f then
            UpdateThreat(f)
            E.UpdateAuras(f)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Délai C_Timer pour que les données de l'unité soient disponibles
        C_Timer.After(0, function()
            for _, f in pairs(frames) do
                UpdateThreat(f)
                UpdateThreatText(f)
                E.UpdateAuras(f)
                E.UpdateEnemyBuffs(f)
            end
        end)

    elseif event == "UNIT_PET" then
        local f = frames.pet
        if f then E.UpdateAuras(f) end

    elseif event == "RAID_TARGET_UPDATE" then
        for _, f in pairs(frames) do UpdateRaidIcon(f) end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
        for _, f in pairs(frames) do UpdateLeaderIcon(f) end
    end
end)

-- ── Événements par unit (menace, absorb, auras) ─────────────────
-- Enregistrés après que les frames soient créées dans Initialize.
local unitSupplementaryFrames = {}

local function RegisterSupplementaryEvents()
    for unit, _ in pairs(frames) do
        if not unitSupplementaryFrames[unit] then
            local uef = CreateFrame("Frame")
            uef:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", unit)
            uef:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED",   unit)
            uef:RegisterUnitEvent("UNIT_AURA",                    unit)
            uef:SetScript("OnEvent", function(_, event, u)
                local frame = frames[u]
                if not frame then return end

                if event == "UNIT_THREAT_SITUATION_UPDATE" then
                    UpdateThreat(frame)
                    UpdateThreatText(frame)
                    -- Rafraîchir la couleur de santé (menace → GetHealthColor)
                    if frame.Health and frame.Health.ForceUpdate then
                        frame.Health:ForceUpdate()
                    else
                        UpdateHealth(frame)
                    end

                elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
                    UpdateAbsorb(frame)

                elseif event == "UNIT_AURA" then
                    E.UpdateAuras(frame)
                    E.UpdateEnemyBuffs(frame)
                end
            end)
            unitSupplementaryFrames[unit] = uef
        end
    end
end

-- =====================================
-- API PUBLIQUE
-- =====================================

function UF.IsLocked()
    return isLocked
end

function UF.ToggleLock()
    isLocked = not isLocked

    for unit, frame in pairs(frames) do
        if not isLocked then
            -- Déverrouillé: retirer RegisterUnitWatch pour garder la frame visible lors du drag
            UnregisterUnitWatch(frame)
            frame:Show()
            if frame.auraContainer then
                frame.auraContainer:EnableMouse(true)
                frame.auraContainer:Show()
            end
            if frame.enemyBuffContainer then
                frame.enemyBuffContainer:EnableMouse(true)
                frame.enemyBuffContainer:Show()
            end
        else
            -- Verrouillé: réactiver RegisterUnitWatch
            if not InCombatLockdown() then
                frame:SetAttribute("unit", unit)
                RegisterUnitWatch(frame)
            end
            if frame.auraContainer then
                frame.auraContainer:EnableMouse(false)
            end
            if frame.enemyBuffContainer then
                frame.enemyBuffContainer:EnableMouse(false)
            end

            -- Ré-ancrer les frames anchorTo (ToT, Pet) à leur parent avec le bon offset
            local unitSettings = TomoModDB.unitFrames[unit]
            if unitSettings and unitSettings.anchorTo and frames[unitSettings.anchorTo] then
                local pos = unitSettings.position
                frame:ClearAllPoints()
                frame:SetPoint(
                    pos.point or "TOPLEFT",
                    frames[unitSettings.anchorTo],
                    pos.relativePoint or "TOPRIGHT",
                    pos.x or 8,
                    pos.y or 0
                )
            end

            -- Ré-ancrer la castbar au parent (StartMoving peut corrompre les anchors enfants)
            if frame.castbar and unit ~= "player" then
                local cbPos   = unitSettings and unitSettings.castbar and unitSettings.castbar.position
                local offsets = unitSettings and unitSettings.elementOffsets and unitSettings.elementOffsets.castbar
                frame.castbar:ClearAllPoints()
                frame.castbar:SetPoint(
                    (cbPos and cbPos.point) or "TOP",
                    frame,
                    (cbPos and cbPos.relativePoint) or "BOTTOM",
                    ((cbPos and cbPos.x) or 0) + (offsets and offsets.x or 0),
                    ((cbPos and cbPos.y) or -6) + (offsets and offsets.y or 0)
                )
            end

            -- Mise à jour complète via oUF si disponible, sinon manuelle
            if UnitExists(unit) then
                if frame.UpdateAllElements then
                    frame:UpdateAllElements("ToggleLock")
                else
                    UpdateHealth(frame)
                    UpdateAbsorb(frame)
                    if frame.power then E.UpdatePower(frame) end
                    UpdateName(frame)
                    UpdateLevel(frame)
                    UpdateThreat(frame)
                    UpdateThreatText(frame)
                    UpdateRaidIcon(frame)
                    UpdateLeaderIcon(frame)
                    E.UpdateAuras(frame)
                    E.UpdateEnemyBuffs(frame)
                end
            end
        end
    end

    if isLocked then
        print("|cff0cd29fTomoMod UF:|r " .. TomoMod_L["msg_uf_locked"])
    else
        print("|cff0cd29fTomoMod UF:|r " .. TomoMod_L["msg_uf_unlocked"])
    end

    -- Sync BossFrames
    if TomoMod_BossFrames and TomoMod_BossFrames.ToggleLock then
        TomoMod_BossFrames.ToggleLock()
    end
end

-- Helpers castbar player (pour le système Movers)
function UF.IsPlayerCastbarLocked()
    local frame = frames["player"]
    if not frame or not frame.castbar then return true end
    local cb = frame.castbar
    return cb.IsLocked and cb:IsLocked() or true
end

function UF.UnlockPlayerCastbar()
    local frame = frames["player"]
    if not frame or not frame.castbar then return end
    local cb = frame.castbar
    if cb.SetLocked and cb:IsLocked() then
        cb:SetLocked(false)
        cb:ShowPreview()
    end
end

function UF.LockPlayerCastbar()
    local frame = frames["player"]
    if not frame or not frame.castbar then return end
    local cb = frame.castbar
    if cb.SetLocked and not cb:IsLocked() then
        cb:SetLocked(true)
        cb:HidePreview()
    end
end

function UF.TogglePlayerCastbarLock()
    local frame = frames["player"]
    if not frame or not frame.castbar then return end
    local cb = frame.castbar
    if cb.SetLocked then
        local newLocked = not cb.isLocked
        cb:SetLocked(newLocked)
        if not newLocked then
            cb:ShowPreview()
        else
            cb:HidePreview()
        end
    end
end

function UF.RefreshUnit(unitKey)
    local frame    = frames[unitKey]
    local settings = TomoModDB.unitFrames[unitKey]
    if not frame or not settings then return end

    local globalDB    = TomoModDB.unitFrames
    local font        = globalDB.fontFamily or globalDB.font or "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    local fontSize    = globalDB.fontSize or 12
    local fontOutline = globalDB.fontOutline or "OUTLINE"

    frame:SetSize(settings.width, settings.healthHeight + (settings.powerHeight or 0))
    frame.health:SetSize(settings.width, settings.healthHeight)

    if frame.health.text     then frame.health.text:SetFont(font, fontSize,     fontOutline) end
    if frame.health.nameText then frame.health.nameText:SetFont(font, fontSize - 1, fontOutline) end
    if frame.health.levelText then frame.health.levelText:SetFont(font, fontSize - 2, fontOutline) end

    if frame.power and settings.powerHeight then
        frame.power:SetSize(settings.width, settings.powerHeight)
        if frame.power.text then frame.power.text:SetFont(font, 8, fontOutline) end
    end

    if frame.castbar and settings.castbar then
        frame.castbar:SetSize(settings.castbar.width, settings.castbar.height)
        local cbFontSize = math.max(8, settings.castbar.height - 8)
        if frame.castbar.spellText then frame.castbar.spellText:SetFont(font, cbFontSize, fontOutline) end
        if frame.castbar.timerText then frame.castbar.timerText:SetFont(font, cbFontSize, fontOutline) end
    end

    -- Offsets d'éléments
    local offsets = settings.elementOffsets
    if offsets then
        if frame.health.nameText and offsets.name then
            frame.health.nameText:ClearAllPoints()
            frame.health.nameText:SetPoint("LEFT", offsets.name.x, offsets.name.y)
        end
        if frame.health.levelText and offsets.level then
            frame.health.levelText:ClearAllPoints()
            frame.health.levelText:SetPoint("RIGHT", offsets.level.x, offsets.level.y)
        end
        if frame.health.text and offsets.healthText then
            frame.health.text:ClearAllPoints()
            frame.health.text:SetPoint("CENTER", offsets.healthText.x, offsets.healthText.y)
        end
        if frame.power and offsets.power then
            frame.power:ClearAllPoints()
            frame.power:SetPoint("TOP", frame.health, "BOTTOM", offsets.power.x, offsets.power.y)
        end
        if frame.castbar and settings.castbar and offsets.castbar and unitKey ~= "player" then
            local cbPos = settings.castbar.position
            if cbPos then
                frame.castbar:ClearAllPoints()
                frame.castbar:SetPoint(
                    cbPos.point or "TOP", frame, cbPos.relativePoint or "BOTTOM",
                    (cbPos.x or 0) + offsets.castbar.x,
                    (cbPos.y or -6) + offsets.castbar.y
                )
            end
        end
        if frame.auraContainer and offsets.auras then
            local auraPos = settings.auras and settings.auras.position
            if auraPos then
                frame.auraContainer:ClearAllPoints()
                frame.auraContainer:SetPoint(
                    auraPos.point or "BOTTOMLEFT", frame, auraPos.relativePoint or "TOPLEFT",
                    (auraPos.x or 0) + offsets.auras.x,
                    (auraPos.y or 6) + offsets.auras.y
                )
            end
        end
    end

    -- Raid icon offset
    if frame.health and frame.health.raidIcon and settings.raidIconOffset then
        local ofs = settings.raidIconOffset
        frame.health.raidIcon:ClearAllPoints()
        frame.health.raidIcon:SetPoint("BOTTOM", frame.health, "TOP", ofs.x, ofs.y)
    end

    -- Leader icon offset
    if frame.health and frame.health.leaderIcon and settings.leaderIconOffset then
        local ofs = settings.leaderIconOffset
        frame.health.leaderIcon:ClearAllPoints()
        frame.health.leaderIcon:SetPoint("BOTTOMLEFT", frame.health, "TOPLEFT", ofs.x, ofs.y)
    end

    -- Threat text — repositionnement et taille police
    if frame.threatText then
        local tt    = settings.threatText
        local fsize = (tt and tt.fontSize) or 13
        local ox    = (tt and tt.offsetX) or 0
        local oy    = (tt and tt.offsetY) or 0
        frame.threatText:SetFont(font, fsize, fontOutline)
        frame.threatText:ClearAllPoints()
        frame.threatText:SetPoint("CENTER", frame.health, "CENTER", ox, oy)
    elseif settings.threatText and settings.threatText.enabled then
        frame.threatText = E.CreateThreatText(frame.health, settings)
    end

    -- Redimensionner les icônes d'aura
    if frame.auraContainer and frame.auraContainer.icons and settings.auras then
        local auraSize = settings.auras.size or 30
        local spacing  = settings.auras.spacing or 3
        frame.auraContainer:SetSize(300, auraSize + 4)
        for idx, icon in ipairs(frame.auraContainer.icons) do
            icon:SetSize(auraSize, auraSize)
            if icon.texture then icon.texture:SetAllPoints(icon) end
            icon:ClearAllPoints()
            if idx == 1 then
                icon:SetPoint("LEFT", 0, 0)
            else
                icon:SetPoint("LEFT", frame.auraContainer.icons[idx - 1], "RIGHT", spacing, 0)
            end
        end
    end

    -- Enemy Buff Container
    if settings.enemyBuffs then
        local eb = frame.enemyBuffContainer
        if eb then
            local wantedEnabled = settings.enemyBuffs.enabled
            local wantedSize    = settings.enemyBuffs.size     or 24
            local wantedMax     = settings.enemyBuffs.maxAuras or 4
            local currentSize   = eb._tomoSize    or 0
            local currentMax    = eb._tomoMaxAuras or 0
            if not wantedEnabled then
                eb:Hide()
            elseif currentSize ~= wantedSize or currentMax ~= wantedMax then
                eb:Hide()
                eb:SetParent(nil)
                frame.enemyBuffContainer = nil
                E.UpdateEnemyBuffs(frame)
            end
        elseif settings.enemyBuffs.enabled then
            E.UpdateEnemyBuffs(frame)
        end
    end

    -- Mise à jour visuelle via oUF:UpdateAllElements si disponible
    if frame.UpdateAllElements then
        frame:UpdateAllElements("RefreshUnit")
    else
        UpdateHealth(frame)
        UpdateAbsorb(frame)
        if frame.power then E.UpdatePower(frame) end
        UpdateName(frame)
        UpdateLevel(frame)
        UpdateThreat(frame)
        UpdateThreatText(frame)
        UpdateRaidIcon(frame)
        UpdateLeaderIcon(frame)
        E.UpdateAuras(frame)
        E.UpdateEnemyBuffs(frame)
    end
end

-- Preview de la menace (appelé par ConfigUI OnShow/OnHide)
function UF.RefreshThreatPreview(enabled)
    local targetFrame = frames["target"]
    if not targetFrame or not targetFrame.threatText then return end
    local settings = TomoModDB.unitFrames and TomoModDB.unitFrames["target"]
    local tt = settings and settings.threatText
    if not tt or not tt.enabled then return end
    UpdateThreatText(targetFrame, enabled and true or false)
end

function UF.RefreshAllUnits()
    for _, unitKey in ipairs({ "player", "target", "focus", "targettarget", "pet" }) do
        if frames[unitKey] then
            UF.RefreshUnit(unitKey)
        end
    end
    if TomoMod_BossFrames and TomoMod_BossFrames.RefreshAll then
        TomoMod_BossFrames.RefreshAll()
    end
end

-- =====================================
-- INITIALIZE — Spawn des frames via oUF:Factory
-- oUF:Factory s'exécute immédiatement puisqu'on est
-- dans le handler PLAYER_LOGIN de Init.lua (IsLoggedIn() = true).
-- =====================================
function UF.Initialize()
    if not TomoModDB or not TomoModDB.unitFrames then return end
    if not TomoModDB.unitFrames.enabled then return end

    local oUF = TomoMod_oUF
    if not oUF then
        print("|cffff0000TomoMod UF:|r Bibliothèque oUF introuvable (X-oUF: TomoMod_oUF)!")
        return
    end

    oUF:Factory(function(ouf)
        -- Enregistrer le style et l'activer avant tout Spawn
        ouf:RegisterStyle("TomoMod", StyleTomoMod)
        ouf:SetActiveStyle("TomoMod")

        -- Spawn des frames actives dans l'ordre de construction
        local buildOrder = { "player", "target", "focus", "targettarget", "pet" }
        for _, unit in ipairs(buildOrder) do
            local settings = TomoModDB.unitFrames[unit]
            if settings and settings.enabled then
                -- ouf:Spawn crée la frame, appelle StyleTomoMod,
                -- puis appelle oUF:DisableBlizzard(unit) automatiquement.
                local f = ouf:Spawn(unit, "TomoMod_UF_" .. unit)
                frames[unit] = f
            end
        end

        -- ── Positionnement initial ──────────────────────────────────
        -- Frames autonomes (player, target, focus) → ancrées à UIParent
        for _, unit in ipairs({ "player", "target", "focus" }) do
            local f        = frames[unit]
            local settings = TomoModDB.unitFrames[unit]
            if f and settings and settings.position then
                local pos = settings.position
                f:ClearAllPoints()
                f:SetPoint(
                    pos.point or "CENTER", UIParent,
                    pos.relativePoint or "CENTER",
                    pos.x or 0, pos.y or 0
                )
            end
        end

        -- Frames ancrées (ToT → Target, Pet → Player)
        for _, unit in ipairs({ "targettarget", "pet" }) do
            local f        = frames[unit]
            local settings = TomoModDB.unitFrames[unit]
            if f and settings then
                if settings.anchorTo and frames[settings.anchorTo] then
                    local pos = settings.position
                    f:ClearAllPoints()
                    f:SetPoint(
                        pos.point or "TOPLEFT",
                        frames[settings.anchorTo],
                        pos.relativePoint or "TOPRIGHT",
                        pos.x or 8, pos.y or 0
                    )
                elseif settings.position then
                    local pos = settings.position
                    f:ClearAllPoints()
                    f:SetPoint(
                        pos.point or "CENTER", UIParent,
                        pos.relativePoint or "CENTER",
                        pos.x or 0, pos.y or 0
                    )
                end
            end
        end

        -- ── Castbars Blizzard + ActionBar cast overlay ──────────────
        if TomoModDB.unitFrames.hideBlizzardFrames then
            HideBlizzardExtra()
        end

        -- ── Événements supplémentaires (menace, absorb, auras) ──────
        RegisterSupplementaryEvents()

        -- ── Updater de durée des auras ──────────────────────────────
        E.StartAuraDurationUpdater(frames)

        -- ── Appliquer tailles, polices et offsets ───────────────────
        UF.RefreshAllUnits()

        print("|cff0cd29fTomoMod UF:|r " .. TomoMod_L["msg_uf_initialized"])
    end)
end

-- =====================================
-- ENREGISTREMENT DU MODULE
-- =====================================
TomoMod_RegisterModule("unitFrames", UF)

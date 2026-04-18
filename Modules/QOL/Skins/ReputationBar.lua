-- =====================================
-- ReputationBar.lua — Barre de réputation personnalisée
-- Gère : factions traditionnelles, Renown (TWW/DF), Paragon
-- =====================================

TomoMod_ReputationBar = TomoMod_ReputationBar or {}
local RB = TomoMod_ReputationBar
local L  = TomoMod_L

-- Couleurs par standing (1=Hostile … 8=Exalted)
local STANDING_COLORS = {
    [1] = { 0.80, 0.13, 0.13 },  -- Hostile
    [2] = { 0.93, 0.35, 0.18 },  -- Unfriendly
    [3] = { 0.93, 0.67, 0.13 },  -- Neutral
    [4] = { 0.93, 0.86, 0.13 },  -- Friendly
    [5] = { 0.13, 0.73, 0.20 },  -- Honored
    [6] = { 0.13, 0.73, 0.60 },  -- Revered
    [7] = { 0.00, 0.55, 1.00 },  -- Exalted
    [8] = { 0.00, 0.55, 1.00 },  -- Paragon base
}
local RENOWN_COLOR  = { 0.60, 0.30, 1.00 }
local PARAGON_COLOR = { 1.00, 0.80, 0.10 }

local STANDING_LABELS = {
    [1] = "Hostile",    [2] = "Inamical",
    [3] = "Neutre",     [4] = "Aimable",
    [5] = "Honoré",     [6] = "Révéré",
    [7] = "Exalté",     [8] = "Exalté",
}

local repBar     = nil
local factionText  = nil
local standingText = nil
local pctText      = nil
local valueText    = nil
local isLocked     = true
local updateFrame  = nil

-- =====================================
-- HELPERS
-- =====================================

local function FormatRepValue(v)
    if v >= 1000 then
        return string.format("%.1fk", v / 1000)
    end
    return tostring(v)
end

local function GetStandingLabel(reaction)
    return STANDING_LABELS[reaction] or "Inconnu"
end

-- =====================================
-- =====================================
-- SUPPRESS BLIZZARD REP BAR
-- =====================================

-- [TWW TAINT] MainStatusTrackingBarContainer and ReputationWatchBar are touched by
-- Blizzard secure code (notably during UI scaling and keybind clearing). The pattern
-- `hooksecurefunc(frame, "Show", function(self) self:Hide() end)` propagates taint
-- because our insecure Hide() forces a state mismatch Blizzard's secure pipeline
-- wasn't expecting.
--
-- Safe replacement: SetAlpha(0) from within the hook. The frame remains "shown"
-- logically (no state mismatch for Blizzard), but is visually invisible.
-- EnableMouse(false) prevents it from eating clicks.
local _tmHiddenRepFrames = {}

local function SuppressBlizzRepBar()
    local db = TomoModDB and TomoModDB.reputationBar
    if not db or not db.hideBlizzRepBar then return end

    local function tryHide(f)
        if not f or f._tmRepHidden then return end
        f._tmRepHidden = true
        f:SetAlpha(0)
        if f.EnableMouse then f:EnableMouse(false) end
        _tmHiddenRepFrames[#_tmHiddenRepFrames + 1] = f
        if f.Show then
            hooksecurefunc(f, "Show", function(self)
                if self._tmRepHidden then self:SetAlpha(0) end
            end)
        end
    end

    tryHide(_G["ReputationWatchBar"])
    tryHide(_G["MainStatusTrackingBarContainer"])
    tryHide(_G["MainStatusTrackingBarContainer2"])

    if StatusTrackingBarManager and StatusTrackingBarManager.UpdateBarsShown then
        hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", function()
            local f = _G["ReputationWatchBar"]
            if f and f._tmRepHidden then f:SetAlpha(0) end
        end)
    end
end

-- =====================================
-- UPDATE
-- =====================================

local function UpdateBar()
    if not repBar or not isLocked then return end
    local db = TomoModDB and TomoModDB.reputationBar
    if not db or not db.enabled then return end

    -- API TWW (GetWatchedFactionInfo supprimée en 11.x)
    if not C_Reputation or not C_Reputation.GetWatchedFactionData then
        repBar:Hide()
        return
    end
    local data = C_Reputation.GetWatchedFactionData()

    if not data or not data.name then
        repBar:Hide()
        return
    end

    repBar:Show()

    -- Helper local pour afficher une faction traditionnelle (standingID)
    local function ApplyTraditionalRep()
        local bottom  = data.currentReactionThreshold or 0
        local top     = data.nextReactionThreshold    or 1
        local current = data.currentStanding          or 0
        local barValue = current - bottom
        local barMax   = top - bottom
        if barMax <= 0 then barMax = 1 end

        repBar:SetMinMaxValues(0, barMax)
        repBar:SetValue(barValue)

        local reaction = data.reaction or 4
        local col = STANDING_COLORS[reaction] or STANDING_COLORS[4]
        repBar:SetStatusBarColor(col[1], col[2], col[3], 0.85)

        factionText:SetFormattedText("%s", data.name or "")
        standingText:SetText(GetStandingLabel(reaction))
        local pct = (barValue / barMax) * 100
        pctText:SetFormattedText("%.1f%%", pct)
        valueText:SetFormattedText("%s / %s", FormatRepValue(barValue), FormatRepValue(barMax))
    end

    -- ===== Renown (factions TWW / Dragonflight) =====
    if data.isRenown then
        local lvl     = data.renownLevel or 0
        local bottom  = data.currentReactionThreshold or 0
        local top     = data.nextReactionThreshold    or 2500
        local current = data.currentStanding          or 0
        local barValue = current - bottom
        local barMax   = top - bottom
        if barMax <= 0 then barMax = 1 end

        repBar:SetMinMaxValues(0, barMax)
        repBar:SetValue(barValue)
        repBar:SetStatusBarColor(RENOWN_COLOR[1], RENOWN_COLOR[2], RENOWN_COLOR[3], 0.85)

        factionText:SetFormattedText("%s", data.name or "")
        standingText:SetFormattedText("Renown %d", lvl)
        local pct = (barValue / barMax) * 100
        pctText:SetFormattedText("%.1f%%", pct)
        valueText:SetFormattedText("%s / %s", FormatRepValue(barValue), FormatRepValue(barMax))

    -- ===== Paragon (dépassement exalté) =====
    elseif data.factionID and C_Reputation and C_Reputation.GetFactionParagonInfo then
        local paragonOk, currentEarned, threshold, _, hasReward = pcall(C_Reputation.GetFactionParagonInfo, data.factionID)
        if paragonOk and currentEarned and threshold and threshold > 0 then
            local barValue = currentEarned % threshold
            local barMax   = threshold
            repBar:SetMinMaxValues(0, barMax)
            repBar:SetValue(barValue)
            repBar:SetStatusBarColor(PARAGON_COLOR[1], PARAGON_COLOR[2], PARAGON_COLOR[3], 0.85)

            factionText:SetFormattedText("%s", data.name or "")
            standingText:SetText(hasReward and "Paragon (Reward!)" or "Paragon")
            local pct = (barValue / barMax) * 100
            pctText:SetFormattedText("%.1f%%", pct)
            valueText:SetFormattedText("%s / %s", FormatRepValue(barValue), FormatRepValue(barMax))
        else
            ApplyTraditionalRep()
        end

    -- ===== Factions traditionnelles =====
    else
        ApplyTraditionalRep()
    end
end

-- =====================================
-- CREATE BAR
-- =====================================

local function CreateReputationBar()
    local db = TomoModDB.reputationBar
    local w  = db.width  or 350
    local h  = db.height or 22

    -- Frame principal = StatusBar
    repBar = CreateFrame("StatusBar", "TomoMod_ReputationBar", UIParent)
    repBar:SetSize(w, h)
    repBar:SetStatusBarTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki")
    repBar:SetStatusBarColor(0.13, 0.73, 0.20, 0.85)
    repBar:SetFrameStrata("BACKGROUND")
    repBar:SetFrameLevel(3)

    -- Position
    local pos = db.position
    if pos then
        repBar:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        -- Auto-ancrer au-dessus de la LevelingBar (frame) si présente et visible,
        -- sinon bas d'écran. On vérifie que lb est bien un Frame (pas juste le module table).
        local lb = _G["TomoMod_LevelingBar"]
        if lb and lb.GetObjectType and lb:GetObjectType() == "Frame" then
            repBar:SetPoint("BOTTOM", lb, "TOP", 0, 4)
        else
            repBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 70)
        end
    end

    -- Fond sombre
    local bg = repBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.05, 0.05, 0.08, 0.80)

    -- Bordure fine
    local border = CreateFrame("Frame", nil, repBar, "BackdropTemplate")
    border:SetPoint("TOPLEFT",     repBar, "TOPLEFT",     -1, 1)
    border:SetPoint("BOTTOMRIGHT", repBar, "BOTTOMRIGHT",  1, -1)
    border:SetFrameLevel(repBar:GetFrameLevel() - 1)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 0.70)

    -- Texte faction (gauche)
    factionText = repBar:CreateFontString(nil, "OVERLAY")
    factionText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 10, "OUTLINE")
    factionText:SetPoint("LEFT", repBar, "LEFT", 4, 0)
    factionText:SetTextColor(1, 1, 1, 0.95)
    factionText:SetJustifyH("LEFT")

    -- Standing (centre-gauche)
    standingText = repBar:CreateFontString(nil, "OVERLAY")
    standingText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 10, "OUTLINE")
    standingText:SetPoint("CENTER", repBar, "CENTER", -20, 0)
    standingText:SetTextColor(1, 1, 1, 0.80)

    -- Pourcentage (centre-droit)
    pctText = repBar:CreateFontString(nil, "OVERLAY")
    pctText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 10, "OUTLINE")
    pctText:SetPoint("CENTER", repBar, "CENTER", 20, 0)
    pctText:SetTextColor(1, 1, 1, 0.80)

    -- Valeurs (droite)
    valueText = repBar:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 10, "OUTLINE")
    valueText:SetPoint("RIGHT", repBar, "RIGHT", -4, 0)
    valueText:SetTextColor(1, 1, 1, 0.70)
    valueText:SetJustifyH("RIGHT")

    -- Tooltip
    repBar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local db2 = TomoModDB.reputationBar
        local data2
        if C_Reputation and C_Reputation.GetWatchedFactionData then
            data2 = C_Reputation.GetWatchedFactionData()
        end
        if data2 and data2.name then
            GameTooltip:AddLine(data2.name, 1, 1, 1)
            if data2.isRenown then
                GameTooltip:AddLine("Renown " .. (data2.renownLevel or 0), 0.60, 0.30, 1.00)
            else
                GameTooltip:AddLine(GetStandingLabel(data2.reaction or 4), 0.8, 0.8, 0.8)
            end
            local bottom  = data2.currentReactionThreshold or 0
            local top     = data2.nextReactionThreshold    or 1
            local current = data2.currentStanding          or 0
            GameTooltip:AddLine(
                string.format("%s / %s", FormatRepValue(current - bottom), FormatRepValue(top - bottom)),
                0.8, 0.8, 0.8
            )
        end
        GameTooltip:Show()
    end)
    repBar:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Unlock border (Layout Mode)
    repBar.unlockBorder = CreateFrame("Frame", nil, repBar, "BackdropTemplate")
    repBar.unlockBorder:SetPoint("TOPLEFT",     repBar, "TOPLEFT",     -2, 2)
    repBar.unlockBorder:SetPoint("BOTTOMRIGHT", repBar, "BOTTOMRIGHT",  2, -2)
    repBar.unlockBorder:SetFrameLevel(repBar:GetFrameLevel() + 5)
    repBar.unlockBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    repBar.unlockBorder:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.90)
    repBar.unlockBorder:Hide()

    -- Draggable (Layout Mode)
    repBar:SetMovable(true)
    repBar:SetClampedToScreen(true)
    repBar:RegisterForDrag("LeftButton")
    repBar:SetScript("OnDragStart", function(self)
        if not isLocked then self:StartMoving() end
    end)
    repBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left   = self:GetLeft()   or 0
        local bottom = self:GetBottom() or 0
        db.position = {
            point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT",
            x = left, y = bottom,
        }
    end)

    -- Update ticker
    updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnEvent", function(self, event)
        UpdateBar()
    end)
    updateFrame:RegisterEvent("UPDATE_FACTION")
    updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    UpdateBar()
end

-- =====================================
-- PUBLIC API (Layout Mode)
-- =====================================

function RB.IsLocked()
    return isLocked
end

function RB.ToggleLock()
    isLocked = not isLocked
    if not repBar then return end
    if not isLocked then
        -- Mode Layout : afficher le unlock border + drag label
        repBar.unlockBorder:Show()
        repBar:Show()
        if not factionText:GetText() or factionText:GetText() == "" then
            factionText:SetText("Réputation")
        end
        if not standingText:GetText() or standingText:GetText() == "" then
            standingText:SetText("Exalté")
        end
        pctText:SetText("100%")
        valueText:SetText("21000 / 21000")
        repBar:SetMinMaxValues(0, 100)
        repBar:SetValue(100)
        repBar:SetStatusBarColor(STANDING_COLORS[7][1], STANDING_COLORS[7][2], STANDING_COLORS[7][3], 0.85)
    else
        repBar.unlockBorder:Hide()
        UpdateBar()
    end
end

-- =====================================
-- INITIALIZE
-- ================================================================

function RB.Initialize()
    if not TomoModDB or not TomoModDB.reputationBar then return end
    if not TomoModDB.reputationBar.enabled then return end

    CreateReputationBar()
    SuppressBlizzRepBar()
end

TomoMod_RegisterModule("reputationBar", RB)

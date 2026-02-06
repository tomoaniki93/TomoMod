-- =====================================
-- Nameplates.lua — Complete Nameplate System
-- Castbar, Auras, Tank Mode, Alpha
-- =====================================

TomoMod_Nameplates = TomoMod_Nameplates or {}
local NP = TomoMod_Nameplates

-- =====================================
-- LOCALS
-- =====================================

local activePlates = {} -- [nameplateFrame] = ourPlate
local unitPlates = {}   -- [unitToken] = ourPlate

local UnitName, UnitLevel, UnitEffectiveLevel = UnitName, UnitLevel, UnitEffectiveLevel
local UnitClass, UnitClassification = UnitClass, UnitClassification
local UnitIsPlayer, UnitIsEnemy, UnitIsTapDenied = UnitIsPlayer, UnitIsEnemy, UnitIsTapDenied
local UnitReaction, UnitThreatSituation = UnitReaction, UnitThreatSituation
local GetThreatStatusColor = GetThreatStatusColor
local C_NamePlate = C_NamePlate

local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

local function DB()
    return TomoModDB and TomoModDB.nameplates or {}
end

-- =====================================
-- BORDER HELPER
-- =====================================

local function CreatePixelBorder(parent)
    local function Edge(p1, p2, w, h)
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        t:SetPoint(p1)
        t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, 1)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    Edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
end

-- =====================================
-- CREATE NAMEPLATE
-- =====================================

local function CreatePlate(baseFrame)
    local settings = DB()
    local tex = settings.texture or TEXTURE
    local font = settings.font or FONT
    local fontSize = settings.fontSize or 9
    local w = settings.width or 150
    local h = settings.height or 14

    local plate = CreateFrame("Frame", nil, baseFrame)
    plate:SetAllPoints(baseFrame)
    plate:SetFrameStrata("BACKGROUND")
    plate:EnableMouse(false)  -- Let clicks pass through to Blizzard nameplate

    -- Health bar
    plate.health = CreateFrame("StatusBar", nil, plate)
    plate.health:SetSize(w, h)
    plate.health:SetPoint("CENTER", 0, 0)
    plate.health:SetStatusBarTexture(tex)
    plate.health:GetStatusBarTexture():SetHorizTile(false)
    plate.health:SetMinMaxValues(0, 100)
    plate.health:SetValue(100)
    plate.health:EnableMouse(false)

    local bg = plate.health:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.10, 0.10, 0.12, 0.9)
    plate.health.bg = bg

    CreatePixelBorder(plate.health)

    -- Name
    local nameFontSize = settings.nameFontSize or 10
    plate.nameText = plate.health:CreateFontString(nil, "OVERLAY")
    plate.nameText:SetFont(font, nameFontSize, "OUTLINE")
    plate.nameText:SetPoint("BOTTOM", plate.health, "TOP", 0, 2)
    plate.nameText:SetTextColor(1, 1, 1)

    -- Level
    plate.levelText = plate.health:CreateFontString(nil, "OVERLAY")
    plate.levelText:SetFont(font, fontSize, "OUTLINE")
    plate.levelText:SetPoint("RIGHT", plate.health, "LEFT", -3, 0)

    -- Health text
    plate.healthText = plate.health:CreateFontString(nil, "OVERLAY")
    plate.healthText:SetFont(font, fontSize, "OUTLINE")
    plate.healthText:SetPoint("CENTER", plate.health, "CENTER", 0, 0)
    plate.healthText:SetTextColor(1, 1, 1, 0.9)

    -- Classification
    plate.classText = plate.health:CreateFontString(nil, "OVERLAY")
    plate.classText:SetFont(font, fontSize + 2, "OUTLINE")
    plate.classText:SetPoint("LEFT", plate.health, "RIGHT", 3, 0)
    plate.classText:Hide()

    -- Threat border
    plate.threatFrame = CreateFrame("Frame", nil, plate.health)
    plate.threatFrame:SetPoint("TOPLEFT", -2, 2)
    plate.threatFrame:SetPoint("BOTTOMRIGHT", 2, -2)
    plate.threatFrame:SetFrameLevel(plate.health:GetFrameLevel() + 10)
    plate.threatBorders = {}
    local function ThreatEdge(p1, p2, w2, h2)
        local t = plate.threatFrame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(1, 0, 0, 1)
        t:SetPoint(p1)
        t:SetPoint(p2)
        if w2 then t:SetWidth(w2) end
        if h2 then t:SetHeight(h2) end
        table.insert(plate.threatBorders, t)
    end
    ThreatEdge("TOPLEFT", "TOPRIGHT", nil, 2)
    ThreatEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
    ThreatEdge("TOPLEFT", "BOTTOMLEFT", 2, nil)
    ThreatEdge("TOPRIGHT", "BOTTOMRIGHT", 2, nil)
    plate.threatFrame:Hide()
    plate.threatFrame:EnableMouse(false)

    -- Castbar
    plate.castbar = CreateFrame("StatusBar", nil, plate)
    local cbH = settings.castbarHeight or 10
    plate.castbar:SetSize(w, cbH)
    plate.castbar:SetPoint("TOP", plate.health, "BOTTOM", 0, -2)
    plate.castbar:SetStatusBarTexture(tex)
    plate.castbar:GetStatusBarTexture():SetHorizTile(false)
    plate.castbar:SetMinMaxValues(0, 1)
    plate.castbar:SetValue(0)
    plate.castbar:SetStatusBarColor(1, 0.7, 0, 1)

    local cbBg = plate.castbar:CreateTexture(nil, "BACKGROUND")
    cbBg:SetAllPoints()
    cbBg:SetColorTexture(0.06, 0.06, 0.08, 0.9)
    CreatePixelBorder(plate.castbar)

    plate.castbar.icon = plate.castbar:CreateTexture(nil, "OVERLAY")
    plate.castbar.icon:SetSize(cbH, cbH)
    plate.castbar.icon:SetPoint("RIGHT", plate.castbar, "LEFT", -2, 0)
    plate.castbar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    plate.castbar.text = plate.castbar:CreateFontString(nil, "OVERLAY")
    plate.castbar.text:SetFont(font, math.max(7, cbH - 3), "OUTLINE")
    plate.castbar.text:SetPoint("LEFT", 3, 0)
    plate.castbar.text:SetTextColor(1, 1, 1)

    plate.castbar.timer = plate.castbar:CreateFontString(nil, "OVERLAY")
    plate.castbar.timer:SetFont(font, math.max(7, cbH - 3), "OUTLINE")
    plate.castbar.timer:SetPoint("RIGHT", -3, 0)
    plate.castbar.timer:SetTextColor(1, 1, 1, 0.8)

    plate.castbar:Hide()
    plate.castbar:EnableMouse(false)

    -- Not-interruptible overlay (grey, anchored to fill texture)
    -- SetAlpha accepts secrets from C_CurveUtil — key TWW technique
    local cbStatusTex = plate.castbar:GetStatusBarTexture()
    plate.castbar.niOverlay = plate.castbar:CreateTexture(nil, "ARTWORK", nil, 1)
    plate.castbar.niOverlay:SetPoint("TOPLEFT", cbStatusTex, "TOPLEFT", 0, 0)
    plate.castbar.niOverlay:SetPoint("BOTTOMRIGHT", cbStatusTex, "BOTTOMRIGHT", 0, 0)
    plate.castbar.niOverlay:SetColorTexture(0.5, 0.5, 0.5, 1)
    plate.castbar.niOverlay:SetAlpha(0)
    plate.castbar.niOverlay:Show()

    -- Castbar update
    plate.castbar.casting = false
    plate.castbar.channeling = false
    plate.castbar.duration_obj = nil
    plate.castbar:SetScript("OnUpdate", function(self, elapsed)
        if not self.casting and not self.channeling then
            self:Hide()
            return
        end
        -- Progress: GetTime() * 1000 is non-secret, bar fill handled C-side
        self:SetValue(GetTime() * 1000)
        -- Timer from stored duration object (param 0 for displayable value)
        if self.timer and self.duration_obj then
            self.timer:SetText(string.format("%.1f", self.duration_obj:GetRemainingDuration(0)))
        end
    end)

    -- Aura icons
    plate.auras = {}
    local maxAuras = settings.maxAuras or 5
    local auraSize = settings.auraSize or 20
    for i = 1, maxAuras do
        local aura = CreateFrame("Frame", nil, plate)
        aura:SetSize(auraSize, auraSize)
        aura:EnableMouse(false)
        if i == 1 then
            aura:SetPoint("BOTTOMLEFT", plate.health, "TOPLEFT", 0, 16)
        else
            aura:SetPoint("LEFT", plate.auras[i - 1], "RIGHT", 2, 0)
        end

        aura.icon = aura:CreateTexture(nil, "ARTWORK")
        aura.icon:SetAllPoints()
        aura.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
        aura.cooldown:SetAllPoints(aura.icon)
        aura.cooldown:SetDrawEdge(false)
        aura.cooldown:SetReverse(true)
        aura.cooldown:SetHideCountdownNumbers(true)
        aura.cooldown:EnableMouse(false)

        aura.count = aura:CreateFontString(nil, "OVERLAY")
        aura.count:SetFont(font, 8, "OUTLINE")
        aura.count:SetPoint("BOTTOMRIGHT", -1, 1)

        aura.duration = aura:CreateFontString(nil, "OVERLAY")
        aura.duration:SetFont(font, 8, "OUTLINE")
        aura.duration:SetPoint("TOP", aura, "BOTTOM", 0, -1)
        aura.duration:SetTextColor(1, 1, 0.6, 1)

        CreatePixelBorder(aura)
        aura:Hide()
        plate.auras[i] = aura
    end

    -- Target indicator arrows (shown only on current target)
    local arrowSize = h + 6
    local ARROW_LEFT = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\arrow_left"
    local ARROW_RIGHT = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\arrow_right"

    plate.targetArrowLeft = plate:CreateTexture(nil, "OVERLAY")
    plate.targetArrowLeft:SetTexture(ARROW_LEFT)
    plate.targetArrowLeft:SetSize(arrowSize * 0.6, arrowSize)
    plate.targetArrowLeft:SetPoint("RIGHT", plate.health, "LEFT", 2, 0)
    plate.targetArrowLeft:SetVertexColor(1, 1, 1, 0.9)
    plate.targetArrowLeft:Hide()

    plate.targetArrowRight = plate:CreateTexture(nil, "OVERLAY")
    plate.targetArrowRight:SetTexture(ARROW_RIGHT)
    plate.targetArrowRight:SetSize(arrowSize * 0.6, arrowSize)
    plate.targetArrowRight:SetPoint("LEFT", plate.health, "RIGHT", -2, 0)
    plate.targetArrowRight:SetVertexColor(1, 1, 1, 0.9)
    plate.targetArrowRight:Hide()

    -- Raid marker icon (right side, half in/half out)
    local raidIconSize = h + 4
    plate.raidIcon = plate.health:CreateTexture(nil, "OVERLAY")
    plate.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    plate.raidIcon:SetSize(raidIconSize, raidIconSize)
    plate.raidIcon:SetPoint("LEFT", plate.health, "RIGHT", -(raidIconSize / 2), 0)
    plate.raidIcon:Hide()

    return plate
end

-- =====================================
-- UPDATE FUNCTIONS
-- =====================================

local function UpdateSize(plate)
    local s = DB()
    local h = s.height or 14
    plate.health:SetSize(s.width or 150, h)
    plate.castbar:SetSize(s.width or 150, s.castbarHeight or 10)
    -- Update name font size
    if plate.nameText then
        local font = s.font or FONT
        plate.nameText:SetFont(font, s.nameFontSize or 10, s.fontOutline or "OUTLINE")
    end
    -- Resize target arrows to match health height
    if plate.targetArrowLeft then
        local arrowSize = h + 6
        plate.targetArrowLeft:SetSize(arrowSize * 0.6, arrowSize)
        plate.targetArrowRight:SetSize(arrowSize * 0.6, arrowSize)
    end
    if plate.raidIcon then
        local raidIconSize = h + 4
        plate.raidIcon:SetSize(raidIconSize, raidIconSize)
        plate.raidIcon:ClearAllPoints()
        plate.raidIcon:SetPoint("LEFT", plate.health, "RIGHT", -(raidIconSize / 2), 0)
    end
    -- Resize auras
    if plate.auras then
        local auraSize = s.auraSize or 20
        for i, aura in ipairs(plate.auras) do
            aura:SetSize(auraSize, auraSize)
            aura.icon:SetSize(auraSize - 2, auraSize - 2)
        end
    end
end

local function GetHealthColor(unit)
    local s = DB()

    -- Tank mode
    if s.tankMode then
        local role = UnitGroupRolesAssigned("player")
        if role == "TANK" and UnitIsEnemy("player", unit) then
            local status = UnitThreatSituation("player", unit)
            if status and status >= 3 then
                local c = s.tankColors.hasThreat
                return c.r, c.g, c.b
            elseif status and status >= 1 then
                local c = s.tankColors.lowThreat
                return c.r, c.g, c.b
            else
                local c = s.tankColors.noThreat
                return c.r, c.g, c.b
            end
        end
    end

    -- Class colors for players
    if UnitIsPlayer(unit) and s.useClassColors then
        local _, class = UnitClass(unit)
        if class and RAID_CLASS_COLORS[class] then
            local c = RAID_CLASS_COLORS[class]
            return c.r, c.g, c.b
        end
    end

    -- Tapped
    if UnitIsTapDenied(unit) then
        local c = s.colors.tapped
        return c.r, c.g, c.b
    end

    -- Reaction
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then
            local c = s.colors.friendly; return c.r, c.g, c.b
        elseif reaction == 4 then
            local c = s.colors.neutral; return c.r, c.g, c.b
        else
            -- Hostile: use classification colors if enabled
            if s.useClassificationColors then
                local cls = UnitClassification(unit)
                if cls == "worldboss" then
                    local c = s.colors.boss or s.colors.hostile; return c.r, c.g, c.b
                elseif cls == "elite" or cls == "rareelite" then
                    local c = s.colors.elite or s.colors.hostile; return c.r, c.g, c.b
                elseif cls == "rare" then
                    local c = s.colors.rare or s.colors.hostile; return c.r, c.g, c.b
                elseif cls == "trivial" or cls == "minus" then
                    local c = s.colors.trivial or s.colors.hostile; return c.r, c.g, c.b
                else
                    local c = s.colors.normal or s.colors.hostile; return c.r, c.g, c.b
                end
            end
            local c = s.colors.hostile; return c.r, c.g, c.b
        end
    end

    if UnitIsEnemy("player", unit) then
        if s.useClassificationColors then
            local cls = UnitClassification(unit)
            if cls == "worldboss" then
                local c = s.colors.boss or s.colors.hostile; return c.r, c.g, c.b
            elseif cls == "elite" or cls == "rareelite" then
                local c = s.colors.elite or s.colors.hostile; return c.r, c.g, c.b
            elseif cls == "rare" then
                local c = s.colors.rare or s.colors.hostile; return c.r, c.g, c.b
            elseif cls == "trivial" or cls == "minus" then
                local c = s.colors.trivial or s.colors.hostile; return c.r, c.g, c.b
            else
                local c = s.colors.normal or s.colors.hostile; return c.r, c.g, c.b
            end
        end
        local c = s.colors.hostile; return c.r, c.g, c.b
    end

    return 1, 1, 1
end

-- Sets health text directly on FontString using C-side SetFormattedText.
-- No tainted Lua strings created — all secret values stay C-side.
local function SetHealthTextNP(fontString, current, max, fmt, unit)
    if not fontString then return end

    if unit then
        if UnitIsDead(unit) then fontString:SetText("Dead"); return
        elseif UnitIsGhost(unit) then fontString:SetText("Ghost"); return
        elseif not UnitIsConnected(unit) then fontString:SetText("Offline"); return
        end
    end
    if not unit then fontString:SetText(""); return end

    local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

    if fmt == "current" then
        fontString:SetFormattedText("%s", AbbreviateLargeNumbers(current))
    elseif fmt == "current_percent" then
        fontString:SetFormattedText("%s %d%%", AbbreviateLargeNumbers(current), UnitHealthPercent(unit, true, ScaleTo100))
    else
        -- Default: percent
        fontString:SetFormattedText("%d%%", UnitHealthPercent(unit, true, ScaleTo100))
    end
end

local function UpdatePlate(plate, unit)
    if not plate or not unit then return end
    local s = DB()

    -- Health (C-side widget methods accept secret numbers natively)
    local hp = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)
    plate.health:SetMinMaxValues(0, hpMax)
    plate.health:SetValue(hp)

    -- Color
    local r, g, b = GetHealthColor(unit)
    plate.health:SetStatusBarColor(r, g, b, 1)

    -- Health text (SetFormattedText is C-side — zero Lua taint)
    if s.showHealthText then
        SetHealthTextNP(plate.healthText, hp, hpMax, s.healthTextFormat or "percent", unit)
        plate.healthText:Show()
    else
        plate.healthText:Hide()
    end

    -- Name
    if s.showName then
        local name = UnitName(unit)
        if not name then name = "" end
        -- UnitName may return a secret string — SetText is C-side, handles it
        plate.nameText:SetText(name)
        plate.nameText:Show()
    else
        plate.nameText:Hide()
    end

    -- Level
    if s.showLevel then
        local level = UnitEffectiveLevel(unit)
        local classification = UnitClassification(unit)
        local txt = (level == -1) and "??" or tostring(level)
        if classification == "elite" then txt = txt .. "+"
        elseif classification == "rare" then txt = txt .. "R"
        elseif classification == "rareelite" then txt = txt .. "R+"
        elseif classification == "worldboss" then txt = "Boss" end
        plate.levelText:SetText(txt)
        local color = GetQuestDifficultyColor(level)
        plate.levelText:SetTextColor(color.r, color.g, color.b)
        plate.levelText:Show()
    else
        plate.levelText:Hide()
    end

    -- Classification icon
    if s.showClassification then
        local cls = UnitClassification(unit)
        if cls == "elite" then
            plate.classText:SetText("★"); plate.classText:SetTextColor(1, 0.84, 0); plate.classText:Show()
        elseif cls == "rareelite" then
            plate.classText:SetText("★★"); plate.classText:SetTextColor(0, 0.8, 1); plate.classText:Show()
        elseif cls == "rare" then
            plate.classText:SetText("◆"); plate.classText:SetTextColor(0, 0.8, 1); plate.classText:Show()
        elseif cls == "worldboss" then
            plate.classText:SetText("☠"); plate.classText:SetTextColor(1, 0, 0); plate.classText:Show()
        else
            plate.classText:Hide()
        end
    else
        plate.classText:Hide()
    end

    -- Raid marker (C-side SetRaidTargetIconTexture accepts secret index)
    if plate.raidIcon then
        local index = GetRaidTargetIndex(unit)
        if index then
            SetRaidTargetIconTexture(plate.raidIcon, index)
            plate.raidIcon:Show()
        else
            plate.raidIcon:Hide()
        end
    end

    -- Threat
    if s.showThreat and UnitIsEnemy("player", unit) then
        local status = UnitThreatSituation("player", unit)
        if status and status >= 2 then
            local tr, tg, tb = GetThreatStatusColor(status)
            for _, border in ipairs(plate.threatBorders) do
                border:SetVertexColor(tr, tg, tb, 1)
            end
            plate.threatFrame:Show()
        else
            plate.threatFrame:Hide()
        end
    else
        plate.threatFrame:Hide()
    end

    -- Alpha (selected vs not) + target indicator arrows
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate then
        local isTarget = UnitIsUnit(unit, "target")
        nameplate:SetAlpha(isTarget and (s.selectedAlpha or 1) or (s.unselectedAlpha or 0.8))

        -- Target arrows
        if plate.targetArrowLeft and plate.targetArrowRight then
            if isTarget then
                plate.targetArrowLeft:Show()
                plate.targetArrowRight:Show()
            else
                plate.targetArrowLeft:Hide()
                plate.targetArrowRight:Hide()
            end
        end
    end

    -- Auras
    if s.showAuras then
        local auraIndex = 0
        local maxAuras = s.maxAuras or 5

        -- TWW: ALL aura data fields are secret. Use |PLAYER filter for "only mine" (C-side).
        local auraFilter = "HARMFUL"
        if s.showOnlyMyAuras then auraFilter = "HARMFUL|PLAYER" end

        local results = {C_UnitAuras.GetAuraSlots(unit, auraFilter)}
        -- results[1] = continuationToken, results[2..n] = slot indices
        for i = 2, #results do
            if auraIndex >= maxAuras then break end
            local data = C_UnitAuras.GetAuraDataBySlot(unit, results[i])
            if data then
                auraIndex = auraIndex + 1
                local auraFrame = plate.auras[auraIndex]
                if auraFrame then
                    -- SetTexture is C-side, accepts secret icon value
                    auraFrame.icon:SetTexture(data.icon)

                    -- Duration object (C_UnitAuras.GetAuraDuration)
                    local durObj = C_UnitAuras.GetAuraDuration(unit, data.auraInstanceID)
                    auraFrame._auraUnit = unit
                    auraFrame._auraInstanceID = data.auraInstanceID

                    if durObj then
                        -- TWW: Duration methods return secrets — can't compare, can't do arithmetic
                        -- Cooldown swipe impossible (needs startTime = GetTime() - (total - remaining))
                        auraFrame.cooldown:Hide()
                        -- Duration text: string.format is C function, accepts secrets
                        if auraFrame.duration then
                            auraFrame.duration:SetText(string.format("%.0f", durObj:GetRemainingDuration()))
                            auraFrame.duration:Show()
                        end
                    else
                        auraFrame.cooldown:Hide()
                        if auraFrame.duration then auraFrame.duration:Hide() end
                    end

                    -- Stack count (non-secret display string, empty if < 2)
                    local stackStr = C_UnitAuras.GetAuraApplicationDisplayCount(unit, data.auraInstanceID, 2, 1000)
                    auraFrame.count:SetText(stackStr or "")
                    auraFrame.count:Show()

                    auraFrame:Show()
                end
            end
        end

        -- Hide remaining
        for i = auraIndex + 1, maxAuras do
            if plate.auras[i] then
                plate.auras[i]:Hide()
            end
        end
    else
        for _, a in ipairs(plate.auras) do a:Hide() end
    end
end

-- =====================================
-- CASTBAR HELPERS
-- =====================================

local function UpdateCastbar(plate, unit)
    if not plate or not plate.castbar then return end
    local s = DB()
    if not s.showCastbar then plate.castbar:Hide(); return end
    plate.castbar.unit = unit

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible

    -- Check casting — TWW: SetMinMaxValues accepts secrets (start/end MS)
    name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo(unit)
    if type(name) ~= "nil" then
        plate.castbar.casting = true
        plate.castbar.channeling = false
        plate.castbar.interrupted = false
        plate.castbar.duration_obj = UnitCastingDuration(unit)
        plate.castbar:SetMinMaxValues(startTimeMS, endTimeMS)
        plate.castbar:SetReverseFill(false)
        plate.castbar.text:SetFormattedText("%s", name)
        plate.castbar.icon:SetTexture(texture)
        -- TWW: SetAlpha accepts secrets — grey overlay alpha from C_CurveUtil
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 1, 0)
        plate.castbar.niOverlay:SetAlpha(alpha)
        plate.castbar:Show()
        return
    end

    -- Check channeling
    local chanNI
    name, _, texture, startTimeMS, endTimeMS, _, chanNI = UnitChannelInfo(unit)
    if type(name) ~= "nil" then
        plate.castbar.casting = false
        plate.castbar.channeling = true
        plate.castbar.interrupted = false
        plate.castbar.duration_obj = UnitChannelDuration(unit)
        plate.castbar:SetMinMaxValues(startTimeMS, endTimeMS)
        plate.castbar:SetReverseFill(true)
        plate.castbar.text:SetFormattedText("%s", name)
        plate.castbar.icon:SetTexture(texture)
        -- Same overlay alpha for channels
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(chanNI, 1, 0)
        plate.castbar.niOverlay:SetAlpha(alpha)
        plate.castbar:Show()
        return
    end

    plate.castbar:Hide()
    plate.castbar.casting = false
    plate.castbar.channeling = false
    plate.castbar.duration_obj = nil
end

-- =====================================
-- EVENT HANDLING
-- =====================================

local eventFrame = CreateFrame("Frame")

local function OnNamePlateAdded(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end

    -- Create or reuse our plate
    if not activePlates[nameplate] then
        activePlates[nameplate] = CreatePlate(nameplate)
    end

    local plate = activePlates[nameplate]
    plate.unit = unit
    plate._blizzUnitFrame = nameplate.UnitFrame
    unitPlates[unit] = plate

    -- Do NOT call nameplate.UnitFrame:SetAlpha(0) here — it runs in Blizzard's
    -- event context and taints CompactUnitFrame code. The OnUpdate handles it.
    plate:SetScript("OnUpdate", function(self)
        if self._blizzUnitFrame then
            self._blizzUnitFrame:SetAlpha(0)
        end
    end)

    UpdateSize(plate)
    UpdatePlate(plate, unit)
    UpdateCastbar(plate, unit)
    plate:Show()
end

local function OnNamePlateRemoved(unit)
    local plate = unitPlates[unit]
    if plate then
        -- Stop suppressing Blizzard UnitFrame
        plate:SetScript("OnUpdate", nil)
        if plate._blizzUnitFrame then
            plate._blizzUnitFrame:SetAlpha(1)
        end
        plate:Hide()
        plate.castbar:Hide()
        for _, a in ipairs(plate.auras) do a:Hide() end
        unitPlates[unit] = nil
    end
end

eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
eventFrame:RegisterEvent("UNIT_FACTION")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
eventFrame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        OnNamePlateAdded(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        OnNamePlateRemoved(unit)
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Defer: UnitIsUnit can propagate taint
        C_Timer.After(0, function()
            local s = DB()
            for u, p in pairs(unitPlates) do
                local np = C_NamePlate.GetNamePlateForUnit(u)
                if np then
                    local isTarget = UnitIsUnit(u, "target")
                    np:SetAlpha(isTarget and (s.selectedAlpha or 1) or (s.unselectedAlpha or 0.8))
                    -- Target arrows
                    if p.targetArrowLeft and p.targetArrowRight then
                        if isTarget then
                            p.targetArrowLeft:Show()
                            p.targetArrowRight:Show()
                        else
                            p.targetArrowLeft:Hide()
                            p.targetArrowRight:Hide()
                        end
                    end
                end
            end
        end)
    elseif event == "RAID_TARGET_UPDATE" then
        -- No unit arg — update raid icon on all plates
        for u, p in pairs(unitPlates) do
            if p.raidIcon then
                local index = GetRaidTargetIndex(u)
                if index then
                    SetRaidTargetIconTexture(p.raidIcon, index)
                    p.raidIcon:Show()
                else
                    p.raidIcon:Hide()
                end
            end
        end
    elseif unit and unitPlates[unit] then
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_THREAT_SITUATION_UPDATE"
            or event == "UNIT_FACTION" or event == "UNIT_AURA" then
            -- Defer: UpdatePlate touches UnitHealth (secret numbers) — isolate taint
            local p = unitPlates[unit]
            C_Timer.After(0, function() UpdatePlate(p, unit) end)
        elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            -- Mid-cast state change: re-call UpdateCastbar to re-read notInterruptible and update overlay
            if unitPlates[unit] then
                UpdateCastbar(unitPlates[unit], unit)
            end
        elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            if unitPlates[unit] then
                UpdateCastbar(unitPlates[unit], unit)
            end
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- Cast was interrupted → green flash then hide
            local p = unitPlates[unit]
            if p and p.castbar then
                p.castbar.niOverlay:SetAlpha(0)
                p.castbar:SetStatusBarColor(0.1, 0.8, 0.1, 1)
                p.castbar.text:SetFormattedText("%s", INTERRUPTED or "Interrompu")
                p.castbar:Show()
                C_Timer.After(0.4, function()
                    if p.castbar then
                        p.castbar:SetStatusBarColor(0.8, 0.1, 0.1, 1)
                        p.castbar:Hide()
                        p.castbar.casting = false
                        p.castbar.channeling = false
                        p.castbar.duration_obj = nil
                    end
                end)
            end
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            local p = unitPlates[unit]
            if p and p.castbar then
                p.castbar.casting = false
                p.castbar.channeling = false
                p.castbar.duration_obj = nil
                p.castbar:Hide()
            end
        end
    end
end)

-- =====================================
-- PUBLIC API
-- =====================================

function NP.Initialize()
    if not DB().enabled then
        NP.Disable()
        return
    end
    NP.Enable()
end

function NP.Enable()
    if TomoModDB and TomoModDB.nameplates then
        TomoModDB.nameplates.enabled = true
    end

    -- Apply nameplate stacking CVars to reduce vertical spread
    local s = DB()
    NP._savedCVars = {
        nameplateOverlapV = GetCVar("nameplateOverlapV"),
        nameplateOtherTopInset = GetCVar("nameplateOtherTopInset"),
        nameplateOtherBottomInset = GetCVar("nameplateOtherBottomInset"),
    }
    SetCVar("nameplateOverlapV", s.overlapV or 1.6)
    SetCVar("nameplateOtherTopInset", s.topInset or 0.065)
    SetCVar("nameplateOtherBottomInset", 0.1)

    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    NP.RefreshAll()

    -- Aura duration ticker (C_UnitAuras.GetAuraDuration returns non-secret Duration methods)
    if not NP._auraTicker then
        NP._auraTicker = C_Timer.NewTicker(0.1, function()
            for u, p in pairs(unitPlates) do
                if p.auras then
                    for _, aura in ipairs(p.auras) do
                        if aura:IsShown() and aura.duration and aura._auraUnit and aura._auraInstanceID then
                            local durObj = C_UnitAuras.GetAuraDuration(aura._auraUnit, aura._auraInstanceID)
                            if durObj then
                                aura.duration:SetText(string.format("%.0f", durObj:GetRemainingDuration()))
                            end
                        end
                    end
                end
            end
        end)
    end

    print("|cff0cd29fTomoMod NP:|r Activées")
end

function NP.Disable()
    eventFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")

    -- Stop aura duration ticker
    if NP._auraTicker then
        NP._auraTicker:Cancel()
        NP._auraTicker = nil
    end

    -- Restore original CVars
    if NP._savedCVars then
        for k, v in pairs(NP._savedCVars) do
            if v then SetCVar(k, v) end
        end
        NP._savedCVars = nil
    end

    for nameplate, plate in pairs(activePlates) do
        plate:SetScript("OnUpdate", nil)
        plate:Hide()
        if plate._blizzUnitFrame then
            plate._blizzUnitFrame:SetAlpha(1)
        end
    end
    unitPlates = {}
end

function NP.RefreshAll()
    for unit, plate in pairs(unitPlates) do
        UpdateSize(plate)
        UpdatePlate(plate, unit)
        UpdateCastbar(plate, unit)
    end
end

function NP.ApplySettings()
    local s = DB()
    SetCVar("nameplateOverlapV", s.overlapV or 1.6)
    SetCVar("nameplateOtherTopInset", s.topInset or 0.065)
    NP.RefreshAll()
end

TomoMod_RegisterModule("nameplates", NP)

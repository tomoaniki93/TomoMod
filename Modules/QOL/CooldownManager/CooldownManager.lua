-- =====================================
-- CooldownManager V3 — Phase 1+2+3 (CDMScanner + CDMLayout + ProcGlow + Keybinds)
-- Clean & modern reskin of Blizzard CooldownManager
-- Inspired by CooldownManagerCentered + DDingUI architecture
-- 9-slice rounded borders, class overlay on active auras,
-- custom swipe colors, utility dimming, centered layout,
-- hotkeys, custom CD text, visibility rules, GCD hiding,
-- desaturation, charge-aware dimming, vertical layout,
-- proc glow, pandemic borders
--
-- Phase 1: All frame.cooldownID accesses via CDMScanner weak tables.
-- Phase 2: All positioning via CDMLayout own layout engine.
-- Phase 3: ProcGlow + Keybinds extracted into own modules.
--   Requires CDMScanner, CDMLayout, CDMKeybinds, CDMProcGlow
--   loaded before this file.
-- =====================================

TomoMod_CooldownManager = TomoMod_CooldownManager or {}
local CDM = TomoMod_CooldownManager

-- =====================================
-- CDMScanner reference (Phase 1 anti-taint caching)
-- All frame.cooldownID accesses go through Scanner weak tables
-- =====================================
local Scanner = TomoMod_CDMScanner

-- =====================================
-- CDMLayout reference (Phase 2 own layout engine)
-- All viewer positioning goes through CDMLayout
-- =====================================
local CDMLayout = TomoMod_CDMLayout

-- =====================================
-- CDMKeybinds reference (Phase 3 extracted keybind system)
-- =====================================
local CDMKeybinds = TomoMod_CDMKeybinds

-- =====================================
-- CDMProcGlow reference (Phase 3 proc glow effects)
-- =====================================
local CDMProcGlow = TomoMod_CDMProcGlow

-- =====================================
-- CONSTANTS
-- =====================================
local FONT            = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BORDER_TEX      = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\border.png"
local BORDER_CORNER   = 4
local ICON_INSET      = 3
local SPACING         = 1
local TICK_RATE       = 0.25
local GCD_SPELL_ID    = 61304
local floor, abs, ceil = math.floor, math.abs, math.ceil

-- V3.1 constants
local PANDEMIC_THRESHOLD_DEFAULT = 0.3
local PANDEMIC_COLOR   = { r = 1.0, g = 0.6, b = 0.0 }
local RANGE_OOR_COLOR  = { r = 0.8, g = 0.1, b = 0.1 }
local RANGE_OK_COLOR   = { r = 1.0, g = 1.0, b = 1.0 }
local SOUND_ALERT_DEFAULT_FILE = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Golden_Lust.ogg"
local SOUND_ALERT_COOLDOWN     = 1.0

-- =====================================
-- CLASS OVERLAY COLOR TABLE
-- =====================================
local CLASS_OVERLAY_COLORS = {
    WARRIOR     = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN     = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER      = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE       = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST      = { r = 1.00, g = 1.00, b = 1.00 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    SHAMAN      = { r = 0.00, g = 0.44, b = 0.87 },
    MAGE        = { r = 0.25, g = 0.78, b = 0.92 },
    WARLOCK     = { r = 0.53, g = 0.53, b = 0.93 },
    MONK        = { r = 0.00, g = 1.00, b = 0.60 },
    DRUID       = { r = 1.00, g = 0.49, b = 0.04 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER      = { r = 0.20, g = 0.58, b = 0.50 },
}

-- =====================================
-- 9-SLICE ROUNDED BORDER HELPER
-- =====================================
local function Create9SliceBorder(parent, r, g, b, a, sublevel)
    sublevel = sublevel or 7
    a = a or 1
    local parts = {}

    local function Tex()
        local t = parent:CreateTexture(nil, "OVERLAY", nil, sublevel)
        t:SetTexture(BORDER_TEX)
        if r then t:SetVertexColor(r, g, b, a) end
        parts[#parts + 1] = t
        return t
    end

    local tl = Tex(); tl:SetSize(BORDER_CORNER, BORDER_CORNER)
    tl:SetPoint("TOPLEFT"); tl:SetTexCoord(0, 0.5, 0, 0.5)
    local tr = Tex(); tr:SetSize(BORDER_CORNER, BORDER_CORNER)
    tr:SetPoint("TOPRIGHT"); tr:SetTexCoord(0.5, 1, 0, 0.5)
    local bl = Tex(); bl:SetSize(BORDER_CORNER, BORDER_CORNER)
    bl:SetPoint("BOTTOMLEFT"); bl:SetTexCoord(0, 0.5, 0.5, 1)
    local br = Tex(); br:SetSize(BORDER_CORNER, BORDER_CORNER)
    br:SetPoint("BOTTOMRIGHT"); br:SetTexCoord(0.5, 1, 0.5, 1)

    local top = Tex(); top:SetHeight(BORDER_CORNER)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(0.5, 0.5, 0, 0.5)
    local bot = Tex(); bot:SetHeight(BORDER_CORNER)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bot:SetTexCoord(0.5, 0.5, 0.5, 1)
    local left = Tex(); left:SetWidth(BORDER_CORNER)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    left:SetTexCoord(0, 0.5, 0.5, 0.5)
    local right = Tex(); right:SetWidth(BORDER_CORNER)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    right:SetTexCoord(0.5, 1, 0.5, 0.5)

    return parts
end

-- =====================================
-- STATE
-- =====================================
local _, playerClass = UnitClass("player")
local classColor = RAID_CLASS_COLORS[playerClass]
local overlayColor = CLASS_OVERLAY_COLORS[playerClass] or classColor
local viewers = {}
local cdViewers = {}
local todoList = {}
local isInitialized = false
local mainFrame, updateFrame, tickerFrame
local clientSceneActive = false

-- V3.1: Sound alert state
local soundSpellState    = {}
local lastSoundAlertTime = 0

-- =====================================
-- COOLDOWN TRACKER (cache spell CD duration objects)
-- Avoids creating new duration objects every tick
-- =====================================
local CooldownTracker = {}
local trackedSpells = {}
local trackedCharges = {}

function CooldownTracker:GetSpellCD(spellID)
    local data = trackedSpells[spellID]
    if data then return data.cd end
    local obj = C_Spell.GetSpellCooldownDuration(spellID)
    trackedSpells[spellID] = { cd = obj }
    return obj
end

function CooldownTracker:GetChargeCD(spellID)
    local data = trackedCharges[spellID]
    if data then return data.cd end
    local obj = C_Spell.GetSpellChargeDuration(spellID)
    trackedCharges[spellID] = { cd = obj }
    return obj
end

local trackerFrame = CreateFrame("Frame")
trackerFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
trackerFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
trackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
trackerFrame:SetScript("OnEvent", function(_, event, spellId)
    if spellId and event == "SPELL_UPDATE_COOLDOWN" and trackedSpells[spellId] then
        trackedSpells[spellId].cd = C_Spell.GetSpellCooldownDuration(spellId)
    end
    if event == "PLAYER_ENTERING_WORLD" or not spellId then
        for id in pairs(trackedSpells) do
            trackedSpells[id].cd = C_Spell.GetSpellCooldownDuration(id)
        end
    end
    if event == "SPELL_UPDATE_CHARGES" then
        for id in pairs(trackedCharges) do
            local obj = C_Spell.GetSpellChargeDuration(id)
            if obj then trackedCharges[id].cd = obj end
        end
    end
end)

-- Children cache
local childrenCache = {}
local function InvalidateChildrenCache(viewer)
    childrenCache[viewer] = nil
end
local function GetCachedChildren(viewer)
    if not childrenCache[viewer] then
        childrenCache[viewer] = { viewer:GetChildren() }
    end
    return childrenCache[viewer]
end

-- Desaturation curve (0 when off CD, 1 when on CD)
local desaturationCurve = C_CurveUtil.CreateCurve()
desaturationCurve:AddPoint(0, 0)
desaturationCurve:AddPoint(0.001, 1)

-- =====================================
-- UTILS
-- =====================================
local function GetSettings()
    return TomoModDB and TomoModDB.cooldownManager
end

local function GetOverlayColor()
    local s = GetSettings()
    if s and s.useCustomOverlay then
        return { r = s.overlayR or overlayColor.r, g = s.overlayG or overlayColor.g, b = s.overlayB or overlayColor.b }
    end
    return overlayColor
end

local function GetActiveSwipeColor()
    local s = GetSettings()
    if s and s.customSwipeEnabled then
        return s.swipeR or 1, s.swipeG or 0.95, s.swipeB or 0.57, s.swipeA or 0.55
    end
    return nil
end

local function GetCDSwipeColor()
    local s = GetSettings()
    if s and s.customCDSwipeEnabled then
        return s.cdSwipeR or 0, s.cdSwipeG or 0, s.cdSwipeB or 0, s.cdSwipeA or 0.7
    end
    return nil
end

local function FormatCooldown(remaining)
    if remaining >= 60 then
        return string.format("%dm", ceil(remaining / 60))
    elseif remaining >= 10 then
        return string.format("%d", floor(remaining))
    elseif remaining >= 0 then
        return string.format("%.1f", remaining)
    end
    return ""
end

local function FormatDuration(remaining)
    if remaining >= 60 then
        return string.format("%dm", ceil(remaining / 60))
    elseif remaining >= 10 then
        return string.format("%d", floor(remaining))
    else
        return string.format("%.0f", remaining)
    end
end

-- =====================================
-- STYLE: CLEAN BORDER + ICON CROP
-- =====================================
local function StyleButton(button, isBuff)
    if button._cdm_styled then return end
    button._cdm_styled = true

    -- Ensure this frame is in the Scanner cache
    Scanner.EnsureCached(button)

    local width = button:GetWidth()
    local rate = isBuff and 0.85 or 0.92
    local iconRate = isBuff and 0.12 or 0.07
    local oc = GetOverlayColor()

    button:SetSize(width, width * rate)

    -- Strip mask, crop icon
    if button.Icon then
        local mask = button.Icon:GetMaskTexture(1)
        if mask then button.Icon:RemoveMaskTexture(mask) end
        button.Icon:ClearAllPoints()
        button.Icon:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
        button.Icon:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
        button.Icon:SetTexCoord(0.07, 0.93, iconRate, 1 - iconRate)
    end

    -- Dark background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)

    -- 9-slice rounded border (black — default state)
    button._cdm_borders = Create9SliceBorder(button, nil, nil, nil, nil, 7)

    -- Class overlay (shown when spell is active/aura)
    button._cdm_classOverlay = button:CreateTexture(nil, "OVERLAY", nil, 6)
    button._cdm_classOverlay:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
    button._cdm_classOverlay:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
    button._cdm_classOverlay:SetColorTexture(oc.r, oc.g, oc.b, 0.25)
    button._cdm_classOverlay:Hide()

    -- 9-slice rounded border (class-colored — active state)
    button._cdm_activeBorders = Create9SliceBorder(button, oc.r, oc.g, oc.b, 1, 7)
    for _, t in ipairs(button._cdm_activeBorders) do t:Hide() end

    -- 9-slice rounded border (pandemic — orange, buff icons only)
    if isBuff then
        button._cdm_pandemicBorders = Create9SliceBorder(button, PANDEMIC_COLOR.r, PANDEMIC_COLOR.g, PANDEMIC_COLOR.b, 1, 7)
        for _, t in ipairs(button._cdm_pandemicBorders) do t:Hide() end
    end

    -- Custom CD text
    button._cdm_cdText = button:CreateFontString(nil, "OVERLAY", nil)
    button._cdm_cdText:SetFont(FONT, isBuff and (width / 3) or (width / 2.8), "OUTLINE")
    button._cdm_cdText:SetShadowOffset(1, -1)
    button._cdm_cdText:SetShadowColor(0, 0, 0, 1)
    if isBuff then
        button._cdm_cdText:SetPoint("TOP", button, "TOP", 0, -1)
    else
        button._cdm_cdText:SetPoint("CENTER", 0, 0)
    end

    -- Charge count
    if button.ChargeCount then
        for _, r in next, { button.ChargeCount:GetRegions() } do
            if r:GetObjectType() == "FontString" then
                r:SetFont(FONT, width / 3, "OUTLINE")
                r:ClearAllPoints()
                r:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
                r:SetTextColor(0.2, 1, 0.2)
                r:SetDrawLayer("OVERLAY")
                break
            end
        end
    end

    -- Stack count
    if button.Applications then
        for _, r in next, { button.Applications:GetRegions() } do
            if r:GetObjectType() == "FontString" then
                r:SetFont(FONT, width / 3, "OUTLINE")
                r:ClearAllPoints()
                r:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
                r:SetTextColor(0.2, 1, 0.2)
                r:SetDrawLayer("OVERLAY")
                break
            end
        end
    end

    -- DebuffBorder cleanup
    if button.DebuffBorder then
        button.DebuffBorder:ClearAllPoints()
        button.DebuffBorder:SetPoint("TOPLEFT", -2, 2)
        button.DebuffBorder:SetPoint("BOTTOMRIGHT", 2, -2)
    end

    -- Hide Blizzard CD text
    if button.Cooldown then
        button.Cooldown:SetHideCountdownNumbers(true)
        for _, r in next, { button.Cooldown:GetRegions() } do
            if r:GetObjectType() == "FontString" then
                r:SetAlpha(0)
                break
            end
        end

        -- Custom swipe colors: active aura vs normal cooldown
        local sr, sg, sb, sa = GetActiveSwipeColor()
        local cr, cg, cb, ca = GetCDSwipeColor()
        if sr or cr then
            hooksecurefunc(button.Cooldown, "SetCooldown", function(self)
                local parent = self:GetParent()
                if parent and parent.cooldownUseAuraDisplayTime then
                    local af = parent.cooldownUseAuraDisplayTime
                    local isAura = false
                    if issecretvalue and issecretvalue(af) then
                        if (parent.SpellActivationAlert and parent.SpellActivationAlert:IsShown())
                            or (parent.ActiveAuraHighlight and parent.ActiveAuraHighlight:IsShown()) then
                            isAura = true
                        end
                    else
                        isAura = (af == true)
                    end
                    if isAura and sr then
                        self:SetSwipeColor(sr, sg, sb, sa)
                    elseif not isAura and cr then
                        self:SetSwipeColor(cr, cg, cb, ca)
                    end
                elseif cr then
                    self:SetSwipeColor(cr, cg, cb, ca)
                end
            end)
        end

        -- GCD hiding
        local settings = GetSettings()
        if settings and settings.hideGCD then
            hooksecurefunc(button.Cooldown, "SetCooldown", function(self)
                local parent = self:GetParent()
                if parent then
                    local cdID = Scanner.GetCachedCooldownID(parent)
                    if cdID then
                        local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
                        if ok and info then
                            local spellID = info.overrideSpellID or info.spellID
                            if spellID then
                                local cd = C_Spell.GetSpellCooldown(spellID)
                                if cd and cd.isOnGCD then
                                    self:SetCooldownFromDurationObject(C_DurationUtil.CreateDuration())
                                end
                            end
                        end
                    end
                end
            end)
        end
    end

    -- Hotkey text (Essential/Utility only — via CDMKeybinds)
    if not isBuff then
        CDMKeybinds.CreateHotkeyText(button, width)
    end
end

-- =====================================
-- UPDATE ACTIVE STATE + CD TEXT + DESATURATION
-- =====================================
local function UpdateButtonState(button, isBuff)
    if not button._cdm_styled then return end

    -- Active state detection (TWW issecretvalue-safe)
    local isActive = false
    local auraField = button.cooldownUseAuraDisplayTime
    if auraField ~= nil then
        if issecretvalue and issecretvalue(auraField) then
            if button.SpellActivationAlert and button.SpellActivationAlert:IsShown() then
                isActive = true
            elseif button.ActiveAuraHighlight and button.ActiveAuraHighlight:IsShown() then
                isActive = true
            end
        else
            isActive = (auraField == true)
        end
    end

    -- Pandemic detection: show orange border when buff is in the refresh window
    local isPandemic = false
    local settings = GetSettings()
    if isBuff and settings and settings.pandemicEnabled and button.Cooldown then
        local start, duration = button.Cooldown:GetCooldownTimes()
        if type(start) ~= "nil" and type(duration) ~= "nil"
            and not issecretvalue(start) and not issecretvalue(duration) then
            if start > 0 and duration > 0 then
                local now = GetTime()
                local startSec = start / 1000
                local durSec = duration / 1000
                local remaining = startSec + durSec - now
                local threshold = settings.pandemicThreshold or PANDEMIC_THRESHOLD_DEFAULT
                if remaining > 0 and remaining <= (durSec * threshold) then
                    isPandemic = true
                end
            end
        end
    end

    -- Toggle overlay + border
    if isPandemic then
        -- Pandemic: orange border
        button._cdm_classOverlay:Hide()
        for _, t in ipairs(button._cdm_activeBorders) do t:Hide() end
        if button._cdm_pandemicBorders then
            for _, t in ipairs(button._cdm_pandemicBorders) do t:Show() end
        end
        for _, t in ipairs(button._cdm_borders) do t:Hide() end
    elseif isActive then
        button._cdm_classOverlay:Show()
        for _, t in ipairs(button._cdm_activeBorders) do t:Show() end
        if button._cdm_pandemicBorders then
            for _, t in ipairs(button._cdm_pandemicBorders) do t:Hide() end
        end
        for _, t in ipairs(button._cdm_borders) do t:Hide() end
    else
        button._cdm_classOverlay:Hide()
        for _, t in ipairs(button._cdm_activeBorders) do t:Hide() end
        if button._cdm_pandemicBorders then
            for _, t in ipairs(button._cdm_pandemicBorders) do t:Hide() end
        end
        for _, t in ipairs(button._cdm_borders) do t:Show() end
    end

    -- Desaturation on cooldown (non-buff icons)
    if not isBuff and settings and settings.desaturateOnCD and button.Icon then
        local cdID = Scanner.GetCachedCooldownID(button)
        if cdID then
            local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
            if ok and info then
                local spellID = info.overrideSpellID or info.spellID
                if spellID and not isActive then
                    local cd = C_Spell.GetSpellCooldown(spellID)
                    if cd and not cd.isOnGCD then
                        local cdDuration = CooldownTracker:GetSpellCD(spellID)
                        if cdDuration and cdDuration.EvaluateRemainingDuration then
                            local desat = cdDuration:EvaluateRemainingDuration(desaturationCurve)
                            button.Icon:SetDesaturation(desat or 0)
                        else
                            button.Icon:SetDesaturation(0)
                        end
                    else
                        button.Icon:SetDesaturation(0)
                    end
                else
                    button.Icon:SetDesaturation(0)
                end
            end
        end
    end

    -- Range check: tint icon red if target is out of range (Essential/Utility only)
    if not isBuff and settings and settings.rangeCheckEnabled and button.Icon then
        local cdID = Scanner.GetCachedCooldownID(button)
        if cdID then
            local spellID = nil
            local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
            if ok and info then spellID = info.overrideSpellID or info.spellID end
            if spellID then
                local inRange = C_Spell.IsSpellInRange(spellID, "target")
                if inRange == false then
                    -- Explicitly out of range (target exists, spell has range, OOR)
                    button.Icon:SetVertexColor(RANGE_OOR_COLOR.r, RANGE_OOR_COLOR.g, RANGE_OOR_COLOR.b)
                    button._cdm_oorState = true
                else
                    -- In range, no target, or spell has no range component
                    if button._cdm_oorState then
                        button.Icon:SetVertexColor(RANGE_OK_COLOR.r, RANGE_OK_COLOR.g, RANGE_OK_COLOR.b)
                        button._cdm_oorState = false
                    end
                end
            end
        end
    end

    -- Custom CD text
    if button.Cooldown then
        local start, duration = button.Cooldown:GetCooldownTimes()
        if type(start) ~= "nil" and type(duration) ~= "nil"
            and not issecretvalue(start) and not issecretvalue(duration) then
            if start > 0 and duration > 0 then
                local now = GetTime()
                local startSec = start / 1000
                local durSec = duration / 1000
                local remaining = startSec + durSec - now
                if remaining > 0 then
                    if isBuff then
                        button._cdm_cdText:SetText(FormatDuration(remaining))
                        button._cdm_cdText:SetTextColor(1, 1, 1)
                    else
                        button._cdm_cdText:SetText(FormatCooldown(remaining))
                        if remaining < 3 then
                            button._cdm_cdText:SetTextColor(1, 0.8, 0)
                        else
                            button._cdm_cdText:SetTextColor(1, 1, 1)
                        end
                    end
                    button._cdm_cdText:Show()
                    return
                end
            end
        end
    end
    button._cdm_cdText:Hide()
end

-- =====================================
-- BUFF BAR RESKIN
-- =====================================
local function StyleBuffBar(item)
    if item._cdm_styled then return end
    item._cdm_styled = true

    if item.Bar then
        local bar = item.Bar
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
        bar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 0.85)
        if bar.BarBG then bar.BarBG:Hide() end
        bar.Name:Hide()

        if not bar._cdm_bg then
            bar._cdm_bg = bar:CreateTexture(nil, "BACKGROUND")
            bar._cdm_bg:SetPoint("TOPLEFT", -1, 1)
            bar._cdm_bg:SetPoint("BOTTOMRIGHT", 1, -1)
            bar._cdm_bg:SetColorTexture(0, 0, 0, 1)
        end
    end

    if item.Icon then
        local btn = item.Icon
        local h = item.Bar and item.Bar:GetHeight() or 14
        local w = h * 1.15

        btn:SetSize(w, h)
        if btn.Icon then
            local mask = btn.Icon:GetMaskTexture(1)
            if mask then btn.Icon:RemoveMaskTexture(mask) end
            btn.Icon:ClearAllPoints()
            btn.Icon:SetPoint("TOPLEFT", 1, -1)
            btn.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
            btn.Icon:SetTexCoord(0.07, 0.93, 0.1, 0.9)
        end

        -- Strip all Blizzard border/overlay textures
        if btn.Border then btn.Border:SetAlpha(0) end
        if btn.DebuffBorder then btn.DebuffBorder:SetAlpha(0) end
        if btn.IconBorder then btn.IconBorder:SetAlpha(0) end
        if btn.NormalTexture then btn.NormalTexture:SetAlpha(0) end
        if btn.SetNormalTexture then btn:SetNormalTexture("") end
        -- Hide any remaining Blizzard border regions
        for _, region in next, { btn:GetRegions() } do
            if region:GetObjectType() == "Texture" and region ~= btn.Icon
                and region ~= (btn._cdm_border and btn._cdm_border[1]) then
                local atlas = region.GetAtlas and region:GetAtlas()
                local tex = region.GetTexture and region:GetTexture()
                if atlas or (tex and type(tex) == "string" and tex:find("Border")) then
                    region:SetAlpha(0)
                end
            end
        end

        if not btn._cdm_border then
            btn._cdm_border = Create9SliceBorder(btn, nil, nil, nil, nil, 7)
        end

        if btn.Applications then
            local r = btn.Applications
            if r:GetObjectType() == "FontString" then
                r:SetFont(FONT, h / 2 + 2, "OUTLINE")
                r:SetTextColor(0.2, 1, 0.2)
            end
        end
    end
end

-- =====================================
-- UTILITY DIMMING
-- Dim utility icons when NOT on cooldown
-- Uses CooldownTracker for cached duration objects
-- Supports charge-based spells
-- =====================================
local _dimCurve, _dimCurveOpacity

local function GetDimCurve(opacity)
    if _dimCurve and _dimCurveOpacity == opacity then return _dimCurve end
    _dimCurve = C_CurveUtil.CreateCurve()
    _dimCurve:AddPoint(0.0, opacity)
    _dimCurve:AddPoint(0.1, 1)
    _dimCurveOpacity = opacity
    return _dimCurve
end

local function UpdateUtilityDimming()
    local viewer = UtilityCooldownViewer
    if not viewer then return end
    local s = GetSettings()
    if not s or not s.dimUtility then return end
    local dimOpacity = s.dimOpacity or 0.35

    local children = GetCachedChildren(viewer)
    for _, child in ipairs(children) do
        if child and child:IsShown() and child.Icon then
            local cdID = Scanner.GetCachedCooldownID(child)
            if cdID then
                local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
                if ok and info then
                    local spellID = info.overrideSpellID or info.spellID
                    if spellID then
                        local cd = C_Spell.GetSpellCooldown(spellID)
                        if cd and not cd.isOnGCD then
                            -- Use charge CD for spells with charges (cached via Scanner)
                            local cdDuration
                            if Scanner.GetCachedChargesShown(child) then
                                cdDuration = CooldownTracker:GetChargeCD(spellID)
                            else
                                cdDuration = CooldownTracker:GetSpellCD(spellID)
                            end
                            if cdDuration and cdDuration.EvaluateRemainingDuration then
                                local curve = GetDimCurve(dimOpacity)
                                local alpha = cdDuration:EvaluateRemainingDuration(curve)
                                if alpha then
                                    child:SetAlpha(alpha)
                                end
                            else
                                child:SetAlpha(dimOpacity)
                            end
                        else
                            child:SetAlpha(dimOpacity)
                        end
                    end
                end
            end
        end
    end
end

-- =====================================
-- BUFF ICON AURA HOOKS
-- Hook aura events on buff icon children for auto-relayout
-- =====================================
local function HookBuffIconAuras(child, viewer)
    if child._cdm_hooked then return end
    child._cdm_hooked = true
    local function TriggerRelayout()
        todoList[viewer] = true
        InvalidateChildrenCache(viewer)
        CDMLayout.Invalidate(viewer)
        if updateFrame then updateFrame:Show() end
    end
    if child.OnActiveStateChanged then
        hooksecurefunc(child, "OnActiveStateChanged", TriggerRelayout)
    end
    if child.OnUnitAuraAddedEvent then
        hooksecurefunc(child, "OnUnitAuraAddedEvent", TriggerRelayout)
    end
    if child.OnUnitAuraRemovedEvent then
        hooksecurefunc(child, "OnUnitAuraRemovedEvent", TriggerRelayout)
    end
end

-- =====================================
-- SKIN AND LAYOUT (Phase 2)
-- Skins unskinned children, hooks aura events, then delegates
-- positioning + viewer resize to CDMLayout.
-- =====================================
local function SkinAndLayout(viewer, isBuff)
    local isBar = (viewer == BuffBarCooldownViewer)

    if isBar then
        -- Skin all visible bar items
        local children = { viewer:GetChildren() }
        for _, child in ipairs(children) do
            if child:IsShown() then
                StyleBuffBar(child)
            end
        end
    else
        -- Skin all visible icon buttons + hook aura events for buff icons
        local children = GetCachedChildren(viewer)
        for _, child in ipairs(children) do
            if child:IsShown() and child.layoutIndex then
                StyleButton(child, isBuff)
                if not isBuff then CDMKeybinds.UpdateButton(child) end
                -- Phase 3: Re-apply proc glow after reskin
                CDMProcGlow.UpdateButton(child)
                -- Hook buff icon aura events for auto-relayout
                if isBuff then HookBuffIconAuras(child, viewer) end
            end
        end
    end

    -- Delegate positioning + viewer resize to CDMLayout
    CDMLayout.LayoutViewer(viewer, isBuff)
end

-- =====================================
-- TICKER: Update CD text + active state + dimming
-- =====================================
local dimElapsed = 0
local DIM_RATE = 0.1

local function TickerUpdate(dt)
    if not isInitialized then return end

    for _, viewer in ipairs(viewers) do
        if viewer and viewer:IsShown() then
            local isBar = (viewer == BuffBarCooldownViewer)
            if not isBar then
                local isBuff = (viewer == BuffIconCooldownViewer)
                local children = GetCachedChildren(viewer)
                for _, button in ipairs(children) do
                    if button:IsShown() and button._cdm_styled then
                        UpdateButtonState(button, isBuff)
                    end
                end
            end
        end
    end

    -- Utility dimming at a lower rate
    dimElapsed = dimElapsed + dt
    if dimElapsed >= DIM_RATE then
        dimElapsed = 0
        UpdateUtilityDimming()
    end

    -- Sound Alerts: play sound when Essential/Utility spells come off cooldown
    local s = GetSettings()
    if s and s.soundAlertEnabled then
        for _, viewer in ipairs(cdViewers) do
            if viewer and viewer:IsShown() then
                local children = GetCachedChildren(viewer)
                for _, button in ipairs(children) do
                    if button then
                        local cdID = Scanner.GetCachedCooldownID(button)
                        if cdID then
                            local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
                            if ok and info then
                                local spellID = info.overrideSpellID or info.spellID
                                if spellID then
                                    local cd = C_Spell.GetSpellCooldown(spellID)
                                    local isOnCD = cd and cd.duration and cd.duration > 1.5 and not cd.isOnGCD
                                    if isOnCD then
                                        soundSpellState[spellID] = true
                                    elseif soundSpellState[spellID] then
                                        -- Spell just came off cooldown
                                        soundSpellState[spellID] = nil
                                        local now = GetTime()
                                        if (now - lastSoundAlertTime) >= SOUND_ALERT_COOLDOWN then
                                            lastSoundAlertTime = now
                                            local soundFile = s.soundAlertFile or SOUND_ALERT_DEFAULT_FILE
                                            PlaySoundFile(soundFile, "Master")
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- =====================================
-- TODO LIST (deferred layout)
-- =====================================
local function AddToDoList(viewer)
    todoList[viewer] = true
    InvalidateChildrenCache(viewer)
    CDMLayout.Invalidate(viewer)
    if updateFrame then updateFrame:Show() end
end

-- =====================================
-- VISIBILITY RULES (inspired by CooldownManagerCentered)
-- Supports: combat alpha, mounted, vehicle, instance, enemy target
-- =====================================
local function UpdateAlpha()
    local settings = GetSettings()
    if not settings then return end

    local visRules = settings.visibilityRules
    if visRules and next(visRules) then
        -- Advanced visibility rules
        local isMounted = IsMounted()
        local inInstance = IsInInstance()
        local hasTarget = UnitExists("target")
        local targetIsEnemy = UnitCanAttack("player", "target")
        local inCombat = UnitAffectingCombat("player")
        local shapeshiftFormID = GetShapeshiftFormID()
        local inVehicle = clientSceneActive or C_ActionBar.HasOverrideActionBar() or UnitInVehicle("player")

        -- Determine base alpha from combat state
        local alpha
        if inCombat then
            alpha = settings.alphaInCombat or 1.0
        elseif hasTarget then
            alpha = settings.alphaWithTarget or 0.8
        else
            alpha = settings.alphaOutOfCombat or 0.5
        end

        for _, viewer in ipairs(viewers) do
            if viewer then
                local viewerAlpha = alpha
                local shouldHide = false

                if visRules.hideInVehicles and inVehicle then
                    shouldHide = true
                elseif visRules.hideWhenMounted and (isMounted or shapeshiftFormID == 3 or shapeshiftFormID == 29 or shapeshiftFormID == 27) then
                    shouldHide = true
                elseif visRules.hideOutOfCombat and not inCombat and not hasTarget then
                    shouldHide = true
                end

                -- Show overrides
                if shouldHide then
                    if visRules.showInCombat and inCombat then
                        shouldHide = false
                    elseif visRules.showInInstance and inInstance then
                        shouldHide = false
                    elseif visRules.showWithEnemyTarget and hasTarget and targetIsEnemy then
                        shouldHide = false
                    end
                end

                viewer:SetAlpha(shouldHide and 0 or viewerAlpha)
            end
        end
    elseif settings.combatAlpha then
        -- Simple combat alpha mode (V2 compatibility)
        local alpha
        if UnitAffectingCombat("player") then
            alpha = settings.alphaInCombat or 1.0
        elseif UnitExists("target") then
            alpha = settings.alphaWithTarget or 0.8
        else
            alpha = settings.alphaOutOfCombat or 0.5
        end
        for _, viewer in ipairs(viewers) do
            if viewer then viewer:SetAlpha(alpha) end
        end
    end
end

-- =====================================
-- HOTKEY VISIBILITY (delegated to CDMKeybinds)
-- =====================================
local function RefreshHotkeyVisibility()
    CDMKeybinds.RefreshVisibility(cdViewers)
end

-- =====================================
-- INIT
-- =====================================
local function InitViewers()
    if not UtilityCooldownViewer then return false end

    -- Phase 1: Populate CDMScanner cache before anything else
    Scanner.ScanAll()

    -- Phase 3: Initialize keybind system
    CDMKeybinds.Initialize()

    viewers = {
        EssentialCooldownViewer,
        UtilityCooldownViewer,
        BuffIconCooldownViewer,
        BuffBarCooldownViewer,
    }

    cdViewers = {
        EssentialCooldownViewer,
        UtilityCooldownViewer,
    }

    -- Hook Layout on each viewer
    for _, viewer in ipairs(viewers) do
        if viewer then
            local isBuff = (viewer == BuffIconCooldownViewer)
            SkinAndLayout(viewer, isBuff)

            -- Hook ALL known layout methods to catch Blizzard re-positioning.
            -- Use force=true to bypass IsReady (layoutApplyInProgress may be true
            -- during Blizzard's layout pass, which would cause our hook to bail).
            local function OnBlizzardLayout()
                CDMLayout.LayoutViewer(viewer, isBuff, true)
            end

            if viewer.Layout then
                hooksecurefunc(viewer, "Layout", OnBlizzardLayout)
            end
            if viewer.RefreshLayout then
                hooksecurefunc(viewer, "RefreshLayout", OnBlizzardLayout)
            end
            if viewer.UpdateLayout then
                hooksecurefunc(viewer, "UpdateLayout", OnBlizzardLayout)
            end

            local children = GetCachedChildren(viewer)
            for _, child in ipairs(children) do
                -- Ensure each child is cached in Scanner
                Scanner.EnsureCached(child)
                -- Hook aura events for buff icon auto-relayout
                if isBuff then HookBuffIconAuras(child, viewer) end
                child:HookScript("OnShow", function(self)
                    -- Cache newly shown frames (may appear after talent changes)
                    Scanner.EnsureCached(self)
                    AddToDoList(viewer)
                end)
                child:HookScript("OnHide", function() AddToDoList(viewer) end)
            end

            -- For buff icon viewer: schedule retries to beat late Blizzard layout calls
            if isBuff then
                for _, delay in ipairs({ 0.1, 0.3, 0.6, 1.0 }) do
                    C_Timer.After(delay, function()
                        CDMLayout.LayoutViewer(viewer, true, true)
                    end)
                end
            end
        end
    end

    -- [PERF] C_Timer.NewTicker replaces OnUpdate accumulator — no per-frame Lua callback
    tickerFrame = C_Timer.NewTicker(TICK_RATE, function()
        TickerUpdate(TICK_RATE)
    end)

    -- Deferred layout processor (Phase 2: uses SkinAndLayout → CDMLayout)
    updateFrame = CreateFrame("Frame")
    updateFrame:Hide()
    updateFrame:SetScript("OnUpdate", function(self)
        self:Hide()
        for viewer in pairs(todoList) do
            todoList[viewer] = nil
            local isBuff = (viewer == BuffIconCooldownViewer)
            SkinAndLayout(viewer, isBuff)
        end
    end)

    UpdateAlpha()
    isInitialized = true

    -- Phase 3: Initialize proc glow module
    CDMProcGlow.Initialize()

    return true
end

-- =====================================
-- EVENT HANDLER
-- =====================================
local function OnEvent(self, event, arg1)
    local settings = GetSettings()
    if not settings then return end

    if event == "ADDON_LOADED" and arg1 == "Blizzard_CooldownManager" then
        C_Timer.After(0.5, function()
            if not isInitialized then InitViewers() end
        end)

    elseif event == "PLAYER_ENTERING_WORLD" or event == "TRAIT_CONFIG_UPDATED"
        or event == "TRAIT_CONFIG_LIST_UPDATED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        C_Timer.After(0.5, function()
            if not isInitialized then InitViewers() end
            -- Refresh Scanner info cache (override spells may have changed)
            Scanner.RefreshInfo()
            CDMKeybinds.Rebuild()
            RefreshHotkeyVisibility()
            UpdateAlpha()
            -- Force re-layout all after spec/talent change
            for _, viewer in ipairs(viewers) do
                if viewer then AddToDoList(viewer) end
            end
        end)

    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_TARGET_CHANGED" then
        UpdateAlpha()

    elseif event == "UPDATE_BONUS_ACTIONBAR" or event == "ACTIONBAR_SLOT_CHANGED" then
        C_Timer.After(0.1, function()
            CDMKeybinds.Rebuild()
            RefreshHotkeyVisibility()
        end)

    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        UpdateAlpha()
        -- Some spells change on shapeshift
        for _, viewer in ipairs(viewers) do
            if viewer then AddToDoList(viewer) end
        end

    elseif event == "SPELL_UPDATE_COOLDOWN" then
        -- Trigger utility dimming refresh (via the ticker, but also on event for responsiveness)
        UpdateUtilityDimming()

    elseif event == "CLIENT_SCENE_OPENED" then
        local sceneType = arg1
        clientSceneActive = (sceneType == 1)
        UpdateAlpha()

    elseif event == "CLIENT_SCENE_CLOSED" then
        clientSceneActive = false
        UpdateAlpha()

    elseif event == "MOUNT_JOURNAL_USABILITY_CHANGED" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        UpdateAlpha()
    end
end

-- =====================================
-- PUBLIC API
-- =====================================
function CDM.Initialize()
    if not TomoModDB then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    mainFrame = CreateFrame("Frame")
    mainFrame:RegisterEvent("ADDON_LOADED")
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    mainFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    mainFrame:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
    mainFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    mainFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    mainFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    mainFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    mainFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    mainFrame:RegisterEvent("CLIENT_SCENE_OPENED")
    mainFrame:RegisterEvent("CLIENT_SCENE_CLOSED")
    mainFrame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
    mainFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    mainFrame:SetScript("OnEvent", OnEvent)

    -- Hook edit mode enter/exit for runtime state
    -- Note: CDMLayout handles viewer resize save/restore during Edit Mode.
    -- These hooks handle CDM-specific behavior (alpha, relayout).
    if EventRegistry then
        EventRegistry:RegisterCallback("EditMode.Enter", function()
            -- CDMLayout restores Blizzard viewer sizes automatically
        end)
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            -- Force refresh on exit edit mode
            C_Timer.After(0, function()
                if isInitialized then
                    for _, viewer in ipairs(viewers) do
                        if viewer then AddToDoList(viewer) end
                    end
                end
            end)
        end)
        EventRegistry:RegisterCallback("CooldownViewerSettings.OnDataChanged", function()
            C_Timer.After(0, function()
                if isInitialized then
                    for _, viewer in ipairs(viewers) do
                        if viewer then
                            InvalidateChildrenCache(viewer)
                            AddToDoList(viewer)
                        end
                    end
                end
            end)
        end)
    end
end
function CDM.ApplySettings()
    if not isInitialized then return end
    local settings = GetSettings()
    if not settings then return end

    -- Update overlay color reference
    overlayColor = CLASS_OVERLAY_COLORS[playerClass] or classColor

    RefreshHotkeyVisibility()

    -- Update visibility/alpha
    local visRules = settings.visibilityRules
    if (visRules and next(visRules)) or settings.combatAlpha then
        UpdateAlpha()
    else
        for _, viewer in ipairs(viewers) do
            if viewer then viewer:SetAlpha(1) end
        end
    end

    -- Invalidate caches and re-layout all viewers (Phase 2: via SkinAndLayout → CDMLayout)
    for _, viewer in ipairs(viewers) do
        if viewer then
            InvalidateChildrenCache(viewer)
            CDMLayout.Invalidate(viewer)
            local isBuff = (viewer == BuffIconCooldownViewer)
            SkinAndLayout(viewer, isBuff)
        end
    end

    -- Phase 3: Refresh proc glows after settings change
    CDMProcGlow.RefreshAll()
end

function CDM.SetEnabled(enabled)
    local settings = GetSettings()
    if settings then
        settings.enabled = enabled
        if enabled and not isInitialized then
            InitViewers()
        end
    end
end

-- Export
_G.TomoMod_CooldownManager = CDM

-- =====================================
-- DEBUG: Layout diagnostics
-- /tomocdm debug  — prints viewer state, methods, settings
-- /tomocdm force  — forces horizontal layout on buff icons
-- =====================================
SLASH_TOMOCDMDEBUG1 = "/tomocdm"
SlashCmdList["TOMOCDMDEBUG"] = function(msg)
    if msg == "debug" then
        print("|cff00ccffTomoMod CDM Debug:|r")
        print("  isInitialized: " .. tostring(isInitialized))

        local db = TomoModDB and TomoModDB.cooldownManager
        print("  DB.buffIconDirection: " .. tostring(db and db.buffIconDirection))
        print("  DB.buffBarDirection: " .. tostring(db and db.buffBarDirection))

        local biv = BuffIconCooldownViewer
        if biv then
            print("  BuffIconCooldownViewer exists: true")
            print("    :GetName() = " .. tostring(biv:GetName()))
            print("    .isHorizontal = " .. tostring(biv.isHorizontal))
            print("    .iconDirection = " .. tostring(biv.iconDirection))
            print("    .Layout exists = " .. tostring(biv.Layout ~= nil))
            print("    .RefreshLayout exists = " .. tostring(biv.RefreshLayout ~= nil))
            print("    .UpdateLayout exists = " .. tostring(biv.UpdateLayout ~= nil))
            local children = { biv:GetChildren() }
            local shown = 0
            for _, c in ipairs(children) do
                if c:IsShown() then shown = shown + 1 end
            end
            print("    Children: " .. #children .. " total, " .. shown .. " shown")
            if shown > 0 then
                local first
                for _, c in ipairs(children) do
                    if c:IsShown() then first = c; break end
                end
                if first then
                    local pt, rel, rp, ox, oy = first:GetPoint()
                    print("    First shown child point: " .. tostring(pt) .. " → " .. tostring(rp) .. " (" .. tostring(ox) .. ", " .. tostring(oy) .. ")")
                end
            end
        else
            print("  BuffIconCooldownViewer exists: false")
        end

    elseif msg == "force" then
        local biv = BuffIconCooldownViewer
        if not biv then
            print("|cff00ccffTomoMod CDM:|r BuffIconCooldownViewer not found")
            return
        end
        print("|cff00ccffTomoMod CDM:|r Forcing horizontal layout on buff icons...")
        CDMLayout.LayoutViewer(biv, true, true)
        -- Print result
        local children = { biv:GetChildren() }
        for i, c in ipairs(children) do
            if c:IsShown() then
                local pt, _, rp, ox, oy = c:GetPoint()
                print(string.format("  [%d] %s → %s (%.1f, %.1f)", i, tostring(pt), tostring(rp), ox or 0, oy or 0))
            end
        end

    else
        print("|cff00ccffTomoMod CDM:|r Commands: debug, force")
    end
end
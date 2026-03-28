-- =====================================
-- CooldownManager V2
-- Clean & modern reskin of Blizzard CooldownManager
-- 9-slice rounded borders, class overlay on active auras,
-- custom swipe colors, utility dimming, centered layout,
-- hotkeys, custom CD text
-- =====================================

TomoMod_CooldownManager = TomoMod_CooldownManager or {}
local CDM = TomoMod_CooldownManager

-- =====================================
-- CONSTANTS
-- =====================================
local FONT            = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BORDER_TEX      = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\border.png"
local BORDER_CORNER   = 4
local ICON_INSET      = 3
local SPACING         = 1
local TICK_RATE       = 0.25
local floor, abs, ceil = math.floor, math.abs, math.ceil

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
local hotkeys = {}
local viewers = {}
local cdViewers = {}
local todoList = {}
local isInitialized = false
local mainFrame, updateFrame, tickerFrame

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

-- Named sort functions
local function SortByStableSlot(a, b)
    return (a._cdm_stableSlot or 0) < (b._cdm_stableSlot or 0)
end
local function SortByLayoutIndex(a, b)
    return (a.layoutIndex or 0) < (b.layoutIndex or 0)
end

-- [PERF] Pre-allocated tables for hot-path layout functions
local _cdm_visible = {}
local _cdm_buffVisible = {}
local _cdm_positions = {}
local _le_offsets = {}
local _le_rows = {}

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
-- LAYOUT ENGINE (inspired by CooldownManagerCentered)
-- Pure math — no frame access
-- =====================================
local LayoutEngine = {}

function LayoutEngine.CenteredRowXOffsets(count, itemWidth, padding, directionMod, iconLimit)
    if not count or count <= 0 then return _le_offsets end
    local dir = directionMod or 1
    local missing = (iconLimit or count) - count
    local startX = ((itemWidth + padding) * missing / 2) * dir
    wipe(_le_offsets)
    for i = 1, count do
        _le_offsets[i] = startX + (i - 1) * (itemWidth + padding) * dir
    end
    return _le_offsets
end

function LayoutEngine.CenteredColYOffsets(count, itemHeight, padding, directionMod, iconLimit)
    if not count or count <= 0 then return _le_offsets end
    local dir = directionMod or 1
    local missing = (iconLimit or count) - count
    local startY = -((itemHeight + padding) * missing / 2) * dir
    wipe(_le_offsets)
    for i = 1, count do
        _le_offsets[i] = startY - (i - 1) * (itemHeight + padding) * dir
    end
    return _le_offsets
end

function LayoutEngine.BuildRows(iconLimit, children)
    -- Wipe sub-rows in-place to reuse them, then trim excess
    for _, row in pairs(_le_rows) do wipe(row) end
    local limit = iconLimit or 0
    if limit <= 0 then
        -- Remove all rows
        for k in pairs(_le_rows) do _le_rows[k] = nil end
        return _le_rows
    end
    local maxRow = 0
    for i = 1, #children do
        local ri = floor((i - 1) / limit) + 1
        if ri > maxRow then maxRow = ri end
        _le_rows[ri] = _le_rows[ri] or {}
        _le_rows[ri][#_le_rows[ri] + 1] = children[i]
    end
    -- Trim rows beyond what we need
    for k = maxRow + 1, #_le_rows do _le_rows[k] = nil end
    return _le_rows
end

-- =====================================
-- HOTKEY SYSTEM
-- =====================================
local function CheckKeyName(name)
    name = string.gsub(name, "Num Pad ", "")
    name = string.gsub(name, "Num Pad", "")
    name = string.gsub(name, "Middle Mouse", "M3")
    name = string.gsub(name, "Mouse Button (%d)", "M%1")
    name = string.gsub(name, "Mouse Wheel Up", "MU")
    name = string.gsub(name, "Mouse Wheel Down", "MD")
    name = string.gsub(name, "^s%-", "S")
    name = string.gsub(name, "^a%-", "A")
    name = string.gsub(name, "^c%-", "C")
    name = string.gsub(name, "Delete", "Dt")
    name = string.gsub(name, "Page Down", "Pd")
    name = string.gsub(name, "Page Up", "Pu")
    name = string.gsub(name, "Insert", "In")
    name = string.gsub(name, "Del", "Dt")
    name = string.gsub(name, "Home", "Hm")
    name = string.gsub(name, "Capslock", "Ck")
    name = string.gsub(name, "Num Lock", "Nk")
    name = string.gsub(name, "Scroll Lock", "Sk")
    name = string.gsub(name, "Backspace", "Bs")
    name = string.gsub(name, "Spacebar", "Sb")
    name = string.gsub(name, "End", "Ed")
    name = string.gsub(name, "Up Arrow", "^")
    name = string.gsub(name, "Down Arrow", "V")
    name = string.gsub(name, "Right Arrow", ">")
    name = string.gsub(name, "Left Arrow", "<")
    return name
end

local function ScanKeys(barName, total)
    for i = 1, total do
        local actionButton = _G[barName .. i]
        if not actionButton then break end
        local hotkey = _G[actionButton:GetName() .. "HotKey"]
        if not hotkey then break end
        local text = hotkey:GetText()
        local slot = actionButton.action
        if slot and text then
            hotkeys[slot] = CheckKeyName(text)
        end
    end
end

local function CheckHotkeys()
    wipe(hotkeys)
    ScanKeys("ActionButton", 12)
    ScanKeys("MultiBarBottomLeftButton", 12)
    ScanKeys("MultiBarBottomRightButton", 12)
    ScanKeys("MultiBarRightButton", 12)
    ScanKeys("MultiBarLeftButton", 12)
    ScanKeys("MultiBar5Button", 12)
    ScanKeys("MultiBar6Button", 12)
    ScanKeys("MultiBar7Button", 12)
    ScanKeys("BonusActionButton", 12)
    ScanKeys("ExtraActionButton", 12)
    ScanKeys("VehicleMenuBarActionButton", 12)
    ScanKeys("OverrideActionBarButton", 12)
    ScanKeys("PetActionButton", 10)
end

local function GetSpellHotkey(spellID)
    local slots = C_ActionBar.FindSpellActionButtons(spellID)
    if slots and #slots > 0 then
        for _, slot in ipairs(slots) do
            if hotkeys[slot] then return hotkeys[slot] end
        end
    end
    return nil
end

-- =====================================
-- STYLE: CLEAN BORDER + ICON CROP
-- =====================================
local function StyleButton(button, isBuff)
    if button._cdm_styled then return end
    button._cdm_styled = true

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

        -- Custom swipe color on active aura
        local sr, sg, sb, sa = GetActiveSwipeColor()
        if sr then
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
                    if isAura then
                        self:SetSwipeColor(sr, sg, sb, sa)
                    end
                end
            end)
        end
    end

    -- Hotkey text (Essential/Utility only)
    if not isBuff then
        button._cdm_hotkey = button:CreateFontString(nil, "OVERLAY")
        button._cdm_hotkey:SetFont(FONT, math.max(8, width / 4 - 1), "OUTLINE")
        button._cdm_hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
        button._cdm_hotkey:SetTextColor(0.9, 0.9, 0.9, 0.9)
        button._cdm_hotkey:SetShadowOffset(1, -1)
        button._cdm_hotkey:SetShadowColor(0, 0, 0, 1)
        button._cdm_hotkey:Hide()
    end
end

-- =====================================
-- UPDATE ACTIVE STATE + CD TEXT
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

    -- Toggle overlay + border
    if isActive then
        button._cdm_classOverlay:Show()
        for _, t in ipairs(button._cdm_activeBorders) do t:Show() end
        for _, t in ipairs(button._cdm_borders) do t:Hide() end
    else
        button._cdm_classOverlay:Hide()
        for _, t in ipairs(button._cdm_activeBorders) do t:Hide() end
        for _, t in ipairs(button._cdm_borders) do t:Show() end
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
-- HOTKEY UPDATE
-- =====================================
local function UpdateButtonHotkey(button)
    local settings = GetSettings()
    if not settings or not settings.showHotKey or not button._cdm_hotkey then return end

    local spellID = button:GetSpellID()
    if type(spellID) ~= "nil" and not (issecretvalue and issecretvalue(spellID)) then
        button._cdm_spellID = spellID
        local keyText = GetSpellHotkey(spellID)
        if keyText then
            button._cdm_hotkey:SetText(keyText)
            button._cdm_hotkey:Show()
        else
            button._cdm_hotkey:Hide()
        end
    end
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

        if not btn._cdm_border then
            btn._cdm_border = btn:CreateTexture(nil, "BACKGROUND")
            btn._cdm_border:SetAllPoints(btn)
            btn._cdm_border:SetColorTexture(0, 0, 0, 1)
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
-- VIEWER ADAPTERS
-- Collect visible children for each viewer type
-- =====================================
local ViewerAdapters = {}

function ViewerAdapters.CollectVisibleSorted(viewer)
    local children = GetCachedChildren(viewer)
    wipe(_cdm_visible)
    for _, child in ipairs(children) do
        if child:IsShown() and child.layoutIndex then
            _cdm_visible[#_cdm_visible + 1] = child
        end
    end
    table.sort(_cdm_visible, SortByLayoutIndex)
    return _cdm_visible
end

function ViewerAdapters.CollectVisibleBuffIcons()
    if not BuffIconCooldownViewer then return _cdm_buffVisible, 0 end
    local children = GetCachedChildren(BuffIconCooldownViewer)
    wipe(_cdm_buffVisible)
    local total = 0
    for _, child in ipairs(children) do
        if child and (child.Icon or child.icon) and child.layoutIndex then
            total = total + 1
            if child:IsShown() then
                _cdm_buffVisible[#_cdm_buffVisible + 1] = child
                -- Hook aura events for auto-relayout
                if not child._cdm_hooked then
                    child._cdm_hooked = true
                    if child.OnActiveStateChanged then
                        hooksecurefunc(child, "OnActiveStateChanged", function()
                            todoList[BuffIconCooldownViewer] = true
                            InvalidateChildrenCache(BuffIconCooldownViewer)
                            if updateFrame then updateFrame:Show() end
                        end)
                    end
                    if child.OnUnitAuraAddedEvent then
                        hooksecurefunc(child, "OnUnitAuraAddedEvent", function()
                            todoList[BuffIconCooldownViewer] = true
                            InvalidateChildrenCache(BuffIconCooldownViewer)
                            if updateFrame then updateFrame:Show() end
                        end)
                    end
                    if child.OnUnitAuraRemovedEvent then
                        hooksecurefunc(child, "OnUnitAuraRemovedEvent", function()
                            todoList[BuffIconCooldownViewer] = true
                            InvalidateChildrenCache(BuffIconCooldownViewer)
                            if updateFrame then updateFrame:Show() end
                        end)
                    end
                end
            end
        end
    end
    table.sort(_cdm_buffVisible, SortByLayoutIndex)
    return _cdm_buffVisible, total
end

-- =====================================
-- UTILITY DIMMING
-- Dim utility icons when NOT on cooldown
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
        if child and child:IsShown() and child.Icon and child.cooldownID then
            local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, child.cooldownID)
            if ok and info then
                local spellID = info.overrideSpellID or info.spellID
                if spellID then
                    local cd = C_Spell.GetSpellCooldown(spellID)
                    if cd and not cd.isOnGCD then
                        local duration = C_Spell.GetSpellCooldownDuration(spellID)
                        if duration and duration.EvaluateRemainingDuration then
                            local curve = GetDimCurve(dimOpacity)
                            local alpha = duration:EvaluateRemainingDuration(curve)
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

-- =====================================
-- LAYOUT: CENTERED ALIGNMENT V2
-- Uses LayoutEngine for proper centered rows with iconLimit,
-- dirty-check positioning, center-outward buffs
-- =====================================
local function PositionRowHorizontal(viewer, row, yOffset, w, padding, dirMod, anchor, iconLimit)
    local count = #row
    local xOffsets = LayoutEngine.CenteredRowXOffsets(count, w, padding, dirMod, iconLimit)
    for i, icon in ipairs(row) do
        local x = xOffsets[i] or 0
        -- Dirty-check: skip repositioning if already correct
        local needSet = true
        if icon.GetPoint then
            local pt, _, rp, ox, oy = icon:GetPoint()
            if ox and oy then
                if pt == anchor and rp == anchor and abs(x - ox) < 1 and abs(yOffset - oy) < 1 then
                    needSet = false
                end
            end
        end
        if needSet then
            icon:ClearAllPoints()
            icon:SetPoint(anchor, viewer, anchor, x, yOffset)
        end
    end
end

local function LayoutViewer(viewer, isBuff)
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then return end

    -- Buff bars: stable-slot vertical stack
    local isBar = (viewer == BuffBarCooldownViewer)
    if isBar then
        local children = GetCachedChildren(viewer)
        wipe(_cdm_visible)
        for _, child in ipairs(children) do
            if child:IsShown() then _cdm_visible[#_cdm_visible + 1] = child end
        end
        if #_cdm_visible == 0 then
            viewer._cdm_nextSlot = nil
            for _, child in ipairs(children) do child._cdm_stableSlot = nil end
            return
        end
        for _, item in ipairs(_cdm_visible) do
            StyleBuffBar(item)
            if not item._cdm_stableSlot then
                viewer._cdm_nextSlot = (viewer._cdm_nextSlot or 0) + 1
                item._cdm_stableSlot = viewer._cdm_nextSlot
            end
        end
        table.sort(_cdm_visible, SortByStableSlot)
        local BAR_GAP = 2
        local yOff = 0
        for _, item in ipairs(_cdm_visible) do
            local h = item:GetHeight()
            item:ClearAllPoints()
            item:SetPoint("TOPLEFT", viewer, "TOPLEFT", 0, -yOff)
            item:SetPoint("TOPRIGHT", viewer, "TOPRIGHT", 0, -yOff)
            yOff = yOff + h + BAR_GAP
        end
        return
    end

    -- Buff Icons: use dedicated adapter for aura hooks
    local visible, totalSlots
    if isBuff then
        visible, totalSlots = ViewerAdapters.CollectVisibleBuffIcons()
    else
        visible = ViewerAdapters.CollectVisibleSorted(viewer)
    end

    if #visible == 0 then return end

    -- Style + hotkey
    for _, button in ipairs(visible) do
        StyleButton(button, isBuff)
        if not isBuff then UpdateButtonHotkey(button) end
    end

    -- Only re-layout horizontal viewers
    if not viewer.isHorizontal then return end

    local btnW = visible[1]:GetWidth()
    local btnH = visible[1]:GetHeight()
    local iconLimit = viewer.iconLimit or viewer.stride or 8
    local padding = viewer.childXPadding or SPACING

    if isBuff then
        -- ======================================
        -- BUFF CENTER-OUTWARD PATTERN
        -- 1st: center, 2nd: left, 3rd: right...
        -- ======================================
        local numIcons = #visible
        local gap = padding
        wipe(_cdm_positions)
        for i = 1, numIcons do
            if i == 1 then
                _cdm_positions[i] = 0
            else
                local slot = ceil((i - 1) / 2)
                local isRight = ((i - 1) % 2 == 1)
                if isRight then
                    _cdm_positions[i] = slot * (btnW + gap)
                else
                    _cdm_positions[i] = -slot * (btnW + gap)
                end
            end
        end
        for i, child in ipairs(visible) do
            child:ClearAllPoints()
            child:SetPoint("TOP", viewer, "TOP", _cdm_positions[i], 0)
        end
    else
        -- ======================================
        -- ESSENTIAL / UTILITY: Centered rows via LayoutEngine
        -- ======================================
        local rows = LayoutEngine.BuildRows(iconLimit, visible)
        if #rows == 0 then return end
        local maxIcons = math.min(iconLimit, #visible)
        local yPadding = viewer.childYPadding or SPACING
        local iconDirMod = (viewer.iconDirection == 1) and 1 or -1
        local fromAnchor1 = "TOP"
        local fromAnchor2 = (viewer.iconDirection == 1) and "LEFT" or "RIGHT"
        local rowAnchor = fromAnchor1 .. fromAnchor2
        local cumY = 0
        for _, row in ipairs(rows) do
            PositionRowHorizontal(viewer, row, -cumY, btnW, padding, iconDirMod, rowAnchor, maxIcons)
            cumY = cumY + btnH + yPadding
        end
    end
end

-- =====================================
-- TICKER: Update CD text + active state + dimming
-- =====================================
local dimElapsed = 0
local DIM_RATE = 0.1

local function TickerUpdate(dt)
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
end

-- =====================================
-- TODO LIST (deferred layout)
-- =====================================
local function AddToDoList(viewer)
    todoList[viewer] = true
    InvalidateChildrenCache(viewer)
    if updateFrame then updateFrame:Show() end
end

-- =====================================
-- ALPHA MANAGEMENT
-- =====================================
local function UpdateAlpha()
    local settings = GetSettings()
    if not settings or not settings.combatAlpha then return end

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

-- =====================================
-- HOTKEY VISIBILITY
-- =====================================
local function RefreshHotkeyVisibility()
    local settings = GetSettings()
    if not settings then return end

    for _, viewer in ipairs(cdViewers) do
        if viewer then
            local children = GetCachedChildren(viewer)
            for _, button in ipairs(children) do
                if button._cdm_hotkey then
                    if settings.showHotKey then
                        UpdateButtonHotkey(button)
                    else
                        button._cdm_hotkey:Hide()
                    end
                end
            end
        end
    end
end

-- =====================================
-- INIT
-- =====================================
local function InitViewers()
    if not UtilityCooldownViewer then return false end

    CheckHotkeys()

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
            LayoutViewer(viewer, isBuff)

            if viewer.Layout then
                hooksecurefunc(viewer, "Layout", function()
                    AddToDoList(viewer)
                end)
            end

            local children = GetCachedChildren(viewer)
            for _, child in ipairs(children) do
                child:HookScript("OnShow", function() AddToDoList(viewer) end)
                child:HookScript("OnHide", function() AddToDoList(viewer) end)
            end
        end
    end

    -- [PERF] C_Timer.NewTicker replaces OnUpdate accumulator — no per-frame Lua callback
    tickerFrame = C_Timer.NewTicker(TICK_RATE, function()
        TickerUpdate(TICK_RATE)
    end)

    -- Deferred layout processor
    updateFrame = CreateFrame("Frame")
    updateFrame:Hide()
    updateFrame:SetScript("OnUpdate", function(self)
        self:Hide()
        for viewer in pairs(todoList) do
            todoList[viewer] = nil
            local isBuff = (viewer == BuffIconCooldownViewer)
            LayoutViewer(viewer, isBuff)
        end
    end)

    UpdateAlpha()
    isInitialized = true
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
            CheckHotkeys()
            RefreshHotkeyVisibility()
            UpdateAlpha()
        end)

    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_TARGET_CHANGED" then
        if settings.combatAlpha then
            UpdateAlpha()
        end

    elseif event == "UPDATE_BONUS_ACTIONBAR" or event == "ACTIONBAR_SLOT_CHANGED" then
        C_Timer.After(0.1, function()
            CheckHotkeys()
            RefreshHotkeyVisibility()
        end)
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
    mainFrame:SetScript("OnEvent", OnEvent)
end

function CDM.ApplySettings()
    if not isInitialized then return end
    local settings = GetSettings()
    if not settings then return end

    -- Update overlay color reference
    overlayColor = CLASS_OVERLAY_COLORS[playerClass] or classColor

    RefreshHotkeyVisibility()

    if settings.combatAlpha then
        UpdateAlpha()
    else
        for _, viewer in ipairs(viewers) do
            if viewer then viewer:SetAlpha(1) end
        end
    end

    -- Re-layout all viewers
    for _, viewer in ipairs(viewers) do
        if viewer then
            local isBuff = (viewer == BuffIconCooldownViewer)
            LayoutViewer(viewer, isBuff)
        end
    end
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
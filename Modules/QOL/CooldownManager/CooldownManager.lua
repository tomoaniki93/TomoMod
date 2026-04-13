-- =====================================
-- CooldownManager V3
-- Clean & modern reskin of Blizzard CooldownManager
-- Inspired by CooldownManagerCentered architecture
-- 9-slice rounded borders, class overlay on active auras,
-- custom swipe colors, utility dimming, centered layout,
-- hotkeys, custom CD text, visibility rules, GCD hiding,
-- desaturation, charge-aware dimming, vertical layout
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
local hotkeys = {}
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
-- RUNTIME (inspired by CooldownManagerCentered)
-- Prevents operations during edit mode / layout transitions
-- =====================================
local Runtime = {}
Runtime.isInEditMode = false

function Runtime:IsReady(viewer)
    if not viewer then return false end
    if type(viewer) == "string" then viewer = _G[viewer] end
    if not viewer or not viewer.IsInitialized or not EditModeManagerFrame then return false end
    if EditModeManagerFrame.layoutApplyInProgress or not viewer:IsInitialized() then return false end
    return true
end

function Runtime:IsAllReady()
    for _, v in ipairs(viewers) do
        if not self:IsReady(v) then return false end
    end
    return true
end

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

function LayoutEngine.StartRowXOffsets(count, itemWidth, padding, directionMod)
    if not count or count <= 0 then return _le_offsets end
    local dir = directionMod or 1
    wipe(_le_offsets)
    for i = 1, count do
        _le_offsets[i] = (i - 1) * (itemWidth + padding) * dir
    end
    return _le_offsets
end

function LayoutEngine.EndRowXOffsets(count, itemWidth, padding, directionMod)
    if not count or count <= 0 then return _le_offsets end
    local dir = directionMod or 1
    wipe(_le_offsets)
    for i = 1, count do
        _le_offsets[i] = -((i - 1) * (itemWidth + padding)) * dir
    end
    return _le_offsets
end

function LayoutEngine.StartColYOffsets(count, itemHeight, padding, directionMod)
    if not count or count <= 0 then return _le_offsets end
    local dir = directionMod or 1
    wipe(_le_offsets)
    for i = 1, count do
        _le_offsets[i] = -((i - 1) * (itemHeight + padding)) * dir
    end
    return _le_offsets
end

function LayoutEngine.EndColYOffsets(count, itemHeight, padding, directionMod)
    if not count or count <= 0 then return _le_offsets end
    local dir = directionMod or 1
    wipe(_le_offsets)
    for i = 1, count do
        _le_offsets[i] = (i - 1) * (itemHeight + padding) * dir
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
-- HOTKEY SYSTEM (improved — macro/item/ElvUI/Dominos support)
-- =====================================
local function CheckKeyName(name)
    if not name or name == "" or name == "●" then return nil end
    name = string.upper(name)
    name = string.gsub(name, "PADLTRIGGER", "LT")
    name = string.gsub(name, "PADRTRIGGER", "RT")
    name = string.gsub(name, "SHIFT%-", "S")
    name = string.gsub(name, "CTRL%-", "C")
    name = string.gsub(name, "STRG%-", "ST")
    name = string.gsub(name, "ALT%-", "A")
    name = string.gsub(name, "META%-", "M")
    name = string.gsub(name, "MOUSE%s?WHEEL%s?UP", "MWU")
    name = string.gsub(name, "MOUSE%s?WHEEL%s?DOWN", "MWD")
    name = string.gsub(name, "MIDDLE%s?MOUSE", "MM")
    name = string.gsub(name, "MOUSE%s?BUTTON%s?", "M")
    name = string.gsub(name, "BUTTON", "M")
    name = string.gsub(name, "NUMPAD%s?PLUS", "N+")
    name = string.gsub(name, "NUMPAD%s?MINUS", "N-")
    name = string.gsub(name, "NUMPAD%s?MULTIPLY", "N*")
    name = string.gsub(name, "NUMPAD%s?DIVIDE", "N/")
    name = string.gsub(name, "NUMPAD%s?DECIMAL", "N.")
    name = string.gsub(name, "NUMPAD%s?ENTER", "NEnt")
    name = string.gsub(name, "NUMPAD%s?", "N")
    name = string.gsub(name, "NUM%s?PAD%s?", "N")
    name = string.gsub(name, "NUM%s?", "N")
    name = string.gsub(name, "PAGE%s?UP", "PGU")
    name = string.gsub(name, "PAGE%s?DOWN", "PGD")
    name = string.gsub(name, "INSERT", "INS")
    name = string.gsub(name, "DELETE", "DEL")
    name = string.gsub(name, "SPACEBAR", "Spc")
    name = string.gsub(name, "ENTER", "Ent")
    name = string.gsub(name, "ESCAPE", "Esc")
    name = string.gsub(name, "TAB", "Tab")
    name = string.gsub(name, "CAPS%s?LOCK", "Caps")
    name = string.gsub(name, "HOME", "Hom")
    name = string.gsub(name, "END", "End")
    name = string.gsub(name, "UP ARROW", "^")
    name = string.gsub(name, "DOWN ARROW", "V")
    name = string.gsub(name, "RIGHT ARROW", ">")
    name = string.gsub(name, "LEFT ARROW", "<")
    name = string.gsub(name, "BACKSPACE", "Bs")
    return name
end

-- Map spellID → formatted keybind text
local spellKeyBindCache = {}

local BLIZZARD_BARS = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local ELVUI_BARS = {
    "ElvUI_Bar1Button",
    "ElvUI_Bar2Button",
    "ElvUI_Bar3Button",
    "ElvUI_Bar4Button",
    "ElvUI_Bar5Button",
    "ElvUI_Bar6Button",
    "ElvUI_Bar7Button",
    "ElvUI_Bar8Button",
    "ElvUI_Bar9Button",
    "ElvUI_Bar10Button",
}

local function AssignSpellForSlot(slot, keyBind, result)
    local actionType, id, subType = GetActionInfo(slot)
    if not id or result[id] then return end
    if (actionType == "macro" and subType == "spell") or (actionType == "spell") then
        result[id] = keyBind
    elseif actionType == "macro" then
        local macroName = GetActionText(slot)
        local macroSpellID = macroName and GetMacroSpell(macroName)
        if macroSpellID and not result[macroSpellID] then
            result[macroSpellID] = keyBind
        end
    elseif actionType == "item" then
        local spellName, spellId = C_Item.GetItemSpell(id)
        if spellId and not result[spellId] then
            result[spellId] = keyBind
        end
    end
end

local function CheckHotkeys()
    local result = {}

    -- ElvUI bars (uses GetBindingKey)
    if _G["ElvUI_Bar1Button1"] then
        for _, barPrefix in ipairs(ELVUI_BARS) do
            for j = 1, 12 do
                local button = _G[barPrefix .. j]
                local slot = button and button.action
                if button and slot and button.config then
                    local keyBind = GetBindingKey(button.config.keyBoundTarget)
                    if keyBind then
                        local formatted = CheckKeyName(keyBind)
                        if formatted then AssignSpellForSlot(slot, formatted, result) end
                    end
                end
            end
        end
    end

    -- Dominos
    if _G["DominosActionButton1"] then
        for i = 1, 168 do
            local button = _G["DominosActionButton" .. i]
            if not button then break end
            local slot = button.action
            local hotkey = button.HotKey and button.HotKey:GetText()
            if slot and hotkey then
                local formatted = CheckKeyName(hotkey)
                if formatted then AssignSpellForSlot(slot, formatted, result) end
            end
        end
    end

    -- Blizzard bars (uses GetBindingKey for reliability)
    for _, barPrefix in ipairs(BLIZZARD_BARS) do
        for j = 1, 12 do
            local button = _G[barPrefix .. j]
            local slot = button and button.action
            local keyBoundTarget = button and button.commandName
            if button and slot and keyBoundTarget then
                local keyBind = GetBindingKey(keyBoundTarget)
                if keyBind then
                    local formatted = CheckKeyName(keyBind)
                    if formatted then AssignSpellForSlot(slot, formatted, result) end
                end
            end
        end
    end

    -- Bonus, Extra, Override, Vehicle, Pet
    local extraBars = {
        { "BonusActionButton", 12 },
        { "ExtraActionButton", 12 },
        { "VehicleMenuBarActionButton", 12 },
        { "OverrideActionBarButton", 12 },
        { "PetActionButton", 10 },
    }
    for _, info in ipairs(extraBars) do
        local prefix, total = info[1], info[2]
        for j = 1, total do
            local button = _G[prefix .. j]
            if not button then break end
            local hotkey = _G[button:GetName() .. "HotKey"]
            local text = hotkey and hotkey:GetText()
            local slot = button.action
            if slot and text then
                local formatted = CheckKeyName(text)
                if formatted then
                    -- Direct slot assignment fallback
                    hotkeys[slot] = formatted
                end
            end
        end
    end

    -- Store in spellKeyBindCache
    wipe(spellKeyBindCache)
    for spellID, keyBind in pairs(result) do
        spellKeyBindCache[spellID] = keyBind
    end
    -- Merge the legacy hotkeys table
    wipe(hotkeys)
    for k, v in pairs(result) do hotkeys[k] = v end
end

local function GetSpellHotkey(spellID)
    -- Direct cache hit
    if spellKeyBindCache[spellID] then return spellKeyBindCache[spellID] end

    -- Try override spell
    local overrideID = C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(spellID)
    if overrideID and spellKeyBindCache[overrideID] then return spellKeyBindCache[overrideID] end

    -- Try base spell
    local baseID = C_Spell.GetBaseSpell and C_Spell.GetBaseSpell(spellID)
    if baseID and spellKeyBindCache[baseID] then return spellKeyBindCache[baseID] end

    -- Fallback: action bar slot lookup
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
                if parent and parent.cooldownID then
                    local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, parent.cooldownID)
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
    if not isBuff and settings and settings.desaturateOnCD and button.Icon and button.cooldownID then
        local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, button.cooldownID)
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

    -- Range check: tint icon red if target is out of range (Essential/Utility only)
    if not isBuff and settings and settings.rangeCheckEnabled and button.Icon and button.cooldownID then
        local spellID = nil
        local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, button.cooldownID)
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

    local spellID = nil
    -- Try cooldownID first (more reliable)
    if button.cooldownID then
        local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, button.cooldownID)
        if ok and info then
            spellID = info.spellID
        end
    end
    -- Fallback to GetSpellID
    if not spellID then
        spellID = button:GetSpellID()
        if type(spellID) == "nil" or (issecretvalue and issecretvalue(spellID)) then
            spellID = nil
        end
    end

    if spellID then
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
        if child and child:IsShown() and child.Icon and child.cooldownID then
            local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, child.cooldownID)
            if ok and info then
                local spellID = info.overrideSpellID or info.spellID
                if spellID then
                    local cd = C_Spell.GetSpellCooldown(spellID)
                    if cd and not cd.isOnGCD then
                        -- Use charge CD for spells with charges
                        local cdDuration
                        if not issecretvalue(child.cooldownChargesShown) and child.cooldownChargesShown then
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

local function PositionRowVertical(viewer, row, xOffset, h, padding, dirMod, anchor, iconLimit)
    local count = #row
    local yOffsets = LayoutEngine.CenteredColYOffsets(count, h, padding, dirMod, iconLimit)
    for i, icon in ipairs(row) do
        local y = yOffsets[i] or 0
        local needSet = true
        if icon.GetPoint then
            local pt, _, rp, ox, oy = icon:GetPoint()
            if ox and oy then
                if pt == anchor and rp == anchor and abs(xOffset - ox) < 1 and abs(y - oy) < 1 then
                    needSet = false
                end
            end
        end
        if needSet then
            icon:ClearAllPoints()
            icon:SetPoint(anchor, viewer, anchor, xOffset, y)
        end
    end
end

local function LayoutViewer(viewer, isBuff)
    if not Runtime:IsReady(viewer) then return end
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

    local btnW = visible[1]:GetWidth()
    local btnH = visible[1]:GetHeight()
    local iconLimit = viewer.iconLimit or viewer.stride or 8
    local padding = viewer.childXPadding or SPACING

    if isBuff then
        -- ======================================
        -- BUFF ICON ALIGNMENT
        -- Modes: CENTER (center-outward), START (left-aligned), END (right-aligned)
        -- Supports horizontal and vertical layouts
        -- ======================================
        local settings = GetSettings()
        local alignment = (settings and settings.buffAlignment) or "CENTER"
        local numIcons = #visible
        local gap = padding
        local isHorizontal = viewer.isHorizontal ~= false
        local iconDirection = viewer.iconDirection == 1 and 1 or -1

        if isHorizontal then
            local offsets
            local anchor, relativePoint
            if alignment == "START" then
                offsets = LayoutEngine.StartRowXOffsets(numIcons, btnW, gap, iconDirection)
                anchor = iconDirection == 1 and "TOPLEFT" or "TOPRIGHT"
                relativePoint = anchor
            elseif alignment == "END" then
                offsets = LayoutEngine.EndRowXOffsets(numIcons, btnW, gap, iconDirection)
                anchor = iconDirection == 1 and "TOPRIGHT" or "TOPLEFT"
                relativePoint = anchor
            else -- CENTER (center-outward)
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
                return -- Already positioned
            end
            for i, icon in ipairs(visible) do
                local x = offsets[i] or 0
                icon:ClearAllPoints()
                icon:SetPoint(anchor, viewer, relativePoint, x, 0)
            end
        else
            -- Vertical buff layout
            local offsets
            local anchor, relativePoint
            local dirMod = iconDirection == 1 and -1 or 1
            if alignment == "START" then
                offsets = LayoutEngine.StartColYOffsets(numIcons, btnH, gap, dirMod)
                anchor = iconDirection == 1 and "BOTTOMLEFT" or "TOPLEFT"
                relativePoint = anchor
            elseif alignment == "END" then
                offsets = LayoutEngine.EndColYOffsets(numIcons, btnH, gap, dirMod)
                anchor = iconDirection == 1 and "TOPLEFT" or "BOTTOMLEFT"
                relativePoint = anchor
            else -- CENTER
                offsets = LayoutEngine.CenteredColYOffsets(numIcons, btnH, gap, dirMod, totalSlots)
                anchor = iconDirection == 1 and "BOTTOMLEFT" or "TOPLEFT"
                relativePoint = anchor
            end
            for i, icon in ipairs(visible) do
                local y = offsets[i] or 0
                icon:ClearAllPoints()
                icon:SetPoint(anchor, viewer, relativePoint, 0, y)
            end
        end
    else
        -- ======================================
        -- ESSENTIAL / UTILITY: Centered rows via LayoutEngine
        -- Supports horizontal and vertical layouts
        -- ======================================
        local rows = LayoutEngine.BuildRows(iconLimit, visible)
        if #rows == 0 then return end
        local maxIcons = math.min(iconLimit, #visible)
        local yPadding = viewer.childYPadding or SPACING
        local isHorizontal = viewer.isHorizontal ~= false

        if isHorizontal then
            local iconDirMod = (viewer.iconDirection == 1) and 1 or -1
            local fromAnchor1 = "TOP"
            local fromAnchor2 = (viewer.iconDirection == 1) and "LEFT" or "RIGHT"
            local rowAnchor = fromAnchor1 .. fromAnchor2
            local cumY = 0
            for _, row in ipairs(rows) do
                PositionRowHorizontal(viewer, row, -cumY, btnW, padding, iconDirMod, rowAnchor, maxIcons)
                cumY = cumY + btnH + yPadding
            end
        else
            -- Vertical layout
            local iconDirMod = (viewer.iconDirection == 1) and -1 or 1
            local fromAnchor1 = (viewer.iconDirection == 1) and "BOTTOM" or "TOP"
            local fromAnchor2 = "LEFT"
            local colAnchor = fromAnchor1 .. fromAnchor2
            local cumX = 0
            for _, row in ipairs(rows) do
                PositionRowVertical(viewer, row, cumX, btnH, yPadding, iconDirMod, colAnchor, maxIcons)
                cumX = cumX + btnW + padding
            end
        end
    end
end

-- =====================================
-- TICKER: Update CD text + active state + dimming
-- =====================================
local dimElapsed = 0
local DIM_RATE = 0.1

local function TickerUpdate(dt)
    if not Runtime:IsAllReady() then return end

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
                    if button and button.cooldownID then
                        local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, button.cooldownID)
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

-- =====================================
-- TODO LIST (deferred layout)
-- =====================================
local function AddToDoList(viewer)
    todoList[viewer] = true
    InvalidateChildrenCache(viewer)
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
            CheckHotkeys()
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
    if EventRegistry then
        EventRegistry:RegisterCallback("EditMode.Enter", function()
            Runtime.isInEditMode = true
        end)
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            Runtime.isInEditMode = false
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

    -- Invalidate caches and re-layout all viewers
    for _, viewer in ipairs(viewers) do
        if viewer then
            InvalidateChildrenCache(viewer)
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
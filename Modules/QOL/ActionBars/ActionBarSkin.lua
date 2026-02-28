-- =====================================
-- ActionBarSkin.lua
-- Skins action bar buttons with rounded 9-slice borders
-- matching the TomoMod visual style (border.png)
-- =====================================

TomoMod_ActionBarSkin = TomoMod_ActionBarSkin or {}
local ABS = TomoMod_ActionBarSkin

-- =====================================
-- CONSTANTES
-- =====================================
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BORDER_TEX = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\border.png"
local BORDER_CORNER = 5
local ICON_INSET = 3
local BG_COLOR = { 0.05, 0.05, 0.1, 1 }

local skinnedButtons = {}
local classColor

-- =====================================
-- HELPERS
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.actionBarSkin then return nil end
    return TomoModDB.actionBarSkin
end

local function GetBorderColor()
    local settings = GetSettings()
    if settings and settings.useClassColor then
        if not classColor then
            local _, class = UnitClass("player")
            classColor = RAID_CLASS_COLORS[class] or { r = 0.3, g = 0.3, b = 0.4 }
        end
        return classColor.r, classColor.g, classColor.b, 1
    else
        return 0.3, 0.3, 0.4, 1
    end
end

-- =====================================
-- 9-SLICE BORDER
-- =====================================
local function Create9SliceBorder(parent, r, g, b, a)
    a = a or 1
    local parts = {}
    local function Tex()
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetTexture(BORDER_TEX)
        if r then t:SetVertexColor(r, g, b, a) end
        parts[#parts + 1] = t
        return t
    end

    local c = BORDER_CORNER

    local tl = Tex(); tl:SetSize(c, c)
    tl:SetPoint("TOPLEFT"); tl:SetTexCoord(0, 0.5, 0, 0.5)
    local tr = Tex(); tr:SetSize(c, c)
    tr:SetPoint("TOPRIGHT"); tr:SetTexCoord(0.5, 1, 0, 0.5)
    local bl = Tex(); bl:SetSize(c, c)
    bl:SetPoint("BOTTOMLEFT"); bl:SetTexCoord(0, 0.5, 0.5, 1)
    local br = Tex(); br:SetSize(c, c)
    br:SetPoint("BOTTOMRIGHT"); br:SetTexCoord(0.5, 1, 0.5, 1)

    local top = Tex(); top:SetHeight(c)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(0.5, 0.5, 0, 0.5)
    local bot = Tex(); bot:SetHeight(c)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bot:SetTexCoord(0.5, 0.5, 0.5, 1)
    local left = Tex(); left:SetWidth(c)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    left:SetTexCoord(0, 0.5, 0.5, 0.5)
    local right = Tex(); right:SetWidth(c)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    right:SetTexCoord(0.5, 1, 0.5, 0.5)

    return parts
end

-- =====================================
-- SKIN A SINGLE BUTTON
-- =====================================
local function SkinButton(button)
    if not button then return end
    if skinnedButtons[button] then return end

    local name = button:GetName()
    if not name then return end

    -- Get the icon texture
    local icon = button.icon or button.Icon
    if not icon then return end

    -- Mark as skinned
    skinnedButtons[button] = true

    -- ===== Hide default border textures =====
    -- NormalTexture (the default round/square border)
    local normal = button:GetNormalTexture()
    if normal then
        normal:SetTexture(nil)
        normal:SetAlpha(0)
        normal:Hide()
    end

    -- Pushed texture
    local pushed = button:GetPushedTexture()
    if pushed then
        pushed:SetTexture(nil)
        pushed:SetAlpha(0)
    end

    -- Hide the default highlight border but keep a subtle one
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetColorTexture(1, 1, 1, 0.1)
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
        highlight:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
    end

    -- Hide checked texture (for stance/form buttons)
    if button.GetCheckedTexture then
        local ok, checked = pcall(button.GetCheckedTexture, button)
        if ok and checked then
            checked:SetColorTexture(1, 1, 1, 0.15)
            checked:ClearAllPoints()
            checked:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
            checked:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
        end
    end

    -- Hide Blizzard "SlotArt" / "IconMask" if present
    if button.SlotArt then button.SlotArt:Hide() end
    if button.IconMask then button.IconMask:Hide() end
    if button.SlotBackground then button.SlotBackground:Hide() end

    -- Remove icon mask to get square icons
    if icon.SetMask then
        pcall(icon.SetMask, icon, nil)
    end

    -- ===== Dark background (fills rounded corners) =====
    local bg = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetAllPoints()
    bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
    button._tmBG = bg

    -- ===== Inset icon =====
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
    icon:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- ===== 9-slice border =====
    local r, g, b, a = GetBorderColor()
    local borderParts = Create9SliceBorder(button, r, g, b, a)
    button._tmBorder = borderParts

    -- ===== Fix cooldown frame to match inset =====
    local cooldown = button.cooldown or _G[name .. "Cooldown"]
    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    end

    -- ===== Style HotKey text =====
    local hotkey = button.HotKey or _G[name .. "HotKey"]
    if hotkey then
        hotkey:SetFont(FONT, 12, "OUTLINE")
        hotkey:ClearAllPoints()
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        hotkey:SetJustifyH("RIGHT")
    end

    -- ===== Style Count text =====
    local count = button.Count or _G[name .. "Count"]
    if count then
        count:SetFont(FONT, 12, "OUTLINE")
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end

    -- ===== Style macro Name text =====
    local macroName = button.Name or _G[name .. "Name"]
    if macroName then
        macroName:SetFont(FONT, 8, "OUTLINE")
        macroName:ClearAllPoints()
        macroName:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
    end

    -- ===== Border glow (equipped items) =====
    if button.Border then
        button.Border:SetTexture(nil)
        button.Border:Hide()
    end

    -- ===== Flash texture =====
    local flash = button.Flash or _G[name .. "Flash"]
    if flash then
        flash:ClearAllPoints()
        flash:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
        flash:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
        flash:SetColorTexture(1, 0.2, 0.2, 0.3)
    end
end

-- =====================================
-- BUTTON LISTS (barKey matches Database barOpacity keys)
-- =====================================
local BAR_DEFS = {
    { prefix = "ActionButton",              barKey = "ActionButton",           count = 12 },
    { prefix = "MultiBarBottomLeftButton",  barKey = "MultiBarBottomLeft",     count = 12 },
    { prefix = "MultiBarBottomRightButton", barKey = "MultiBarBottomRight",    count = 12 },
    { prefix = "MultiBarRightButton",       barKey = "MultiBarRight",          count = 12 },
    { prefix = "MultiBarLeftButton",        barKey = "MultiBarLeft",           count = 12 },
    { prefix = "MultiBar5Button",           barKey = "MultiBar5",              count = 12 },
    { prefix = "MultiBar6Button",           barKey = "MultiBar6",              count = 12 },
    { prefix = "MultiBar7Button",           barKey = "MultiBar7",              count = 12 },
    { prefix = "PetActionButton",           barKey = "PetActionButton",        count = 10 },
    { prefix = "StanceButton",              barKey = "StanceButton",           count = 10 },
    { prefix = "PossessButton",             barKey = "StanceButton",           count = 12 },
    { prefix = "OverrideActionBarButton",   barKey = "OverrideBar",            count = 6  },
    { prefix = "ExtraActionButton",         barKey = "ActionButton",           count = 1  },
}

-- Reverse lookup: buttonName prefix → barKey
local buttonBarKey = {}

local function SkinAllButtons()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    local opacities = settings.barOpacity or {}

    for _, bar in ipairs(BAR_DEFS) do
        local alpha = (opacities[bar.barKey] or 100) / 100
        for i = 1, bar.count do
            local button = _G[bar.prefix .. i]
            if button then
                buttonBarKey[button] = bar.barKey
                SkinButton(button)
                button:SetAlpha(alpha)
            end
        end
    end
end

-- =====================================
-- PER-BAR OPACITY
-- =====================================
local function ApplyBarOpacityInternal(barKey, pct)
    local alpha = (pct or 100) / 100
    -- Ne jamais masquer la barre véhicule si on est dans un véhicule
    if barKey == "OverrideBar" and UnitInVehicle and UnitInVehicle("player") then
        return
    end
    for button, bk in pairs(buttonBarKey) do
        if bk == barKey then
            button:SetAlpha(alpha)
        end
    end
end

function ABS.ApplyBarOpacity(barKey, pct)
    ApplyBarOpacityInternal(barKey, pct)
end

local function ApplyAllOpacities()
    local settings = GetSettings()
    if not settings then return end
    local opacities = settings.barOpacity or {}
    for _, bar in ipairs(BAR_DEFS) do
        ApplyBarOpacityInternal(bar.barKey, opacities[bar.barKey] or 100)
    end
end

-- =====================================
-- VEHICLE / OVERRIDE BAR VISIBILITY
-- Force les boutons du véhicule à alpha=1 quoi qu'il arrive
-- (opacité barre, combat-show, etc. ne doivent pas les masquer)
-- =====================================
local vehicleFrame = CreateFrame("Frame")
vehicleFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
vehicleFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
vehicleFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
vehicleFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
vehicleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local function RefreshVehicleBarVisibility()
    local inVehicle = UnitInVehicle and UnitInVehicle("player")
    for button, bk in pairs(buttonBarKey) do
        if bk == "OverrideBar" then
            if inVehicle then
                button:SetAlpha(1)
            else
                -- Rétablir l'opacité configurée hors véhicule
                local settings = GetSettings()
                local pct = settings and settings.barOpacity and settings.barOpacity["OverrideBar"] or 0
                button:SetAlpha(pct / 100)
            end
        end
    end
end

vehicleFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
        if unit ~= "player" then return end
    end
    -- Petit délai pour que WoW finisse de set up la barre override
    C_Timer.After(0.1, RefreshVehicleBarVisibility)
end)

-- =====================================
-- COMBAT SHOW / HIDE
-- =====================================
local combatFrame = CreateFrame("Frame")
combatFrame:Hide()

local function SetBarVisible(barKey, visible)
    local settings = GetSettings()
    if not settings then return end
    -- Ne jamais masquer la barre véhicule si on est dans un véhicule
    if barKey == "OverrideBar" and UnitInVehicle and UnitInVehicle("player") then
        return
    end
    local opacities = settings.barOpacity or {}
    local targetAlpha = visible and ((opacities[barKey] or 100) / 100) or 0
    for button, bk in pairs(buttonBarKey) do
        if bk == barKey then
            button:SetAlpha(targetAlpha)
        end
    end
end

local function ApplyCombatVisibility()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    local combatShow = settings.combatShow or {}
    local inCombat = InCombatLockdown()

    -- Track whether we need combat events
    local needEvents = false

    for barKey, enabled in pairs(combatShow) do
        if enabled then
            needEvents = true
            SetBarVisible(barKey, inCombat)
        end
    end

    -- Register/unregister combat events as needed
    if needEvents then
        combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entering combat
        combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- leaving combat
        combatFrame:Show()
    else
        combatFrame:UnregisterAllEvents()
        combatFrame:Hide()
        -- Restore all opacities when no bars use combat show
        ApplyAllOpacities()
    end
end

combatFrame:SetScript("OnEvent", function(_, event)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    local combatShow = settings.combatShow or {}
    local inCombat = (event == "PLAYER_REGEN_DISABLED")

    for barKey, enabled in pairs(combatShow) do
        if enabled then
            SetBarVisible(barKey, inCombat)
        end
    end
end)

-- Public API for config panel
function ABS.ApplyCombatShow()
    ApplyCombatVisibility()
end

-- =====================================
-- UPDATE BORDER COLORS
-- =====================================
local function UpdateBorderColors()
    local r, g, b, a = GetBorderColor()
    for button, _ in pairs(skinnedButtons) do
        if button._tmBorder then
            for _, tex in ipairs(button._tmBorder) do
                tex:SetVertexColor(r, g, b, a)
            end
        end
    end
end

-- =====================================
-- UNSKIN (for toggle off — requires reload for full revert)
-- =====================================
local function HideSkin()
    for button, _ in pairs(skinnedButtons) do
        if button._tmBorder then
            for _, tex in ipairs(button._tmBorder) do
                tex:Hide()
            end
        end
        if button._tmBG then
            button._tmBG:Hide()
        end
    end
end

local function ShowSkin()
    for button, _ in pairs(skinnedButtons) do
        if button._tmBorder then
            for _, tex in ipairs(button._tmBorder) do
                tex:Show()
            end
        end
        if button._tmBG then
            button._tmBG:Show()
        end
    end
    ApplyAllOpacities()
end

-- =====================================
-- HOOKS (for late-created buttons + TWW mixin compat)
-- =====================================
local function SetupHooks()
    -- Suppress NormalTexture on various update events
    local function SuppressNormal(self)
        if not skinnedButtons[self] then return end
        local normal = self:GetNormalTexture()
        if normal then
            normal:SetTexture(nil)
            normal:SetAlpha(0)
        end
        if self.Border and self.Border:IsShown() then
            self.Border:Hide()
        end
        if self.SlotArt and self.SlotArt:IsShown() then
            self.SlotArt:Hide()
        end
    end

    -- Try hooking global functions (may exist in some WoW versions)
    pcall(hooksecurefunc, "ActionButton_UpdateHotkeys", function(self)
        local settings = GetSettings()
        if not settings or not settings.enabled then return end
        SkinButton(self)
    end)

    pcall(hooksecurefunc, "ActionButton_UpdateState", SuppressNormal)
    pcall(hooksecurefunc, "ActionButton_UpdateUsable", SuppressNormal)
    pcall(hooksecurefunc, "ActionButton_Update", function(self)
        SuppressNormal(self)
        local settings = GetSettings()
        if settings and settings.enabled then
            SkinButton(self)
        end
    end)

    -- TWW mixin hooks
    if ActionBarActionButtonMixin then
        pcall(hooksecurefunc, ActionBarActionButtonMixin, "Update", function(self)
            SuppressNormal(self)
            local settings = GetSettings()
            if settings and settings.enabled then
                SkinButton(self)
            end
        end)
        pcall(hooksecurefunc, ActionBarActionButtonMixin, "UpdateButtonArt", SuppressNormal)
    end

    -- Periodic rescan for late bars (runs a few times then stops)
    local rescanCount = 0
    C_Timer.NewTicker(1, function(ticker)
        rescanCount = rescanCount + 1
        SkinAllButtons()
        if rescanCount >= 5 then
            ticker:Cancel()
        end
    end)
end

-- =====================================
-- SHIFT REVEAL (hold Shift to show all bars at 100%)
-- =====================================

local shiftRevealActive = false
local shiftRevealing = false

local function ShowAllBars()
    if shiftRevealing then return end
    shiftRevealing = true
    for button, _ in pairs(buttonBarKey) do
        button:SetAlpha(1)
    end
end

local function RestoreAllBars()
    if not shiftRevealing then return end
    shiftRevealing = false
    ApplyAllOpacities()
    -- Re-apply combat visibility after shift restore
    ApplyCombatVisibility()
end

local shiftFrame = CreateFrame("Frame")
shiftFrame:Hide()

shiftFrame:SetScript("OnEvent", function(_, event, key, state)
    if not shiftRevealActive then return end
    if key == "LSHIFT" or key == "RSHIFT" then
        if state == 1 then
            ShowAllBars()
        else
            RestoreAllBars()
        end
    end
end)

function ABS.SetShiftReveal(enabled)
    shiftRevealActive = enabled
    if enabled then
        shiftFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    else
        shiftFrame:UnregisterEvent("MODIFIER_STATE_CHANGED")
        if shiftRevealing then
            RestoreAllBars()
        end
    end
end

-- =====================================
-- PUBLIC API
-- =====================================
function ABS.Initialize()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Cache class color
    local _, class = UnitClass("player")
    classColor = RAID_CLASS_COLORS[class]

    -- Defer to ensure all bars are loaded
    C_Timer.After(0.5, function()
        SkinAllButtons()
        SetupHooks()

        -- Enable shift-reveal if configured
        if settings.shiftReveal then
            ABS.SetShiftReveal(true)
        end

        -- Apply combat visibility settings
        ApplyCombatVisibility()

        -- Second pass for late-loaded bars
        C_Timer.After(2, function()
            SkinAllButtons()
            -- Re-apply combat visibility after second pass
            ApplyCombatVisibility()
        end)
    end)
end

function ABS.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end
    settings.enabled = enabled

    if enabled then
        if next(skinnedButtons) then
            ShowSkin()
            ApplyCombatVisibility()
        else
            ABS.Initialize()
        end
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_abs_enabled"])
    else
        -- Disable combat frame when skin is disabled
        combatFrame:UnregisterAllEvents()
        combatFrame:Hide()
        HideSkin()
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_abs_disabled"])
    end
end

function ABS.UpdateColors()
    classColor = nil -- force refresh
    local _, class = UnitClass("player")
    classColor = RAID_CLASS_COLORS[class]
    UpdateBorderColors()
end

-- Export
_G.TomoMod_ActionBarSkin = ABS

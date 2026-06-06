-- =====================================
-- ActionBars.lua — TomoBar system v3.0.0
-- Bar management: per-bar settings, drag overlays, BarEditor
-- Centralized FadeManager, display conditions, click-through
-- Inspired by Dominos architecture
-- =====================================

TomoMod_ActionBars = TomoMod_ActionBars or {}
local AB = TomoMod_ActionBars

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ACCENT    = { 0.047, 0.824, 0.624, 1 }

-- =====================================================================
-- BAR DEFINITIONS
-- Maps each logical bar to its Blizzard frame name + button prefix/count
-- =====================================================================
local BAR_DEFS = {
    { id = "bar1", name = "Action Bar 1",            frame = "MainMenuBar",          prefix = "ActionButton",              count = 12 },
    { id = "bar2", name = "Action Bar 2 (BL)",       frame = "MultiBarBottomLeft",   prefix = "MultiBarBottomLeftButton",  count = 12 },
    { id = "bar3", name = "Action Bar 3 (BR)",       frame = "MultiBarBottomRight",  prefix = "MultiBarBottomRightButton", count = 12 },
    { id = "bar4", name = "Action Bar 4 (Right)",    frame = "MultiBarRight",        prefix = "MultiBarRightButton",       count = 12 },
    { id = "bar5", name = "Action Bar 5 (Left)",     frame = "MultiBarLeft",         prefix = "MultiBarLeftButton",        count = 12 },
    { id = "bar6", name = "Action Bar 6",            frame = "MultiBar5",            prefix = "MultiBar5Button",           count = 12 },
    { id = "bar7", name = "Action Bar 7",            frame = "MultiBar6",            prefix = "MultiBar6Button",           count = 12 },
    { id = "bar8", name = "Action Bar 8",            frame = "MultiBar7",            prefix = "MultiBar7Button",           count = 12 },
    { id = "pet",  name = "Pet Bar",                 frame = "PetActionBarFrame",    prefix = "PetActionButton",           count = 10 },
    { id = "stance", name = "Stance Bar",            frame = "StanceBarFrame",       prefix = "StanceButton",              count = 10 },
}

-- Table of active TomoBar instances indexed by id
AB.bars = {}

-- =====================================================================
-- DB DEFAULTS
-- =====================================================================
local DB_DEFAULTS = {
    enabled         = true,
    alpha           = 1.0,
    fade            = false,
    fadeAlpha        = 0.0,
    fadeInDelay     = 0,
    fadeInDuration  = 0.15,
    fadeOutDelay    = 0.3,
    fadeOutDuration = 0.25,
    scale           = 1.0,
    showHotkey      = true,
    showMacro       = true,
    showCount       = true,
    showEmptyButtons = false,
    clickThrough    = false,
    displayCondition = "",
    combatOnly      = false,
    hotkeySize      = 12,
    macroSize       = 9,
}

local function GetBarDB(id)
    if not TomoModDB then return DB_DEFAULTS end
    TomoModDB.actionBars            = TomoModDB.actionBars or {}
    TomoModDB.actionBars.bars       = TomoModDB.actionBars.bars or {}
    TomoModDB.actionBars.bars[id]   = TomoModDB.actionBars.bars[id] or {}

    local db = TomoModDB.actionBars.bars[id]
    for k, v in pairs(DB_DEFAULTS) do
        if db[k] == nil then db[k] = v end
    end
    return db
end

-- =====================================================================
-- FADE MANAGER (inspired by Dominos fadeManager.lua)
-- Centralized polling-based fade system with proper focus detection
-- =====================================================================
local FadeManager = {}
FadeManager.watched = {}
FadeManager._timer = nil

-- Check if the mouse is over a frame or any of its descendants (incl. flyouts)
local function IsDescendant(frame, ancestor)
    if not frame or frame == ancestor then return frame == ancestor end
    if frame.IsForbidden and frame:IsForbidden() then return false end
    return IsDescendant(frame:GetParent(), ancestor)
end

local function IsFlyoutFocus(flyout, owner)
    if flyout and flyout:IsVisible() and flyout:IsMouseOver(1, -1, -1, 1) then
        return IsDescendant(flyout, owner)
    end
    return false
end

local function IsBarFocused(bar)
    local bf = bar.blizzFrame
    if not bf then return false end
    if bf.IsForbidden and bf:IsForbidden() then return false end

    -- Direct mouse-over check on the bar frame
    if bf:IsMouseOver(1, -1, -1, 1) then return true end

    -- Check each button for mouse focus
    for i = 1, bar.count do
        local btn = _G[bar.prefix .. i]
        if btn and btn:IsVisible() and btn:IsMouseOver(1, -1, -1, 1) then
            return true
        end
    end

    -- Check flyout menus (spell flyouts anchored to action buttons)
    if _G.SpellFlyout and IsFlyoutFocus(_G.SpellFlyout, bf) then
        return true
    end

    -- Check GetMouseFocus descendants
    if type(GetMouseFoci) == "function" then
        for _, focus in ipairs(GetMouseFoci()) do
            if IsDescendant(focus, bf) then return true end
        end
    elseif type(GetMouseFocus) == "function" then
        local focus = GetMouseFocus()
        if focus and IsDescendant(focus, bf) then return true end
    end

    return false
end

function FadeManager:Update()
    for bar in pairs(self.watched) do
        local focused = IsBarFocused(bar)
        if focused and not bar._focused then
            bar._focused = true
            bar:FadeIn()
        elseif not focused and bar._focused then
            bar._focused = nil
            bar:FadeOut()
        end
    end

    if next(self.watched) then
        self:RequestUpdate()
    end
end

function FadeManager:RequestUpdate()
    if not self._updateFunc then
        self._updateFunc = function()
            self._waiting = false
            self:Update()
        end
    end
    if not self._waiting then
        self._waiting = true
        C_Timer.After(0.15, self._updateFunc)
    end
end

function FadeManager:Add(bar)
    if not self.watched[bar] then
        self.watched[bar] = true
        bar._focused = IsBarFocused(bar) or nil
        self:RequestUpdate()
    end
end

function FadeManager:Remove(bar)
    if self.watched[bar] then
        self.watched[bar] = nil
        bar._focused = nil
    end
end

AB.FadeManager = FadeManager

-- =====================================================================
-- DISPLAY CONDITION PRESETS (inspired by Dominos barStates)
-- =====================================================================
AB.DISPLAY_PRESETS = {
    { value = "",                                text = "Toujours visible" },
    { value = "[combat]show;hide",               text = "Combat uniquement" },
    { value = "[mod:shift]show;hide",            text = "Shift maintenu" },
    { value = "[mod:ctrl]show;hide",             text = "Ctrl maintenu" },
    { value = "[mod:alt]show;hide",              text = "Alt maintenu" },
    { value = "[combat]show;[mod:shift]show;hide", text = "Combat ou Shift" },
    { value = "[group]show;hide",                text = "En groupe uniquement" },
    { value = "[harm,nodead]show;hide",          text = "Cible hostile" },
    { value = "custom",                          text = "Personnalisé..." },
}

-- =====================================================================
-- TOMOBAR CLASS
-- =====================================================================
local TomoBar = {}
TomoBar.__index = TomoBar

function TomoBar:Create(def)
    local self = setmetatable({}, TomoBar)
    self.id     = def.id
    self.name   = def.name
    self.prefix = def.prefix
    self.count  = def.count
    self.db     = GetBarDB(def.id)

    -- Reference to the Blizzard bar frame
    self.blizzFrame = def.frame and _G[def.frame]

    -- State tracking
    self._focused    = nil
    self._transparent = false

    -- Create display condition wrapper (SecureHandlerStateTemplate)
    self:_CreateDisplayWrapper()

    -- Create drag overlay anchor frame
    self:_CreateOverlay()
    self:ApplySettings()

    return self
end

-- =====================================================================
-- DISPLAY CONDITION WRAPPER (inspired by Dominos frame.lua)
-- Uses RegisterStateDriver for macro-conditional visibility
-- =====================================================================
function TomoBar:_CreateDisplayWrapper()
    local bf = self.blizzFrame
    if not bf then return end

    -- Create a secure state handler frame for display conditions
    local wrapper = CreateFrame("Frame", "TomoBar_Display_" .. self.id, UIParent, "SecureHandlerStateTemplate")
    wrapper:SetAllPoints(bf)

    -- Store reference to the Blizzard frame as a frame ref
    wrapper:SetFrameRef("bar", bf)

    -- Secure snippet: show/hide the bar based on state-display
    wrapper:SetAttribute("_onstate-display", [[
        local bar = self:GetFrameRef("bar")
        if bar then
            if newstate == "hide" then
                bar:Hide()
            else
                bar:Show()
            end
        end
    ]])

    self._displayWrapper = wrapper
end

function TomoBar:UpdateDisplayCondition()
    local db = self.db
    local wrapper = self._displayWrapper
    if not wrapper then return end

    local condition = db.displayCondition or ""

    if condition ~= "" then
        RegisterStateDriver(wrapper, "display", condition)
    else
        UnregisterStateDriver(wrapper, "display")
        -- Ensure bar is shown when no condition is set
        if self.blizzFrame and not InCombatLockdown() then
            self.blizzFrame:Show()
        end
    end
end

function TomoBar:_CreateOverlay()
    -- Create a transparent handle frame that can be dragged
    local handle = CreateFrame("Frame", "TomoBar_Handle_" .. self.id, UIParent, "BackdropTemplate")
    handle:SetSize(140, 22)
    handle:SetFrameStrata("MEDIUM")
    handle:SetClampedToScreen(true)

    -- Position above the bar
    if self.blizzFrame then
        handle:SetPoint("BOTTOM", self.blizzFrame, "TOP", 0, 4)
    else
        handle:SetPoint("CENTER")
    end

    handle:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    handle:SetBackdropColor(1, 0.18, 0.18, 0.55)
    handle:SetBackdropBorderColor(1, 0.28, 0.28, 1)
    handle:Hide()

    -- Drag support
    handle:SetMovable(true)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")

    -- Bar name label
    local lbl = handle:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 11, "OUTLINE")
    lbl:SetPoint("CENTER")
    lbl:SetTextColor(1, 1, 1, 1)
    lbl:SetText(self.name)
    handle.lbl = lbl

    -- Drag scripts
    local self_ref = self
    handle:SetScript("OnDragStart", function(h)
        h:StartMoving()
    end)
    handle:SetScript("OnDragStop", function(h)
        h:StopMovingOrSizing()
        self_ref:_ApplyHandlePositionToBar()
    end)

    -- Right-click: open BarEditor
    handle:SetScript("OnMouseUp", function(h, btn)
        if btn == "RightButton" then
            AB.ShowBarEditor(self_ref)
        end
    end)

    -- Hover color shift
    handle:SetScript("OnEnter", function(h)
        h:SetBackdropColor(0.9, 0.10, 0.10, 0.65)
    end)
    handle:SetScript("OnLeave", function(h)
        h:SetBackdropColor(1, 0.18, 0.18, 0.55)
    end)

    self.handle = handle
end

function TomoBar:_ApplyHandlePositionToBar()
    if not self.blizzFrame then return end
    -- Move the Blizzard bar so it sits just below the handle
    local hx = self.handle:GetLeft()
    local hy = self.handle:GetBottom()
    if not hx or not hy then return end
    local scale = UIParent:GetEffectiveScale()
    local bW = self.blizzFrame:GetWidth() or 100
    local cx = (hx + self.handle:GetWidth() / 2) / scale
    local cy = (hy - 4) / scale
    self.blizzFrame:ClearAllPoints()
    self.blizzFrame:SetPoint("TOP", UIParent, "BOTTOMLEFT", cx, cy)
end

function TomoBar:ApplySettings()
    local db = self.db
    local bf = self.blizzFrame
    if not bf then return end

    -- Alpha
    bf:SetAlpha(db.alpha or 1)

    -- Scale — EditMode frames have a protected SetScaleBase; scale buttons instead
    local scale = db.scale or 1
    if bf.SetScaleBase then
        for i = 1, self.count do
            local btn = _G[self.prefix .. i]
            if btn then btn:SetScale(scale) end
        end
    else
        bf:SetScale(scale)
    end

    -- Button text options
    for i = 1, self.count do
        local btn = _G[self.prefix .. i]
        if btn then
            -- HotKey
            local hk = btn.HotKey or _G[btn:GetName() and (btn:GetName() .. "HotKey")]
            if hk then
                if db.showHotkey then
                    hk:Show()
                    hk:SetFont(FONT, db.hotkeySize or 12, "OUTLINE")
                else
                    hk:Hide()
                end
            end
            -- Macro name
            local mn = btn.Name or _G[btn:GetName() and (btn:GetName() .. "Name")]
            if mn then
                if db.showMacro then
                    mn:Show()
                    mn:SetFont(FONT, db.macroSize or 9, "OUTLINE")
                else
                    mn:Hide()
                end
            end
            -- Count text
            local ct = btn.Count or _G[btn:GetName() and (btn:GetName() .. "Count")]
            if ct then
                if db.showCount then ct:Show() else ct:Hide() end
            end
            -- Click-through
            btn:EnableMouse(not db.clickThrough)
            -- Empty buttons visibility
            if not db.showEmptyButtons then
                local action = btn.action or btn:GetAttribute("action")
                if action and HasAction and not HasAction(action) then
                    -- Let Blizzard handle empty slot visibility
                end
            end
        end
    end

    -- Fade setup via FadeManager
    self:UpdateFade()

    -- Display conditions
    self:UpdateDisplayCondition()

    -- Update transparency state (hide cooldowns on invisible bars)
    self:UpdateTransparent()
end

-- =====================================================================
-- FADE (via centralized FadeManager, inspired by Dominos)
-- =====================================================================
function TomoBar:UpdateFade()
    local db = self.db
    local bf = self.blizzFrame
    if not bf then return end

    if db.fade then
        -- Set initial faded alpha
        if not self._focused then
            bf:SetAlpha(db.fadeAlpha or 0)
        end
        FadeManager:Add(self)
    else
        FadeManager:Remove(self)
        bf:SetAlpha(db.alpha or 1)
    end
end

function TomoBar:FadeIn()
    local db  = self.db
    local bf  = self.blizzFrame
    if not bf or not db.fade then return end

    local targetAlpha = db.alpha or 1
    local delay       = db.fadeInDelay or 0
    local duration    = db.fadeInDuration or 0.15

    if delay > 0 then
        C_Timer.After(delay, function()
            if self._focused then
                UIFrameFadeIn(bf, duration, bf:GetAlpha(), targetAlpha)
            end
        end)
    else
        UIFrameFadeIn(bf, duration, bf:GetAlpha(), targetAlpha)
    end
end

function TomoBar:FadeOut()
    local db  = self.db
    local bf  = self.blizzFrame
    if not bf or not db.fade then return end

    local targetAlpha = db.fadeAlpha or 0
    local delay       = db.fadeOutDelay or 0.3
    local duration    = db.fadeOutDuration or 0.25

    if delay > 0 then
        C_Timer.After(delay, function()
            if not self._focused then
                UIFrameFadeOut(bf, duration, bf:GetAlpha(), targetAlpha)
            end
        end)
    else
        UIFrameFadeOut(bf, duration, bf:GetAlpha(), targetAlpha)
    end
end

-- =====================================================================
-- TRANSPARENT STATE (inspired by Dominos — hide cooldowns at 0 alpha)
-- =====================================================================
function TomoBar:UpdateTransparent()
    local bf = self.blizzFrame
    if not bf then return end

    local isTransparent = bf:GetAlpha() == 0
    if self._transparent ~= isTransparent then
        self._transparent = isTransparent
        for i = 1, self.count do
            local btn = _G[self.prefix .. i]
            if btn then
                local cd = btn.cooldown or _G[btn:GetName() and (btn:GetName() .. "Cooldown")]
                if cd then
                    if isTransparent then
                        cd:SetAlpha(0)
                    else
                        cd:SetAlpha(1)
                    end
                end
            end
        end
    end
end

-- =====================================================================
-- CLICK-THROUGH
-- =====================================================================
function TomoBar:SetClickThrough(enable)
    self.db.clickThrough = enable
    for i = 1, self.count do
        local btn = _G[self.prefix .. i]
        if btn then
            btn:EnableMouse(not enable)
        end
    end
end

function TomoBar:Lock()
    self.handle:Hide()
    if self.blizzFrame then
        self.blizzFrame:SetAlpha(self.db.alpha or 1)
    end
end

function TomoBar:Unlock()
    self.handle:Show()
    if self.handle and self.blizzFrame then
        -- Position handle above bar
        local bf = self.blizzFrame
        self.handle:ClearAllPoints()
        self.handle:SetPoint("BOTTOM", bf, "TOP", 0, 4)
    end
    if self.blizzFrame then
        self.blizzFrame:SetAlpha(1)
    end
end

-- =====================================================================
-- LOCK / UNLOCK ALL BARS
-- =====================================================================
function AB.LockAll()
    for _, bar in pairs(AB.bars) do
        bar:Lock()
    end
end

function AB.UnlockAll()
    for _, bar in pairs(AB.bars) do
        bar:Unlock()
    end
end

function AB.IsUnlocked()
    for _, bar in pairs(AB.bars) do
        if bar.handle and bar.handle:IsShown() then return true end
    end
    return false
end

-- =====================================================================
-- BAR EDITOR POPUP
-- =====================================================================
local editorFrame

local function EnsureEditorFrame()
    if editorFrame then return end

    editorFrame = CreateFrame("Frame", "TomoModBarEditor", UIParent, "BackdropTemplate")
    editorFrame:SetSize(340, 440)
    editorFrame:SetFrameStrata("DIALOG")
    editorFrame:SetFrameLevel(200)
    editorFrame:SetPoint("CENTER")
    editorFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editorFrame:SetBackdropColor(0.07, 0.07, 0.09, 0.98)
    editorFrame:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.55)
    editorFrame:SetMovable(true)
    editorFrame:EnableMouse(true)
    editorFrame:RegisterForDrag("LeftButton")
    editorFrame:SetScript("OnDragStart", editorFrame.StartMoving)
    editorFrame:SetScript("OnDragStop",  editorFrame.StopMovingOrSizing)
    editorFrame:SetClampedToScreen(true)
    editorFrame:Hide()
    tinsert(UISpecialFrames, "TomoModBarEditor")
end

function AB.ShowBarEditor(bar)
    EnsureEditorFrame()
    local ef = editorFrame
    local db = bar.db
    local aR, aG, aB = ACCENT[1], ACCENT[2], ACCENT[3]

    -- Anchor to the right of the config panel
    ef:ClearAllPoints()
    local configPanel = _G["TomoModConfigFrame"]
    if configPanel and configPanel:IsShown() then
        ef:SetPoint("TOPLEFT", configPanel, "TOPRIGHT", 8, 0)
    else
        ef:SetPoint("CENTER")
    end

    -- Clear previous content
    for i = ef:GetNumChildren(), 1, -1 do
        local child = select(i, ef:GetChildren())
        if child and child ~= ef then child:Hide() end
    end
    -- Also clear font strings / textures
    for i = ef:GetNumRegions(), 1, -1 do
        local region = select(i, ef:GetRegions())
        if region then region:Hide() end
    end

    -- Reapply backdrop (the cleanup above hides BackdropTemplate's internal textures)
    ef:SetBackdrop(nil)
    ef:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    ef:SetBackdropColor(0.07, 0.07, 0.09, 0.98)
    ef:SetBackdropBorderColor(aR, aG, aB, 0.55)
    -- Force-show backdrop regions that the cleanup loop may have hidden
    for i = 1, ef:GetNumRegions() do
        local region = select(i, ef:GetRegions())
        if region and region.GetDrawLayer then
            local layer = region:GetDrawLayer()
            if layer == "BACKGROUND" then region:Show() end
        end
    end

    -- Recreate the editor content
    local FONT_PATH = FONT
    local FONT_BOLD_PATH = FONT_BOLD

    -- Title bar
    local titleBg = ef:CreateTexture(nil, "BACKGROUND")
    titleBg:SetHeight(42)
    titleBg:SetPoint("TOPLEFT")
    titleBg:SetPoint("TOPRIGHT")
    titleBg:SetColorTexture(0.05, 0.05, 0.065, 1)

    local titleLbl = ef:CreateFontString(nil, "OVERLAY")
    titleLbl:SetFont(FONT_BOLD_PATH, 13, "")
    titleLbl:SetPoint("LEFT", 14, 0)
    titleLbl:SetPoint("TOP")
    titleLbl:SetPoint("BOTTOM", ef, "TOP", 0, -42)
    titleLbl:SetJustifyV("MIDDLE")
    titleLbl:SetText(bar.name)
    titleLbl:SetTextColor(0.90, 0.93, 0.91, 1)

    -- Accent line under title
    local titleSep = ef:CreateTexture(nil, "ARTWORK")
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  0, -42)
    titleSep:SetPoint("TOPRIGHT", 0, -42)
    titleSep:SetColorTexture(aR, aG, aB, 0.25)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, ef)
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("TOPRIGHT", -8, -7)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(FONT_BOLD_PATH, 18, "")
    closeTxt:SetPoint("CENTER", 0, 1)
    closeTxt:SetText("×")
    closeTxt:SetTextColor(0.36, 0.36, 0.40, 1)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(0.9, 0.3, 0.3, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(0.36, 0.36, 0.40, 1) end)
    closeBtn:SetScript("OnClick", function() ef:Hide() end)

    -- ===== Widget builders (local helpers) =====
    local function MakeLabel(text, y)
        local lbl = ef:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_PATH, 10, "")
        lbl:SetPoint("TOPLEFT", 16, y)
        lbl:SetTextColor(0.50, 0.50, 0.55, 1)
        lbl:SetText(text)
        return y - 14
    end

    local function MakeCheckbox(text, val, y, cb)
        local f = CreateFrame("Button", nil, ef)
        f:SetSize(310, 24)
        f:SetPoint("TOPLEFT", 16, y)

        local box = CreateFrame("Button", nil, f, "BackdropTemplate")
        box:SetSize(16, 16)
        box:SetPoint("LEFT", 0, 0)
        box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        box:SetBackdropColor(0.10, 0.10, 0.12, 1)
        box:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)

        local tick = box:CreateTexture(nil, "OVERLAY")
        tick:SetSize(10, 10)
        tick:SetPoint("CENTER")
        tick:SetColorTexture(aR, aG, aB, 1)

        local lbl = f:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_PATH, 11, "")
        lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
        lbl:SetTextColor(0.80, 0.82, 0.81, 1)
        lbl:SetText(text)

        local state = val
        local function Update()
            if state then
                tick:Show()
                box:SetBackdropBorderColor(aR, aG, aB, 0.80)
            else
                tick:Hide()
                box:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)
            end
        end
        Update()

        box:SetScript("OnClick", function()
            state = not state
            Update()
            if cb then cb(state) end
        end)
        f:SetScript("OnClick", function()
            state = not state
            Update()
            if cb then cb(state) end
        end)
        f.SetChecked = function(_, v) state = v; Update() end

        return f, y - 28
    end

    local function MakeSlider(text, val, minV, maxV, step, y, cb, fmt)
        fmt = fmt or "%.2f"
        local label = ef:CreateFontString(nil, "OVERLAY")
        label:SetFont(FONT_PATH, 11, "")
        label:SetPoint("TOPLEFT", 16, y)
        label:SetTextColor(0.80, 0.82, 0.81, 1)
        label:SetText(text)

        local valTxt = ef:CreateFontString(nil, "OVERLAY")
        valTxt:SetFont(FONT_PATH, 11, "")
        valTxt:SetPoint("TOPRIGHT", -16, y)
        valTxt:SetTextColor(aR, aG, aB, 1)
        valTxt:SetText(string.format(fmt, val))

        local slider = CreateFrame("Slider", nil, ef, "BackdropTemplate")
        slider:SetOrientation("HORIZONTAL")
        slider:SetSize(308, 8)
        slider:SetPoint("TOPLEFT", 16, y - 18)
        slider:SetMinMaxValues(minV, maxV)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(val)

        local trackBg = slider:CreateTexture(nil, "BACKGROUND")
        trackBg:SetAllPoints()
        trackBg:SetColorTexture(0.12, 0.12, 0.14, 1)

        slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(10, 14)
        thumb:SetVertexColor(aR, aG, aB, 1)

        slider:SetScript("OnValueChanged", function(_, v)
            v = math.floor(v / step + 0.5) * step
            valTxt:SetText(string.format(fmt, v))
            if cb then cb(v) end
        end)

        return slider, y - 46
    end

    -- ===== Build editor widgets =====
    local y = -52

    -- Alpha
    y = MakeLabel("Opacité de la barre", y)
    local _, ny = MakeSlider("", db.alpha, 0, 1, 0.05, y, function(v)
        db.alpha = v
        bar:ApplySettings()
    end, "%.2f")
    y = ny

    -- Scale
    y = MakeLabel("Échelle", y)
    local _, ny2 = MakeSlider("", db.scale, 0.5, 2.0, 0.05, y, function(v)
        db.scale = v
        bar:ApplySettings()
    end, "%.2f")
    y = ny2

    -- === FADE SECTION ===
    y = MakeLabel("— Fondu (Fade) —", y)

    -- Fade toggle
    local _, ny3 = MakeCheckbox("Activer le fondu au repos", db.fade, y, function(v)
        db.fade = v
        bar:ApplySettings()
    end)
    y = ny3

    -- Fade alpha
    y = MakeLabel("Opacité au repos", y)
    local _, ny4 = MakeSlider("", db.fadeAlpha, 0, 1, 0.05, y, function(v)
        db.fadeAlpha = v
        bar:ApplySettings()
    end, "%.2f")
    y = ny4

    -- Fade-in duration
    y = MakeLabel("Durée fondu entrant (sec)", y)
    local _, nyFiD = MakeSlider("", db.fadeInDuration or 0.15, 0, 1, 0.05, y, function(v)
        db.fadeInDuration = v
    end, "%.2f")
    y = nyFiD

    -- Fade-out delay
    y = MakeLabel("Délai fondu sortant (sec)", y)
    local _, nyFoDelay = MakeSlider("", db.fadeOutDelay or 0.3, 0, 2, 0.1, y, function(v)
        db.fadeOutDelay = v
    end, "%.1f")
    y = nyFoDelay

    -- Fade-out duration
    y = MakeLabel("Durée fondu sortant (sec)", y)
    local _, nyFoD = MakeSlider("", db.fadeOutDuration or 0.25, 0, 1, 0.05, y, function(v)
        db.fadeOutDuration = v
    end, "%.2f")
    y = nyFoD

    -- === VISIBILITY SECTION ===
    y = MakeLabel("— Visibilité —", y)

    -- Display condition dropdown
    y = MakeLabel("Condition d'affichage", y)
    local presetValues = {}
    local presetLabels = {}
    for _, p in ipairs(AB.DISPLAY_PRESETS) do
        presetValues[#presetValues + 1] = p.value
        presetLabels[#presetLabels + 1] = p.text
    end

    -- Find current preset index
    local currentPreset = db.displayCondition or ""
    local isCustom = true
    for _, p in ipairs(AB.DISPLAY_PRESETS) do
        if p.value == currentPreset then isCustom = false; break end
    end

    -- Preset buttons (compact 2-column layout)
    local col1X, col2X = 16, 170
    local btnH = 22
    for idx, preset in ipairs(AB.DISPLAY_PRESETS) do
        if preset.value ~= "custom" then
            local pBtn = CreateFrame("Button", nil, ef, "BackdropTemplate")
            pBtn:SetSize(146, btnH)
            local col = ((idx - 1) % 2)
            local row = math.floor((idx - 1) / 2)
            pBtn:SetPoint("TOPLEFT", col == 0 and col1X or col2X, y - (row * (btnH + 2)))
            pBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

            local isActive = (currentPreset == preset.value)
            if isActive then
                pBtn:SetBackdropColor(aR * 0.3, aG * 0.3, aB * 0.3, 0.9)
                pBtn:SetBackdropBorderColor(aR, aG, aB, 0.8)
            else
                pBtn:SetBackdropColor(0.08, 0.08, 0.10, 1)
                pBtn:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)
            end

            local pLbl = pBtn:CreateFontString(nil, "OVERLAY")
            pLbl:SetFont(FONT_PATH, 9, "")
            pLbl:SetPoint("CENTER")
            pLbl:SetTextColor(0.80, 0.82, 0.81, 1)
            pLbl:SetText(preset.text)

            pBtn:SetScript("OnClick", function()
                db.displayCondition = preset.value
                bar:UpdateDisplayCondition()
                -- Refresh the editor
                AB.ShowBarEditor(bar)
            end)
            pBtn:SetScript("OnEnter", function()
                pBtn:SetBackdropBorderColor(aR, aG, aB, 1)
            end)
            pBtn:SetScript("OnLeave", function()
                if currentPreset == preset.value then
                    pBtn:SetBackdropBorderColor(aR, aG, aB, 0.8)
                else
                    pBtn:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)
                end
            end)
        end
    end
    local totalPresetRows = math.ceil((#AB.DISPLAY_PRESETS - 1) / 2)
    y = y - (totalPresetRows * (btnH + 2)) - 6

    -- Custom condition editbox
    if isCustom and currentPreset ~= "" then
        y = MakeLabel("Condition personnalisée :", y)
        local editBox = CreateFrame("EditBox", nil, ef, "BackdropTemplate")
        editBox:SetSize(308, 24)
        editBox:SetPoint("TOPLEFT", 16, y)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetFont(FONT_PATH, 10, "")
        editBox:SetTextColor(0.9, 0.9, 0.9, 1)
        editBox:SetAutoFocus(false)
        editBox:SetText(currentPreset)
        editBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        editBox:SetBackdropColor(0.06, 0.06, 0.08, 1)
        editBox:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)
        editBox:SetTextInsets(6, 6, 2, 2)
        editBox:SetScript("OnEnterPressed", function(self)
            db.displayCondition = self:GetText()
            bar:UpdateDisplayCondition()
            self:ClearFocus()
        end)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        y = y - 30
    end

    -- === BUTTON OPTIONS ===
    y = MakeLabel("— Boutons —", y)

    -- Show hotkey
    local _, ny5 = MakeCheckbox("Afficher les raccourcis (hotkey)", db.showHotkey, y, function(v)
        db.showHotkey = v
        bar:ApplySettings()
    end)
    y = ny5

    -- Show macro name
    local _, ny6 = MakeCheckbox("Afficher le nom de macro", db.showMacro, y, function(v)
        db.showMacro = v
        bar:ApplySettings()
    end)
    y = ny6

    -- Show count
    local _, nyCt = MakeCheckbox("Afficher les compteurs (stacks)", db.showCount, y, function(v)
        db.showCount = v
        bar:ApplySettings()
    end)
    y = nyCt

    -- Show empty buttons
    local _, nyEB = MakeCheckbox("Afficher les emplacements vides", db.showEmptyButtons, y, function(v)
        db.showEmptyButtons = v
        bar:ApplySettings()
    end)
    y = nyEB

    -- Click-through
    local _, nyCT = MakeCheckbox("Clic traversant (click-through)", db.clickThrough, y, function(v)
        db.clickThrough = v
        bar:SetClickThrough(v)
    end)
    y = nyCT

    -- Hotkey font size
    y = MakeLabel("Taille police raccourcis", y)
    local _, ny7 = MakeSlider("", db.hotkeySize, 8, 18, 1, y, function(v)
        db.hotkeySize = v
        bar:ApplySettings()
    end, "%.0f")
    y = ny7

    -- Macro font size
    y = MakeLabel("Taille police macro", y)
    local _, ny8 = MakeSlider("", db.macroSize, 6, 16, 1, y, function(v)
        db.macroSize = v
        bar:ApplySettings()
    end, "%.0f")
    y = ny8

    -- Adjust editor height to content
    ef:SetHeight(math.abs(y) + 20)

    -- Position near the bar handle
    if bar.handle and bar.handle:IsShown() then
        ef:ClearAllPoints()
        ef:SetPoint("LEFT", bar.handle, "RIGHT", 12, 0)
    else
        ef:ClearAllPoints()
        ef:SetPoint("CENTER")
    end

    ef:Show()
end

-- =====================================================================
-- INITIALIZE
-- =====================================================================
function AB.Initialize()
    if not TomoModDB then return end
    TomoModDB.actionBars = TomoModDB.actionBars or { bars = {} }

    AB.bars = {}
    for _, def in ipairs(BAR_DEFS) do
        local bar = TomoBar:Create(def)
        AB.bars[def.id] = bar
    end
end

-- =====================================================================
-- APPLY ALL
-- =====================================================================
function AB.ApplyAll()
    for _, bar in pairs(AB.bars) do
        bar:ApplySettings()
    end
end

-- =====================================================================
-- GET BAR BY ID
-- =====================================================================
function AB.GetBar(id)
    return AB.bars[id]
end

-- =====================================================================
-- BOOT
-- =====================================================================
local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function()
    AB.Initialize()
end)

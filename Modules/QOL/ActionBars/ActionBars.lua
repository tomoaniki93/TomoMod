-- =====================================
-- ActionBars.lua — TomoBar system v2.7.0
-- Bar management: per-bar settings, drag overlays, BarEditor
-- Wraps native Blizzard action bars with full settings control
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
    enabled       = true,
    alpha         = 1.0,
    fade          = false,
    fadeAlpha     = 0.0,
    scale         = 1.0,
    showHotkey    = true,
    showMacro     = true,
    combatOnly    = false,
    hotkeySize    = 12,
    macroSize     = 9,
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

    -- Create drag overlay anchor frame
    self:_CreateOverlay()
    self:ApplySettings()

    return self
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
        end
    end

    -- Fade setup
    if db.fade then
        self:_SetupFade()
    else
        self:_TeardownFade()
        bf:SetAlpha(db.alpha or 1)
    end
end

function TomoBar:_SetupFade()
    local db  = self.db
    local bf  = self.blizzFrame
    if not bf or self._fadeSetup then return end
    self._fadeSetup = true

    bf:SetAlpha(db.fadeAlpha or 0)

    local self_ref = self
    bf:HookScript("OnEnter", function()
        if not self_ref.db.fade then return end
        UIFrameFadeIn(bf, 0.15, bf:GetAlpha(), self_ref.db.alpha or 1)
    end)
    bf:HookScript("OnLeave", function()
        if not self_ref.db.fade then return end
        C_Timer.After(0.3, function()
            if not MouseIsOver(bf) then
                UIFrameFadeOut(bf, 0.25, bf:GetAlpha(), self_ref.db.fadeAlpha or 0)
            end
        end)
    end)

    -- Also hook each button
    for i = 1, self.count do
        local btn = _G[self.prefix .. i]
        if btn then
            btn:HookScript("OnEnter", function()
                if not self_ref.db.fade then return end
                UIFrameFadeIn(bf, 0.15, bf:GetAlpha(), self_ref.db.alpha or 1)
            end)
            btn:HookScript("OnLeave", function()
                if not self_ref.db.fade then return end
                C_Timer.After(0.3, function()
                    if not MouseIsOver(bf) then
                        UIFrameFadeOut(bf, 0.25, bf:GetAlpha(), self_ref.db.fadeAlpha or 0)
                    end
                end)
            end)
        end
    end
end

function TomoBar:_TeardownFade()
    self._fadeSetup = false
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

    -- Fade
    local _, ny3 = MakeCheckbox("Disparition au repos (fade)", db.fade, y, function(v)
        db.fade = v
        bar:ApplySettings()
    end)
    y = ny3

    -- Fade alpha
    y = MakeLabel("Opacité au repos (fade)", y)
    local _, ny4 = MakeSlider("", db.fadeAlpha, 0, 1, 0.05, y, function(v)
        db.fadeAlpha = v
        bar:ApplySettings()
    end, "%.2f")
    y = ny4

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

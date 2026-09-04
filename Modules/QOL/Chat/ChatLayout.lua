-- =====================================================================
-- ChatLayout.lua — numeric presentation shell for TomoMod Chat V4
-- Nothing created here is anchored into Blizzard's chat anchor chain.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end

local Layout = {}
Chat.RegisterModule("Layout", Layout)

local WHITE = "Interface\\Buttons\\WHITE8X8"
local BG_R, BG_G, BG_B = 0.025, 0.045, 0.05
local TEAL_R, TEAL_G, TEAL_B = 0.20, 0.82, 0.60

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeNumber(value)
    return type(value) == "number" and not IsSecret(value)
end

local function SafeRect(frame)
    if not frame then return end
    local left, bottom, width, height = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
    if not SafeNumber(left) or not SafeNumber(bottom) or not SafeNumber(width) or not SafeNumber(height) then
        return
    end
    if width <= 1 or height <= 1 then return end
    return left, bottom, width, height
end

local function CreateBackdropFrame(name, parent)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:EnableMouse(false)
    return frame
end

local function SaveChatPosition(frame)
    if not frame then return end

    local db = Chat.GetDB()
    db.position = type(db.position) == "table" and db.position or {}
    if TomoMod_Layout and TomoMod_Layout.Save then
        TomoMod_Layout.Save(db.position, frame)
    end

    -- Keep Blizzard's own chat-window persistence in sync as well. The call is
    -- optional so a client rename cannot prevent the TomoMod position save.
    if type(FCF_SavePositionAndDimensions) == "function" then
        pcall(FCF_SavePositionAndDimensions, frame)
    end
end

function Layout:Initialize()
    if self.panel then return end

    local panel = CreateBackdropFrame("TomoMod_ChatV4Panel", UIParent)
    panel:SetFrameStrata("LOW")
    panel:SetFrameLevel(5)
    panel:Hide()
    self.panel = panel

    local messageHost = CreateFrame("Frame", "TomoMod_ChatV4MessageHost", UIParent, "BackdropTemplate")
    messageHost:SetBackdrop({ bgFile = WHITE })
    messageHost:SetFrameStrata("MEDIUM")
    messageHost:SetFrameLevel(90)
    messageHost:EnableMouse(false)
    messageHost:Hide()
    self.messageHost = messageHost

    local tabsHost = CreateFrame("Frame", "TomoMod_ChatV4TabsHost", UIParent, "BackdropTemplate")
    tabsHost:SetBackdrop({ bgFile = WHITE })
    tabsHost:SetFrameStrata("MEDIUM")
    tabsHost:SetFrameLevel(98)
    tabsHost:EnableMouse(false)
    tabsHost:Hide()
    self.tabsHost = tabsHost

    local sidebarHost = CreateFrame("Frame", "TomoMod_ChatV4SidebarHost", UIParent, "BackdropTemplate")
    sidebarHost:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    sidebarHost:SetFrameStrata("MEDIUM")
    sidebarHost:SetFrameLevel(99)
    sidebarHost:Hide()
    self.sidebarHost = sidebarHost

    local inputHost = CreateBackdropFrame("TomoMod_ChatV4InputHost", UIParent)
    inputHost:SetFrameStrata("MEDIUM")
    inputHost:SetFrameLevel(88)
    inputHost:Hide()
    self.inputHost = inputHost

    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(TEAL_R, TEAL_G, TEAL_B, 0.55)
    divider:SetHeight(1)
    self.divider = divider

    self:RegisterMover()

    self:ApplySettings(Chat.IsEnabled())
end

function Layout:EnsureMover()
    if self.mover then return self.mover end

    local mover = CreateFrame("Frame", "TomoMod_ChatV4Mover", UIParent, "BackdropTemplate")
    mover:SetAllPoints(self.panel)
    mover:SetFrameStrata("HIGH")
    mover:SetFrameLevel(500)
    mover:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 2 })
    mover:SetBackdropColor(TEAL_R, TEAL_G, TEAL_B, 0.16)
    mover:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, 0.95)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:Hide()

    local label = mover:CreateFontString(nil, "OVERLAY")
    TomoMod_Utils.StyleMoverLabel(label, 12)
    label:SetPoint("CENTER")
    label:SetText((TomoMod_L and TomoMod_L["frame_chat_v4"]) or "Chat V4")

    mover:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        local frame = _G.ChatFrame1
        if not frame then return end

        self._dragFrame = frame
        self._wasMovable = frame.IsMovable and frame:IsMovable() or false
        frame:SetMovable(true)
        frame:StartMoving()
        self:SetScript("OnUpdate", function()
            Layout:RefreshGeometry()
        end)
    end)

    mover:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        local frame = self._dragFrame
        self._dragFrame = nil
        if not frame then return end

        frame:StopMovingOrSizing()
        if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
        SaveChatPosition(frame)
        if not self._wasMovable then frame:SetMovable(false) end
        self._wasMovable = nil
        Layout:RefreshGeometry()
    end)

    self.mover = mover
    return mover
end

function Layout:SetMoverUnlocked(unlocked)
    local mover = self:EnsureMover()
    if unlocked and Chat.IsEnabled() then
        mover:SetAllPoints(self.panel)
        mover:Show()
    else
        if mover._dragFrame then
            mover:GetScript("OnDragStop")(mover)
        end
        mover:Hide()
    end
end

function Layout:RegisterMover()
    if self._moverRegistered then return end
    local movers = _G.TomoMod_Movers
    if not movers or type(movers.RegisterEntry) ~= "function" then return end

    self._moverRegistered = true
    movers.RegisterEntry({
        label = (TomoMod_L and TomoMod_L["frame_chat_v4"]) or "Chat V4",
        unlock = function() Layout:SetMoverUnlocked(true) end,
        lock = function() Layout:SetMoverUnlocked(false) end,
        isActive = function() return Chat.IsEnabled() end,
    })
end

function Layout:RefreshGeometry()
    if not self.panel then return end
    local cf = _G.ChatFrame1
    local left, bottom, width, height = SafeRect(cf)
    if not left then return end

    self._lastRect = { left, bottom, width, height }

    local db = Chat.GetDB()
    local a = db.appearance
    local sb = db.sidebar
    local tabH = a.tabHeight or 25
    local inputH = a.inputHeight or 30
    local sideW = sb.width or 32
    local gap = 5
    local sideRight = sb.side == "RIGHT"

    local panelLeft = sideRight and left or (left - sideW - gap)
    local panelBottom = bottom - inputH - gap
    local panelWidth = width + sideW + gap
    local panelHeight = height + tabH + inputH + gap * 2

    self.panel:ClearAllPoints()
    self.panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", panelLeft, panelBottom)
    self.panel:SetSize(panelWidth, panelHeight)

    self.messageHost:ClearAllPoints()
    self.messageHost:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
    self.messageHost:SetSize(width, height)

    self.tabsHost:ClearAllPoints()
    self.tabsHost:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom + height + gap)
    self.tabsHost:SetSize(width, tabH)

    self.inputHost:ClearAllPoints()
    self.inputHost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, bottom - gap)
    self.inputHost:SetSize(width, inputH)

    self.sidebarHost:ClearAllPoints()
    if sideRight then
        self.sidebarHost:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left + width + gap, panelBottom)
    else
        self.sidebarHost:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - sideW - gap, panelBottom)
    end
    self.sidebarHost:SetSize(sideW, panelHeight)

    self.divider:ClearAllPoints()
    if sideRight then
        self.divider:SetPoint("TOPRIGHT", self.panel, "TOPRIGHT", -sideW - gap, -tabH - gap)
        self.divider:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 0, -tabH - gap)
    else
        self.divider:SetPoint("TOPLEFT", self.panel, "TOPLEFT", sideW + gap, -tabH - gap)
        self.divider:SetPoint("TOPRIGHT", self.panel, "TOPRIGHT", 0, -tabH - gap)
    end

    local renderer = Chat.Modules.Renderer
    if renderer and renderer.LayoutWindows then renderer:LayoutWindows() end
    local tabs = Chat.Modules.Tabs
    if tabs and tabs.Refresh then tabs:Refresh() end
    local input = Chat.Modules.Input
    if input and input.Refresh then input:Refresh() end
    local sidebar = Chat.Modules.Sidebar
    if sidebar and sidebar.LayoutButtons then sidebar:LayoutButtons() end
end

function Layout:ApplySettings(enabled)
    if not self.panel then return end
    local db = Chat.GetDB()
    local a = db.appearance
    local frameAlpha = a.bgAlpha or 0.72
    local messageAlpha = a.messageBgAlpha
    if type(messageAlpha) ~= "number" then messageAlpha = frameAlpha end

    -- The outer panel owns only the border. Each visible surface owns its own
    -- fill so the message area can be made transparent without also fading the
    -- tabs, sidebar or input box (and without a global backdrop showing through).
    self.panel:SetBackdropColor(BG_R, BG_G, BG_B, 0)
    self.panel:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, a.borderAlpha or 0.22)
    self.messageHost:SetBackdropColor(BG_R, BG_G, BG_B, messageAlpha)
    self.tabsHost:SetBackdropColor(BG_R, BG_G, BG_B, frameAlpha)
    self.sidebarHost:SetBackdropColor(BG_R, BG_G, BG_B, math.min(0.96, frameAlpha + 0.08))
    self.sidebarHost:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, a.borderAlpha or 0.22)
    self.inputHost:SetBackdropColor(BG_R, BG_G, BG_B, math.min(0.96, frameAlpha + 0.08))
    self.inputHost:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, a.borderAlpha or 0.22)

    if enabled then
        self.panel:Show()
        self.messageHost:Show()
        self.tabsHost:Show()
        self.sidebarHost:Show()
        self.inputHost:Show()
        self:RefreshGeometry()
    else
        self.panel:Hide()
        self.messageHost:Hide()
        self.tabsHost:Hide()
        self.sidebarHost:Hide()
        self.inputHost:Hide()
    end

    local movers = _G.TomoMod_Movers
    local layoutUnlocked = movers and type(movers.IsUnlocked) == "function" and movers.IsUnlocked()
    self:SetMoverUnlocked(enabled and layoutUnlocked)
end

function Layout:GetSafeRect(frame)
    return SafeRect(frame)
end

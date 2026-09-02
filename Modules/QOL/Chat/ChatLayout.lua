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

    self:ApplySettings(Chat.IsEnabled())
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
end

function Layout:GetSafeRect(frame)
    return SafeRect(frame)
end

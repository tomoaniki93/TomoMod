-- =====================================================================
-- ChatTabs.lua — TomoMod Chat V4 tab strip
-- Blizzard tabs remain the behavior authority; TomoMod owns their visuals
-- and placement so detached windows (notably ChatFrame2 / Combat Log) still
-- live inside the single V4 container.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end

local Tabs = {}
Chat.RegisterModule("Tabs", Tabs)

Tabs.ghosts = {}
Tabs.unread = {}
Tabs.selected = nil

local TEAL_R, TEAL_G, TEAL_B = 0.20, 0.82, 0.60
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeNumber(value)
    return type(value) == "number" and not IsSecret(value)
end

local function SafeRect(frame)
    if not frame then return end
    local l, b, w, h = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
    if not SafeNumber(l) or not SafeNumber(b) or not SafeNumber(w) or not SafeNumber(h) then return end
    if w <= 1 or h <= 1 then return end
    return l, b, w, h
end

local function SuppressNativeTab(tab, ghost)
    ghost.nativeRegions = ghost.nativeRegions or {}
    local count = select("#", tab:GetRegions())
    for i = 1, count do
        local region = select(i, tab:GetRegions())
        if region and region.SetAlpha then
            if ghost.nativeRegions[region] == nil then
                ghost.nativeRegions[region] = region:GetAlpha()
            end
            region:SetAlpha(0)
        end
    end
end

local function RestoreNativeTab(ghost)
    if not ghost.nativeRegions then return end
    for region, alpha in pairs(ghost.nativeRegions) do
        if region and region.SetAlpha then region:SetAlpha(alpha or 1) end
    end
end

local function ShouldMirrorTab(cf)
    if not cf then return false end
    if cf._tomoCommunity then return true end
    -- Combat Log is special: players can undock/move ChatFrame2 independently,
    -- but V4 still treats it as a first-class tab beside General.
    return cf == _G.ChatFrame1 or cf == _G.ChatFrame2 or cf.isDocked == true
end

local function NativeSelectedFrame()
    local selected = GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow
        and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
    return selected or SELECTED_CHAT_FRAME or _G.ChatFrame1
end

function Tabs:GetSelectedFrame()
    if self.selected and ShouldMirrorTab(self.selected) then
        return self.selected
    end
    local selected = NativeSelectedFrame()
    if selected and ShouldMirrorTab(selected) then return selected end
    return _G.ChatFrame1
end

function Tabs:SetSelectedFrame(cf)
    if not ShouldMirrorTab(cf) then return end
    self.selected = cf
    self.unread[cf] = nil
end

local function RefreshSelection()
    local renderer = Chat.Modules.Renderer
    if renderer then
        local selected = Tabs:GetSelectedFrame()
        if selected then renderer:EnsureFrame(selected) end
        renderer:RefreshVisibility()
    end
    local input = Chat.Modules.Input
    if input and input.Refresh then input:Refresh() end
end

local function CreateGhost()
    local g = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    g:SetBackdrop({ bgFile = WHITE })
    g:SetBackdropColor(0.025, 0.045, 0.05, 0.88)
    g:SetFrameStrata("MEDIUM")
    g:SetFrameLevel(100)
    g:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    g:EnableMouse(true)
    g:Hide()

    local text = g:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", 0, 1)
    text:SetTextColor(0.72, 0.76, 0.78, 1)
    g.text = text

    local underline = g:CreateTexture(nil, "OVERLAY")
    underline:SetColorTexture(TEAL_R, TEAL_G, TEAL_B, 1)
    underline:SetHeight(2)
    underline:SetPoint("BOTTOMLEFT", 2, 0)
    underline:SetPoint("BOTTOMRIGHT", -2, 0)
    underline:Hide()
    g.underline = underline

    local dot = g:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dot:SetPoint("TOPRIGHT", -3, -2)
    dot:SetText("•")
    dot:SetTextColor(TEAL_R, TEAL_G, TEAL_B, 1)
    dot:Hide()
    g.dot = dot

    g:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.045, 0.075, 0.08, 0.96)
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    g:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.025, 0.045, 0.05, 0.88)
        local active = self.cf == Tabs:GetSelectedFrame()
        self.text:SetTextColor(active and 1 or 0.72, active and 1 or 0.76, active and 1 or 0.78, 1)
    end)
    g:SetScript("OnClick", function(self, button)
        local cf, tab = self.cf, self.tab
        if not cf then return end

        Tabs:SetSelectedFrame(cf)

        -- Let Blizzard execute its normal tab behavior (Combat Log filter state,
        -- temporary windows, context menu). The native tab is only invisible;
        -- it is not replaced as a behavior implementation.
        if tab and tab.Click then
            tab:Click(button or "LeftButton")
        end

        C_Timer.After(0, function()
            RefreshSelection()
            Tabs:Refresh()
        end)
    end)

    return g
end

function Tabs:NotifyMessage(cf)
    if cf ~= self:GetSelectedFrame() then
        self.unread[cf] = true
        self:Refresh()
    end
end

function Tabs:Refresh()
    if not self._initialized then return end
    local enabled = Chat.IsEnabled()
    local selected = self:GetSelectedFrame()
    if selected then self.unread[selected] = nil end

    local layout = Chat.Modules.Layout
    local host = layout and layout.tabsHost
    local _, _, hostWidth, hostHeight = SafeRect(host)
    if not host then return end

    local used = 0
    local x = 1
    local function PlaceGhost(cf, tab, name)
        used = used + 1
        local g = self.ghosts[used] or CreateGhost()
        self.ghosts[used] = g
        g.cf = cf
        g.tab = tab
        g.text:SetText(name)

        -- Never use the native tab's screen position. ChatFrame2 can be
        -- undocked and physically moved by Blizzard; V4 tabs always flow
        -- left-to-right inside our own tabsHost.
        local nativeWidth = tab and tab.GetWidth and tab:GetWidth()
        local textWidth = g.text:GetStringWidth()
        if not SafeNumber(textWidth) then textWidth = 48 end
        local width = SafeNumber(nativeWidth) and nativeWidth or (textWidth + 22)
        width = math.max(62, math.min(130, width))
        if hostWidth and x + width > hostWidth then
            width = math.max(42, hostWidth - x - 1)
        end

        g:ClearAllPoints()
        g:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", x, 1)
        g:SetSize(width, math.max(18, (hostHeight or 25) - 2))
        x = x + width + 3

        local active = cf == selected
        g.text:SetTextColor(active and 1 or 0.72, active and 1 or 0.76, active and 1 or 0.78, 1)
        g.underline:SetShown(active)
        g.dot:SetShown(self.unread[cf] == true and not active)
        g:Show()
        if tab then SuppressNativeTab(tab, g) end
    end

    for i = 1, 20 do
        local cf = _G["ChatFrame" .. i]
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if cf and tab and ShouldMirrorTab(cf) then
            local name = GetChatWindowInfo and select(1, GetChatWindowInfo(i))
            if IsSecret(name) then name = nil end

            if enabled and name and name ~= "" then
                PlaceGhost(cf, tab, name)
            end
        end
    end

    local renderer = Chat.Modules.Renderer
    local community = renderer and renderer.communityFrame
    if enabled and community then
        PlaceGhost(community, nil,
            (TomoMod_L and TomoMod_L["chat_v4_tab_community"]) or "Community")
    end

    for i = used + 1, #self.ghosts do
        local g = self.ghosts[i]
        RestoreNativeTab(g)
        g:Hide()
        g.cf = nil
        g.tab = nil
    end
end

function Tabs:Initialize()
    self._initialized = true
    self.selected = NativeSelectedFrame() or _G.ChatFrame1
    self:Refresh()
end

function Tabs:ApplySettings(enabled)
    if enabled then
        self:Refresh()
    else
        self.selected = nil
        for _, g in ipairs(self.ghosts) do
            RestoreNativeTab(g)
            g:Hide()
        end
    end
end

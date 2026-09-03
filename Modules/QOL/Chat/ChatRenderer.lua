-- =====================================================================
-- ChatRenderer.lua — owned message surfaces for TomoMod Chat V4
-- Blizzard chat frames remain the formatting/security authority.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end

local Renderer = {}
Chat.RegisterModule("Renderer", Renderer)

Renderer.windows = {}
Renderer.combatQuickState = nil
Renderer.combatQuickInset = 0
Renderer.alphaLocks = setmetatable({}, { __mode = "k" })
Renderer.alphaHooks = setmetatable({}, { __mode = "k" })
Renderer.alphaEnforcing = setmetatable({}, { __mode = "k" })
Renderer.interactionEnabled = true
Renderer.communitySeen = {}
Renderer.communitySeenOrder = {}
Renderer.communitySourcesBackfilled = setmetatable({}, { __mode = "k" })

local COMMUNITY_EVENTS = {
    CHAT_MSG_WHISPER = true,
    CHAT_MSG_WHISPER_INFORM = true,
    CHAT_MSG_BN_WHISPER = true,
    CHAT_MSG_BN_WHISPER_INFORM = true,
    CHAT_MSG_GUILD = true,
    CHAT_MSG_OFFICER = true,
}

local COMMUNITY_TYPES = {
    "WHISPER", "WHISPER_INFORM",
    "BN_WHISPER", "BN_WHISPER_INFORM",
    "GUILD", "OFFICER",
}

local NATIVE_CHROME_SUFFIXES = {
    "Background",
    "TopLeftTexture", "BottomLeftTexture", "TopRightTexture", "BottomRightTexture",
    "LeftTexture", "RightTexture", "BottomTexture", "TopTexture",
    "ButtonFrameBackground",
    "ButtonFrameTopLeftTexture", "ButtonFrameBottomLeftTexture",
    "ButtonFrameTopRightTexture", "ButtonFrameBottomRightTexture",
    "ButtonFrameLeftTexture", "ButtonFrameRightTexture",
    "ButtonFrameBottomTexture", "ButtonFrameTopTexture",
}

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeNumber(value)
    return type(value) == "number" and not IsSecret(value)
end

local function SafeOffset(value)
    return SafeNumber(value)
end

local communityFrame = { _tomoCommunity = true }
Renderer.communityFrame = communityFrame

function communityFrame:GetName()
    return "TomoMod_ChatV4Community"
end

local function CommunitySurface()
    local win = Renderer.windows[communityFrame]
    return win and win.smf
end

for _, method in ipairs({
    "GetNumMessages", "GetMessageInfo", "GetScrollOffset",
    "ScrollUp", "ScrollDown", "PageUp", "PageDown", "ScrollToTop", "ScrollToBottom",
}) do
    local methodName = method
    communityFrame[methodName] = function(_, ...)
        local surface = CommunitySurface()
        local callback = surface and surface[methodName]
        if callback then return callback(surface, ...) end
    end
end

local function IsCommunityMessage(chatTypeID, event)
    if not IsSecret(event) and type(event) == "string" and COMMUNITY_EVENTS[event] then
        return true
    end
    if IsSecret(chatTypeID) or type(chatTypeID) ~= "number" then return false end

    for _, chatType in ipairs(COMMUNITY_TYPES) do
        local info = ChatTypeInfo and ChatTypeInfo[chatType]
        if info and not IsSecret(info.id) and info.id == chatTypeID then return true end
    end
    return false
end

local function CommunityMessageKey(message, chatTypeID, lineID, event)
    if not IsSecret(lineID) and (type(lineID) == "number" or type(lineID) == "string")
        and lineID ~= 0 and lineID ~= "" then
        return "line:" .. tostring(lineID)
    end
    if IsSecret(message) or type(message) ~= "string" then return end

    local kind = not IsSecret(event) and type(event) == "string" and event
    if not kind then
        kind = not IsSecret(chatTypeID) and tostring(chatTypeID or "") or ""
    end
    local stamp = GetTime and math.floor(GetTime() * 5) or 0
    return kind .. ":" .. stamp .. ":" .. message
end

-- Blizzard reapplies FloatingChatFrame alpha after a native tab click. A
-- one-shot SetAlpha(0) therefore lasts only until the first General/Combat Log
-- switch. Keep the presentation regions locked at zero while V4 owns the
-- visuals, then release the lock before restoring the captured native alpha.
local function LockAlpha(region)
    if not region or type(region.SetAlpha) ~= "function" then return end

    Renderer.alphaLocks[region] = true
    if not Renderer.alphaHooks[region] and hooksecurefunc then
        local ok = pcall(hooksecurefunc, region, "SetAlpha", function(self)
            if not Renderer.alphaLocks[self] or Renderer.alphaEnforcing[self] then return end
            Renderer.alphaEnforcing[self] = true
            self:SetAlpha(0)
            Renderer.alphaEnforcing[self] = nil
        end)
        if ok then Renderer.alphaHooks[region] = true end
    end

    Renderer.alphaEnforcing[region] = true
    region:SetAlpha(0)
    Renderer.alphaEnforcing[region] = nil
end

local function RestoreAlpha(region, alpha)
    if not region or type(region.SetAlpha) ~= "function" then return end
    Renderer.alphaLocks[region] = nil
    Renderer.alphaEnforcing[region] = nil
    region:SetAlpha(alpha == nil and 1 or alpha)
end

function Renderer:ShouldManage(cf)
    if not cf then return false end
    if cf._tomoCommunity then return true end
    -- Blizzard remains the authority for Combat Log filtering and formatting:
    -- ChatFrame2 receives the final filtered lines first, then our AddMessage
    -- post-hook mirrors those lines into the V4 surface.
    if cf == _G.ChatFrame1 or cf == _G.ChatFrame2 then return true end
    return cf.isDocked == true
end

local function CaptureRegionAlpha(native, region)
    if not region or not region.SetAlpha or not region.GetAlpha then return end
    native.chrome = native.chrome or {}
    if native.chrome[region] == nil then
        native.chrome[region] = region:GetAlpha()
    end
end

local function EachNativeChrome(cf, callback)
    if not cf or not callback then return end
    local seen = {}
    local function Add(region)
        if region and not seen[region] then
            seen[region] = true
            callback(region)
        end
    end

    Add(cf.Background)
    Add(cf.ResizeButton)

    local name = cf.GetName and cf:GetName()
    if name then
        for _, suffix in ipairs(NATIVE_CHROME_SUFFIXES) do
            Add(cf[suffix])
            Add(_G[name .. suffix])
        end
        Add(_G[name .. "ResizeButton"])
    end
end

local function CaptureNativeState(cf, win)
    win.native = win.native or {}
    local native = win.native

    if native.fontFile == nil and cf.GetFont then
        native.fontFile, native.fontSize, native.fontFlags = cf:GetFont()
    end

    local text = cf.FontStringContainer
    if text and native.textAlpha == nil then native.textAlpha = text:GetAlpha() end

    local bar = cf.ScrollBar
    if bar and native.scrollAlpha == nil then native.scrollAlpha = bar:GetAlpha() end

    local name = cf:GetName()
    local buttonFrame = name and _G[name .. "ButtonFrame"]
    if buttonFrame and native.buttonAlpha == nil then native.buttonAlpha = buttonFrame:GetAlpha() end

    local scrollButton = cf.ScrollToBottomButton
    if scrollButton and native.scrollButtonAlpha == nil then native.scrollButtonAlpha = scrollButton:GetAlpha() end

    EachNativeChrome(cf, function(region)
        CaptureRegionAlpha(native, region)
    end)
end

function Renderer:SuppressNative(cf)
    if not cf or cf._tomoCommunity then return end
    local win = self.windows[cf]
    if not win then return end
    CaptureNativeState(cf, win)

    LockAlpha(cf.FontStringContainer)
    LockAlpha(cf.ScrollBar)

    local name = cf:GetName()
    local buttonFrame = name and _G[name .. "ButtonFrame"]
    LockAlpha(buttonFrame)
    LockAlpha(cf.ScrollToBottomButton)

    -- The old implementation only hid text + scroll controls. Blizzard's
    -- Background/NineSlice textures therefore remained visible as a second
    -- translucent rectangle behind the V4 panel. Suppress every documented
    -- FloatingChatFrame chrome region while keeping the frame itself alive.
    EachNativeChrome(cf, function(region)
        LockAlpha(region)
    end)
end

function Renderer:RestoreNative(cf)
    if not cf or cf._tomoCommunity then return end
    local win = self.windows[cf]
    if not win or not win.native then return end
    local native = win.native

    if native.fontFile and native.fontSize and cf.SetFont then
        cf:SetFont(native.fontFile, native.fontSize, native.fontFlags or "")
    end
    RestoreAlpha(cf.FontStringContainer, native.textAlpha)
    RestoreAlpha(cf.ScrollBar, native.scrollAlpha)

    local name = cf:GetName()
    local buttonFrame = name and _G[name .. "ButtonFrame"]
    RestoreAlpha(buttonFrame, native.buttonAlpha)
    RestoreAlpha(cf.ScrollToBottomButton, native.scrollButtonAlpha)

    if native.chrome then
        for region, alpha in pairs(native.chrome) do
            RestoreAlpha(region, alpha)
        end
    end
end

local function GetCombatQuickFrame()
    local cf = _G.ChatFrame2
    if cf and cf.CombatLogQuickButtonFrame then
        return cf.CombatLogQuickButtonFrame
    end
    -- Retail has used this named frame for the real Combat Log controls while
    -- keeping a dummy CombatLogQuickButtonFrame for floating-chat compatibility.
    return _G.CombatLogQuickButtonFrame_Custom
end

local function CaptureCombatQuickState(frame)
    if not frame or Renderer.combatQuickState then return end
    local state = {
        frame = frame,
        shown = frame:IsShown(),
        points = {},
        strata = frame.GetFrameStrata and frame:GetFrameStrata(),
        level = frame.GetFrameLevel and frame:GetFrameLevel(),
    }
    local count = frame.GetNumPoints and frame:GetNumPoints() or 0
    for i = 1, count do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        if point and relativePoint and SafeNumber(x or 0) and SafeNumber(y or 0) then
            state.points[#state.points + 1] = {
                point, relativeTo, relativePoint, x or 0, y or 0,
            }
        end
    end
    Renderer.combatQuickState = state
end

function Renderer:RestoreCombatQuickFrame()
    local state = self.combatQuickState
    if not state or not state.frame then return end
    local frame = state.frame
    frame:ClearAllPoints()
    for _, point in ipairs(state.points) do
        frame:SetPoint(point[1], point[2], point[3], point[4], point[5])
    end
    if state.strata and frame.SetFrameStrata then frame:SetFrameStrata(state.strata) end
    if state.level and frame.SetFrameLevel then frame:SetFrameLevel(state.level) end
    frame:SetShown(state.shown)
    self.combatQuickState = nil
    self.combatQuickInset = 0
end

function Renderer:LayoutCombatQuickFrame(selected)
    local quick = GetCombatQuickFrame()
    local layout = Chat.Modules.Layout
    if not quick or not layout or not layout.messageHost then
        self.combatQuickInset = 0
        return 0
    end

    CaptureCombatQuickState(quick)

    if not Chat.IsEnabled() then
        self:RestoreCombatQuickFrame()
        return 0
    end

    if selected ~= _G.ChatFrame2 then
        quick:Hide()
        self.combatQuickInset = 0
        return 0
    end

    -- Keep Blizzard's filter buttons and their click behavior, but anchor the
    -- bar to the V4 message area instead of ChatFrame2's independently movable
    -- native rectangle. No reparenting and no filter logic is replaced.
    quick:ClearAllPoints()
    quick:SetPoint("TOPLEFT", layout.messageHost, "TOPLEFT", 0, 0)
    quick:SetPoint("TOPRIGHT", layout.messageHost, "TOPRIGHT", 0, 0)
    if quick.SetFrameStrata then quick:SetFrameStrata("MEDIUM") end
    if quick.SetFrameLevel then quick:SetFrameLevel(layout.messageHost:GetFrameLevel() + 4) end
    quick:Show()

    local height = quick.GetHeight and quick:GetHeight()
    if not SafeNumber(height) or height < 1 then height = 28 end
    self.combatQuickInset = height + 2
    return self.combatQuickInset
end

function Renderer:CreateWindow(cf)
    if self.windows[cf] then return self.windows[cf] end
    local layout = Chat.Modules.Layout
    if not layout or not layout.messageHost then return end

    local smf = CreateFrame("ScrollingMessageFrame", nil, layout.messageHost)
    smf:SetAllPoints(layout.messageHost)
    smf:SetFading(false)
    smf:SetIndentedWordWrap(true)
    smf:SetJustifyH("LEFT")
    smf:SetScrollAllowed(true)
    smf:EnableMouse(self.interactionEnabled)
    smf:EnableMouseWheel(self.interactionEnabled)
    smf:SetHyperlinksEnabled(self.interactionEnabled)
    smf:SetFrameLevel(layout.messageHost:GetFrameLevel() + 1)
    smf:Hide()

    local win = {
        cf = cf,
        smf = smf,
        backfilled = false,
    }
    self.windows[cf] = win

    smf:SetScript("OnHyperlinkClick", function(_, link, text, button)
        if type(link) == "string" and link:sub(1, 6) == "tmurl:" then
            local copy = Chat.Modules.Copy
            if copy and copy.ShowURLPopup then copy:ShowURLPopup(link:sub(7)) end
            return
        end
        if SetItemRef then SetItemRef(link, text, button, smf) end
    end)
    smf:SetScript("OnMouseWheel", function(_, delta)
        if not Chat.IsEnabled() then return end
        local up = delta > 0
        if IsShiftKeyDown() then
            if up then cf:ScrollToTop() else cf:ScrollToBottom() end
        elseif IsControlKeyDown() and cf.PageUp and cf.PageDown then
            if up then cf:PageUp() else cf:PageDown() end
        else
            for _ = 1, 3 do
                if up then cf:ScrollUp() else cf:ScrollDown() end
            end
        end
    end)

    if not cf._tomoCommunity then CaptureNativeState(cf, win) end
    self:ApplyWindowSettings(win)
    return win
end

-- Blizzard Edit Mode and TomoMod Layout Mode both need to receive the mouse on
-- the native chat frame underneath this presentation surface. Outside those
-- modes the V4 surface owns the mouse again so hyperlinks and scrolling work.
function Renderer:SetInteractionEnabled(enabled)
    self.interactionEnabled = enabled and true or false
    for _, win in pairs(self.windows) do
        local smf = win.smf
        if smf then
            smf:EnableMouse(self.interactionEnabled)
            smf:EnableMouseWheel(self.interactionEnabled)
            smf:SetHyperlinksEnabled(self.interactionEnabled)
        end
    end
end

function Renderer:ApplyWindowSettings(win)
    if not win or not win.smf then return end
    local a = Chat.GetDB().appearance
    local native = win.native or {}
    local font = native.fontFile or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flags = native.fontFlags or ""
    local size = a.fontSize or native.fontSize or 13

    if win.cf and win.cf.SetFont then win.cf:SetFont(font, size, flags) end
    win.smf:SetFont(font, size, flags)
    win.smf:SetMaxLines(a.maxLines or 512)

    local messages = Chat.GetDB().messages or {}
    local fade = messages.fade ~= false
    win.smf:SetFading(fade)
    if fade then
        if win.smf.SetTimeVisible then win.smf:SetTimeVisible(120) end
        if win.smf.SetFadeDuration then win.smf:SetFadeDuration(3) end
    end
end

function Renderer:Backfill(cf)
    local win = self.windows[cf] or self:CreateWindow(cf)
    if not win or win.backfilled then return end
    win.backfilled = true

    local count = cf.GetNumMessages and cf:GetNumMessages() or 0
    if type(count) ~= "number" or IsSecret(count) then return end
    if not cf._tomoCommunity then self.communitySourcesBackfilled[cf] = true end
    local maxLines = Chat.GetDB().appearance.maxLines or 512
    local first = math.max(1, count - maxLines + 1)

    for i = first, count do
        local ok, msg, r, g, b, chatTypeID, messageAccessID, lineID, event = pcall(cf.GetMessageInfo, cf, i)
        if ok and msg ~= nil then
            local messages = Chat.Modules.Messages
            local display = messages and messages.Format and messages:Format(msg) or msg
            win.smf:AddMessage(display, r, g, b, chatTypeID)
            if not cf._tomoCommunity then
                self:AddCommunityMessage(msg, r, g, b, chatTypeID, messageAccessID, lineID, event, display)
            end
        end
    end
end

function Renderer:BackfillCommunity(cf)
    if not cf or cf._tomoCommunity or self.communitySourcesBackfilled[cf] then return end

    local count = cf.GetNumMessages and cf:GetNumMessages() or 0
    if type(count) ~= "number" or IsSecret(count) then return end
    self.communitySourcesBackfilled[cf] = true
    local maxLines = Chat.GetDB().appearance.maxLines or 512
    local first = math.max(1, count - maxLines + 1)

    for i = first, count do
        local ok, msg, r, g, b, chatTypeID, messageAccessID, lineID, event = pcall(cf.GetMessageInfo, cf, i)
        if ok and msg ~= nil then
            self:AddCommunityMessage(msg, r, g, b, chatTypeID, messageAccessID, lineID, event)
        end
    end
end

function Renderer:AddCommunityMessage(msg, r, g, b, chatTypeID, messageAccessID, lineID, event, display)
    if not IsCommunityMessage(chatTypeID, event) then return end

    local key = CommunityMessageKey(msg, chatTypeID, lineID, event)
    if key and self.communitySeen[key] then return end
    if key then
        self.communitySeen[key] = true
        local order = self.communitySeenOrder
        order[#order + 1] = key
        if #order > 1024 then
            self.communitySeen[table.remove(order, 1)] = nil
        end
    end

    local win = self.windows[communityFrame] or self:CreateWindow(communityFrame)
    if not win then return end
    if display == nil then
        local messages = Chat.Modules.Messages
        display = messages and messages.Format and messages:Format(msg) or msg
    end
    win.smf:AddMessage(display, r, g, b, chatTypeID, messageAccessID, lineID)

    local tabs = Chat.Modules.Tabs
    if tabs and tabs.NotifyMessage then tabs:NotifyMessage(communityFrame) end
end

function Renderer:OnAddMessage(cf, msg, r, g, b, chatTypeID, messageAccessID, lineID, event)
    if not Chat.IsEnabled() then return end
    if not self:ShouldManage(cf) then
        self:AddCommunityMessage(msg, r, g, b, chatTypeID, messageAccessID, lineID, event)
        return
    end
    local win = self.windows[cf] or self:CreateWindow(cf)
    if not win then return end

    self:SuppressNative(cf)
    local messages = Chat.Modules.Messages
    local display = messages and messages.Format and messages:Format(msg) or msg
    win.smf:AddMessage(display, r, g, b, chatTypeID)
    self:AddCommunityMessage(msg, r, g, b, chatTypeID, messageAccessID, lineID, event, display)

    local offset = cf.GetScrollOffset and cf:GetScrollOffset()
    if SafeOffset(offset) then win.smf:SetScrollOffset(offset) end

    local tabs = Chat.Modules.Tabs
    if tabs and tabs.NotifyMessage then tabs:NotifyMessage(cf) end
end

function Renderer:SyncScroll(cf)
    local win = self.windows[cf]
    if not win then return end
    local offset = cf.GetScrollOffset and cf:GetScrollOffset()
    if SafeOffset(offset) then win.smf:SetScrollOffset(offset) end
end

function Renderer:GetSelectedFrame()
    local tabs = Chat.Modules.Tabs
    if tabs and tabs.GetSelectedFrame then
        local selected = tabs:GetSelectedFrame()
        if selected then return selected end
    end
    local selected = GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow
        and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
    if selected then return selected end
    return SELECTED_CHAT_FRAME or _G.ChatFrame1
end

function Renderer:LayoutWindow(win)
    local layout = Chat.Modules.Layout
    if not win or not win.smf or not layout or not layout.messageHost then return end
    win.smf:ClearAllPoints()
    local inset = win.cf == _G.ChatFrame2 and (self.combatQuickInset or 0) or 0
    win.smf:SetPoint("TOPLEFT", layout.messageHost, "TOPLEFT", 0, -inset)
    win.smf:SetPoint("BOTTOMRIGHT", layout.messageHost, "BOTTOMRIGHT", 0, 0)
end

function Renderer:RefreshVisibility()
    local selected = self:GetSelectedFrame()
    self:LayoutCombatQuickFrame(selected)

    for cf, win in pairs(self.windows) do
        self:LayoutWindow(win)
        local show = Chat.IsEnabled() and cf == selected and self:ShouldManage(cf)
        win.smf:SetShown(show)
        if show then self:SuppressNative(cf) end
    end

    local tabs = Chat.Modules.Tabs
    if tabs and tabs.Refresh then tabs:Refresh() end
    local input = Chat.Modules.Input
    if input and input.Refresh then input:Refresh() end
end

function Renderer:LayoutWindows()
    local layout = Chat.Modules.Layout
    if not layout or not layout.messageHost then return end
    self:LayoutCombatQuickFrame(self:GetSelectedFrame())
    for _, win in pairs(self.windows) do
        self:LayoutWindow(win)
    end
end

function Renderer:EnsureFrame(cf)
    if not self:ShouldManage(cf) then return end
    local win = self.windows[cf] or self:CreateWindow(cf)
    if not win then return end
    self:Backfill(cf)
    if Chat.IsEnabled() then self:SuppressNative(cf) end
end

function Renderer:RebuildAll()
    for cf, win in pairs(self.windows) do
        if win.smf and win.smf.Clear then win.smf:Clear() end
        win.backfilled = cf._tomoCommunity and true or false
    end
    wipe(self.communitySeen)
    wipe(self.communitySeenOrder)
    self.communitySourcesBackfilled = setmetatable({}, { __mode = "k" })
    for cf in pairs(self.windows) do
        if not cf._tomoCommunity then self:Backfill(cf) end
    end
    for i = 1, 20 do
        self:BackfillCommunity(_G["ChatFrame" .. i])
    end
    self:RefreshVisibility()
end

function Renderer:Initialize()
    self:EnsureFrame(communityFrame)
    self:ApplySettings(Chat.IsEnabled())
end

function Renderer:ApplySettings(enabled)
    local messages = Chat.Modules.Messages
    local signature = messages and messages.SettingsSignature and messages:SettingsSignature() or ""
    local rebuild = self._messageSignature ~= nil and signature ~= self._messageSignature
    self._messageSignature = signature

    for cf, win in pairs(self.windows) do
        self:ApplyWindowSettings(win)
        if enabled and self:ShouldManage(cf) then
            self:SuppressNative(cf)
        else
            self:RestoreNative(cf)
            win.smf:Hide()
        end
    end

    if enabled then
        if rebuild then
            self:RebuildAll()
        else
            self:RefreshVisibility()
        end
    else
        self:RestoreCombatQuickFrame()
    end
end

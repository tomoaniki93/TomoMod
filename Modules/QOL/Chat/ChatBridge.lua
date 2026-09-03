-- =====================================================================
-- ChatBridge.lua — secure-safe bridge from Blizzard chat to TomoMod Chat V4
-- No FCF_* function is hooked. AddMessage/scroll post-hooks only touch
-- TomoMod-owned frames and are gated by chatV4.enabled.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end

local Bridge = {}
Chat.RegisterModule("Bridge", Bridge)

Bridge.hooked = {}
Bridge.hookedTabs = {}
Bridge.editModeHooksInstalled = false
Bridge.layoutModeHookInstalled = false

local SCROLL_METHODS = {
    "ScrollUp", "ScrollDown", "PageUp", "PageDown", "ScrollToTop", "ScrollToBottom",
}

local function WheelHandler(cf, delta)
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
end

local function RefreshSelection()
    local renderer = Chat.Modules.Renderer
    if renderer then
        local selected = renderer:GetSelectedFrame()
        if selected then renderer:EnsureFrame(selected) end
        renderer:RefreshVisibility()
    end
    local layout = Chat.Modules.Layout
    if layout then layout:RefreshGeometry() end
end

local function IsBlizzardEditModeActive()
    local manager = _G.EditModeManagerFrame
    if not manager then return false end
    if type(manager.IsEditModeActive) == "function" then
        local ok, active = pcall(manager.IsEditModeActive, manager)
        if ok then return active and true or false end
    end
    if type(manager.IsShown) == "function" then
        local ok, shown = pcall(manager.IsShown, manager)
        if ok then return shown and true or false end
    end
    return false
end

local function IsTomoModLayoutActive()
    local movers = _G.TomoMod_Movers
    return movers and type(movers.IsUnlocked) == "function" and movers.IsUnlocked() or false
end

local function RefreshInteractionState(refreshGeometry)
    local renderer = Chat.Modules.Renderer
    if renderer and renderer.SetInteractionEnabled then
        renderer:SetInteractionEnabled(not IsBlizzardEditModeActive() and not IsTomoModLayoutActive())
    end
    if refreshGeometry then
        local layout = Chat.Modules.Layout
        if layout then layout:RefreshGeometry() end
    end
end

local function InstallEditModeHooks()
    local manager = _G.EditModeManagerFrame
    if not Bridge.editModeHooksInstalled and manager then
        Bridge.editModeHooksInstalled = true
        if type(manager.EnterEditMode) == "function" then
            hooksecurefunc(manager, "EnterEditMode", function()
                RefreshInteractionState(false)
            end)
        end
        if type(manager.ExitEditMode) == "function" then
            hooksecurefunc(manager, "ExitEditMode", function()
                C_Timer.After(0, function() RefreshInteractionState(true) end)
            end)
        end
    end

    local movers = _G.TomoMod_Movers
    if not Bridge.layoutModeHookInstalled and movers and type(movers.SetUnlocked) == "function" then
        Bridge.layoutModeHookInstalled = true
        hooksecurefunc(movers, "SetUnlocked", function()
            C_Timer.After(0, function() RefreshInteractionState(true) end)
        end)
    end
end

function Bridge:HookFrame(cf)
    if not cf or self.hooked[cf] then return end
    self.hooked[cf] = true

    hooksecurefunc(cf, "AddMessage", function(frame, msg, r, g, b, chatTypeID, messageAccessID, lineID, event)
        local renderer = Chat.Modules.Renderer
        if renderer then
            renderer:OnAddMessage(frame, msg, r, g, b, chatTypeID, messageAccessID, lineID, event)
        end
    end)

    for _, method in ipairs(SCROLL_METHODS) do
        if type(cf[method]) == "function" then
            hooksecurefunc(cf, method, function(frame)
                local renderer = Chat.Modules.Renderer
                if renderer then renderer:SyncScroll(frame) end
            end)
        end
    end

    -- Retail 12.x normally has no wheel script on ordinary chat frames. Only
    -- fill the empty slot; never replace another addon/Blizzard handler.
    if not cf:GetScript("OnMouseWheel") then
        cf:SetScript("OnMouseWheel", WheelHandler)
        cf:EnableMouseWheel(true)
    end

    -- Native tabs remain the click authority. A post-click refresh only mirrors
    -- Blizzard's newly selected window into TomoMod-owned presentation frames.
    local name = cf.GetName and cf:GetName()
    local tab = name and _G[name .. "Tab"]
    if tab and not self.hookedTabs[tab] then
        self.hookedTabs[tab] = true
        tab:HookScript("OnClick", function()
            local tabs = Chat.Modules.Tabs
            if tabs and tabs.SetSelectedFrame then tabs:SetSelectedFrame(cf) end
            C_Timer.After(0, RefreshSelection)
        end)
    end
end

function Bridge:ScanFrames()
    local renderer = Chat.Modules.Renderer
    for i = 1, 20 do
        local cf = _G["ChatFrame" .. i]
        if cf then
            self:HookFrame(cf)
            if renderer then
                renderer:EnsureFrame(cf)
                renderer:BackfillCommunity(cf)
            end
        end
    end
    if renderer then renderer:RefreshVisibility() end
    local layout = Chat.Modules.Layout
    if layout then layout:RefreshGeometry() end
end

function Bridge:Initialize()
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("UPDATE_CHAT_WINDOWS")
    events:RegisterEvent("UPDATE_CHAT_COLOR")
    events:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" and addonName ~= "Blizzard_EditMode" then return end
        InstallEditModeHooks()
        C_Timer.After(0, function() Bridge:ScanFrames() end)
    end)
    self.events = events

    InstallEditModeHooks()
    RefreshInteractionState(false)

    if _G.ChatFrame1 then
        _G.ChatFrame1:HookScript("OnSizeChanged", function()
            C_Timer.After(0, function()
                local layout = Chat.Modules.Layout
                if layout then layout:RefreshGeometry() end
            end)
        end)
        _G.ChatFrame1:HookScript("OnShow", function()
            C_Timer.After(0, function() Bridge:ScanFrames() end)
        end)
    end

    self:ScanFrames()
    C_Timer.After(0.5, function() Bridge:ScanFrames() end)
end

function Bridge:ApplySettings(enabled)
    local renderer = Chat.Modules.Renderer
    if enabled then
        self:ScanFrames()
    elseif renderer then
        renderer:ApplySettings(false)
    end
end

-- =====================================================================
-- ChatInput.lua — skins the native Blizzard edit boxes without replacing them
-- Sending chat remains entirely Blizzard-owned.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end

local Input = {}
Chat.RegisterModule("Input", Input)

Input.boxes = {}

local function SelectedFrame()
    local renderer = Chat.Modules.Renderer
    if renderer and renderer.GetSelectedFrame then
        local selected = renderer:GetSelectedFrame()
        if selected then return selected end
    end
    local selected = GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
    return selected or SELECTED_CHAT_FRAME or _G.ChatFrame1
end

local function EditBoxFor(cf)
    if cf and cf._tomoCommunity then cf = _G.ChatFrame1 end
    local name = cf and cf.GetName and cf:GetName()
    return name and _G[name .. "EditBox"]
end

local function SuppressEditBoxArt(eb, state)
    local name = eb and eb.GetName and eb:GetName()
    if not name then return end
    state.native = state.native or {}
    local suffixes = { "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }
    for _, suffix in ipairs(suffixes) do
        local tex = _G[name .. suffix]
        if tex and tex.SetAlpha then
            if state.native[tex] == nil then state.native[tex] = tex:GetAlpha() end
            tex:SetAlpha(0)
        end
    end
end

local function RestoreEditBoxArt(state)
    if not state.native then return end
    for tex, alpha in pairs(state.native) do
        if tex and tex.SetAlpha then tex:SetAlpha(alpha or 1) end
    end
end

function Input:EnsureBox(eb)
    if not eb then return end
    local state = self.boxes[eb]
    if state then return state end

    state = {}
    self.boxes[eb] = state
    SuppressEditBoxArt(eb, state)

    if not state.hooked then
        state.hooked = true
        eb:HookScript("OnShow", function() C_Timer.After(0, function() Input:Refresh() end) end)
        eb:HookScript("OnHide", function() C_Timer.After(0, function() Input:Refresh() end) end)
    end

    return state
end

function Input:Refresh()
    local layout = Chat.Modules.Layout
    if not layout or not layout.inputHost then return end
    if not Chat.IsEnabled() then
        layout.inputHost:Hide()
        return
    end

    local cf = SelectedFrame()
    local eb = EditBoxFor(cf)
    if not eb then
        layout.inputHost:Show()
        return
    end

    local state = self:EnsureBox(eb)
    SuppressEditBoxArt(eb, state)

    local a = Chat.GetDB().appearance
    if eb.SetFont then eb:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", a.fontSize or 13, "") end

    -- The background is owned by TomoMod, but the edit box itself stays exactly
    -- where Blizzard placed it. ChatLayout's default geometry already follows
    -- the normal bottom-edit-box placement and this refresh only toggles art.
    layout.inputHost:SetShown(true)
end

function Input:Initialize()
    for i = 1, 20 do
        self:EnsureBox(_G["ChatFrame" .. i .. "EditBox"])
    end
    self:Refresh()
end

function Input:ApplySettings(enabled)
    local layout = Chat.Modules.Layout
    if enabled then
        self:Refresh()
    else
        for _, state in pairs(self.boxes) do RestoreEditBoxArt(state) end
        if layout and layout.inputHost then layout.inputHost:Hide() end
    end
end

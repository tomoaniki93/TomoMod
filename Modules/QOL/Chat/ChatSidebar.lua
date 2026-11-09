-- =====================================================================
-- ChatSidebar.lua — TomoMod Chat V4 sidebar
-- Friends / Guild / Player Status / Voice / Mute / Deafen / Copy /
-- Loot Browser / TomoMod Settings / Scroll Bottom.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end
local L = TomoMod_L

local Sidebar = {}
Chat.RegisterModule("Sidebar", Sidebar)

Sidebar.buttons = {}
Sidebar.nativeAlpha = {}

local TEAL_R, TEAL_G, TEAL_B = 0.20, 0.82, 0.60
local RED_R, RED_G, RED_B = 0.95, 0.28, 0.28
local YELLOW_R, YELLOW_G, YELLOW_B = 1.00, 0.78, 0.20
local GREEN_R, GREEN_G, GREEN_B = 0.42, 0.96, 0.58
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

-- Sidebar icon assets. Every visual lives in its own 64x64 transparent TGA
-- so the artwork can be replaced without touching this Lua file.
local SIDEBAR_TEX = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Chat\\Sidebar\\"
local ICON_TEXTURES = {
    friends = SIDEBAR_TEX .. "friends.tga",
    guild = SIDEBAR_TEX .. "guild.tga",
    playerStatus = {
        ONLINE = SIDEBAR_TEX .. "status_online.tga",
        AFK = SIDEBAR_TEX .. "status_afk.tga",
        DND = SIDEBAR_TEX .. "status_dnd.tga",
    },
    voice = SIDEBAR_TEX .. "voice.tga",
    mute = {
        inactive = SIDEBAR_TEX .. "mute.tga",
        active = SIDEBAR_TEX .. "mute_active.tga",
    },
    deafen = {
        inactive = SIDEBAR_TEX .. "deafen.tga",
        active = SIDEBAR_TEX .. "deafen_active.tga",
    },
    copy = SIDEBAR_TEX .. "copy.tga",
    loot = SIDEBAR_TEX .. "loot.tga",
    settings = SIDEBAR_TEX .. "settings.tga",
    scroll = SIDEBAR_TEX .. "scroll.tga",
}

local NATIVE_CHAT_CONTROLS = {
    "ChatFrameMenuButton",
    "ChatFrameChannelButton",
    "ChatFrameToggleVoiceMuteButton",
    "ChatFrameToggleVoiceDeafenButton",
    "QuickJoinToastButton",
}

local STATIC_BUTTONS = {
    friends = true,
    guild = true,
    voice = true,
    copy = true,
    loot = true,
    settings = true,
    scroll = true,
}

local function SetNativeControlsSuppressed(suppressed)
    for _, name in ipairs(NATIVE_CHAT_CONTROLS) do
        local control = _G[name]
        if control and control.SetAlpha then
            if Sidebar.nativeAlpha[control] == nil then
                Sidebar.nativeAlpha[control] = control:GetAlpha()
            end
            control:SetAlpha(suppressed and 0 or (Sidebar.nativeAlpha[control] or 1))
        end
    end
end

local function PlayClick()
    if PlaySound then
        PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
    end
end

local function Localize(key, fallback)
    local value = L and L[key]
    if type(value) == "string" and value ~= key then return value end
    return fallback or key
end

local function SetTooltip(button, title, text)
    button:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, Chat.GetDB().sidebar.side == "RIGHT" and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if text and text ~= "" then
            GameTooltip:AddLine(text, 0.72, 0.76, 0.78, true)
        end
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function ButtonVisualState(button, mode)
    mode = mode or "default"
    if mode == "active" then
        button:SetBackdropColor(0.08, 0.11, 0.12, 0.94)
        button:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, 0.72)
        button.accent:SetColorTexture(TEAL_R, TEAL_G, TEAL_B, 1)
        button.accent:Show()
    elseif mode == "danger" then
        button:SetBackdropColor(0.11, 0.07, 0.07, 0.94)
        button:SetBackdropBorderColor(RED_R, RED_G, RED_B, 0.72)
        button.accent:SetColorTexture(RED_R, RED_G, RED_B, 1)
        button.accent:Show()
    elseif mode == "warning" then
        button:SetBackdropColor(0.11, 0.095, 0.05, 0.94)
        button:SetBackdropBorderColor(YELLOW_R, YELLOW_G, YELLOW_B, 0.72)
        button.accent:SetColorTexture(YELLOW_R, YELLOW_G, YELLOW_B, 1)
        button.accent:Show()
    else
        button:SetBackdropColor(0.055, 0.07, 0.075, 0.84)
        button:SetBackdropBorderColor(1, 1, 1, 0.10)
        button.accent:SetColorTexture(TEAL_R, TEAL_G, TEAL_B, 0.75)
        button.accent:Hide()
    end
end

local function CreateButton(parent, key)
    local b = CreateFrame("Button", "TomoMod_ChatV4_" .. key, parent, "BackdropTemplate")
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })

    local shadow = b:CreateTexture(nil, "BACKGROUND")
    shadow:SetTexture(WHITE)
    shadow:SetPoint("TOPLEFT", 1, -1)
    shadow:SetPoint("BOTTOMRIGHT", -1, 1)
    shadow:SetColorTexture(0, 0, 0, 0.28)
    b.shadow = shadow

    local gloss = b:CreateTexture(nil, "BORDER")
    gloss:SetTexture(WHITE)
    gloss:SetPoint("TOPLEFT", 1, -1)
    gloss:SetPoint("TOPRIGHT", -1, -1)
    gloss:SetHeight(7)
    gloss:SetColorTexture(1, 1, 1, 0.05)
    b.gloss = gloss

    local accent = b:CreateTexture(nil, "BORDER")
    accent:SetTexture(WHITE)
    accent:SetPoint("TOPLEFT", 2, -2)
    accent:SetPoint("TOPRIGHT", -2, -2)
    accent:SetHeight(2)
    accent:Hide()
    b.accent = accent
    ButtonVisualState(b, "default")

    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetTexture(WHITE)
    hover:SetPoint("TOPLEFT", 1, -1)
    hover:SetPoint("BOTTOMRIGHT", -1, 1)
    hover:SetColorTexture(1, 1, 1, 0.05)
    hover:Hide()
    b.hover = hover

    local iconHost = CreateFrame("Frame", nil, b)
    iconHost:SetPoint("TOPLEFT", 4, -4)
    iconHost:SetPoint("BOTTOMRIGHT", -4, 4)
    b.iconHost = iconHost

    local icon = iconHost:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(iconHost)
    icon:SetTexCoord(0, 1, 0, 1)
    b.icon = icon

    local count = b:CreateFontString(nil, "OVERLAY")
    count:SetFont(FONT, 10, "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", -2, 3)
    count:SetJustifyH("RIGHT")
    count:SetTextColor(TEAL_R, TEAL_G, TEAL_B, 1)
    count:Hide()
    b.count = count

    local countShadow = b:CreateTexture(nil, "ARTWORK")
    countShadow:SetTexture(WHITE)
    countShadow:SetPoint("BOTTOMRIGHT", -1, 2)
    countShadow:SetSize(12, 8)
    countShadow:SetColorTexture(0.02, 0.03, 0.035, 0.85)
    countShadow:Hide()
    b.countShadow = countShadow

    b:SetScript("OnEnter", function(self)
        self.hover:Show()
        if not self._stateLocked then
            self:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, 0.58)
        end
    end)
    b:HookScript("OnLeave", function(self)
        self.hover:Hide()
        if self._stateMode then
            ButtonVisualState(self, self._stateMode)
        else
            ButtonVisualState(self, "default")
        end
    end)
    b:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.03, 0.045, 0.05, 0.96)
    end)
    b:HookScript("OnMouseUp", function(self)
        if self._stateMode then
            ButtonVisualState(self, self._stateMode)
        else
            ButtonVisualState(self, "default")
        end
        if self:IsMouseOver() and not self._stateLocked then
            self:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, 0.58)
        end
    end)

    Sidebar.buttons[key] = b
    return b
end

local function RenderButtonIcon(button, key, state)
    if not (button and button.icon) then return end

    local texture = ICON_TEXTURES[key]
    if key == "playerStatus" then
        local status = type(state) == "string" and state or "ONLINE"
        texture = ICON_TEXTURES.playerStatus[status] or ICON_TEXTURES.playerStatus.ONLINE
    elseif key == "mute" then
        texture = state and ICON_TEXTURES.mute.active or ICON_TEXTURES.mute.inactive
    elseif key == "deafen" then
        texture = state and ICON_TEXTURES.deafen.active or ICON_TEXTURES.deafen.inactive
    end

    button.icon:SetTexture(texture)
end

local function FriendCount()
    local wowOnline = C_FriendList and C_FriendList.GetNumOnlineFriends and C_FriendList.GetNumOnlineFriends() or 0
    local bnetOnline = 0
    if BNGetNumFriends then
        local _, online = BNGetNumFriends()
        if type(online) == "number" then bnetOnline = online end
    end
    return (wowOnline or 0) + bnetOnline
end

local function GuildCount()
    if not IsInGuild or not IsInGuild() then return 0 end
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    end
    local _, online = GetNumGuildMembers()
    return online or 0
end

local function PlayerStatus()
    if BNGetInfo then
        local _, _, _, _, afk, dnd = BNGetInfo()
        if dnd then return "DND" end
        if afk then return "AFK" end
    end
    return "ONLINE"
end

local function SendStatus(target)
    local current = PlayerStatus()
    if target == current then return end

    if current == "AFK" and target ~= "AFK" then SendChatMessage("", "AFK") end
    if current == "DND" and target ~= "DND" then SendChatMessage("", "DND") end
    if target == "AFK" then SendChatMessage("", "AFK") end
    if target == "DND" then SendChatMessage("", "DND") end
    C_Timer.After(0.15, function()
        Sidebar:RefreshStatus()
    end)
end

local function BuildStatusMenu(owner)
    if Sidebar.statusMenu then return Sidebar.statusMenu end
    local menu = CreateFrame("Frame", "TomoMod_ChatV4StatusMenu", UIParent, "BackdropTemplate")
    menu:SetSize(136, 74)
    menu:SetFrameStrata("DIALOG")
    menu:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    menu:SetBackdropColor(0.025, 0.045, 0.05, 0.98)
    menu:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, 0.45)
    menu:Hide()
    Sidebar.statusMenu = menu

    local rows = {
        { Localize("chat_v4_status_online", "Online"), "ONLINE", GREEN_R, GREEN_G, GREEN_B },
        { Localize("chat_v4_status_afk", "AFK"), "AFK", YELLOW_R, YELLOW_G, YELLOW_B },
        { Localize("chat_v4_status_dnd", "DND"), "DND", RED_R, RED_G, RED_B },
    }
    for i, row in ipairs(rows) do
        local b = CreateFrame("Button", nil, menu)
        b:SetSize(132, 22)
        b:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 23)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        local dot = b:CreateTexture(nil, "OVERLAY")
        dot:SetTexture(WHITE)
        dot:SetSize(8, 8)
        dot:SetPoint("LEFT", 8, 0)
        dot:SetColorTexture(row[3], row[4], row[5], 1)
        local t = b:CreateFontString(nil, "OVERLAY")
        t:SetFont(FONT, 11, "OUTLINE")
        t:SetPoint("LEFT", 20, 0)
        t:SetText(row[1])
        t:SetTextColor(1, 1, 1, 1)
        b:SetScript("OnClick", function()
            PlayClick()
            SendStatus(row[2])
            menu:Hide()
        end)
    end
    return menu
end

local function OpenTomoModSettings()
    if TomoMod_Config and TomoMod_Config.Toggle then
        TomoMod_Config.Toggle()
    elseif SlashCmdList and SlashCmdList["TOMOMOD"] then
        SlashCmdList["TOMOMOD"]("config")
    end
end

local function BuildSettingsMenu()
    if Sidebar.settingsMenu then return Sidebar.settingsMenu end

    local menu = CreateFrame("Frame", "TomoMod_ChatV4SettingsMenu", UIParent, "BackdropTemplate")
    menu:SetSize(204, 50)
    menu:SetFrameStrata("DIALOG")
    menu:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    menu:SetBackdropColor(0.025, 0.045, 0.05, 0.98)
    menu:SetBackdropBorderColor(TEAL_R, TEAL_G, TEAL_B, 0.45)
    menu:Hide()
    Sidebar.settingsMenu = menu

    local rows = {
        {
            Localize("chat_v4_settings_open", "Open TomoMod settings"),
            OpenTomoModSettings,
            TEAL_R, TEAL_G, TEAL_B,
        },
        {
            Localize("chat_v4_settings_reload", "Reload interface"),
            function() ReloadUI() end,
            YELLOW_R, YELLOW_G, YELLOW_B,
        },
    }

    for i, row in ipairs(rows) do
        local label, action = row[1], row[2]
        local b = CreateFrame("Button", nil, menu)
        b:SetSize(200, 22)
        b:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 23)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        local dot = b:CreateTexture(nil, "OVERLAY")
        dot:SetTexture(WHITE)
        dot:SetSize(8, 8)
        dot:SetPoint("LEFT", 8, 0)
        dot:SetColorTexture(row[3], row[4], row[5], 1)

        local text = b:CreateFontString(nil, "OVERLAY")
        text:SetFont(FONT, 11, "OUTLINE")
        text:SetPoint("LEFT", 22, 0)
        text:SetPoint("RIGHT", -6, 0)
        text:SetJustifyH("LEFT")
        text:SetText(label)
        text:SetTextColor(1, 1, 1, 1)

        b:SetScript("OnClick", function()
            PlayClick()
            menu:Hide()
            action()
        end)
    end

    return menu
end

function Sidebar:RefreshSocialCounts()
    local friends = self.buttons.friends
    if friends then
        local count = FriendCount()
        friends.count:SetText(count)
        friends.count:SetShown(count > 0)
        friends.countShadow:SetShown(count > 0)
    end
    local guild = self.buttons.guild
    if guild then
        local online = GuildCount()
        local shown = IsInGuild and IsInGuild()
        guild.count:SetText(online)
        guild.count:SetShown(shown)
        guild.countShadow:SetShown(shown)
    end
end

function Sidebar:RefreshStatus()
    local b = self.buttons.playerStatus
    if b then
        local status = PlayerStatus()
        RenderButtonIcon(b, "playerStatus", status)
        if status == "AFK" then
            b._stateMode = "warning"
            b._stateLocked = true
            ButtonVisualState(b, "warning")
        elseif status == "DND" then
            b._stateMode = "danger"
            b._stateLocked = true
            ButtonVisualState(b, "danger")
        else
            b._stateMode = "active"
            b._stateLocked = true
            ButtonVisualState(b, "active")
        end
    end

    local mute = self.buttons.mute
    if mute then
        local muted = C_VoiceChat and C_VoiceChat.IsMuted and C_VoiceChat.IsMuted() or false
        RenderButtonIcon(mute, "mute", muted)
        mute._stateMode = muted and "danger" or nil
        mute._stateLocked = muted and true or false
        ButtonVisualState(mute, muted and "danger" or "default")
    end

    local deafen = self.buttons.deafen
    if deafen then
        local deaf = C_VoiceChat and C_VoiceChat.IsDeafened and C_VoiceChat.IsDeafened() or false
        RenderButtonIcon(deafen, "deafen", deaf)
        deafen._stateMode = deaf and "danger" or nil
        deafen._stateLocked = deaf and true or false
        ButtonVisualState(deafen, deaf and "danger" or "default")
    end
end

function Sidebar:RefreshStaticIcons()
    for key in pairs(STATIC_BUTTONS) do
        local b = self.buttons[key]
        if b then
            RenderButtonIcon(b, key)
        end
    end
end

function Sidebar:BuildButtons()
    if self._built then return end
    self._built = true
    local parent = Chat.Modules.Layout.sidebarHost

    local friends = CreateButton(parent, "friends")
    SetTooltip(friends, Localize("chat_v4_btn_friends", "Friends"), Localize("chat_v4_tip_friends", "Open Blizzard Social / Friends."))
    friends:SetScript("OnClick", function()
        PlayClick()
        if ToggleFriendsFrame then ToggleFriendsFrame(1) end
    end)

    local guild = CreateButton(parent, "guild")
    SetTooltip(guild, Localize("chat_v4_btn_guild", "Guild"), Localize("chat_v4_tip_guild", "Open the guild / communities panel."))
    guild:SetScript("OnClick", function()
        PlayClick()
        if ToggleGuildFrame then
            ToggleGuildFrame()
        elseif ToggleCommunitiesFrame then
            ToggleCommunitiesFrame()
        end
    end)

    local status = CreateButton(parent, "playerStatus")
    SetTooltip(status, Localize("chat_v4_btn_status", "Player Status"), Localize("chat_v4_tip_status", "Choose Online, AFK or DND."))
    status:SetScript("OnClick", function(self)
        PlayClick()
        GameTooltip:Hide()
        if Sidebar.settingsMenu then Sidebar.settingsMenu:Hide() end
        local menu = BuildStatusMenu(self)
        menu:ClearAllPoints()
        if Chat.GetDB().sidebar.side == "RIGHT" then
            menu:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0)
        else
            menu:SetPoint("TOPLEFT", self, "TOPRIGHT", 5, 0)
        end
        menu:SetShown(not menu:IsShown())
    end)

    local voice = CreateButton(parent, "voice")
    SetTooltip(voice, Localize("chat_v4_btn_voice", "Voice / Channels"), Localize("chat_v4_tip_voice", "Open Blizzard chat channels and voice controls."))
    voice:SetScript("OnClick", function()
        PlayClick()
        if _G.ChatFrameChannelButton and _G.ChatFrameChannelButton.Click then
            _G.ChatFrameChannelButton:Click()
        end
    end)

    local mute = CreateButton(parent, "mute")
    SetTooltip(mute, Localize("chat_v4_btn_mute", "Mute Microphone"), Localize("chat_v4_tip_mute", "Toggle your voice-chat microphone."))
    mute:SetScript("OnClick", function()
        PlayClick()
        if C_VoiceChat and C_VoiceChat.ToggleMuted then C_VoiceChat.ToggleMuted() end
        C_Timer.After(0, function() Sidebar:RefreshStatus() end)
    end)

    local deafen = CreateButton(parent, "deafen")
    SetTooltip(deafen, Localize("chat_v4_btn_deafen", "Deafen"), Localize("chat_v4_tip_deafen", "Toggle voice-chat deafen."))
    deafen:SetScript("OnClick", function()
        PlayClick()
        if C_VoiceChat and C_VoiceChat.ToggleDeafened then C_VoiceChat.ToggleDeafened() end
        C_Timer.After(0, function() Sidebar:RefreshStatus() end)
    end)


    local copy = CreateButton(parent, "copy")
    SetTooltip(copy, Localize("chat_v4_btn_copy", "Copy Chat"), Localize("chat_v4_tip_copy", "Open the TomoMod copy window for the selected tab."))
    copy:SetScript("OnClick", function()
        PlayClick()
        if Chat.Modules.Copy then Chat.Modules.Copy:Toggle() end
    end)

    local loot = CreateButton(parent, "loot")
    SetTooltip(loot, Localize("chat_v4_btn_loot", "Loot Browser"), Localize("chat_v4_tip_loot", "Open TomoMod Loot Browser."))
    loot:SetScript("OnClick", function()
        PlayClick()
        if TomoMod_Loots and TomoMod_Loots.Toggle then
            TomoMod_Loots:Toggle()
        elseif SlashCmdList and SlashCmdList["TOMOMOD"] then
            SlashCmdList["TOMOMOD"]("loot")
        end
    end)

    local settings = CreateButton(parent, "settings")
    SetTooltip(settings, Localize("chat_v4_btn_settings", "TomoMod Settings"), Localize("chat_v4_tip_settings", "Open TomoMod settings or reload the interface."))
    settings:SetScript("OnClick", function(self)
        PlayClick()
        GameTooltip:Hide()
        if Sidebar.statusMenu then Sidebar.statusMenu:Hide() end

        local menu = BuildSettingsMenu()
        menu:ClearAllPoints()
        if Chat.GetDB().sidebar.side == "RIGHT" then
            menu:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0)
        else
            menu:SetPoint("TOPLEFT", self, "TOPRIGHT", 5, 0)
        end
        menu:SetShown(not menu:IsShown())
    end)

    local scroll = CreateButton(parent, "scroll")
    SetTooltip(scroll, Localize("chat_v4_btn_scroll", "Scroll to Bottom"), Localize("chat_v4_tip_scroll", "Return to the newest chat message."))
    scroll:SetScript("OnClick", function()
        PlayClick()
        local cf = Chat.Modules.Renderer and Chat.Modules.Renderer:GetSelectedFrame()
        if cf and cf.ScrollToBottom then cf:ScrollToBottom() end
    end)

    self:RefreshStaticIcons()
    self:RefreshSocialCounts()
    self:RefreshStatus()
end

local GROUP_BREAK_BEFORE = {
    voice = true,
    copy = true,
    loot = true,
    scroll = true,
}

function Sidebar:LayoutButtons()
    if not self._built then return end
    local db = Chat.GetDB().sidebar
    local parent = Chat.Modules.Layout.sidebarHost
    if not parent then return end

    local enabledMap = db.buttons or {}
    local order = db.order or {}
    local iconSize = db.iconSize or 20
    local spacing = db.spacing or 2
    local y = -6

    local scrollButton = self.buttons.scroll
    local scrollSize = iconSize
    if scrollButton then
        scrollButton:SetSize(scrollSize, scrollSize)
        scrollButton:ClearAllPoints()
        scrollButton:SetPoint("BOTTOM", parent, "BOTTOM", 0, 6)
        scrollButton:SetShown(enabledMap.scroll ~= false and Chat.IsEnabled())
    end

    for _, key in ipairs(order) do
        local b = self.buttons[key]
        if b and key ~= "scroll" then
            local shown = enabledMap[key] ~= false and Chat.IsEnabled()
            b:SetShown(shown)
            if shown then
                if GROUP_BREAK_BEFORE[key] then y = y - 5 end
                b:SetSize(iconSize, iconSize)
                b:ClearAllPoints()
                b:SetPoint("TOP", parent, "TOP", 0, y)
                y = y - iconSize - spacing
            end
        end
    end

    self:RefreshStaticIcons()
    self:RefreshStatus()
    self:RefreshSocialCounts()
end

function Sidebar:Initialize()
    self:BuildButtons()
    self:LayoutButtons()

    local events = CreateFrame("Frame")
    events:RegisterEvent("FRIENDLIST_UPDATE")
    events:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
    events:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
    events:RegisterEvent("BN_INFO_CHANGED")
    events:RegisterEvent("PLAYER_GUILD_UPDATE")
    events:RegisterEvent("GUILD_ROSTER_UPDATE")
    events:RegisterEvent("PLAYER_FLAGS_CHANGED")
    events:RegisterEvent("VOICE_CHAT_MUTED_CHANGED")
    events:RegisterEvent("VOICE_CHAT_DEAFENED_CHANGED")
    events:SetScript("OnEvent", function(_, event)
        if event == "FRIENDLIST_UPDATE"
            or event:find("BN_FRIEND", 1, true)
            or event == "PLAYER_GUILD_UPDATE"
            or event == "GUILD_ROSTER_UPDATE" then
            Sidebar:RefreshSocialCounts()
        end
        Sidebar:RefreshStatus()
    end)
    self.events = events
end

function Sidebar:ApplySettings(enabled)
    local parent = Chat.Modules.Layout and Chat.Modules.Layout.sidebarHost
    if parent then parent:SetShown(enabled) end
    SetNativeControlsSuppressed(enabled)
    if enabled then
        self:RefreshStaticIcons()
        self:RefreshSocialCounts()
        self:RefreshStatus()
        self:LayoutButtons()
    else
        if self.statusMenu then self.statusMenu:Hide() end
        if self.settingsMenu then self.settingsMenu:Hide() end
    end
end

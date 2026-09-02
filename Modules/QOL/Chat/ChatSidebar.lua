-- =====================================================================
-- ChatSidebar.lua — TomoMod Chat V4 sidebar
-- Friends / Guild / Player Status / Voice / Mute / Deafen / Emotes /
-- Copy / Loot Browser / TomoMod Settings / Scroll Bottom.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end

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
    b.iconRegions = {}

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

local function WipeIcon(button)
    for i = 1, #button.iconRegions do
        local region = button.iconRegions[i]
        if region then
            region:Hide()
            if region.SetParent then
                region:SetParent(nil)
            end
        end
    end
    wipe(button.iconRegions)
end

local function AddPiece(button, layer, w, h, x, y, r, g, b, a, rotation)
    local tex = button.iconHost:CreateTexture(nil, layer or "ARTWORK")
    tex:SetTexture(WHITE)
    tex:SetSize(w, h)
    tex:SetPoint("CENTER", button.iconHost, "CENTER", x or 0, y or 0)
    tex:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    if rotation then tex:SetRotation(rotation) end
    button.iconRegions[#button.iconRegions + 1] = tex
    return tex
end

local function AddOutlineRect(button, x, y, w, h, t, r, g, b, a)
    AddPiece(button, "ARTWORK", w, t, x, y + ((h - t) / 2), r, g, b, a)
    AddPiece(button, "ARTWORK", w, t, x, y - ((h - t) / 2), r, g, b, a)
    AddPiece(button, "ARTWORK", t, h, x - ((w - t) / 2), y, r, g, b, a)
    AddPiece(button, "ARTWORK", t, h, x + ((w - t) / 2), y, r, g, b, a)
end

local function AddChevron(button, x, y, size, r, g, b)
    AddPiece(button, "ARTWORK", size, 2, x - (size * 0.22), y + 1, r, g, b, 1, math.rad(45))
    AddPiece(button, "ARTWORK", size, 2, x + (size * 0.22), y + 1, r, g, b, 1, math.rad(-45))
end

local function IconScale(button)
    local w = button:GetWidth() or 20
    return math.max(12, math.floor(w - 8))
end

local function DrawFriends(button)
    local s = IconScale(button)
    local unit = math.max(1, math.floor(s / 12))
    local head = unit * 2 + 1
    local bodyW = unit * 3 + 1
    local bodyH = unit * 2 + 1

    AddPiece(button, "ARTWORK", head, head, -3, 4, 1, 1, 1, 1)
    AddPiece(button, "ARTWORK", head, head, 3, 2, 1, 1, 1, 0.86)
    AddPiece(button, "ARTWORK", bodyW, bodyH, -3, -2, 1, 1, 1, 1)
    AddPiece(button, "ARTWORK", bodyW, bodyH, 3, -4, 1, 1, 1, 0.86)
end

local function DrawGuild(button)
    local poleR, poleG, poleB = 0.92, 0.94, 0.98
    AddPiece(button, "ARTWORK", 2, 13, -5, 0, poleR, poleG, poleB, 1)
    AddPiece(button, "ARTWORK", 9, 2, 0, 5, 0.98, 0.98, 0.98, 1)
    AddPiece(button, "ARTWORK", 9, 2, -1, 2, 0.98, 0.98, 0.98, 1)
    AddPiece(button, "ARTWORK", 5, 2, -2, -1, 0.98, 0.98, 0.98, 1)
    AddPiece(button, "ARTWORK", 3, 2, 2, 0, 0.98, 0.98, 0.98, 1, math.rad(-35))
end

local function DrawPlayerStatus(button, mode)
    local r, g, b = GREEN_R, GREEN_G, GREEN_B
    if mode == "AFK" then
        r, g, b = YELLOW_R, YELLOW_G, YELLOW_B
    elseif mode == "DND" then
        r, g, b = RED_R, RED_G, RED_B
    end
    AddOutlineRect(button, 0, 0, 12, 12, 2, 0.14, 0.18, 0.19, 1)
    AddPiece(button, "ARTWORK", 6, 6, 0, 0, r, g, b, 1)
end

local function DrawVoice(button)
    AddPiece(button, "ARTWORK", 4, 7, -5, 0, 1, 1, 1, 1)
    AddPiece(button, "ARTWORK", 6, 2, -2, 0, 1, 1, 1, 1, math.rad(30))
    AddPiece(button, "ARTWORK", 6, 2, -2, 0, 1, 1, 1, 1, math.rad(-30))
    AddPiece(button, "ARTWORK", 2, 4, 5, 0, TEAL_R, TEAL_G, TEAL_B, 1)
    AddPiece(button, "ARTWORK", 2, 7, 8, 0, TEAL_R, TEAL_G, TEAL_B, 0.85)
end

local function DrawMute(button, active)
    local baseR, baseG, baseB = 0.96, 0.97, 0.99
    local slashR, slashG, slashB = active and RED_R or TEAL_R, active and RED_G or TEAL_G, active and RED_B or TEAL_B

    AddOutlineRect(button, 0, 3, 7, 8, 2, baseR, baseG, baseB, 1)
    AddPiece(button, "ARTWORK", 2, 6, 0, -2, baseR, baseG, baseB, 1)
    AddPiece(button, "ARTWORK", 8, 2, 0, -5, baseR, baseG, baseB, 1)
    AddPiece(button, "ARTWORK", 14, 2, 0, 0, slashR, slashG, slashB, 1, math.rad(-45))
end

local function DrawDeafen(button, active)
    local baseR, baseG, baseB = 0.96, 0.97, 0.99
    local slashR, slashG, slashB = active and RED_R or TEAL_R, active and RED_G or TEAL_G, active and RED_B or TEAL_B

    AddPiece(button, "ARTWORK", 10, 2, 0, 5, baseR, baseG, baseB, 1)
    AddPiece(button, "ARTWORK", 2, 7, -5, 1, baseR, baseG, baseB, 1)
    AddPiece(button, "ARTWORK", 2, 7, 5, 1, baseR, baseG, baseB, 1)
    AddPiece(button, "ARTWORK", 4, 2, -3, -3, baseR, baseG, baseB, 1)
    AddPiece(button, "ARTWORK", 4, 2, 3, -3, baseR, baseG, baseB, 1)
    AddPiece(button, "ARTWORK", 14, 2, 0, 0, slashR, slashG, slashB, 1, math.rad(-45))
end

local function DrawCopy(button)
    AddOutlineRect(button, 2, -1, 9, 11, 2, YELLOW_R, YELLOW_G, YELLOW_B, 1)
    AddOutlineRect(button, -2, 2, 9, 11, 2, GREEN_R, GREEN_G, GREEN_B, 1)
    AddPiece(button, "ARTWORK", 5, 1, 2, 2, YELLOW_R, YELLOW_G, YELLOW_B, 1)
    AddPiece(button, "ARTWORK", 5, 1, -2, 5, GREEN_R, GREEN_G, GREEN_B, 1)
end

local function DrawLoot(button)
    local pageR, pageG, pageB = 0.96, 0.97, 0.99
    AddOutlineRect(button, -4, 0, 7, 11, 2, pageR, pageG, pageB, 1)
    AddOutlineRect(button, 4, 0, 7, 11, 2, pageR, pageG, pageB, 1)
    AddPiece(button, "ARTWORK", 2, 11, 0, 0, TEAL_R, TEAL_G, TEAL_B, 1)
    AddPiece(button, "ARTWORK", 3, 1, -4, 2, pageR, pageG, pageB, 0.90)
    AddPiece(button, "ARTWORK", 3, 1, 4, 2, pageR, pageG, pageB, 0.90)
    AddPiece(button, "ARTWORK", 3, 1, -4, -1, pageR, pageG, pageB, 0.90)
    AddPiece(button, "ARTWORK", 3, 1, 4, -1, pageR, pageG, pageB, 0.90)
end

local function DrawSettings(button)
    local function cog(x, y, size, r, g, b)
        local core = math.max(3, math.floor(size * 0.42))
        local tooth = math.max(2, math.floor(size * 0.22))
        AddPiece(button, "ARTWORK", core, core, x, y, r, g, b, 1)
        AddPiece(button, "ARTWORK", core, tooth, x, y + (core / 2) + 1, r, g, b, 1)
        AddPiece(button, "ARTWORK", core, tooth, x, y - (core / 2) - 1, r, g, b, 1)
        AddPiece(button, "ARTWORK", tooth, core, x - (core / 2) - 1, y, r, g, b, 1)
        AddPiece(button, "ARTWORK", tooth, core, x + (core / 2) + 1, y, r, g, b, 1)
        AddPiece(button, "ARTWORK", tooth + 1, tooth, x - (core / 2), y + (core / 2), r, g, b, 1, math.rad(45))
        AddPiece(button, "ARTWORK", tooth + 1, tooth, x + (core / 2), y + (core / 2), r, g, b, 1, math.rad(-45))
        AddPiece(button, "ARTWORK", tooth + 1, tooth, x - (core / 2), y - (core / 2), r, g, b, 1, math.rad(-45))
        AddPiece(button, "ARTWORK", tooth + 1, tooth, x + (core / 2), y - (core / 2), r, g, b, 1, math.rad(45))
    end

    cog(-3, 2, 9, 0.95, 0.97, 0.99)
    cog(4, -3, 7, TEAL_R, TEAL_G, TEAL_B)
end

local function DrawScroll(button)
    AddChevron(button, 0, 3, 8, 0.96, 0.97, 0.99)
    AddChevron(button, 0, -2, 8, TEAL_R, TEAL_G, TEAL_B)
end

local function RenderButtonIcon(button, key, state)
    WipeIcon(button)
    if key == "friends" then
        DrawFriends(button)
    elseif key == "guild" then
        DrawGuild(button)
    elseif key == "playerStatus" then
        DrawPlayerStatus(button, state)
    elseif key == "voice" then
        DrawVoice(button)
    elseif key == "mute" then
        DrawMute(button, state)
    elseif key == "deafen" then
        DrawDeafen(button, state)
    elseif key == "copy" then
        DrawCopy(button)
    elseif key == "loot" then
        DrawLoot(button)
    elseif key == "settings" then
        DrawSettings(button)
    elseif key == "scroll" then
        DrawScroll(button)
    end
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
        { "Online", "ONLINE", GREEN_R, GREEN_G, GREEN_B },
        { "AFK", "AFK", YELLOW_R, YELLOW_G, YELLOW_B },
        { "DND", "DND", RED_R, RED_G, RED_B },
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
    SetTooltip(friends, "Friends", "Open Blizzard Social / Friends.")
    friends:SetScript("OnClick", function()
        PlayClick()
        if ToggleFriendsFrame then ToggleFriendsFrame(1) end
    end)

    local guild = CreateButton(parent, "guild")
    SetTooltip(guild, "Guild", "Open the guild / communities panel.")
    guild:SetScript("OnClick", function()
        PlayClick()
        if ToggleGuildFrame then
            ToggleGuildFrame()
        elseif ToggleCommunitiesFrame then
            ToggleCommunitiesFrame()
        end
    end)

    local status = CreateButton(parent, "playerStatus")
    SetTooltip(status, "Player Status", "Choose Online, AFK or DND.")
    status:SetScript("OnClick", function(self)
        PlayClick()
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
    SetTooltip(voice, "Voice / Channels", "Open Blizzard chat channels and voice controls.")
    voice:SetScript("OnClick", function()
        PlayClick()
        if _G.ChatFrameChannelButton and _G.ChatFrameChannelButton.Click then
            _G.ChatFrameChannelButton:Click()
        end
    end)

    local mute = CreateButton(parent, "mute")
    SetTooltip(mute, "Mute Microphone", "Toggle your voice-chat microphone.")
    mute:SetScript("OnClick", function()
        PlayClick()
        if C_VoiceChat and C_VoiceChat.ToggleMuted then C_VoiceChat.ToggleMuted() end
        C_Timer.After(0, function() Sidebar:RefreshStatus() end)
    end)

    local deafen = CreateButton(parent, "deafen")
    SetTooltip(deafen, "Deafen", "Toggle voice-chat deafen.")
    deafen:SetScript("OnClick", function()
        PlayClick()
        if C_VoiceChat and C_VoiceChat.ToggleDeafened then C_VoiceChat.ToggleDeafened() end
        C_Timer.After(0, function() Sidebar:RefreshStatus() end)
    end)


    local copy = CreateButton(parent, "copy")
    SetTooltip(copy, "Copy Chat", "Open the TomoMod copy window for the selected tab.")
    copy:SetScript("OnClick", function()
        PlayClick()
        if Chat.Modules.Copy then Chat.Modules.Copy:Toggle() end
    end)

    local loot = CreateButton(parent, "loot")
    SetTooltip(loot, "Loot Browser", "Open TomoMod Loot Browser.")
    loot:SetScript("OnClick", function()
        PlayClick()
        if TomoMod_Loots and TomoMod_Loots.Toggle then
            TomoMod_Loots:Toggle()
        elseif SlashCmdList and SlashCmdList["TOMOMOD"] then
            SlashCmdList["TOMOMOD"]("loot")
        end
    end)

    local settings = CreateButton(parent, "settings")
    SetTooltip(settings, "TomoMod", "Open the main TomoMod configuration.")
    settings:SetScript("OnClick", function()
        PlayClick()
        if TomoMod_Config and TomoMod_Config.Toggle then
            TomoMod_Config.Toggle()
        elseif SlashCmdList and SlashCmdList["TOMOMOD"] then
            SlashCmdList["TOMOMOD"]("config")
        end
    end)

    local scroll = CreateButton(parent, "scroll")
    SetTooltip(scroll, "Scroll to Bottom", "Return to the newest chat message.")
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
    elseif self.statusMenu then
        self.statusMenu:Hide()
    end
end

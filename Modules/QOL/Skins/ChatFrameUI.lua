-- =====================================
-- ChatFrameUI.lua
-- Multi-Position Chat Frame UI for TomoMod
-- Creates decorative containers at up to 4 screen corners with:
--   sidebar, window, tab bar, button bar with modifier-key switching,
--   sidebar icons (voice chat, mute, deafen, professions, shortcuts,
--   copy chat, emotes, player status), layout switching, and
--   raid frame manager reskin.
--
-- Adapted from MayronUI Chat Framework by Mayron (public domain).
-- =====================================

TomoMod_ChatFrameUI = TomoMod_ChatFrameUI or {}
local CFUI = TomoMod_ChatFrameUI

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_PATH    = "Interface\\AddOns\\TomoMod\\"
local MEDIA         = (ADDON_PATH .. "Assets\\Textures\\Chat\\"):gsub("\\", "/")
local ADDON_FONT    = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"

local L = TomoMod_L or {}

local format, pairs, ipairs, type = string.format, pairs, ipairs, type
local strlower, strtrim             = strlower, strtrim
local InCombatLockdown              = InCombatLockdown
local PlaySound                     = PlaySound
local hooksecurefunc                = hooksecurefunc
local GetNumGroupMembers            = GetNumGroupMembers
local math_rad                      = math.rad
local SOUNDKIT                      = SOUNDKIT
local CLICK_SOUND                   = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856

local ANCHOR_ORDER = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }

-- State
local chatFrames    = {}   -- [anchorName] = frameData
local sideBarIcons  = {}   -- [iconType]   = widget
local isInitialized = false
local isActive      = false

-- =====================================
-- SETTINGS
-- =====================================

local function S()  return TomoModDB and TomoModDB.chatFrameUI or {} end
local function FS(a) local s = S(); return s.chatFrames and s.chatFrames[a] or {} end

function CFUI.IsActive() return isActive end

-- =====================================
-- HELPERS
-- =====================================

local function KillElement(e)
    if not e then return end
    if e.UnregisterAllEvents then e:UnregisterAllEvents() end
    e:Hide(); e:SetAlpha(0)
    if e.SetSize then e:SetSize(0.001, 0.001) end
end

local function HasSub(s, sub) return s and sub and s:find(sub, 1, true) ~= nil end

-- =====================================
-- SIDEBAR ICON CREATORS
-- =====================================

local IconCreators = {}

-- Voice chat (wraps Blizzard widget)
function IconCreators.voiceChat()
    local btn = ChatFrameChannelButton
    if btn then sideBarIcons.voiceChat = btn end
    return btn
end

-- Deafen (Retail only, wraps Blizzard widget)
function IconCreators.deafen()
    local btn = ChatFrameToggleVoiceDeafenButton
    if btn then sideBarIcons.deafen = btn end
    return btn
end

-- Mute (Retail only, wraps Blizzard widget)
function IconCreators.mute()
    local btn = ChatFrameToggleVoiceMuteButton
    if btn then sideBarIcons.mute = btn end
    return btn
end

-- Diagnostics
function IconCreators.emotes()
    if sideBarIcons.emotes then return sideBarIcons.emotes end
    local btn = CreateFrame("Button", "TomoMod_CFUI_Emotes", UIParent)
    btn:SetNormalTexture(MEDIA .. "speechIcon")
    btn:GetNormalTexture():SetVertexColor(0.9, 0.8, 0.0)
    btn:SetHighlightAtlas("chatframe-button-highlight")
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 16, 8)
        GameTooltip:SetText("Diagnostics")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", function()
        PlaySound(CLICK_SOUND)
        ChatFrame_OpenChat("/tmdiag")
    end)
    sideBarIcons.emotes = btn
    return btn
end

-- Loot Browser (opens TomoMod_Loots panel)
function IconCreators.professions()
    if sideBarIcons.professions then return sideBarIcons.professions end
    local btn = CreateFrame("Button", "TomoMod_CFUI_Professions", UIParent)
    btn:SetNormalTexture(MEDIA .. "book")
    btn:GetNormalTexture():SetVertexColor(0.9, 0.8, 0.0)
    btn:SetHighlightAtlas("chatframe-button-highlight")
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 16, 8)
        GameTooltip:SetText("Loot Browser")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", function()
        PlaySound(CLICK_SOUND)
        if TomoMod_Loots and TomoMod_Loots.Toggle then
            TomoMod_Loots:Toggle()
        end
    end)
    sideBarIcons.professions = btn
    return btn
end

-- Shortcuts (addon slash command menu)
function IconCreators.shortcuts()
    if sideBarIcons.shortcuts then return sideBarIcons.shortcuts end
    local btn = CreateFrame("Button", "TomoMod_CFUI_Shortcuts", UIParent)
    btn:SetNormalTexture(MEDIA .. "shortcuts")
    btn:GetNormalTexture():SetVertexColor(0.9, 0.8, 0.0)
    btn:SetHighlightAtlas("chatframe-button-highlight")
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 16, 8)
        GameTooltip:SetText(L["cfui_show_shortcuts"] or "Show AddOn Shortcuts")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local menu
    btn:SetScript("OnClick", function(self)
        PlaySound(CLICK_SOUND)
        if not menu then
            menu = CreateFrame("Frame", "TomoMod_CFUI_ShortMenu", self, "BackdropTemplate")
            menu:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
            menu:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
            menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            menu:SetFrameStrata("TOOLTIP")

            local items = {
                { "TomoMod Config",    function() if SlashCmdList["TOMOMOD"] then SlashCmdList["TOMOMOD"]("config") end end },
                --{ "TomoMod Profiles",  function() if SlashCmdList["TOMOMOD"] then SlashCmdList["TOMOMOD"]("profiles") end end },
                { "Clear Chat",        function() for _, f in ipairs(CHAT_FRAMES) do local cf = _G[f]; if cf then cf:Clear() end end end },
                { "Reload UI",         ReloadUI },
            }
            -- Detect popular third-party addons
            if _G.SlashCmdList and _G.SlashCmdList.Leatrix_Plus then
                items[#items + 1] = { "Leatrix Plus", function() _G.SlashCmdList.Leatrix_Plus("") end }
            end
            if _G.Bartender4 and _G.Bartender4.ChatCommand then
                items[#items + 1] = { "Bartender4", _G.Bartender4.ChatCommand }
            end
            if _G.Details and _G.Details.OpenOptionsWindow then
                items[#items + 1] = { "Details!", _G.Details.OpenOptionsWindow }
            end

            for idx, item in ipairs(items) do
                local b = CreateFrame("Button", nil, menu)
                b:SetSize(156, 22); b:SetPoint("TOPLEFT", 2, -2 - (idx - 1) * 24)
                b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetPoint("LEFT", 6, 0); fs:SetText(item[1]); fs:SetTextColor(1, 1, 1)
                b:SetScript("OnClick", function() item[2](); menu:Hide() end)
            end
            menu:SetSize(160, #items * 24 + 4)
            menu:Hide()
        end
        menu:SetShown(not menu:IsShown())
        if menu:IsShown() then menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", self, "TOPRIGHT", 4, 0) end
    end)

    sideBarIcons.shortcuts = btn
    return btn
end

-- Copy Chat (delegates to ChatFrameSkin's copy system)
function IconCreators.copyChat()
    if sideBarIcons.copyChat then return sideBarIcons.copyChat end
    local btn = CreateFrame("Button", "TomoMod_CFUI_CopyChat", UIParent)
    btn:SetNormalTexture(MEDIA .. "copyIcon")
    btn:GetNormalTexture():SetVertexColor(0.9, 0.8, 0.0)
    btn:SetHighlightAtlas("chatframe-button-highlight")
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 16, 8)
        GameTooltip:SetText(L["cfui_copy_chat"] or "Copy Chat Text")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", function()
        PlaySound(CLICK_SOUND)
        if _G.TomoModCopyChatFrame then
            if _G.TomoModCopyChatFrame:IsShown() then
                _G.TomoModCopyChatFrame:Hide()
            else
                if TomoMod_ChatFrameSkin and TomoMod_ChatFrameSkin.CopyChatToFrame then
                    TomoMod_ChatFrameSkin.CopyChatToFrame()
                end
                _G.TomoModCopyChatFrame:Show()
            end
        end
    end)
    sideBarIcons.copyChat = btn
    return btn
end

-- Player Status (Available / AFK / DND)
function IconCreators.playerStatus()
    if sideBarIcons.playerStatus then return sideBarIcons.playerStatus end
    local btn = CreateFrame("Button", "TomoMod_CFUI_Status", UIParent)
    btn:SetHighlightAtlas("chatframe-button-highlight")

    local function Update()
        local status = FRIENDS_TEXTURE_ONLINE
        local _, _, _, _, afk, dnd = BNGetInfo()
        if afk then status = FRIENDS_TEXTURE_AFK elseif dnd then status = FRIENDS_TEXTURE_DND end
        btn:SetNormalTexture(status)
    end
    Update()
    btn:RegisterEvent("BN_INFO_CHANGED"); btn:SetScript("OnEvent", Update)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 16, 8)
        local _, _, _, _, afk, dnd = BNGetInfo()
        GameTooltip:SetText(afk and FRIENDS_LIST_AWAY or dnd and FRIENDS_LIST_BUSY or FRIENDS_LIST_AVAILABLE or "Status")
        GameTooltip:AddLine(L["cfui_click_toggle_status"] or "Click to toggle AFK", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", function() PlaySound(CLICK_SOUND); SendChatMessage("", "AFK") end)

    sideBarIcons.playerStatus = btn
    return btn
end

-- =====================================
-- SIDEBAR ICON POSITIONING (MayronUI algorithm)
-- =====================================

local ALL_ICON_TYPES = { "voiceChat", "deafen", "mute", "professions", "shortcuts", "copyChat", "emotes", "playerStatus" }

local function HideAllIcons()
    for _, t in ipairs(ALL_ICON_TYPES) do
        local icon = sideBarIcons[t]
        if icon then icon:ClearAllPoints(); icon:Hide() end
    end
end

local function PositionIcons(iconSettings, muiFrame)
    HideAllIcons()
    if not muiFrame or not muiFrame:IsShown() or not muiFrame.sidebar then return end

    local isBottom = HasSub(muiFrame.anchorName, "BOTTOM")
    local anchor, total, bottomIdx = nil, 0, 0

    for idx, value in ipairs(iconSettings) do
        if type(value) == "table" and type(value.type) == "string" and value.type ~= "none" then
            local useBottom = false
            local v = value

            if total >= 3 then
                useBottom = true
                local newI = #iconSettings - bottomIdx
                v = iconSettings[newI]
                if total == 3 then anchor = nil end
                bottomIdx = bottomIdx + 1
            end

            if v and type(v) == "table" and v.type ~= "none" then
                local skip = (v.type == "deafen" or v.type == "mute") and not ChatFrameToggleVoiceDeafenButton
                if not skip then
                    total = total + 1
                    local creator = IconCreators[v.type]
                    local icon = creator and creator()
                    if icon then
                        icon:ClearAllPoints(); icon:SetParent(muiFrame); icon:SetSize(24, 24)
                        if v.type == "voiceChat" or v.type == "deafen" or v.type == "mute" then
                            icon:DisableDrawLayer("ARTWORK")
                        end
                        if anchor then
                            local pt, rp, yo = "TOPLEFT", "BOTTOMLEFT", -2
                            if useBottom then pt, rp, yo = "BOTTOMLEFT", "TOPLEFT", 2 end
                            icon:SetPoint(pt, anchor, rp, 0, yo)
                        else
                            local pt, rp, yo = "TOPLEFT", "TOPLEFT", -14
                            if useBottom then pt, rp, yo = "BOTTOMLEFT", "BOTTOMLEFT", 14 end
                            icon:SetPoint(pt, muiFrame.sidebar, rp, 1, yo)
                        end
                        icon:Show(); anchor = icon
                    end
                end
            end
        end
    end
end

function CFUI.RefreshSideBarIcons()
    local s = S()
    local target = chatFrames[s.iconsAnchor or "TOPLEFT"]
    target = target and target.frame and target.frame:IsShown() and target.frame

    if not target then
        for _, data in pairs(chatFrames) do
            if data.frame and data.frame:IsShown() then target = data.frame; break end
        end
    end

    if target then PositionIcons(s.icons or {}, target) end
end

-- =====================================
-- BUTTON BAR (3 buttons with modifier-key switching)
-- =====================================

local function CreateButtonBar(parent, anchorName)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(135 * 3, 20)
    if HasSub(anchorName, "RIGHT") then bar:SetPoint(anchorName, -20, 0) else bar:SetPoint(anchorName, 20, 0) end

    local btns = {}
    for id = 1, 3 do
        local b = CreateFrame("Button", nil, bar)
        btns[id] = b; b:SetSize(135, 20)
        b:SetNormalFontObject("GameFontNormalSmall"); b:SetHighlightFontObject("GameFontHighlightSmall"); b:SetText("")
        if id == 1 then b:SetPoint("TOPLEFT") else b:SetPoint("LEFT", btns[id - 1], "RIGHT") end

        local tex = (id == 1 or id == 3) and (MEDIA .. "sideButton") or (MEDIA .. "middleButton")
        b:SetNormalTexture(tex); b:SetHighlightTexture(tex)

        if id == 3 then
            b:GetNormalTexture():SetTexCoord(1, 0, 0, 1)
            b:GetHighlightTexture():SetTexCoord(1, 0, 0, 1)
        end
        if HasSub(anchorName, "BOTTOM") then
            if id == 3 then
                b:GetNormalTexture():SetTexCoord(1, 0, 1, 0)
                b:GetHighlightTexture():SetTexCoord(1, 0, 1, 0)
            else
                b:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
                b:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
            end
        end

        b:SetScript("OnClick", function(self)
            if InCombatLockdown() then return end
            local label = self:GetText()
            if label and TomoMod_ChatButtonHandlers and TomoMod_ChatButtonHandlers[label] then
                TomoMod_ChatButtonHandlers[label]()
            end
        end)
    end

    return bar, btns
end

-- Update button labels based on active modifier key
local function UpdateButtonLabels(fd)
    if not fd or not fd.buttons or not fd.settings then return end
    local btnCfg = fd.settings.buttons
    if not btnCfg then return end

    for _, state in ipairs(btnCfg) do
        local match = true
        if state.key then
            if     state.key == "C" then match = IsControlKeyDown()
            elseif state.key == "S" then match = IsShiftKeyDown()
            elseif state.key == "A" then match = IsAltKeyDown()
            else   match = false end
        else
            match = not IsControlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown()
        end
        if match then
            for i = 1, 3 do if fd.buttons[i] and state[i] then fd.buttons[i]:SetText(state[i]) end end
            break
        end
    end
end

local function SetUpModifierListener(anchorName)
    local fd = chatFrames[anchorName]; if not fd then return end
    if not fd.modListener then
        fd.modListener = CreateFrame("Frame")
        fd.modListener:RegisterEvent("MODIFIER_STATE_CHANGED")
        fd.modListener:SetScript("OnEvent", function()
            local s = S()
            if s.swapInCombat or not InCombatLockdown() then UpdateButtonLabels(fd) end
        end)
    end
    UpdateButtonLabels(fd)
end

-- =====================================
-- LAYOUT BUTTON
-- =====================================

local function CreateLayoutButton(parent, anchorName)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetNormalFontObject("GameFontNormalSmall"); btn:SetHighlightFontObject("GameFontHighlightSmall")
    btn:SetText(" "); btn:GetFontString():SetPoint("CENTER", 1, 0)
    btn:SetSize(21, 120); btn:SetPoint("LEFT", parent.sidebar, "LEFT")
    btn:SetNormalTexture(MEDIA .. "layoutButton"); btn:SetHighlightTexture(MEDIA .. "layoutButton")

    if HasSub(anchorName, "RIGHT") then
        btn:SetPoint("LEFT", parent.sidebar, "LEFT", 2, 0)
        btn:GetNormalTexture():SetTexCoord(1, 0, 0, 1)
        btn:GetHighlightTexture():SetTexCoord(1, 0, 0, 1)
    end

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 8, -38)
        GameTooltip:SetText(L["cfui_layout_button"] or "TomoMod Layout")
        GameTooltip:AddDoubleLine(
            L["cfui_left_click"] or "Left Click:",
            L["cfui_switch_layout"] or "Switch Layout",
            0.047, 0.824, 0.624, 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then CFUI.SwitchLayout() end
    end)

    return btn
end

-- =====================================
-- TAB BAR
-- =====================================

local function SetUpTabBar(fd, tabCfg)
    if not tabCfg then return end
    local frame = fd.frame; local an = frame.anchorName

    if tabCfg.show then
        if not fd.tabs then
            fd.tabs = frame:CreateTexture(nil, "ARTWORK")
            fd.tabs:SetSize(358, 23); fd.tabs:SetTexture(MEDIA .. "tabs")
        end
        fd.tabs:ClearAllPoints()
        if HasSub(an, "RIGHT") then
            fd.tabs:SetPoint(an, frame.sidebar, "TOPLEFT", 0, tabCfg.yOffset or -12)
            fd.tabs:SetTexCoord(1, 0, 0, 1)
        else
            fd.tabs:SetPoint(an, frame.sidebar, "TOPRIGHT", 0, tabCfg.yOffset or -12)
        end
        fd.tabs:Show()
    elseif fd.tabs then
        fd.tabs:Hide()
    end
end

-- =====================================
-- FRAME CREATION
-- =====================================

local function CreateMUIFrame(anchorName)
    local settings = FS(anchorName)

    local f = CreateFrame("Frame", "TomoMod_MUI_" .. anchorName, UIParent)
    f:SetFrameStrata("LOW"); f:SetFrameLevel(1)
    f:SetSize(358, 310)
    f:SetPoint(anchorName, UIParent, anchorName, settings.xOffset or 2, settings.yOffset or -2)
    f.anchorName = anchorName

    f.sidebar = f:CreateTexture(nil, "ARTWORK")
    f.sidebar:SetTexture(MEDIA .. "sidebar"); f.sidebar:SetSize(24, 300)
    f.sidebar:SetPoint(anchorName, 0, -10)

    local wyo = (settings.window and settings.window.yOffset) or -37
    f.window = CreateFrame("Frame", nil, f)
    f.window:SetSize(367, 248)
    f.window:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 2, wyo)
    f.window.texture = f.window:CreateTexture(nil, "ARTWORK")
    f.window.texture:SetTexture(MEDIA .. "window"); f.window.texture:SetAllPoints(true)

    f.layoutButton = CreateLayoutButton(f, anchorName)

    local bar, btns = CreateButtonBar(f, anchorName)

    local fd = { frame = f, settings = settings, buttonsBar = bar, buttons = btns }
    chatFrames[anchorName] = fd
    return fd
end

-- =====================================
-- REPOSITIONING (mirror textures for non-TOPLEFT anchors)
-- =====================================

local function RepositionFrame(fd)
    local f  = fd.frame
    local an = f.anchorName
    local s  = fd.settings
    local wyo = (s.window and s.window.yOffset) or -37

    f:ClearAllPoints(); f.window:ClearAllPoints(); f.sidebar:ClearAllPoints(); fd.buttonsBar:ClearAllPoints()
    f:SetPoint(an, UIParent, an, s.xOffset or 2, s.yOffset or -2)

    if an == "TOPRIGHT" then
        f.sidebar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -10)
        f.window:SetPoint("TOPRIGHT", f.sidebar, "TOPLEFT", -2, wyo)
        f.window.texture:SetTexCoord(1, 0, 0, 1)
    elseif an == "BOTTOMLEFT" then
        f.sidebar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 10)
        f.window:SetPoint("BOTTOMLEFT", f.sidebar, "BOTTOMRIGHT", 2, wyo)
        f.window.texture:SetTexCoord(0, 1, 1, 0)
    elseif an == "BOTTOMRIGHT" then
        f.sidebar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 10)
        f.window:SetPoint("BOTTOMRIGHT", f.sidebar, "BOTTOMLEFT", -2, wyo)
        f.window.texture:SetTexCoord(1, 0, 1, 0)
    else -- TOPLEFT
        f.sidebar:SetPoint("TOPLEFT", 0, -10)
        f.window:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 2, wyo)
        f.window.texture:SetTexCoord(0, 1, 0, 1)
    end

    -- Sidebar flip
    if HasSub(an, "RIGHT") then
        f.sidebar:SetTexCoord(1, 0, 0, 1); fd.buttonsBar:SetPoint(an, -20, 0)
    else
        f.sidebar:SetTexCoord(0, 1, 0, 1); fd.buttonsBar:SetPoint(an, 20, 0)
    end

    -- Layout button flip
    if f.layoutButton then
        f.layoutButton:ClearAllPoints()
        if HasSub(an, "RIGHT") then
            f.layoutButton:SetPoint("LEFT", f.sidebar, "LEFT", 2, 0)
            f.layoutButton:GetNormalTexture():SetTexCoord(1, 0, 0, 1)
            f.layoutButton:GetHighlightTexture():SetTexCoord(1, 0, 0, 1)
        else
            f.layoutButton:SetPoint("LEFT", f.sidebar, "LEFT")
            f.layoutButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
            f.layoutButton:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
        end
    end

    SetUpTabBar(fd, s.tabBar or { show = true, yOffset = -12 })
end

-- =====================================
-- ENABLE / DISABLE FRAMES
-- =====================================

local function EnableFrame(anchorName)
    local fd = chatFrames[anchorName]
    if not fd then fd = CreateMUIFrame(anchorName) end

    fd.settings = FS(anchorName)
    fd.frame:Show()
    RepositionFrame(fd)

    -- TOPLEFT follows ChatFrame1 via OnUpdate
    if anchorName == "TOPLEFT" then
        fd.frame._cfw = -1; fd.frame._cfh = -1
        fd.frame:SetScript("OnUpdate", function(self)
            if not ChatFrame1 then return end
            local w, h = ChatFrame1:GetWidth(), ChatFrame1:GetHeight()
            if w == self._cfw and h == self._cfh then return end
            self._cfw = w; self._cfh = h
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", ChatFrame1, "TOPLEFT", -22, 25)
            self:SetHeight(h + 55); self:SetWidth(w + 40)
            self.sidebar:SetHeight(h + 30)
            self.window:SetSize(w + 10, h - 20)
        end)
    end

    SetUpModifierListener(anchorName)
end

local function DisableFrame(anchorName)
    local fd = chatFrames[anchorName]
    if fd and fd.frame then fd.frame:Hide() end
end

-- =====================================
-- EDIT BOX CONFIGURATION
-- =====================================

local function ConfigureEditBox()
    local eb = S().editBox or {}
    local editbox = ChatFrame1EditBox
    if not editbox then return end

    editbox:ClearAllPoints()
    local yo = eb.yOffset or -8

    if (eb.position or "BOTTOM") == "TOP" then
        editbox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT",  -3, yo)
        editbox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT",  3, yo)
    else
        editbox:SetPoint("TOPLEFT",  ChatFrame1, "BOTTOMLEFT", -3, yo)
        editbox:SetPoint("TOPRIGHT", ChatFrame1, "BOTTOMRIGHT", 3, yo)
    end

    if eb.height then editbox:SetHeight(eb.height) end
    if editbox.SetBackdropColor and eb.backdropColor then
        local c = eb.backdropColor
        editbox:SetBackdropColor(c.r or 0, c.g or 0, c.b or 0, c.a or 0.6)
    end
end

-- =====================================
-- TEXT HIGHLIGHTING (MayronUI-style: word groups with color + sound)
-- =====================================

local highlightGroups = {}

local function UpdateHighlightGroups()
    wipe(highlightGroups)
    local s = S()
    if not s.highlighted then return end
    for _, g in ipairs(s.highlighted) do
        if type(g) == "table" and g.color then highlightGroups[#highlightGroups + 1] = g end
    end
end

local HL_PATTERNS = {
    "(|Hchannel:.-|h%[.-%]|h |Hplayer:.-|h%[.-%]|h: )(.*)",
    "(|Hplayer:.-|h%[.-%]|h.-: )(.*)",
}

function CFUI.HighlightText(text)
    if #highlightGroups == 0 then return text end
    local prefix, body, ts, snd

    for _, pat in ipairs(HL_PATTERNS) do
        if CHAT_TIMESTAMP_FORMAT then ts, prefix, body = text:match("(.-)" .. pat)
        else prefix, body = text:match("^" .. pat) end

        if prefix and body then
            body = strtrim(body)
            for _, g in ipairs(highlightGroups) do
                local r, g2, b = g.color[1] or 1, g.color[2] or 1, g.color[3] or 1
                local hex = format("|cff%02x%02x%02x", r * 255, g2 * 255, b * 255)
                for _, w in ipairs(g) do
                    if type(w) == "string" then
                        local sw = g.upperCase and w or strlower(w)
                        local bl = g.upperCase and body or strlower(body)
                        local s2 = bl:find(sw, 1, true)
                        if s2 then
                            local orig = body:sub(s2, s2 + #w - 1)
                            body = body:gsub(orig:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"), hex .. orig .. "|r", 1)
                            if not snd and type(g.sound) == "number" then snd = g.sound end
                        end
                    end
                end
            end
            text = (ts or "") .. prefix .. body; break
        end
    end
    if snd then PlaySound(snd) end
    return text
end

-- =====================================
-- BNTOAST REPOSITIONING
-- =====================================

local function RepositionBNToast()
    if not ChatFrame1 or not ChatAlertFrame then return end
    local rp = ChatFrame1:GetPoint()
    ChatAlertFrame:ClearAllPoints()
    if rp and rp:find("TOP") then
        ChatAlertFrame:SetPoint("TOPLEFT", ChatFrame1, "BOTTOMLEFT", 0, -60)
    else
        if ChatFrame1Tab then ChatAlertFrame:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "TOPLEFT", 0, 10) end
    end
end

-- =====================================
-- RAID FRAME MANAGER RESKIN
-- =====================================

local raidMgrDone = false

local function SetUpRaidFrameManager()
    if raidMgrDone or not CompactRaidFrameManager then return end
    raidMgrDone = true

    CompactRaidFrameManager:DisableDrawLayer("ARTWORK")
    CompactRaidFrameManager:EnableMouse(false)
    if CompactRaidFrameManager.toggleButton then KillElement(CompactRaidFrameManager.toggleButton) end

    local function NukeTexture(w) if w then w:SetTexture(""); w.SetTexture = function() end end end
    NukeTexture(_G.CompactRaidFrameManagerDisplayFrameHeaderDelineator)
    NukeTexture(_G.CompactRaidFrameManagerDisplayFrameFilterOptionsFooterDelineator)
    if _G.CompactRaidFrameManagerDisplayFrameHeaderBackground then
        _G.CompactRaidFrameManagerDisplayFrameHeaderBackground:Hide()
        _G.CompactRaidFrameManagerDisplayFrameHeaderBackground.Show = function() end
    end

    local btn = CreateFrame("Button", "TomoMod_RaidMgrButton", UIParent)
    btn:SetSize(15, 100); btn:SetPoint("LEFT")
    btn:SetNormalTexture(MEDIA .. "sideButton")
    btn:GetNormalTexture():SetTexCoord(1, 0, 0, 1)
    btn.icon = btn:CreateTexture(nil, "OVERLAY")
    btn.icon:SetSize(12, 8); btn.icon:SetPoint("CENTER")
    btn.icon:SetTexture(MEDIA .. "arrow"); btn.icon:SetRotation(math_rad(-90))
    btn.icon:SetVertexColor(0.047, 0.824, 0.624)

    btn.displayFrame = CompactRaidFrameManager.displayFrame
    btn.displayFrame:SetParent(btn)
    btn.displayFrame:ClearAllPoints()
    btn.displayFrame:SetPoint("TOPLEFT", btn, "TOPRIGHT", 5, 0)

    local function OnEvt(self) self:SetShown(GetNumGroupMembers() > 0) end
    btn:RegisterEvent("GROUP_ROSTER_UPDATE"); btn:RegisterEvent("PLAYER_ENTERING_WORLD")
    btn:SetScript("OnEvent", OnEvt)
    btn:SetScript("OnClick", function(self)
        if self.displayFrame:IsVisible() then
            self.displayFrame:Hide(); self.icon:SetRotation(math_rad(-90))
        else
            self.displayFrame:Show(); self.icon:SetRotation(math_rad(90))
        end
        self.displayFrame:SetSize(CompactRaidFrameManager:GetWidth(), CompactRaidFrameManager:GetHeight())
    end)
    btn:SetScript("OnEnter", function(self) local r, g, b = self.icon:GetVertexColor(); self.icon:SetVertexColor(r * 1.2, g * 1.2, b * 1.2) end)
    btn:SetScript("OnLeave", function(self) self.icon:SetVertexColor(0.047, 0.824, 0.624) end)
    OnEvt(btn)
end

-- =====================================
-- LAYOUT SYSTEM (save / load / cycle)
-- =====================================

function CFUI.SaveLayout(name)
    local s = S(); s.layouts = s.layouts or {}
    local layout = {}
    for an, fd in pairs(chatFrames) do
        if fd.frame then
            local p, _, rp, x, y = fd.frame:GetPoint()
            layout[an] = { enabled = fd.frame:IsShown(), point = p, relPoint = rp, x = x, y = y }
        end
    end
    s.layouts[name] = layout; s.currentLayout = name
end

function CFUI.LoadLayout(name)
    local s = S()
    if not s.layouts or not s.layouts[name] then return end
    for an, d in pairs(s.layouts[name]) do
        if d.enabled then
            EnableFrame(an)
            local fd = chatFrames[an]
            if fd and fd.frame and d.point then
                fd.frame:ClearAllPoints(); fd.frame:SetPoint(d.point, UIParent, d.relPoint, d.x, d.y)
            end
        else DisableFrame(an) end
    end
    s.currentLayout = name; CFUI.RefreshSideBarIcons()
end

function CFUI.SwitchLayout()
    local s = S()
    if not s.layouts then return end
    local names = {}
    for n in pairs(s.layouts) do names[#names + 1] = n end
    if #names == 0 then
        print("|cFF00CCFFTomoMod|r: " .. (L["cfui_no_layouts"] or "No saved layouts."))
        return
    end
    table.sort(names)
    local cur = s.currentLayout; local ni = 1
    for i, n in ipairs(names) do if n == cur then ni = (i % #names) + 1; break end end
    CFUI.LoadLayout(names[ni])
end

-- =====================================
-- MAIN INITIALIZATION
-- =====================================

local function LoadChatFrameUI()
    local s = S(); if not s.enabled then return end
    isActive = true

    -- Hide ChatFrameSkin's container (this module takes over the visual layer)
    if ChatFrame1 and ChatFrame1.tuiContainer then ChatFrame1.tuiContainer:Hide() end

    for _, an in ipairs(ANCHOR_ORDER) do
        local fs = s.chatFrames and s.chatFrames[an]
        if fs and fs.enabled then EnableFrame(an) end
    end

    CFUI.RefreshSideBarIcons()
    ConfigureEditBox()
    UpdateHighlightGroups()
    C_Timer.After(1, RepositionBNToast)

    -- Raid frame manager
    if s.raidFrameManager ~= false then
        local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_CompactRaidFrames")
        if isLoaded then
            SetUpRaidFrameManager()
        else
            local ldr = CreateFrame("Frame"); ldr:RegisterEvent("ADDON_LOADED")
            ldr:SetScript("OnEvent", function(self, _, n)
                if n == "Blizzard_CompactRaidFrames" then SetUpRaidFrameManager(); self:UnregisterAllEvents() end
            end)
        end
    end
end

-- =====================================
-- PUBLIC API
-- =====================================

function CFUI.ApplySettings()
    if not isActive then return end
    local s = S()
    for _, an in ipairs(ANCHOR_ORDER) do
        local fs = s.chatFrames and s.chatFrames[an]
        if fs and fs.enabled then EnableFrame(an) else DisableFrame(an) end
    end
    CFUI.RefreshSideBarIcons(); ConfigureEditBox(); UpdateHighlightGroups()
end

function CFUI.SetEnabled(value)
    if not TomoModDB or not TomoModDB.chatFrameUI then return end
    TomoModDB.chatFrameUI.enabled = value
    if value then
        if not isActive then LoadChatFrameUI() end
    else
        isActive = false
        for _, d in pairs(chatFrames) do if d.frame then d.frame:Hide() end end
        HideAllIcons()
        if ChatFrame1 and ChatFrame1.tuiContainer then ChatFrame1.tuiContainer:Show() end
    end
end

function CFUI.Initialize()
    if isInitialized then return end
    if not S().enabled then return end
    isInitialized = true
    C_Timer.After(0.6, LoadChatFrameUI)
end

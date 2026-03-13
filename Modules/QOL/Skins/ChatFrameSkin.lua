-- =====================================
-- ChatFrameSkin.lua
-- Skins the Blizzard Chat Frame
-- Dark theme matching ObjectiveTracker / CharacterSkin
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_ChatFrameSkin = TomoMod_ChatFrameSkin or {}
local CFS = TomoMod_ChatFrameSkin

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local L = TomoMod_L

local isInitialized = false
local isHooked      = false

-- Dark theme palette
local BACKDROP_COLOR = { 0.06, 0.06, 0.08 }
local BORDER_COLOR   = { 0.12, 0.12, 0.14, 1 }
local ACCENT_COLOR   = { 0.05, 0.82, 0.62, 1 }
local TAB_BG         = { 0.08, 0.08, 0.10, 0.90 }
local TAB_ACTIVE     = { 0.05, 0.82, 0.62, 0.30 }
local EDITBOX_BG     = { 0.04, 0.04, 0.06, 0.95 }

-- Dedup
local skinnedFrames = setmetatable({}, { __mode = "k" })
local skinnedTabs   = setmetatable({}, { __mode = "k" })

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.chatFrameSkin or {}
end

local function IsEnabled()
    return S().enabled
end

-- =====================================
-- HELPER: Strip textures
-- =====================================

local function StripTextures(frame)
    if not frame or not frame.GetRegions then return end
    for _, region in pairs({ frame:GetRegions() }) do
        if region:IsObjectType("Texture") then
            region:SetTexture(nil)
            region:SetAlpha(0)
            region:Hide()
        end
    end
end

-- =====================================
-- HELPER: Kill NineSlice
-- =====================================

local function KillNineSlice(frame)
    if not frame then return end
    local ns = frame.NineSlice
    if ns then
        StripTextures(ns)
        ns:SetAlpha(0)
        ns:Hide()
    end
end

-- =====================================
-- SKIN CHAT TAB
-- =====================================

local function SkinChatTab(tab)
    if not tab or skinnedTabs[tab] then return end
    skinnedTabs[tab] = true

    -- Strip Blizzard tab textures
    StripTextures(tab)

    -- Hide left/middle/right textures
    for _, key in ipairs({ "leftTexture", "middleTexture", "rightTexture",
                           "leftSelectedTexture", "middleSelectedTexture", "rightSelectedTexture",
                           "leftHighlightTexture", "middleHighlightTexture", "rightHighlightTexture" }) do
        if tab[key] then
            tab[key]:SetTexture(nil)
            tab[key]:SetAlpha(0)
        end
    end

    -- Blizzard API for selected/highlight textures
    if tab.GetLeftTexture then pcall(function() tab:GetLeftTexture():SetAlpha(0) end) end
    if tab.GetMiddleTexture then pcall(function() tab:GetMiddleTexture():SetAlpha(0) end) end
    if tab.GetRightTexture then pcall(function() tab:GetRightTexture():SetAlpha(0) end) end

    -- Dark tab background
    if not tab._tmBG then
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(TAB_BG[1], TAB_BG[2], TAB_BG[3], TAB_BG[4])
        tab._tmBG = bg
    end

    -- Accent underline for active tab
    if not tab._tmAccent then
        local accent = tab:CreateTexture(nil, "OVERLAY")
        accent:SetHeight(2)
        accent:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 2, 0)
        accent:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 0)
        accent:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0)
        tab._tmAccent = accent
    end

    -- Style tab text
    local text = tab.Text or tab:GetFontString()
    if text and text.SetFont then
        text:SetFont(ADDON_FONT_BOLD, 11, "OUTLINE")
    end

    -- Hook to update accent on selection
    if not tab._tmTabHooked then
        tab._tmTabHooked = true
        hooksecurefunc(tab, "SetAlpha", function(self)
            if self._tmAccent then
                local a = self:GetAlpha()
                if a >= 0.9 then
                    self._tmAccent:SetAlpha(0.80)
                else
                    self._tmAccent:SetAlpha(0)
                end
            end
        end)
    end
end

-- =====================================
-- SKIN EDITBOX
-- =====================================

local function SkinEditBox(editBox)
    if not editBox or skinnedFrames[editBox] then return end
    skinnedFrames[editBox] = true

    -- Strip default textures
    StripTextures(editBox)
    KillNineSlice(editBox)

    -- Hide known editbox texture children
    for _, key in ipairs({ "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }) do
        local tex = editBox[key]
        if tex then
            tex:SetTexture(nil)
            tex:SetAlpha(0)
        end
    end

    -- Apply dark background
    if editBox.SetBackdrop then
        editBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        editBox:SetBackdropColor(EDITBOX_BG[1], EDITBOX_BG[2], EDITBOX_BG[3], EDITBOX_BG[4])
        editBox:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    elseif not editBox._tmEditBG then
        local bg = editBox:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(EDITBOX_BG[1], EDITBOX_BG[2], EDITBOX_BG[3], EDITBOX_BG[4])
        editBox._tmEditBG = bg
    end

    -- Style font
    if editBox.SetFont then
        editBox:SetFont(ADDON_FONT, 12, "")
    end
end

-- =====================================
-- SKIN SINGLE CHAT FRAME
-- =====================================

local function SkinChatFrame(chatFrame)
    if not chatFrame or skinnedFrames[chatFrame] then return end
    skinnedFrames[chatFrame] = true

    local s = S()
    local name = chatFrame:GetName()

    -- Strip background textures
    StripTextures(chatFrame)
    KillNineSlice(chatFrame)

    -- Background behind the chat
    local bg = chatFrame.Background or (name and _G[name .. "Background"])
    if bg then
        bg:SetTexture(nil)
        bg:SetAlpha(0)
    end

    -- Kill the Blizzard frame textures
    for _, suffix in ipairs({
        "TopTexture", "BottomTexture", "LeftTexture", "RightTexture",
        "TopLeftTexture", "TopRightTexture", "BottomLeftTexture", "BottomRightTexture",
        "ButtonFrameBackground", "ButtonFrameTopLeftTexture", "ButtonFrameTopRightTexture",
        "ButtonFrameBottomLeftTexture", "ButtonFrameBottomRightTexture",
        "ButtonFrameLeftTexture", "ButtonFrameRightTexture",
        "ButtonFrameTopTexture", "ButtonFrameBottomTexture",
    }) do
        local tex = name and _G[name .. suffix]
        if tex then
            tex:SetTexture(nil)
            tex:SetAlpha(0)
            tex:Hide()
        end
    end

    -- Dark backdrop
    if not chatFrame._tmBG then
        local darkBG = chatFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
        darkBG:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", -4, 4)
        darkBG:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 4, -4)
        darkBG:SetColorTexture(BACKDROP_COLOR[1], BACKDROP_COLOR[2], BACKDROP_COLOR[3], s.bgAlpha or 0.70)
        chatFrame._tmBG = darkBG
    end

    -- Border
    if not chatFrame._tmBorders then
        chatFrame._tmBorders = true
        local b = BORDER_COLOR
        local offsets = {
            { "TOPLEFT", -4, 4, "TOPRIGHT", 4, 4, nil, 1 },
            { "BOTTOMLEFT", -4, -4, "BOTTOMRIGHT", 4, -4, nil, 1 },
            { "TOPLEFT", -4, 4, "BOTTOMLEFT", -4, -4, 1, nil },
            { "TOPRIGHT", 4, 4, "BOTTOMRIGHT", 4, -4, 1, nil },
        }
        for _, info in ipairs(offsets) do
            local t = chatFrame:CreateTexture(nil, "BORDER")
            t:SetColorTexture(b[1], b[2], b[3], b[4])
            t:SetPoint(info[1], chatFrame, info[1], info[2], info[3])
            t:SetPoint(info[4], chatFrame, info[4], info[5], info[6])
            if info[7] then t:SetWidth(info[7]) end
            if info[8] then t:SetHeight(info[8]) end
        end
    end

    -- Hide chat buttons (scroll, social, etc.)
    local buttonFrame = name and _G[name .. "ButtonFrame"]
    if buttonFrame then
        buttonFrame:SetAlpha(0)
        buttonFrame:SetWidth(1)
    end

    -- Style editbox
    local editBox = name and _G[name .. "EditBox"]
    if editBox then
        SkinEditBox(editBox)
    end

    -- Font
    if chatFrame.SetFont then
        chatFrame:SetFont(ADDON_FONT, s.fontSize or 13, "")
    end
end

-- =====================================
-- SKIN ALL CHAT FRAMES
-- =====================================

local function SkinAllChatFrames()
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            SkinChatFrame(chatFrame)
        end

        -- Skin tabs
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then
            SkinChatTab(tab)
        end
    end

    -- Skin CombatLog tab if present
    local combatTab = _G.CombatLogQuickButtonFrame
    if combatTab then
        StripTextures(combatTab)
        if not combatTab._tmBG then
            local bg = combatTab:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(TAB_BG[1], TAB_BG[2], TAB_BG[3], TAB_BG[4])
            combatTab._tmBG = bg
        end
    end

    -- Skin Quick Join toast frame
    local toast = _G.QuickJoinToastButton
    if toast and not skinnedFrames[toast] then
        skinnedFrames[toast] = true
        StripTextures(toast)
    end

    -- Skin channel buttons
    local channelBtn = _G.ChatFrameChannelButton
    if channelBtn and not skinnedFrames[channelBtn] then
        skinnedFrames[channelBtn] = true
        StripTextures(channelBtn)
    end

    local menuBtn = _G.ChatFrameMenuButton
    if menuBtn and not skinnedFrames[menuBtn] then
        skinnedFrames[menuBtn] = true
        StripTextures(menuBtn)
    end
end

-- =====================================
-- HOOKS
-- =====================================

local function InstallHooks()
    if isHooked then return end
    isHooked = true

    -- Hook new temporary chat windows
    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        C_Timer.After(0.1, function()
            if IsEnabled() then SkinAllChatFrames() end
        end)
    end)

    -- Hook tab creation
    if FCF_Tab_OnClick then
        hooksecurefunc("FCF_Tab_OnClick", function(tab)
            if not IsEnabled() then return end
            if tab then SkinChatTab(tab) end
        end)
    end
end

-- =====================================
-- PUBLIC API
-- =====================================

function CFS.ApplySettings()
    if not isInitialized then return end
    if not IsEnabled() then return end
    SkinAllChatFrames()
end

function CFS.SetEnabled(value)
    if not TomoModDB or not TomoModDB.chatFrameSkin then return end
    TomoModDB.chatFrameSkin.enabled = value
    if value then
        isInitialized = true
        SkinAllChatFrames()
        InstallHooks()
    end
end

function CFS.Initialize()
    if isInitialized then return end
    if not IsEnabled() then return end
    isInitialized = true

    C_Timer.After(0.5, function()
        SkinAllChatFrames()
        InstallHooks()
    end)
end

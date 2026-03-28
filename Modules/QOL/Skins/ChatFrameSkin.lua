-- =====================================
-- ChatFrameSkin.lua
-- Skins the Blizzard Chat Frame
-- Dark theme matching ObjectiveTracker panel style
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_ChatFrameSkin = TomoMod_ChatFrameSkin or {}
local CFS = TomoMod_ChatFrameSkin

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_FONT_BLACK = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf"
local L = TomoMod_L

local isInitialized = false
local isHooked      = false

-- Palette (matches ObjectiveTracker exactly)
local ACCENT          = { 0.047, 0.824, 0.624 }  -- teal accent
local BG_COLOR        = { 0, 0, 0 }               -- pure black, alpha from settings
local HEADER_BG       = { 0.10, 0.10, 0.14, 0.90 }
local BORDER_COLOR    = { 0.25, 0.25, 0.30, 0.6 }
local TAB_NORMAL      = { 0.55, 0.55, 0.60, 1 }
local TAB_ACTIVE_COL  = { 0.95, 0.95, 0.97, 1 }
local EDITBOX_BG      = { 0.06, 0.06, 0.08, 0.95 }
local STATUS_COLOR    = { 0.55, 0.55, 0.60, 0.9 }

-- Dedup
local skinnedFrames = setmetatable({}, { __mode = "k" })
local skinnedTabs   = setmetatable({}, { __mode = "k" })

-- Per-frame skin data
local frameSkins = {}

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
-- HELPER: Create 1px border set
-- =====================================

local function CreateBorders(parent, color)
    local borders = {}
    for _, info in ipairs({
        { "TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1 },
        { "BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil },
        { "TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil },
    }) do
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
        t:SetPoint(info[1], parent, info[2])
        t:SetPoint(info[3], parent, info[4])
        if info[5] then t:SetWidth(info[5]) end
        if info[6] then t:SetHeight(info[6]) end
        borders[#borders + 1] = t
    end
    return borders
end

-- =====================================
-- SKIN CHAT TAB
-- =====================================

local function UpdateTabVisuals(tab, isSelected)
    if not tab then return end

    -- Accent underline
    if tab._tmAccent then
        if isSelected then
            tab._tmAccent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.80)
        else
            tab._tmAccent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0)
        end
    end

    -- Tab text color
    local text = tab.Text or tab:GetFontString()
    if text and text.SetTextColor then
        if isSelected then
            text:SetTextColor(TAB_ACTIVE_COL[1], TAB_ACTIVE_COL[2], TAB_ACTIVE_COL[3], TAB_ACTIVE_COL[4])
        else
            text:SetTextColor(TAB_NORMAL[1], TAB_NORMAL[2], TAB_NORMAL[3], TAB_NORMAL[4])
        end
    end
end

local function SkinChatTab(tab)
    if not tab or skinnedTabs[tab] then return end
    skinnedTabs[tab] = true

    -- Strip only Blizzard tab background textures (NOT the FontString)
    for _, key in ipairs({ "leftTexture", "middleTexture", "rightTexture",
                           "leftSelectedTexture", "middleSelectedTexture", "rightSelectedTexture",
                           "leftHighlightTexture", "middleHighlightTexture", "rightHighlightTexture" }) do
        if tab[key] then
            tab[key]:SetTexture(nil)
            tab[key]:SetAlpha(0)
        end
    end

    if tab.GetLeftTexture then pcall(function() tab:GetLeftTexture():SetAlpha(0) end) end
    if tab.GetMiddleTexture then pcall(function() tab:GetMiddleTexture():SetAlpha(0) end) end
    if tab.GetRightTexture then pcall(function() tab:GetRightTexture():SetAlpha(0) end) end

    -- Strip remaining background textures but preserve the fontstring
    if tab.GetRegions then
        for _, region in pairs({ tab:GetRegions() }) do
            if region:IsObjectType("Texture") then
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
    end

    -- Tab text with bold font — force visible
    local text = tab.Text or tab:GetFontString()
    if text then
        local s = S()
        if text.SetFont then
            text:SetFont(ADDON_FONT_BOLD, (s.fontSize or 13) - 1, "OUTLINE")
        end
        text:SetAlpha(1)
        text:Show()
        text:SetDrawLayer("OVERLAY")
    end

    -- Accent underline (like OT header accent)
    if not tab._tmAccent then
        local accent = tab:CreateTexture(nil, "OVERLAY")
        accent:SetHeight(2)
        accent:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 2, 0)
        accent:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 0)
        accent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0)
        tab._tmAccent = accent
    end

    -- Hover highlight
    if not tab._tmHoverHooked then
        tab._tmHoverHooked = true
        tab:HookScript("OnEnter", function(self)
            local txt = self.Text or self:GetFontString()
            if txt then txt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1) end
        end)
        tab:HookScript("OnLeave", function(self)
            -- Determine if this tab's frame is the selected one
            local chatFrame = self and _G[self:GetName() and self:GetName():gsub("Tab$", "")]
            local selected = chatFrame and (chatFrame == SELECTED_CHAT_FRAME or chatFrame == SELECTED_DOCK_FRAME)
            UpdateTabVisuals(self, selected)
        end)
    end

    -- Hook SetAlpha: Blizzard fades inactive tabs to very low alpha (0.2-0.4),
    -- which makes all children (including text) nearly invisible.
    -- We force tab alpha to 1.0 and handle active/inactive purely via text color.
    if not tab._tmAlphaHooked then
        tab._tmAlphaHooked = true
        hooksecurefunc(tab, "SetAlpha", function(self, a)
            -- Blizzard sets ~1.0 for selected, lower for unselected
            local isSelected = (a or self:GetAlpha()) >= 0.9
            UpdateTabVisuals(self, isSelected)
            -- Force tab to stay fully opaque so text is always readable
            if self:GetAlpha() < 1 then
                self:SetAlpha(1)
            end
        end)
    end

    -- Force initial alpha to 1
    tab:SetAlpha(1)
    UpdateTabVisuals(tab, tab == _G["ChatFrame1Tab"])
end

-- =====================================
-- SKIN EDITBOX
-- =====================================

local function SkinEditBox(editBox)
    if not editBox or skinnedFrames[editBox] then return end
    skinnedFrames[editBox] = true

    StripTextures(editBox)
    KillNineSlice(editBox)

    for _, key in ipairs({ "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }) do
        local tex = editBox[key]
        if tex then
            tex:SetTexture(nil)
            tex:SetAlpha(0)
        end
    end

    -- Dark editbox background
    if not editBox._tmEditBG then
        local bg = editBox:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(EDITBOX_BG[1], EDITBOX_BG[2], EDITBOX_BG[3], EDITBOX_BG[4])
        editBox._tmEditBG = bg
    end

    -- Left accent bar on editbox
    if not editBox._tmAccent then
        local acc = editBox:CreateTexture(nil, "OVERLAY")
        acc:SetWidth(2)
        acc:SetPoint("TOPLEFT", editBox, "TOPLEFT", 0, 0)
        acc:SetPoint("BOTTOMLEFT", editBox, "BOTTOMLEFT", 0, 0)
        acc:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.60)
        editBox._tmAccent = acc
    end

    -- Style font
    local s = S()
    if editBox.SetFont then
        editBox:SetFont(ADDON_FONT, s.fontSize or 13, "")
    end
    if editBox.SetTextColor then
        editBox:SetTextColor(0.85, 0.85, 0.85, 1)
    end

    -- Header prefix (e.g. "Say:", "Guild:") — style the header fontstring
    local header = editBox.header or _G[editBox:GetName() and (editBox:GetName() .. "Header")]
    if header and header.SetFont then
        header:SetFont(ADDON_FONT_BOLD, s.fontSize or 13, "OUTLINE")
    end

    -- Reposition editbox to align properly with the skinned chat frame
    editBox:ClearAllPoints()
    local chatFrameName = editBox:GetName() and editBox:GetName():gsub("EditBox$", "")
    local chatFrame = chatFrameName and _G[chatFrameName]
    if chatFrame then
        editBox:SetPoint("TOPLEFT", chatFrame, "BOTTOMLEFT", -8, -2)
        editBox:SetPoint("TOPRIGHT", chatFrame, "BOTTOMRIGHT", 8, -2)
    end
end

-- =====================================
-- STATUS LINE (line count + fade timer)
-- =====================================

local function CreateStatusLine(skinData)
    if skinData.statusText then return end

    local parent = skinData.skinFrame
    if not parent then return end

    local status = parent:CreateFontString(nil, "OVERLAY")
    status:SetFont(ADDON_FONT, 10, "OUTLINE")
    status:SetTextColor(STATUS_COLOR[1], STATUS_COLOR[2], STATUS_COLOR[3], STATUS_COLOR[4])
    status:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 6)
    skinData.statusText = status
end

local function UpdateStatusLine(chatFrame, skinData)
    if not skinData or not skinData.statusText then return end

    -- Line count
    local numMessages = 0
    if chatFrame.GetNumMessages then
        numMessages = chatFrame:GetNumMessages()
    end

    -- Fade info
    local fadeTime = ""
    if chatFrame.GetTimeVisible then
        local visible = chatFrame:GetTimeVisible()
        local fade = chatFrame.GetFadeDuration and chatFrame:GetFadeDuration() or 0
        if visible > 0 then
            local secs = math.floor(visible)
            local fadeSecs = math.floor(fade)
            fadeTime = string.format("  |  %ds + %ds fade", secs, fadeSecs)
        end
    end

    skinData.statusText:SetText(numMessages .. " lines" .. fadeTime)
end

-- =====================================
-- SKIN SINGLE CHAT FRAME
-- =====================================

local function SkinChatFrame(chatFrame)
    if not chatFrame or skinnedFrames[chatFrame] then return end
    skinnedFrames[chatFrame] = true

    local s = S()
    local name = chatFrame:GetName()
    local idx = name and tonumber(name:match("ChatFrame(%d+)")) or 0

    -- Strip only the background (NOT StripTextures on the chatFrame itself,
    -- as that kills internal ScrollingMessageFrame textures used for text rendering)
    KillNineSlice(chatFrame)

    local bg = chatFrame.Background or (name and _G[name .. "Background"])
    if bg then
        bg:SetTexture(nil)
        bg:SetAlpha(0)
    end

    -- Kill all Blizzard frame decoration textures
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

    -- ── Create wrapper skin frame (like OT skinFrame) ──
    local skinData = frameSkins[idx] or {}
    frameSkins[idx] = skinData

    if not skinData.skinFrame then
        local sf = CreateFrame("Frame", "TomoMod_ChatSkin" .. idx, UIParent)
        sf:SetFrameStrata("BACKGROUND")
        sf:SetFrameLevel(0)

        -- Background
        local sfBG = sf:CreateTexture(nil, "BACKGROUND")
        sfBG:SetAllPoints()
        sf.bg = sfBG

        -- Borders (OT style)
        sf.borderTextures = CreateBorders(sf, BORDER_COLOR)

        -- Tab header bar (like OT headerBar)
        local tabBar = CreateFrame("Frame", nil, sf)
        tabBar:SetHeight(26)
        tabBar:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, 0)
        tabBar:SetPoint("TOPRIGHT", sf, "TOPRIGHT", 0, 0)

        local tabBG = tabBar:CreateTexture(nil, "BACKGROUND")
        tabBG:SetAllPoints()
        tabBG:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], HEADER_BG[4])

        -- Accent line under tab bar
        local accent = tabBar:CreateTexture(nil, "ARTWORK")
        accent:SetHeight(1)
        accent:SetPoint("BOTTOMLEFT", tabBar, "BOTTOMLEFT", 0, 0)
        accent:SetPoint("BOTTOMRIGHT", tabBar, "BOTTOMRIGHT", 0, 0)
        accent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.60)

        sf.tabBar = tabBar
        skinData.skinFrame = sf
    end

    -- Position skin frame around chat
    local sf = skinData.skinFrame
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", -8, 26)
    sf:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 8, -8)

    -- Apply background alpha
    sf.bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], s.bgAlpha or 0.70)

    -- Status line
    CreateStatusLine(skinData)
    UpdateStatusLine(chatFrame, skinData)

    -- Only show the skin frame if this chat frame is actually visible
    if chatFrame:IsVisible() then
        sf:Show()
    else
        sf:Hide()
    end

    -- Hide chat buttons
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

    -- Apply chat font safely — preserve flags and use SetFont on the fontObject
    -- to avoid breaking existing message rendering in the ScrollingMessageFrame
    local fontObj = chatFrame:GetFontObject()
    if fontObj then
        local _, _, flags = fontObj:GetFont()
        fontObj:SetFont(ADDON_FONT, s.fontSize or 13, flags or "")
    end

    -- Hook visibility to sync skin frame
    if not chatFrame._tmVisHooked then
        chatFrame._tmVisHooked = true
        chatFrame:HookScript("OnShow", function()
            if skinData.skinFrame and IsEnabled() then skinData.skinFrame:Show() end
        end)
        chatFrame:HookScript("OnHide", function()
            if skinData.skinFrame then skinData.skinFrame:Hide() end
        end)
    end
end

-- =====================================
-- SKIN ALL CHAT FRAMES
-- =====================================

local function SkinAllChatFrames()
    local s = S()

    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            SkinChatFrame(chatFrame)

            -- Update dynamic elements on reskin
            local skinData = frameSkins[i]
            if skinData and skinData.skinFrame then
                skinData.skinFrame.bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], s.bgAlpha or 0.70)
                local fontObj = chatFrame:GetFontObject()
                if fontObj then
                    local _, _, flags = fontObj:GetFont()
                    fontObj:SetFont(ADDON_FONT, s.fontSize or 13, flags or "")
                end
                UpdateStatusLine(chatFrame, skinData)
                -- Sync position
                skinData.skinFrame:ClearAllPoints()
                skinData.skinFrame:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", -8, 26)
                skinData.skinFrame:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 8, -8)
                -- Only show if chat frame is actually visible
                if chatFrame:IsVisible() then
                    skinData.skinFrame:Show()
                else
                    skinData.skinFrame:Hide()
                end
            end
        end

        -- Skin tabs
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then
            SkinChatTab(tab)
        end
    end

    -- Skin CombatLog quick-button bar
    local combatTab = _G.CombatLogQuickButtonFrame
    if combatTab and not skinnedFrames[combatTab] then
        skinnedFrames[combatTab] = true
        StripTextures(combatTab)
        if not combatTab._tmBG then
            local bg = combatTab:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], HEADER_BG[4])
            combatTab._tmBG = bg
        end
    end

    -- Hide Blizzard utility buttons
    local toast = _G.QuickJoinToastButton
    if toast and not skinnedFrames[toast] then
        skinnedFrames[toast] = true
        StripTextures(toast)
    end

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
-- PERIODIC STATUS UPDATE
-- =====================================

local statusTicker

-- [PERF] C_Timer.NewTicker replaces OnUpdate accumulator for 2s poll
local function StartStatusUpdater()
    if statusTicker then return end
    statusTicker = C_Timer.NewTicker(2, function()
        if not IsEnabled() then return end
        for i = 1, NUM_CHAT_WINDOWS or 10 do
            local chatFrame = _G["ChatFrame" .. i]
            local skinData = frameSkins[i]
            if chatFrame and skinData then
                UpdateStatusLine(chatFrame, skinData)
            end
        end
    end)
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

    -- Hook tab clicks
    if FCF_Tab_OnClick then
        hooksecurefunc("FCF_Tab_OnClick", function(tab)
            if not IsEnabled() then return end
            if tab then SkinChatTab(tab) end
        end)
    end

    -- Hook dock updates to re-sync skin positions
    if FCF_DockUpdate then
        hooksecurefunc("FCF_DockUpdate", function()
            if not IsEnabled() then return end
            C_Timer.After(0.1, SkinAllChatFrames)
        end)
    end

    StartStatusUpdater()
end

-- =====================================
-- PUBLIC API
-- =====================================

function CFS.ApplySettings()
    if not isInitialized then return end
    if not IsEnabled() then return end

    -- Reset dedup so font size / alpha changes apply
    wipe(skinnedFrames)
    wipe(skinnedTabs)
    SkinAllChatFrames()
end

function CFS.SetEnabled(value)
    if not TomoModDB or not TomoModDB.chatFrameSkin then return end
    TomoModDB.chatFrameSkin.enabled = value
    if value then
        isInitialized = true
        wipe(skinnedFrames)
        wipe(skinnedTabs)
        SkinAllChatFrames()
        InstallHooks()
    else
        -- Hide all skin frames
        for _, skinData in pairs(frameSkins) do
            if skinData.skinFrame then skinData.skinFrame:Hide() end
        end
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

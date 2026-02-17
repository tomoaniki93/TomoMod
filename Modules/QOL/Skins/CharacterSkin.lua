-- =====================================
-- CharacterSkin.lua
-- Skins Character Sheet (PaperDoll, Reputation, Currency)
-- + Inspect frame — Inspired by ElvUI, adapted to TomoMod style
-- Fully compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_CharacterSkin = TomoMod_CharacterSkin or {}
local CS = TomoMod_CharacterSkin

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_TEXTURE    = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local L = TomoMod_L

local isInitialized   = false
local inspectSkinned  = false

-- Colors matching TomoMod's dark theme
local BACKDROP_COLOR     = { 0.06, 0.06, 0.08, 0.95 }
local BACKDROP_BORDER    = { 0.12, 0.12, 0.14, 1 }
local SLOT_BG            = { 0.08, 0.08, 0.10, 1 }
local SLOT_BORDER        = { 0.20, 0.20, 0.24, 1 }
local HIGHLIGHT_COLOR    = { 1, 1, 1, 0.15 }
local ACCENT_COLOR       = { 0.05, 0.82, 0.62, 1 }
local STAT_GRADIENT      = { 0.8, 0.8, 0.8, 0.12 }
local TAB_BG_INACTIVE    = { 0.06, 0.06, 0.08, 0.9 }
local REP_BAR_BG         = { 0.05, 0.05, 0.07, 1 }

-- Dedup
local skinnedFrames = setmetatable({}, { __mode = "k" })

-- =====================================
-- SETTINGS
-- =====================================

local function GetSettings()
    return TomoModDB and TomoModDB.characterSkin or {}
end

local function IsEnabled()
    local s = GetSettings()
    return s.enabled
end

-- =====================================
-- HELPER: Strip all textures from a frame
-- =====================================

local function StripTextures(frame, killLayer)
    if not frame or not frame.GetRegions then return end
    for _, region in pairs({ frame:GetRegions() }) do
        if region:IsObjectType("Texture") then
            if killLayer then
                local layer = region:GetDrawLayer()
                if layer == killLayer then
                    region:SetTexture(nil)
                    region:SetAlpha(0)
                    region:Hide()
                end
            else
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
    end
end

-- =====================================
-- HELPER: Kill NineSlice border system (TWW)
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
-- HELPER: Kill PortraitContainer (gold circle)
-- =====================================

local function KillPortrait(frame)
    if not frame then return end
    local name = frame.GetName and frame:GetName()

    -- Modern PortraitContainer
    if frame.PortraitContainer then
        frame.PortraitContainer:SetAlpha(0)
        frame.PortraitContainer:Hide()
    end

    -- Legacy portrait global
    local portrait = name and _G[name .. "Portrait"]
    if portrait then
        portrait:SetAlpha(0)
        portrait:Hide()
    end

    -- PortraitOverlay
    if frame.PortraitOverlay then
        frame.PortraitOverlay:SetAlpha(0)
    end
    local overlay = name and _G[name .. "PortraitOverlay"]
    if overlay then
        overlay:SetAlpha(0)
    end

    -- ArtOverlayFrame
    if frame.ArtOverlayFrame then
        frame.ArtOverlayFrame:SetAlpha(0)
    end
end

-- =====================================
-- HELPER: Kill Inset border pieces
-- =====================================

local function KillInsetBorders(frame)
    if not frame then return end
    local borders = {
        "InsetBorderTop", "InsetBorderTopLeft", "InsetBorderTopRight",
        "InsetBorderBottom", "InsetBorderBottomLeft", "InsetBorderBottomRight",
        "InsetBorderLeft", "InsetBorderRight", "Bg",
    }
    for _, key in ipairs(borders) do
        if frame[key] then
            frame[key]:SetAlpha(0)
            frame[key]:Hide()
        end
    end
    KillNineSlice(frame)
end

-- =====================================
-- HELPER: Apply dark TomoMod backdrop
-- =====================================

local function ApplyBackdrop(frame, bgColor, borderColor)
    if not frame then return end
    bgColor = bgColor or BACKDROP_COLOR
    borderColor = borderColor or BACKDROP_BORDER

    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bgColor))
    frame:SetBackdropBorderColor(unpack(borderColor))
end

-- =====================================
-- HELPER: Skin a PortraitFrame (CharacterFrame, InspectFrame, etc.)
-- =====================================

local function SkinPortraitFrame(frame)
    if not frame then return end

    -- 1) Strip all textures on the main frame
    StripTextures(frame)

    -- 2) Kill NineSlice borders
    KillNineSlice(frame)

    -- 3) Kill portrait (gold circle)
    KillPortrait(frame)

    -- 4) Handle TitleContainer (the header bar with name)
    if frame.TitleContainer then
        StripTextures(frame.TitleContainer)
    end

    -- 5) Handle Bg
    if frame.Bg then
        frame.Bg:SetAlpha(0)
        frame.Bg:Hide()
    end

    -- 6) Handle TopTileStreaks
    if frame.TopTileStreaks then
        frame.TopTileStreaks:SetAlpha(0)
    end

    -- 7) Apply our dark backdrop
    ApplyBackdrop(frame, BACKDROP_COLOR, BACKDROP_BORDER)

    -- 8) Handle close button
    local closeBtn = frame.CloseButton or (frame.GetName and _G[frame:GetName() .. "CloseButton"])
    if closeBtn then
        StripTextures(closeBtn)
        closeBtn:SetSize(24, 24)
        closeBtn:ClearAllPoints()
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

        if not closeBtn._tomoText then
            local txt = closeBtn:CreateFontString(nil, "OVERLAY")
            txt:SetFont(ADDON_FONT_BOLD, 16, "OUTLINE")
            txt:SetPoint("CENTER", 0, 0)
            txt:SetText("x")
            txt:SetTextColor(0.6, 0.6, 0.6)
            closeBtn._tomoText = txt

            closeBtn:HookScript("OnEnter", function()
                txt:SetTextColor(1, 0.3, 0.3)
            end)
            closeBtn:HookScript("OnLeave", function()
                txt:SetTextColor(0.6, 0.6, 0.6)
            end)
        end
    end
end

-- =====================================
-- HELPER: Skin an item slot button
-- =====================================

local function StripSlotTextures(slot)
    -- Selectively remove slot border/background textures
    -- WITHOUT touching the item icon
    local iconTex = slot.icon
    local iconBorder = slot.IconBorder
    local iconOverlay = slot.IconOverlay
    local cooldown = slot.Cooldown or slot.cooldown

    for _, region in pairs({ slot:GetRegions() }) do
        if region:IsObjectType("Texture") then
            -- Skip the actual item icon and important overlays
            if region ~= iconTex and region ~= iconBorder and region ~= iconOverlay then
                local name = region.GetName and region:GetName() or ""
                -- Skip search overlay and highlight textures
                if not name:find("SearchOverlay") then
                    region:SetTexture(nil)
                    region:SetAlpha(0)
                    region:Hide()
                end
            end
        end
    end

    -- Kill normal/pushed textures (Blizzard slot borders)
    local normalTex = slot:GetNormalTexture()
    if normalTex and normalTex ~= iconTex then
        normalTex:SetTexture(nil)
        normalTex:SetAlpha(0)
    end
    local pushedTex = slot:GetPushedTexture()
    if pushedTex and pushedTex ~= iconTex then
        pushedTex:SetTexture(nil)
        pushedTex:SetAlpha(0)
    end
end

local function SkinItemSlot(slot)
    if not slot or skinnedFrames[slot] then return end

    StripSlotTextures(slot)
    ApplyBackdrop(slot, SLOT_BG, SLOT_BORDER)

    -- Make sure icon is visible after stripping
    if slot.icon then
        slot.icon:SetAlpha(1)
        slot.icon:Show()
    end

    if slot.icon then
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon:ClearAllPoints()
        slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
        slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
    end

    local hl = slot:GetHighlightTexture()
    if hl then
        hl:SetColorTexture(unpack(HIGHLIGHT_COLOR))
        hl:ClearAllPoints()
        hl:SetPoint("TOPLEFT", 1, -1)
        hl:SetPoint("BOTTOMRIGHT", -1, 1)
    end

    -- IconBorder: hide overlay, use backdrop border color instead
    if slot.IconBorder then
        slot.IconBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        slot.IconBorder:SetDrawLayer("OVERLAY", 1)
        slot.IconBorder:SetAlpha(0)

        hooksecurefunc(slot.IconBorder, "SetVertexColor", function(self, r, g, b)
            local parent = self:GetParent()
            if parent and parent.SetBackdropBorderColor then
                parent:SetBackdropBorderColor(r, g, b, 1)
            end
        end)
        hooksecurefunc(slot.IconBorder, "Hide", function(self)
            local parent = self:GetParent()
            if parent and parent.SetBackdropBorderColor then
                parent:SetBackdropBorderColor(unpack(SLOT_BORDER))
            end
        end)
        hooksecurefunc(slot.IconBorder, "SetShown", function(self, shown)
            if not shown then
                local parent = self:GetParent()
                if parent and parent.SetBackdropBorderColor then
                    parent:SetBackdropBorderColor(unpack(SLOT_BORDER))
                end
            end
        end)
    end

    if slot.popoutButton then
        local pPoint = slot.popoutButton:GetPoint()
        if pPoint == "TOP" then
            slot.popoutButton:ClearAllPoints()
            slot.popoutButton:SetPoint("TOP", slot, "BOTTOM", 0, 2)
        else
            slot.popoutButton:ClearAllPoints()
            slot.popoutButton:SetPoint("LEFT", slot, "RIGHT", -2, 0)
        end
    end

    if slot.ignoreTexture then
        slot.ignoreTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent")
    end

    skinnedFrames[slot] = true
end

-- =====================================
-- HELPER: Skin a tab button (bottom tabs)
-- =====================================

local function SkinTab(tab)
    if not tab or skinnedFrames[tab] then return end

    StripTextures(tab)

    if not tab._tomoBg then
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(unpack(TAB_BG_INACTIVE))
        tab._tomoBg = bg
    end

    local text = tab:GetFontString()
    if text then
        text:SetFont(ADDON_FONT, 11, "")
        text:SetTextColor(0.8, 0.8, 0.8)
    end

    tab:HookScript("OnEnter", function(self)
        if self._tomoBg then self._tomoBg:SetColorTexture(0.14, 0.14, 0.18, 1) end
    end)
    tab:HookScript("OnLeave", function(self)
        if self._tomoBg then self._tomoBg:SetColorTexture(unpack(TAB_BG_INACTIVE)) end
    end)

    skinnedFrames[tab] = true
end

-- =====================================
-- HELPER: Gradient for stat lines
-- =====================================

local function ColorizeStatPane(frame)
    if not frame or frame._tomoGrad then return end
    if frame.Background then
        frame.Background:SetAlpha(0)
    end

    local r, g, b, a = unpack(STAT_GRADIENT)

    frame._leftGrad = frame:CreateTexture(nil, "BORDER")
    frame._leftGrad:SetSize(80, frame:GetHeight())
    frame._leftGrad:SetPoint("LEFT", frame, "CENTER")
    frame._leftGrad:SetColorTexture(1, 1, 1, 1)
    frame._leftGrad:SetGradient("Horizontal",
        CreateColor(r, g, b, a),
        CreateColor(r, g, b, 0)
    )

    frame._rightGrad = frame:CreateTexture(nil, "BORDER")
    frame._rightGrad:SetSize(80, frame:GetHeight())
    frame._rightGrad:SetPoint("RIGHT", frame, "CENTER")
    frame._rightGrad:SetColorTexture(1, 1, 1, 1)
    frame._rightGrad:SetGradient("Horizontal",
        CreateColor(r, g, b, 0),
        CreateColor(r, g, b, a)
    )

    frame._tomoGrad = true
end

-- =====================================
-- HELPER: Skin stats category header
-- =====================================

local function SkinStatsCategory(which)
    local pane = _G.CharacterStatsPane
    if not pane or not pane[which] then return end
    local cat = pane[which]
    StripTextures(cat)
    ApplyBackdrop(cat, { 0.08, 0.08, 0.10, 0.8 }, { 0.15, 0.15, 0.18, 1 })
end

-- =====================================
-- HELPER: Skin reputation scroll children
-- =====================================

local function SkinReputationChild(child)
    if not child or skinnedFrames[child] then return end

    -- Find the reputation bar - TWW uses various paths
    local repBar = nil
    if child.Content then
        repBar = child.Content.ReputationBar or child.Content.repBar
    end
    -- Fallback: look for any StatusBar child
    if not repBar then
        for _, sub in pairs({ child:GetChildren() }) do
            if sub:IsObjectType("StatusBar") then
                repBar = sub
                break
            end
            -- Check one level deeper (Content frame)
            if sub.GetChildren then
                for _, subsub in pairs({ sub:GetChildren() }) do
                    if subsub:IsObjectType("StatusBar") then
                        repBar = subsub
                        break
                    end
                end
            end
            if repBar then break end
        end
    end

    -- Skin the rep bar if found
    if repBar then
        -- Only strip the bar's background textures, not the bar itself
        for _, region in pairs({ repBar:GetRegions() }) do
            if region:IsObjectType("Texture") then
                local layer = region:GetDrawLayer()
                if layer == "BACKGROUND" or layer == "BORDER" then
                    -- Check if it's the actual statusbar texture (don't kill it)
                    local tex = region:GetTexture()
                    if tex and (tostring(tex):find("UI%-StatusBar") or tostring(tex):find("StatusBar")) then
                        -- This is a border/bg piece, safe to remove
                        region:SetAlpha(0)
                        region:Hide()
                    end
                end
            end
        end

        repBar:SetStatusBarTexture(ADDON_TEXTURE)

        if not repBar._tomoBackdrop then
            ApplyBackdrop(repBar, REP_BAR_BG, SLOT_BORDER)
            repBar._tomoBackdrop = true
        end

        -- Make sure bar is visible
        repBar:SetAlpha(1)
        repBar:Show()
    end

    -- Lightly style the row background (don't strip everything)
    if child.Right then
        -- Only hide the Right texture (row separator art)
        child.Right:SetAlpha(0)
    end
    if child.Left then
        child.Left:SetAlpha(0)
    end

    skinnedFrames[child] = true
end

local function UpdateReputationSkins(scrollBox)
    if not scrollBox or not scrollBox.ForEachFrame then return end
    scrollBox:ForEachFrame(SkinReputationChild)
end

-- =====================================
-- HELPER: Skin currency scroll children
-- =====================================

local function SkinCurrencyChild(child)
    if not child or skinnedFrames[child] then return end

    -- Currency icons
    local icon = child.Content and child.Content.CurrencyIcon
    if icon then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetSize(16, 16)
    end

    -- Lightly style row separators
    if child.Right then
        child.Right:SetAlpha(0)
    end
    if child.Left then
        child.Left:SetAlpha(0)
    end

    -- Style category headers (they have a different structure)
    -- Category headers typically have a CategoryName or are a different frame type
    local isCategory = false

    -- Check if this is a category header (has a text with category color)
    if child.Content then
        for _, region in pairs({ child.Content:GetRegions() }) do
            if region:IsObjectType("FontString") then
                local r, g, b = region:GetTextColor()
                -- Category headers tend to have golden/yellow color (>0.8, >0.6, <0.3)
                if r and r > 0.8 and g > 0.5 and b < 0.4 then
                    isCategory = true
                    -- Make category text bigger and bolder
                    region:SetFont(ADDON_FONT_BOLD, 12, "OUTLINE")
                    break
                end
            end
        end
    end

    -- Apply a subtle backdrop to category headers
    if isCategory and not child._tomoCatBg then
        local bg = child:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.10, 0.08, 0.6)
        child._tomoCatBg = bg

        -- Add a left accent bar
        local accent = child:CreateTexture(nil, "BORDER")
        accent:SetWidth(2)
        accent:SetPoint("TOPLEFT", 4, -2)
        accent:SetPoint("BOTTOMLEFT", 4, 2)
        accent:SetColorTexture(unpack(ACCENT_COLOR))
        child._tomoAccent = accent
    end

    skinnedFrames[child] = true
end

local function UpdateCurrencySkins(scrollBox)
    if not scrollBox or not scrollBox.ForEachFrame then return end
    scrollBox:ForEachFrame(SkinCurrencyChild)
end

-- =====================================
-- HELPER: Skin sidebar tabs (PaperDoll)
-- =====================================

local function SkinSidebarTabs()
    local index = 1
    local tab = _G["PaperDollSidebarTab" .. index]
    while tab do
        if not skinnedFrames[tab] then
            if tab.TabBg then
                tab.TabBg:SetAlpha(0)
                tab.TabBg:Hide()
            end

            if not tab._tomoBg then
                local bg = tab:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.08, 0.08, 0.10, 1)
                tab._tomoBg = bg
            end

            if tab.Highlight then
                tab.Highlight:SetColorTexture(1, 1, 1, 0.2)
                tab.Highlight:SetAllPoints()
            end

            if tab.Hider then
                tab.Hider:SetColorTexture(0, 0, 0, 0.7)
                if tab._tomoBg then
                    tab.Hider:SetAllPoints(tab._tomoBg)
                end
            end

            if index == 1 then
                for _, region in pairs({ tab:GetRegions() }) do
                    if region:IsObjectType("Texture") and region ~= tab._tomoBg
                       and region ~= tab.Highlight and region ~= tab.Hider then
                        region:SetTexCoord(0.16, 0.86, 0.16, 0.86)
                    end
                end
            end

            skinnedFrames[tab] = true
        end

        index = index + 1
        tab = _G["PaperDollSidebarTab" .. index]
    end
end

-- =====================================
-- HELPER: Update stat gradient visibility
-- =====================================

local function UpdateStatGradients()
    if not _G.CharacterStatsPane or not _G.CharacterStatsPane.statsFramePool then return end
    for frame in _G.CharacterStatsPane.statsFramePool:EnumerateActive() do
        ColorizeStatPane(frame)
        if frame._leftGrad and frame.Background then
            local shown = frame.Background:IsShown()
            frame._leftGrad:SetShown(shown)
            frame._rightGrad:SetShown(shown)
        end
    end
end

-- =====================================
-- HELPER: Inset visibility for rep/currency
-- =====================================

local showInsetBackdrop = {
    ReputationFrame = true,
    TokenFrame = true,
}

local function UpdateCharacterInset(_, name)
    if not _G.CharacterFrameInset then return end
    if _G.CharacterFrameInset._tomoInsetBg then
        _G.CharacterFrameInset._tomoInsetBg:SetShown(showInsetBackdrop[name] or false)
    end
end

-- =====================================
-- HELPER: Equipment flyout
-- =====================================

local function SkinEquipmentFlyoutButton(button)
    if not button or button._tomoSkinned then return end
    button:SetNormalTexture("")
    button:SetPushedTexture("")
    ApplyBackdrop(button, SLOT_BG, SLOT_BORDER)

    if button.icon then
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon:ClearAllPoints()
        button.icon:SetPoint("TOPLEFT", 1, -1)
        button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    end

    button._tomoSkinned = true
end

local function SkinEquipmentFlyoutItems()
    local flyout = _G.EquipmentFlyoutFrame
    if not flyout then return end

    local bf = flyout.buttonFrame
    if bf and not bf._tomoSkinned then
        StripTextures(bf)
        ApplyBackdrop(bf, { 0.06, 0.06, 0.08, 0.95 }, BACKDROP_BORDER)
        bf._tomoSkinned = true
    end

    if flyout.buttons then
        for _, btn in pairs(flyout.buttons) do
            SkinEquipmentFlyoutButton(btn)
        end
    end
end

-- =====================================
-- HELPER: Equipment Manager / Title pane
-- =====================================

local function SkinEquipmentManagerChild(child)
    if child.icon and not skinnedFrames[child] then
        if child.BgTop then child.BgTop:SetTexture("") end
        if child.BgMiddle then child.BgMiddle:SetTexture("") end
        if child.BgBottom then child.BgBottom:SetTexture("") end
        if child.icon then child.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        if child.HighlightBar then
            child.HighlightBar:SetColorTexture(1, 1, 1, 0.15)
            child.HighlightBar:SetDrawLayer("BACKGROUND")
        end
        if child.SelectedBar then
            child.SelectedBar:SetColorTexture(0.8, 0.8, 0.8, 0.15)
            child.SelectedBar:SetDrawLayer("BACKGROUND")
        end
        skinnedFrames[child] = true
    end
end

local function UpdateEquipmentManagerSkins(scrollBox)
    if scrollBox and scrollBox.ForEachFrame then
        scrollBox:ForEachFrame(SkinEquipmentManagerChild)
    end
end

local function SkinTitleChild(child)
    if not skinnedFrames[child] then
        child:DisableDrawLayer("BACKGROUND")
        skinnedFrames[child] = true
    end
end

local function UpdateTitleSkins(scrollBox)
    if scrollBox and scrollBox.ForEachFrame then
        scrollBox:ForEachFrame(SkinTitleChild)
    end
end

-- =====================================
-- ITEM INFO OVERLAY SYSTEM
-- Shows item name, ilvl, upgrade track next to each slot
-- =====================================

-- Slot layout: which side of the character model each slot is on
local SLOT_SIDE = {
    CharacterHeadSlot           = "LEFT",
    CharacterNeckSlot           = "LEFT",
    CharacterShoulderSlot       = "LEFT",
    CharacterBackSlot           = "LEFT",
    CharacterChestSlot          = "LEFT",
    CharacterShirtSlot          = "LEFT",
    CharacterTabardSlot         = "LEFT",
    CharacterWristSlot          = "LEFT",
    CharacterHandsSlot          = "RIGHT",
    CharacterWaistSlot          = "RIGHT",
    CharacterLegsSlot           = "RIGHT",
    CharacterFeetSlot           = "RIGHT",
    CharacterFinger0Slot        = "RIGHT",
    CharacterFinger1Slot        = "RIGHT",
    CharacterTrinket0Slot       = "RIGHT",
    CharacterTrinket1Slot       = "RIGHT",
    CharacterMainHandSlot       = "BOTTOM_LEFT",
    CharacterSecondaryHandSlot  = "BOTTOM_RIGHT",
}

-- Quality colors
local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 }, -- Poor
    [1] = { 1.00, 1.00, 1.00 }, -- Common
    [2] = { 0.12, 1.00, 0.00 }, -- Uncommon
    [3] = { 0.00, 0.44, 0.87 }, -- Rare
    [4] = { 0.64, 0.21, 0.93 }, -- Epic
    [5] = { 1.00, 0.50, 0.00 }, -- Legendary
    [6] = { 0.90, 0.80, 0.50 }, -- Artifact
    [7] = { 0.00, 0.80, 1.00 }, -- Heirloom
    [8] = { 0.00, 0.80, 1.00 }, -- WoW Token
}

-- Enchantable slots per expansion (based on ChonkyCharacterSheet data)
-- TWW: Chest(5), Legs(7), Feet(8), Wrist(9), Back(15), Rings(11,12), Weapons(16,17)
-- Midnight: Head(1), Shoulder(3), Chest(5), Legs(7), Feet(8), Rings(11,12), Weapons(16,17)
--   Removed in Midnight: Wrist(9), Back(15)
--   Added in Midnight: Head(1), Shoulder(3)

local ENCHANTABLE_SLOTS_TWW = {
    CharacterChestSlot          = true,  -- 5
    CharacterLegsSlot           = true,  -- 7
    CharacterFeetSlot           = true,  -- 8
    CharacterWristSlot          = true,  -- 9
    CharacterBackSlot           = true,  -- 15
    CharacterFinger0Slot        = true,  -- 11
    CharacterFinger1Slot        = true,  -- 12
    CharacterMainHandSlot       = true,  -- 16
    CharacterSecondaryHandSlot  = true,  -- 17
}

local ENCHANTABLE_SLOTS_MIDNIGHT = {
    CharacterHeadSlot           = true,  -- 1
    CharacterShoulderSlot       = true,  -- 3
    CharacterChestSlot          = true,  -- 5
    CharacterLegsSlot           = true,  -- 7
    CharacterFeetSlot           = true,  -- 8
    CharacterFinger0Slot        = true,  -- 11
    CharacterFinger1Slot        = true,  -- 12
    CharacterMainHandSlot       = true,  -- 16
    CharacterSecondaryHandSlot  = true,  -- 17
}

local function IsEnchantableSlot(slotName)
    if GetSettings().midnightEnchants then
        return ENCHANTABLE_SLOTS_MIDNIGHT[slotName] or false
    else
        return ENCHANTABLE_SLOTS_TWW[slotName] or false
    end
end

-- Hidden tooltip for scanning
local scanTip = CreateFrame("GameTooltip", "TomoModItemScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local itemInfoFrames = {} -- slotName -> overlay frame

local function TruncateText(text, maxLen)
    if not text then return "" end
    if #text <= maxLen then return text end
    return text:sub(1, maxLen - 1) .. "..."
end

local function GetUpgradeTrackFromTooltip(slotID)
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", slotID)

    local upgradeLine = nil
    local enchantLine = nil

    -- Use WoW's global ENCHANTED_TOOLTIP_LINE to match enchant lines
    -- EN: "Enchanted: %s" → "Enchanted: (.+)"
    -- FR: "Enchanté : %s" → "Enchanté : (.+)"
    local enchantPattern = nil
    if ENCHANTED_TOOLTIP_LINE then
        enchantPattern = ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)")
    end

    for i = 2, scanTip:NumLines() do
        local left = _G["TomoModItemScanTipTextLeft" .. i]
        if left then
            local text = left:GetText()
            if text then
                -- Upgrade track patterns (EN + FR)
                if text:match("%d+/%d+") and (
                    text:match("Veteran") or text:match("V\195\169t\195\169ran") or
                    text:match("Champion") or
                    text:match("Hero") or text:match("H\195\169ros") or
                    text:match("Myth") or text:match("Mythe") or
                    text:match("Explorer") or text:match("Explorateur") or
                    text:match("Adventurer") or text:match("Aventurier") or
                    text:match("Wyrm") or text:match("Aspect")
                ) then
                    upgradeLine = text
                end

                -- Enchant detection via ENCHANTED_TOOLTIP_LINE global
                if enchantPattern then
                    local enchText = text:match(enchantPattern)
                    if enchText then
                        -- Strip atlas/quality icons from the text
                        enchText = enchText:gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                        enchantLine = enchText
                    end
                end
            end
        end
    end

    return upgradeLine, enchantLine
end

local function CreateItemInfoOverlay(slot, slotName)
    local side = SLOT_SIDE[slotName]
    if not side then return end

    local isBottom = (side == "BOTTOM_LEFT" or side == "BOTTOM_RIGHT")

    local frame = CreateFrame("Frame", nil, slot)
    frame:SetSize(140, isBottom and 14 or 24)
    frame:SetFrameLevel(slot:GetFrameLevel() + 5)

    -- Position based on slot side
    if side == "LEFT" then
        frame:SetPoint("LEFT", slot, "RIGHT", 4, 0)
        frame.align = "LEFT"
    elseif side == "RIGHT" then
        frame:SetPoint("RIGHT", slot, "LEFT", -4, 0)
        frame.align = "RIGHT"
    elseif side == "BOTTOM_LEFT" then
        frame:SetPoint("BOTTOMLEFT", slot, "TOPLEFT", 0, 2)
        frame.align = "LEFT"
        frame.anchorAbove = true
    elseif side == "BOTTOM_RIGHT" then
        frame:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 0, -2)
        frame.align = "LEFT"
        frame.anchorAbove = false
    end

    local justifyH = frame.align
    frame.isBottom = isBottom

    -- Line 1: ilvl (for bottom slots, enchant goes on same line)
    local infoText = frame:CreateFontString(nil, "OVERLAY")
    infoText:SetFont(ADDON_FONT_BOLD, 10, "OUTLINE")
    infoText:SetJustifyH(justifyH)
    infoText:SetWordWrap(false)
    infoText:SetSize(140, 12)
    if isBottom then
        -- Weapon slots
        if frame.anchorAbove then
            -- Left weapon: frame above slot, text at bottom (near slot)
            infoText:SetPoint("BOTTOMLEFT", 0, 0)
        else
            -- Right weapon: frame below slot, text at top (near slot)
            infoText:SetPoint("TOPLEFT", 0, 0)
        end
    else
        if justifyH == "LEFT" then
            infoText:SetPoint("TOPLEFT", 0, 0)
        else
            infoText:SetPoint("TOPRIGHT", 0, 0)
        end
    end
    frame.infoText = infoText

    -- Line 2: Enchant/stat bonus (only for non-bottom slots)
    if not isBottom then
        local statText = frame:CreateFontString(nil, "OVERLAY")
        statText:SetFont(ADDON_FONT, 8, "OUTLINE")
        statText:SetJustifyH(justifyH)
        statText:SetWordWrap(false)
        statText:SetSize(140, 10)
        statText:SetTextColor(0.0, 0.82, 0.62, 0.9)
        if justifyH == "LEFT" then
            statText:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -1)
        else
            statText:SetPoint("TOPRIGHT", infoText, "BOTTOMRIGHT", 0, -1)
        end
        frame.statText = statText
    end

    frame:Hide()
    itemInfoFrames[slotName] = frame
    return frame
end

local function UpdateItemInfoOverlay(slot, slotName)
    local frame = itemInfoFrames[slotName]
    if not frame then
        frame = CreateItemInfoOverlay(slot, slotName)
    end
    if not frame then return end

    local slotID = slot.slotID or slot:GetID()
    if not slotID or slotID == 0 then
        frame:Hide()
        return
    end

    local itemLink = GetInventoryItemLink("player", slotID)
    if not itemLink then
        frame:Hide()
        return
    end

    -- Get item info (with TWW API fallbacks)
    local itemName, _, itemQuality
    if C_Item and C_Item.GetItemInfo then
        itemName, _, itemQuality = C_Item.GetItemInfo(itemLink)
    end
    if not itemName and GetItemInfo then
        itemName, _, itemQuality = GetItemInfo(itemLink)
    end
    if not itemName then
        -- Item not cached yet
        frame:Hide()
        return
    end

    -- Get ilvl (with fallbacks)
    local effectiveILvl
    if GetDetailedItemLevelInfo then
        effectiveILvl = GetDetailedItemLevelInfo(itemLink)
    elseif C_Item and C_Item.GetDetailedItemLevelInfo then
        effectiveILvl = C_Item.GetDetailedItemLevelInfo(itemLink)
    end
    if not effectiveILvl then
        pcall(function()
            effectiveILvl = C_Item.GetCurrentItemLevel(ItemLocation:CreateFromEquipmentSlot(slotID))
        end)
    end

    -- Get upgrade track + enchant from tooltip scan
    local upgradeTrack, enchantInfo = GetUpgradeTrackFromTooltip(slotID)

    -- Quality color for ilvl
    local qColor = QUALITY_COLORS[itemQuality] or { 1, 1, 1 }

    -- Build ilvl string colored by quality
    -- Skip ilvl 1 items (shirt, tabard)
    local infoStr = ""
    if effectiveILvl and effectiveILvl > 1 then
        local hexColor = string.format("ff%02x%02x%02x", qColor[1]*255, qColor[2]*255, qColor[3]*255)
        infoStr = "|c" .. hexColor .. effectiveILvl .. "|r"
    end
    frame.infoText:SetText(infoStr)

    -- If no meaningful ilvl, hide the whole overlay
    if not effectiveILvl or effectiveILvl <= 1 then
        frame:Hide()
        return
    end

    -- Enchant/stat — only for enchantable slots
    local canEnchant = IsEnchantableSlot(slotName)
    if canEnchant and enchantInfo then
        -- Clean up enchant text for compact display
        local short = enchantInfo
        -- Strip French filler words
        short = short:gsub("Score de ", "")
        short = short:gsub(" à la ", " ")
        short = short:gsub(" à l'", " ")
        short = short:gsub(" au ", " ")
        short = short:gsub(" de ", " ")
        short = short:gsub(" du ", " ")
        short = short:gsub(" des ", " ")
        short = short:gsub(" to ", " ")
        -- Strip English filler
        short = short:gsub(" and ", " & ")
        short = short:gsub(" et ", " & ")
        -- Trim whitespace
        short = short:match("^%s*(.-)%s*$") or short
        short = TruncateText(short, frame.isBottom and 20 or 22)

        if frame.isBottom then
            -- Weapons: append enchant to ilvl on same line
            local current = frame.infoText:GetText() or ""
            frame.infoText:SetText(current .. " |cff00d1a0" .. short .. "|r")
        elseif frame.statText then
            frame.statText:SetText(short)
            frame.statText:Show()
        end
    else
        if frame.statText then
            frame.statText:SetText("")
            frame.statText:Hide()
        end
    end

    frame:Show()
end

local function UpdateAllItemInfoOverlays()
    if not GetSettings().showItemInfo then
        -- Hide all overlays
        for _, frame in pairs(itemInfoFrames) do
            frame:Hide()
        end
        return
    end

    for slotName, _ in pairs(SLOT_SIDE) do
        local slot = _G[slotName]
        if slot then
            UpdateItemInfoOverlay(slot, slotName)
        end
    end
end

-- =====================================
-- SKIN: CHARACTER FRAME (main)
-- =====================================

local function SkinCharacterFrame()
    local CharacterFrame = _G.CharacterFrame
    if not CharacterFrame then return end

    -- ===== Main frame: PortraitFrame template =====
    SkinPortraitFrame(CharacterFrame)

    -- ===== Inset frames =====
    local insetNames = {
        "CharacterFrameInset",
        "CharacterFrameInsetRight",
    }
    for _, iname in ipairs(insetNames) do
        local f = _G[iname]
        if f then
            StripTextures(f)
            KillInsetBorders(f)
            KillNineSlice(f)
        end
    end

    -- Inset background for Rep/Currency tabs
    if _G.CharacterFrameInset then
        local insetBg = _G.CharacterFrameInset:CreateTexture(nil, "BACKGROUND")
        insetBg:SetAllPoints()
        insetBg:SetColorTexture(0.04, 0.04, 0.06, 0.6)
        insetBg:Hide()
        _G.CharacterFrameInset._tomoInsetBg = insetBg
    end

    -- ===== Strip decorative frames =====
    local stripNames = {
        "CharacterModelScene",
        "CharacterStatsPane",
        "PaperDollSidebarTabs",
    }
    for _, sname in ipairs(stripNames) do
        local f = _G[sname]
        if f then StripTextures(f) end
    end

    -- ===== Model Scene =====
    local modelScene = _G.CharacterModelScene
    if modelScene then
        if _G.CharacterModelFrameBackgroundOverlay then
            _G.CharacterModelFrameBackgroundOverlay:SetColorTexture(0, 0, 0)
        end
        ApplyBackdrop(modelScene, { 0.04, 0.04, 0.06, 1 }, { 0.10, 0.10, 0.12, 1 })

        for _, corner in ipairs({ "TopLeft", "TopRight", "BotLeft", "BotRight" }) do
            local bg = _G["CharacterModelFrameBackground" .. corner]
            if bg then
                bg:SetDesaturated(false)
                hooksecurefunc(bg, "SetDesaturated", function(self, value)
                    if value then self:SetDesaturated(false) end
                end)
            end
        end
    end

    -- ===== Character Name & Level =====
    if _G.CharacterNameText then
        _G.CharacterNameText:SetFont(ADDON_FONT_BOLD, 13, "OUTLINE")
    end
    if _G.CharacterLevelText then
        _G.CharacterLevelText:SetFont(ADDON_FONT, 11, "OUTLINE")
    end

    -- ===== Item Slots =====
    if _G.PaperDollItemsFrame then
        for _, child in pairs({ _G.PaperDollItemsFrame:GetChildren() }) do
            if child:IsObjectType("Button") or child:IsObjectType("ItemButton") then
                SkinItemSlot(child)
            end
        end
    end

    -- Hook slot updates for highlight fix
    if _G.PaperDollItemSlotButton_Update then
        hooksecurefunc("PaperDollItemSlotButton_Update", function(slot)
            local hl = slot and slot.GetHighlightTexture and slot:GetHighlightTexture()
            if hl and skinnedFrames[slot] then
                hl:SetColorTexture(unpack(HIGHLIGHT_COLOR))
                hl:ClearAllPoints()
                hl:SetPoint("TOPLEFT", 1, -1)
                hl:SetPoint("BOTTOMRIGHT", -1, 1)
            end
        end)
    end

    -- ===== Item Info Overlays =====
    if GetSettings().showItemInfo then
        -- Initial update
        UpdateAllItemInfoOverlays()

        -- Hook into item updates
        if _G.PaperDollItemSlotButton_Update then
            hooksecurefunc("PaperDollItemSlotButton_Update", function(slot)
                local slotName = slot and slot:GetName()
                if slotName and SLOT_SIDE[slotName] then
                    UpdateItemInfoOverlay(slot, slotName)
                end
            end)
        end

        -- Also update on PLAYER_EQUIPMENT_CHANGED
        local itemInfoUpdater = CreateFrame("Frame")
        itemInfoUpdater:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        itemInfoUpdater:RegisterEvent("ITEM_DATA_LOAD_RESULT")
        itemInfoUpdater:SetScript("OnEvent", function(self, event)
            if CharacterFrame:IsShown() then
                C_Timer.After(0.1, UpdateAllItemInfoOverlays)
            end
        end)

        -- Update when character frame shows
        CharacterFrame:HookScript("OnShow", function()
            C_Timer.After(0.2, UpdateAllItemInfoOverlays)
        end)
    end

    -- ===== Stats Pane =====
    if _G.CharacterStatsPane then
        local CSP = _G.CharacterStatsPane

        if CSP.ItemLevelFrame then
            if CSP.ItemLevelFrame.Value then
                CSP.ItemLevelFrame.Value:SetFont(ADDON_FONT_BOLD, 20, "OUTLINE")
            end
            ColorizeStatPane(CSP.ItemLevelFrame)
        end

        for _, cat in ipairs({ "EnhancementsCategory", "ItemLevelCategory", "AttributesCategory" }) do
            if CSP[cat] then SkinStatsCategory(cat) end
        end

        if _G.PaperDollFrame_UpdateStats then
            hooksecurefunc("PaperDollFrame_UpdateStats", UpdateStatGradients)
        end
    end

    -- ===== Bottom Tabs (Personnage, Rep., Monnaies) =====
    local i = 1
    local prevTab
    local tab = _G["CharacterFrameTab" .. i]
    while tab do
        SkinTab(tab)
        tab:ClearAllPoints()
        if prevTab then
            tab:SetPoint("TOPLEFT", prevTab, "TOPRIGHT", 2, 0)
        else
            tab:SetPoint("TOPLEFT", CharacterFrame, "BOTTOMLEFT", 2, 2)
        end
        prevTab = tab
        i = i + 1
        tab = _G["CharacterFrameTab" .. i]
    end

    -- ===== Sidebar Tabs (Stats/Titles/Equipment) =====
    SkinSidebarTabs()
    if _G.PaperDollFrame_UpdateSidebarTabs then
        hooksecurefunc("PaperDollFrame_UpdateSidebarTabs", SkinSidebarTabs)
    end

    -- ===== Equipment Flyout =====
    if _G.EquipmentFlyoutFrameHighlight then StripTextures(_G.EquipmentFlyoutFrameHighlight) end
    if _G.EquipmentFlyoutFrameButtons then
        if _G.EquipmentFlyoutFrameButtons.bg1 then
            _G.EquipmentFlyoutFrameButtons.bg1:SetAlpha(0)
        end
        _G.EquipmentFlyoutFrameButtons:DisableDrawLayer("ARTWORK")
    end
    if _G.EquipmentFlyout_UpdateItems then
        hooksecurefunc("EquipmentFlyout_UpdateItems", SkinEquipmentFlyoutItems)
    end

    -- ===== Equipment Manager Pane =====
    if _G.PaperDollFrame and _G.PaperDollFrame.EquipmentManagerPane then
        local eqScroll = _G.PaperDollFrame.EquipmentManagerPane.ScrollBox
        if eqScroll then
            hooksecurefunc(eqScroll, "Update", UpdateEquipmentManagerSkins)
        end
    end

    -- ===== Title Manager Pane =====
    if _G.PaperDollFrame and _G.PaperDollFrame.TitleManagerPane then
        local titleScroll = _G.PaperDollFrame.TitleManagerPane.ScrollBox
        if titleScroll then
            hooksecurefunc(titleScroll, "Update", UpdateTitleSkins)
        end
    end

    -- ===== Equip/Save Set Buttons =====
    if _G.PaperDollFrameEquipSet then
        StripTextures(_G.PaperDollFrameEquipSet)
        ApplyBackdrop(_G.PaperDollFrameEquipSet, { 0.10, 0.10, 0.13, 1 }, ACCENT_COLOR)
    end
    if _G.PaperDollFrameSaveSet then
        StripTextures(_G.PaperDollFrameSaveSet)
        ApplyBackdrop(_G.PaperDollFrameSaveSet, { 0.10, 0.10, 0.13, 1 }, ACCENT_COLOR)
    end

    -- ===== Track sub-frame changes (inset visibility) =====
    if _G.CharacterFrameMixin and _G.CharacterFrameMixin.ShowSubFrame then
        hooksecurefunc(_G.CharacterFrameMixin, "ShowSubFrame", UpdateCharacterInset)
    end

    -- ===== Apply Scale =====
    local scale = GetSettings().scale or 1.0
    if scale ~= 1.0 then
        CharacterFrame:SetScale(scale)
    end
end

-- =====================================
-- SKIN: REPUTATION FRAME
-- =====================================

local function SkinReputationFrame()
    local RepFrame = _G.ReputationFrame
    if not RepFrame then return end

    StripTextures(RepFrame)

    local detail = RepFrame.ReputationDetailFrame
    if detail then
        StripTextures(detail)
        KillNineSlice(detail)
        ApplyBackdrop(detail, BACKDROP_COLOR, BACKDROP_BORDER)
    end

    if RepFrame.ScrollBox then
        hooksecurefunc(RepFrame.ScrollBox, "Update", UpdateReputationSkins)
    end
end

-- =====================================
-- SKIN: CURRENCY / TOKEN FRAME
-- =====================================

local function SkinCurrencyFrame()
    local TokenFrame = _G.TokenFrame
    if not TokenFrame then return end

    if _G.TokenFramePopup then
        StripTextures(_G.TokenFramePopup)
        KillNineSlice(_G.TokenFramePopup)
        ApplyBackdrop(_G.TokenFramePopup, BACKDROP_COLOR, BACKDROP_BORDER)
        _G.TokenFramePopup:ClearAllPoints()
        _G.TokenFramePopup:SetPoint("TOPLEFT", TokenFrame, "TOPRIGHT", 3, -28)
    end

    if _G.CurrencyTransferLog then
        StripTextures(_G.CurrencyTransferLog)
        KillNineSlice(_G.CurrencyTransferLog)
        KillPortrait(_G.CurrencyTransferLog)
        ApplyBackdrop(_G.CurrencyTransferLog, BACKDROP_COLOR, BACKDROP_BORDER)
    end

    local ctMenu = _G.CurrencyTransferMenu
    if ctMenu then
        StripTextures(ctMenu)
        KillNineSlice(ctMenu)
        ApplyBackdrop(ctMenu, BACKDROP_COLOR, BACKDROP_BORDER)
    end

    if TokenFrame.ScrollBox then
        hooksecurefunc(TokenFrame.ScrollBox, "Update", UpdateCurrencySkins)
    end
end

-- =====================================
-- SKIN: INSPECT FRAME
-- =====================================

local function SkinInspectFrame()
    if inspectSkinned then return end

    local InspectFrame = _G.InspectFrame
    if not InspectFrame then return end

    SkinPortraitFrame(InspectFrame)

    local modelFrame = _G.InspectModelFrame
    if modelFrame then
        StripTextures(modelFrame)
        ApplyBackdrop(modelFrame, { 0.04, 0.04, 0.06, 1 }, { 0.10, 0.10, 0.12, 1 })

        if modelFrame.BackgroundOverlay then
            modelFrame.BackgroundOverlay:SetColorTexture(0, 0, 0)
        end

        for _, corner in ipairs({ "TopLeft", "TopRight", "BotLeft", "BotRight" }) do
            local bg = _G["InspectModelFrameBackground" .. corner]
            if bg then
                bg:SetDesaturated(false)
                hooksecurefunc(bg, "SetDesaturated", function(self, value)
                    if value then self:SetDesaturated(false) end
                end)
            end
        end

        local borderPieces = {
            "InspectModelFrameBorderTopLeft", "InspectModelFrameBorderTopRight",
            "InspectModelFrameBorderTop", "InspectModelFrameBorderLeft",
            "InspectModelFrameBorderRight", "InspectModelFrameBorderBottomLeft",
            "InspectModelFrameBorderBottomRight", "InspectModelFrameBorderBottom",
            "InspectModelFrameBorderBottom2",
        }
        for _, bname in ipairs(borderPieces) do
            local piece = _G[bname]
            if piece then piece:SetAlpha(0); piece:Hide() end
        end
    end

    if _G.InspectPaperDollItemsFrame then
        for _, child in pairs({ _G.InspectPaperDollItemsFrame:GetChildren() }) do
            if (child:IsObjectType("Button") or child:IsObjectType("ItemButton")) and child.icon then
                StripSlotTextures(child)
                ApplyBackdrop(child, SLOT_BG, SLOT_BORDER)

                child.icon:SetAlpha(1)
                child.icon:Show()
                child.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                child.icon:ClearAllPoints()
                child.icon:SetPoint("TOPLEFT", 1, -1)
                child.icon:SetPoint("BOTTOMRIGHT", -1, 1)

                if child.IconBorder then
                    child.IconBorder:SetAlpha(0)
                    hooksecurefunc(child.IconBorder, "SetVertexColor", function(self, r, g, b)
                        local parent = self:GetParent()
                        if parent and parent.SetBackdropBorderColor then
                            parent:SetBackdropBorderColor(r, g, b, 1)
                        end
                    end)
                end
            end
        end
    end

    if _G.InspectPaperDollFrame and _G.InspectPaperDollFrame.ViewButton then
        StripTextures(_G.InspectPaperDollFrame.ViewButton)
        ApplyBackdrop(_G.InspectPaperDollFrame.ViewButton, { 0.10, 0.10, 0.13, 1 }, ACCENT_COLOR)
    end

    if _G.InspectPaperDollItemsFrame and _G.InspectPaperDollItemsFrame.InspectTalents then
        StripTextures(_G.InspectPaperDollItemsFrame.InspectTalents)
        ApplyBackdrop(_G.InspectPaperDollItemsFrame.InspectTalents, { 0.10, 0.10, 0.13, 1 }, ACCENT_COLOR)
        _G.InspectPaperDollItemsFrame.InspectTalents:ClearAllPoints()
        _G.InspectPaperDollItemsFrame.InspectTalents:SetPoint("TOPRIGHT", InspectFrame, "BOTTOMRIGHT", 0, -1)
    end

    local pvpFrame = _G.InspectPVPFrame
    if pvpFrame then
        for pvpI = 1, 3 do
            local slot = pvpFrame["TalentSlot" .. pvpI]
            if slot then
                StripTextures(slot)
                if slot.Border then slot.Border:Hide() end
                if slot.Texture then slot.Texture:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
            end
        end
        if pvpFrame.BG then pvpFrame.BG:SetAlpha(0) end
    end

    if _G.InspectGuildFrameBG then _G.InspectGuildFrameBG:SetAlpha(0) end

    local tabIdx = 1
    local prevInspTab
    local inspTab = _G["InspectFrameTab" .. tabIdx]
    while inspTab do
        SkinTab(inspTab)
        inspTab:ClearAllPoints()
        if tabIdx == 1 then
            inspTab:SetPoint("TOPLEFT", InspectFrame, "BOTTOMLEFT", 2, 2)
        elseif prevInspTab then
            inspTab:SetPoint("TOPLEFT", prevInspTab, "TOPRIGHT", 2, 0)
        end
        prevInspTab = inspTab
        tabIdx = tabIdx + 1
        inspTab = _G["InspectFrameTab" .. tabIdx]
    end

    inspectSkinned = true

    -- ===== Inspect iLvl Display =====
    local ilvlFrame = CreateFrame("Frame", nil, InspectFrame)
    ilvlFrame:SetSize(120, 40)
    ilvlFrame:SetPoint("TOP", InspectFrame, "TOP", 0, -62)
    ilvlFrame:SetFrameLevel(InspectFrame:GetFrameLevel() + 10)

    local ilvlLabel = ilvlFrame:CreateFontString(nil, "OVERLAY")
    ilvlLabel:SetFont(ADDON_FONT, 10, "OUTLINE")
    ilvlLabel:SetPoint("TOP", 0, 0)
    ilvlLabel:SetTextColor(0.7, 0.7, 0.7)
    ilvlLabel:SetText("iLvl")

    local ilvlValue = ilvlFrame:CreateFontString(nil, "OVERLAY")
    ilvlValue:SetFont(ADDON_FONT_BOLD, 22, "OUTLINE")
    ilvlValue:SetPoint("TOP", ilvlLabel, "BOTTOM", 0, -2)
    ilvlValue:SetTextColor(1, 1, 1)
    ilvlFrame.value = ilvlValue
    ilvlFrame:Hide()

    -- Function to calculate inspected unit's ilvl
    local INSPECT_SLOTS = {
        1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17
    } -- Skip shirt(4) and tabard(19)

    local function UpdateInspectIlvl()
        local unit = InspectFrame.unit or "target"
        if not UnitExists(unit) then
            ilvlFrame:Hide()
            return
        end

        local totalIlvl = 0
        local numItems = 0

        for _, slotID in ipairs(INSPECT_SLOTS) do
            local itemLink = GetInventoryItemLink(unit, slotID)
            if itemLink then
                local effectiveILvl
                if GetDetailedItemLevelInfo then
                    effectiveILvl = GetDetailedItemLevelInfo(itemLink)
                elseif C_Item and C_Item.GetDetailedItemLevelInfo then
                    effectiveILvl = C_Item.GetDetailedItemLevelInfo(itemLink)
                end
                if effectiveILvl and effectiveILvl > 1 then
                    totalIlvl = totalIlvl + effectiveILvl
                    numItems = numItems + 1
                end
            end
        end

        if numItems > 0 then
            local avg = math.floor(totalIlvl / numItems + 0.5)
            ilvlValue:SetText(avg)

            -- Color by ilvl range
            if avg >= 639 then
                ilvlValue:SetTextColor(1.0, 0.5, 0.0) -- orange (myth)
            elseif avg >= 626 then
                ilvlValue:SetTextColor(0.64, 0.21, 0.93) -- purple (hero)
            elseif avg >= 610 then
                ilvlValue:SetTextColor(0.0, 0.44, 0.87) -- blue (champion)
            elseif avg >= 584 then
                ilvlValue:SetTextColor(0.12, 1.0, 0.0) -- green (veteran)
            else
                ilvlValue:SetTextColor(1, 1, 1)
            end

            ilvlFrame:Show()
        else
            ilvlFrame:Hide()
        end
    end

    -- Hook inspect updates
    local inspectUpdater = CreateFrame("Frame")
    inspectUpdater:RegisterEvent("INSPECT_READY")
    inspectUpdater:SetScript("OnEvent", function()
        if InspectFrame and InspectFrame:IsShown() then
            C_Timer.After(0.3, UpdateInspectIlvl)
        end
    end)
    InspectFrame:HookScript("OnShow", function()
        C_Timer.After(0.5, UpdateInspectIlvl)
    end)
    InspectFrame:HookScript("OnHide", function()
        ilvlFrame:Hide()
    end)

    -- Apply scale to Inspect too
    local scale = GetSettings().scale or 1.0
    if scale ~= 1.0 then
        InspectFrame:SetScale(scale)
    end
end

-- =====================================
-- INITIALIZE
-- =====================================

function CS.Initialize()
    if isInitialized then return end
    if not IsEnabled() then return end

    local s = GetSettings()

    if s.skinCharacter then
        SkinCharacterFrame()
        SkinReputationFrame()
        SkinCurrencyFrame()
    end

    if s.skinInspect then
        if C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then
            SkinInspectFrame()
        else
            local loader = CreateFrame("Frame")
            loader:RegisterEvent("ADDON_LOADED")
            loader:SetScript("OnEvent", function(self, event, addon)
                if addon == "Blizzard_InspectUI" then
                    if IsEnabled() and GetSettings().skinInspect then
                        SkinInspectFrame()
                    end
                    self:UnregisterEvent("ADDON_LOADED")
                end
            end)
        end
    end

    isInitialized = true
    local U = TomoMod_Utils
    if U then U.Debug("CharacterSkin initialized") end
end

-- =====================================
-- APPLY (config changes — requires reload)
-- =====================================

function CS.ApplySettings()
    if isInitialized then
        -- Refresh item info overlays (handles midnightEnchants toggle)
        if next(itemInfoFrames) then
            UpdateAllItemInfoOverlays()
        end
        print("|cff0cd29fTomoMod|r " .. (L["msg_char_skin_reload"] or "Character Skin: /reload to apply changes."))
    end
end

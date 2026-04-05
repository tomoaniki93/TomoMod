-- =====================================
-- GameMenuSkin.lua
-- Skins the Blizzard Escape / Game Menu
-- Dark/teal themed UI consistent with TomoMod aesthetic
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_GameMenuSkin = TomoMod_GameMenuSkin or {}
local GMS = TomoMod_GameMenuSkin

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local isInitialized = false
local isHooked      = false

-- Palette (matches TomoMod theme)
local ACCENT       = { 0.047, 0.824, 0.624 }
local BG_COLOR     = { 0.06, 0.06, 0.08, 0.98 }
local BORDER_COLOR = { 0.047, 0.824, 0.624, 0.35 }
local TEXT_COLOR   = { 0.88, 0.90, 0.92, 1 }
local TEXT_DIM     = { 0.55, 0.55, 0.60, 1 }
local SEPARATOR    = { 0.15, 0.15, 0.18, 1 }

-- Button states
local BTN_NORMAL   = { 0.09, 0.09, 0.12, 1 }
local BTN_HOVER    = { 0.047, 0.824, 0.624, 0.12 }
local BTN_PRESSED  = { 0.047, 0.824, 0.624, 0.22 }
local BTN_BORDER   = { 0.18, 0.18, 0.22, 0.6 }
local BTN_BORDER_H = { 0.047, 0.824, 0.624, 0.7 }

-- Dedup
local skinnedFrames  = setmetatable({}, { __mode = "k" })
local skinnedButtons = setmetatable({}, { __mode = "k" })

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.gameMenuSkin or {}
end

local function IsEnabled()
    return S().enabled
end

-- =====================================
-- HELPERS
-- =====================================

-- Aggressively kill all textures on a frame, including nested sub-frames
local function NukeTextures(frame, depth)
    if not frame then return end
    depth = depth or 0
    if depth > 3 then return end -- safety

    -- Kill all texture regions on this frame
    if frame.GetRegions then
        for _, region in pairs({ frame:GetRegions() }) do
            if region:IsObjectType("Texture") then
                region:SetTexture(nil)
                region:SetAtlas("")
                region:SetColorTexture(0, 0, 0, 0)
                region:SetAlpha(0)
                region:Hide()
                region:SetSize(0.001, 0.001)
            end
        end
    end

    -- Recurse into named sub-elements that Blizzard uses
    local subs = { "NineSlice", "Border", "Bg", "Background", "Left", "Right",
                   "Middle", "Center", "TopLeft", "TopRight", "BottomLeft",
                   "BottomRight", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }
    for _, key in ipairs(subs) do
        local child = frame[key]
        if child then
            if child.IsObjectType and child:IsObjectType("Texture") then
                child:SetTexture(nil)
                child:SetAtlas("")
                child:SetColorTexture(0, 0, 0, 0)
                child:SetAlpha(0)
                child:Hide()
                child:SetSize(0.001, 0.001)
            elseif child.GetRegions then
                NukeTextures(child, depth + 1)
                child:SetAlpha(0)
                child:Hide()
            end
        end
    end

    -- Also recurse into unnamed child frames
    if frame.GetChildren then
        for _, child in pairs({ frame:GetChildren() }) do
            local name = child:GetName()
            -- Only recurse into decorative sub-frames, not buttons
            if child.GetObjectType and child:GetObjectType() ~= "Button" then
                NukeTextures(child, depth + 1)
            end
        end
    end
end

-- Prevent Blizzard from re-applying textures via hooks
local function LockoutTextures(button)
    -- Kill and permanently disable each standard button texture
    local function KillButtonTex(getTex, hookMethod)
        local tex = getTex and getTex(button)
        if tex then
            tex:SetAlpha(0)
            tex:Hide()
            tex:SetTexture(nil)
            tex:SetSize(0.001, 0.001)
            -- Hook Show on the texture object itself so Blizzard can't re-show it
            if tex.Show and not tex._tmLocked then
                tex._tmLocked = true
                hooksecurefunc(tex, "Show", function(self) self:Hide(); self:SetAlpha(0) end)
                hooksecurefunc(tex, "SetAlpha", function(self) if self._tmLocked then self:Hide() end end)
            end
        end
        -- Hook the setter on the button so new textures get killed too
        if button[hookMethod] then
            hooksecurefunc(button, hookMethod, function(self)
                local t = getTex(self)
                if t then t:SetAlpha(0); t:Hide(); t:SetTexture(nil) end
            end)
        end
    end

    KillButtonTex(button.GetNormalTexture, "SetNormalTexture")
    KillButtonTex(button.GetHighlightTexture, "SetHighlightTexture")
    KillButtonTex(button.GetPushedTexture, "SetPushedTexture")
    KillButtonTex(button.GetDisabledTexture, "SetDisabledTexture")

    -- Also catch SetHighlightAtlas (TWW uses this on some buttons)
    if button.SetHighlightAtlas and not button._tmAtlasHooked then
        button._tmAtlasHooked = true
        hooksecurefunc(button, "SetHighlightAtlas", function(self)
            local tex = self:GetHighlightTexture()
            if tex then tex:SetAlpha(0); tex:Hide() end
        end)
    end
    -- Catch SetNormalAtlas too
    if button.SetNormalAtlas and not button._tmNormalAtlasHooked then
        button._tmNormalAtlasHooked = true
        hooksecurefunc(button, "SetNormalAtlas", function(self)
            local tex = self:GetNormalTexture()
            if tex then tex:SetAlpha(0); tex:Hide() end
        end)
    end
end

-- Create a rounded-look border set (1px lines with accent glow potential)
local function CreateBorders(parent, r, g, b, a)
    r = r or BTN_BORDER[1]
    g = g or BTN_BORDER[2]
    b = b or BTN_BORDER[3]
    a = a or BTN_BORDER[4]

    local borders = {}

    local top = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    top:SetColorTexture(r, g, b, a)
    top:SetHeight(1)
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    borders.top = top

    local bot = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    bot:SetColorTexture(r, g, b, a)
    bot:SetHeight(1)
    bot:SetPoint("BOTTOMLEFT")
    bot:SetPoint("BOTTOMRIGHT")
    borders.bottom = bot

    local lft = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    lft:SetColorTexture(r, g, b, a)
    lft:SetWidth(1)
    lft:SetPoint("TOPLEFT")
    lft:SetPoint("BOTTOMLEFT")
    borders.left = lft

    local rgt = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    rgt:SetColorTexture(r, g, b, a)
    rgt:SetWidth(1)
    rgt:SetPoint("TOPRIGHT")
    rgt:SetPoint("BOTTOMRIGHT")
    borders.right = rgt

    return borders
end

local function SetBorderColor(borders, r, g, b, a)
    if not borders then return end
    for _, t in pairs(borders) do
        t:SetColorTexture(r, g, b, a)
    end
end

-- =====================================
-- ACCENT STRIP (top teal glow line)
-- =====================================

local function CreateAccentStrip(parent)
    local strip = parent:CreateTexture(nil, "OVERLAY", nil, 6)
    strip:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    strip:SetHeight(2)
    strip:SetPoint("TOPLEFT", 1, -1)
    strip:SetPoint("TOPRIGHT", -1, -1)
    return strip
end

-- =====================================
-- SKIN A BUTTON
-- =====================================

local function SkinButton(button)
    if not button or skinnedButtons[button] then return end
    if not button.GetObjectType or button:GetObjectType() ~= "Button" then return end

    skinnedButtons[button] = true

    -- =====================
    -- Phase 1: DESTROY all Blizzard visuals
    -- =====================

    -- Kill standard button textures
    local normalTex = button:GetNormalTexture()
    if normalTex then normalTex:SetAlpha(0); normalTex:Hide(); normalTex:SetTexture(nil) end

    local highlightTex = button:GetHighlightTexture()
    if highlightTex then highlightTex:SetAlpha(0); highlightTex:Hide(); highlightTex:SetTexture(nil) end

    local pushedTex = button:GetPushedTexture()
    if pushedTex then pushedTex:SetAlpha(0); pushedTex:Hide(); pushedTex:SetTexture(nil) end

    local disabledTex = button:GetDisabledTexture()
    if disabledTex then disabledTex:SetAlpha(0); disabledTex:Hide(); disabledTex:SetTexture(nil) end

    -- Nuke everything recursively (NineSlice, Left/Right/Middle, Border, etc.)
    NukeTextures(button)

    -- Prevent Blizzard from re-applying textures
    LockoutTextures(button)

    -- If button has a backdrop, remove it
    if button.SetBackdrop then
        button:SetBackdrop(nil)
    end

    -- =====================
    -- Phase 2: BUILD our custom visuals
    -- =====================

    -- Dark background
    -- Dark background (very low layer — guaranteed behind everything)
    local bg = button:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(BTN_NORMAL[1], BTN_NORMAL[2], BTN_NORMAL[3], BTN_NORMAL[4])

    -- Hover overlay (teal tint) — OVERLAY sublevel 2, above any Blizzard
    -- ARTWORK re-applications, below our borders (sublevel 7) and text
    local hover = button:CreateTexture(nil, "OVERLAY", nil, 2)
    hover:SetAllPoints()
    hover:SetColorTexture(BTN_HOVER[1], BTN_HOVER[2], BTN_HOVER[3], BTN_HOVER[4])
    hover:Hide()

    -- Pressed overlay (deeper teal) — same layer as hover
    local pressed = button:CreateTexture(nil, "OVERLAY", nil, 2)
    pressed:SetAllPoints()
    pressed:SetColorTexture(BTN_PRESSED[1], BTN_PRESSED[2], BTN_PRESSED[3], BTN_PRESSED[4])
    pressed:Hide()

    -- Subtle left accent bar (teal indicator)
    local leftAccent = button:CreateTexture(nil, "OVERLAY", nil, 6)
    leftAccent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0)
    leftAccent:SetWidth(2)
    leftAccent:SetPoint("TOPLEFT", 0, 0)
    leftAccent:SetPoint("BOTTOMLEFT", 0, 0)

    -- Borders
    local borders = CreateBorders(button, BTN_BORDER[1], BTN_BORDER[2], BTN_BORDER[3], BTN_BORDER[4])

    -- Store references
    button._tmBg         = bg
    button._tmHover      = hover
    button._tmPressed    = pressed
    button._tmLeftAccent = leftAccent
    button._tmBorders    = borders

    -- =====================
    -- Phase 3: STYLE the text
    -- =====================

    local text = button:GetFontString()
    if text then
        text:SetFont(ADDON_FONT, 13, "")
        text:SetTextColor(TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3], TEXT_COLOR[4])
        text:SetShadowOffset(0, 0)
        text:ClearAllPoints()
        text:SetPoint("CENTER", 0, 0)
        text:SetDrawLayer("OVERLAY", 7)
    end

    -- Also handle the disabled font string
    local disabledText = button:GetDisabledFontObject()
    if disabledText and disabledText.SetTextColor then
        disabledText:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], TEXT_DIM[4])
    end

    -- =====================
    -- Phase 4: HOVER & PRESS effects
    -- =====================

    button:HookScript("OnEnter", function(self)
        if self._tmHover then self._tmHover:Show() end
        if self._tmLeftAccent then
            self._tmLeftAccent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
        end
        if self._tmBorders then
            SetBorderColor(self._tmBorders, BTN_BORDER_H[1], BTN_BORDER_H[2], BTN_BORDER_H[3], BTN_BORDER_H[4])
        end
        local fs = self:GetFontString()
        if fs then fs:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1) end
    end)

    button:HookScript("OnLeave", function(self)
        if self._tmHover then self._tmHover:Hide() end
        if self._tmPressed then self._tmPressed:Hide() end
        if self._tmLeftAccent then
            self._tmLeftAccent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0)
        end
        if self._tmBorders then
            SetBorderColor(self._tmBorders, BTN_BORDER[1], BTN_BORDER[2], BTN_BORDER[3], BTN_BORDER[4])
        end
        local fs = self:GetFontString()
        if fs then fs:SetTextColor(TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3], TEXT_COLOR[4]) end
    end)

    button:HookScript("OnMouseDown", function(self)
        if self._tmPressed then self._tmPressed:Show() end
        if self._tmHover then self._tmHover:Hide() end
    end)

    button:HookScript("OnMouseUp", function(self)
        if self._tmPressed then self._tmPressed:Hide() end
        if self._tmHover and self:IsMouseOver() then self._tmHover:Show() end
    end)

    -- Re-nuke Blizzard textures every time the button is shown,
    -- in case Blizzard's layout system re-applies decorations
    button:HookScript("OnShow", function(self)
        -- Kill standard textures again
        for _, getter in ipairs({ "GetNormalTexture", "GetHighlightTexture", "GetPushedTexture", "GetDisabledTexture" }) do
            if self[getter] then
                local tex = self[getter](self)
                if tex then tex:SetAlpha(0); tex:Hide() end
            end
        end
        -- Kill any NineSlice children that crept back
        if self.NineSlice then
            self.NineSlice:SetAlpha(0)
            self.NineSlice:Hide()
        end
        -- Ensure our bg is visible and at the right layer
        if self._tmBg then self._tmBg:Show() end
    end)
end

-- =====================================
-- SKIN THE GAME MENU FRAME
-- =====================================

local function SkinGameMenu()
    local menu = GameMenuFrame
    if not menu or skinnedFrames[menu] then return end
    skinnedFrames[menu] = true

    -- =====================
    -- Phase 1: DESTROY all Blizzard chrome
    -- =====================

    NukeTextures(menu)

    -- Kill the portrait container if present
    if menu.PortraitContainer then
        menu.PortraitContainer:SetAlpha(0)
        menu.PortraitContainer:Hide()
    end

    -- Kill the header area textures, keep the text
    if menu.Header then
        NukeTextures(menu.Header)
        if menu.Header.Text then
            menu.Header.Text:SetFont(ADDON_FONT_BOLD, 15, "")
            menu.Header.Text:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
            menu.Header.Text:SetShadowOffset(0, 0)
            menu.Header.Text:SetDrawLayer("OVERLAY", 7)
        end
    end

    -- Also handle the title text directly if it exists
    if menu.TitleText then
        menu.TitleText:SetFont(ADDON_FONT_BOLD, 15, "")
        menu.TitleText:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        menu.TitleText:SetShadowOffset(0, 0)
    end

    -- =====================
    -- Phase 2: BUILD our custom frame
    -- =====================

    -- Apply dark backdrop
    if not menu.SetBackdrop then
        Mixin(menu, BackdropTemplateMixin)
    end
    menu:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
    menu:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])

    -- Teal accent strip at top
    CreateAccentStrip(menu)

    -- Subtle inner shadow at top (gradient)
    local innerShadow = menu:CreateTexture(nil, "ARTWORK", nil, 0)
    innerShadow:SetColorTexture(0, 0, 0, 0.3)
    innerShadow:SetHeight(20)
    innerShadow:SetPoint("TOPLEFT", 1, -3)
    innerShadow:SetPoint("TOPRIGHT", -1, -3)
    innerShadow:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0.3))

    -- =====================
    -- Phase 3: SKIN all buttons
    -- =====================

    -- Get ALL child buttons (including unnamed ones)
    local children = { menu:GetChildren() }
    for _, child in ipairs(children) do
        if child:GetObjectType() == "Button" then
            SkinButton(child)
        end
    end

    -- Also try known button names as fallback
    local knownButtons = {
        "GameMenuButtonSettings",
        "GameMenuButtonEditMode",
        "GameMenuButtonMacros",
        "GameMenuButtonAddons",
        "GameMenuButtonLogout",
        "GameMenuButtonQuit",
        "GameMenuButtonContinue",
        "GameMenuButtonStore",
        "GameMenuButtonHelp",
        "GameMenuButtonWhatsNew",
        "GameMenuButtonOptions",
        "GameMenuButtonUIOptions",
        "GameMenuButtonKeybindings",
    }
    for _, name in ipairs(knownButtons) do
        local btn = _G[name]
        if btn then SkinButton(btn) end
    end
end

-- =====================================
-- HOOKS
-- =====================================

local RefreshTomoModButton  -- forward-declare

local function InstallHooks()
    if isHooked then return end
    isHooked = true

    if GameMenuFrame then
        if GameMenuFrame.buttonPool then
            -- TWW retail : les boutons sont dans un pool, Layout les repositionne
            hooksecurefunc(GameMenuFrame, "Layout", function()
                RefreshTomoModButton()
                if not IsEnabled() then return end
                local children = { GameMenuFrame:GetChildren() }
                for _, child in ipairs(children) do
                    if child:GetObjectType() == "Button" then
                        SkinButton(child)
                    end
                end
            end)
        else
            -- Versions plus anciennes de WoW
            GameMenuFrame:HookScript("OnShow", function()
                C_Timer.After(0, function()
                    RefreshTomoModButton()
                    if not IsEnabled() then return end
                    local children = { GameMenuFrame:GetChildren() }
                    for _, child in ipairs(children) do
                        if child:GetObjectType() == "Button" then
                            SkinButton(child)
                        end
                    end
                end)
            end)
        end

        GameMenuFrame:HookScript("OnSizeChanged", function()
            if not IsEnabled() then return end
            local children = { GameMenuFrame:GetChildren() }
            for _, child in ipairs(children) do
                if child:GetObjectType() == "Button" then
                    SkinButton(child)
                end
            end
        end)
    end
end

-- =====================================
-- BOUTON TOMOMOD dans le Game Menu
-- =====================================

local gmButton = nil

local function CloseGameMenu()
    if HideUIPanel and GameMenuFrame then pcall(HideUIPanel, GameMenuFrame) end
end

local function EnsureTomoModButton()
    if gmButton then return gmButton end
    if not GameMenuFrame then return nil end

    -- MainMenuFrameButtonTemplate = template des boutons natifs du GameMenu en TWW
    gmButton = CreateFrame("Button", "GameMenuButtonTomoMod", GameMenuFrame, "MainMenuFrameButtonTemplate")
    gmButton:SetText("|cff0cd29fTomo|r|cffFFFFFFMod|r")
    gmButton:SetScript("OnClick", function()
        CloseGameMenu()
        C_Timer.After(0.05, function()
            if TomoMod_Config and TomoMod_Config.Toggle then
                TomoMod_Config.Toggle()
            end
        end)
    end)
    gmButton:Show()
    return gmButton
end

local function PositionTomoModButton()
    local btn = gmButton
    if not btn or not GameMenuFrame then return end

    -- ── Chemin TWW retail : les boutons vivent dans un buttonPool ──
    if GameMenuFrame.buttonPool then
        -- Textes des boutons du "groupe 1" (Options + Boutique + évent saisonnier)
        local group1 = {}
        if GAMEMENU_OPTIONS       then group1[GAMEMENU_OPTIONS]       = true end
        if BLIZZARD_STORE         then group1[BLIZZARD_STORE]         = true end
        if GAMEMENU_EXTERNALEVENT then group1[GAMEMENU_EXTERNALEVENT] = true end

        local h, offset = btn:GetHeight(), btn:GetHeight() + 8
        local storeBtn, sizeSet = nil, false

        for poolBtn in GameMenuFrame.buttonPool:EnumerateActive() do
            local text = poolBtn:GetText() or ""

            -- Prend la taille depuis le premier bouton du pool
            if not sizeSet then
                local pw, ph = poolBtn:GetWidth(), poolBtn:GetHeight()
                if pw > 10 and ph > 0 then
                    btn:SetSize(pw, ph)
                    h, offset = ph, ph + 8
                    sizeSet = true
                end
            end

            if BLIZZARD_STORE and text == BLIZZARD_STORE then
                storeBtn = poolBtn                          -- dernier bouton du groupe 1
            elseif not group1[text] then
                poolBtn:AdjustPointsOffset(0, -offset)     -- descend groupes 2+
            end
        end

        btn:ClearAllPoints()
        btn:Show()

        if storeBtn then
            -- Positionné juste sous "Boutique", avant "Add-ons"
            btn:SetPoint("TOPLEFT",  storeBtn, "BOTTOMLEFT",  0, -8)
            btn:SetPoint("TOPRIGHT", storeBtn, "BOTTOMRIGHT", 0, -8)
        else
            btn:SetPoint("BOTTOMLEFT",  GameMenuFrame, "BOTTOMLEFT",  8, 8)
            btn:SetPoint("BOTTOMRIGHT", GameMenuFrame, "BOTTOMRIGHT", -8, 8)
        end

        -- Layout réinitialise la hauteur à chaque appel → on ajoute l'offset à chaque fois
        GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + offset)
        return
    end

    -- ── Fallback versions plus anciennes : détection par Y ──
    local buttons = {}
    for _, child in ipairs({ GameMenuFrame:GetChildren() }) do
        if child:GetObjectType() == "Button" and child ~= btn then
            local cx, cy = child:GetCenter()
            local cw, ch = child:GetWidth(), child:GetHeight()
            if cy and cw and cw > 10 and ch and ch > 0 then
                table.insert(buttons, { frame = child, y = cy, w = cw, h = ch })
            end
        end
    end
    table.sort(buttons, function(a, b) return a.y > b.y end)

    local w, h = 180, 24
    if #buttons > 0 then w, h = buttons[1].w, buttons[1].h end
    btn:SetSize(w, h)
    btn:ClearAllPoints()
    btn:Show()

    local refBtn = nil
    for i = 1, #buttons - 1 do
        if (buttons[i].y - buttons[i + 1].y) > h * 1.3 then
            refBtn = buttons[i + 1].frame
            break
        end
    end
    if not refBtn and #buttons > 0 then refBtn = buttons[#buttons].frame end

    if refBtn then
        btn:SetPoint("BOTTOM", refBtn, "TOP", 0, 4)
    else
        btn:SetPoint("BOTTOMLEFT",  GameMenuFrame, "BOTTOMLEFT",  8, 8)
        btn:SetPoint("BOTTOMRIGHT", GameMenuFrame, "BOTTOMRIGHT", -8, 8)
    end
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + h + 8)
end

RefreshTomoModButton = function()
    local btn = EnsureTomoModButton()
    if not btn then return end
    PositionTomoModButton()
    if IsEnabled() then SkinButton(btn) end
end

-- =====================================
-- PUBLIC API
-- =====================================

function GMS.Initialize()
    if isInitialized then return end
    isInitialized = true

    C_Timer.After(0.5, function()
        if GameMenuFrame then
            EnsureTomoModButton()
            InstallHooks()
            if IsEnabled() then
                SkinGameMenu()
            end
        end
    end)
end

function GMS.ApplySettings()
    if not IsEnabled() then return end
    wipe(skinnedFrames)
    wipe(skinnedButtons)
    if GameMenuFrame then
        SkinGameMenu()
    end
end

function GMS.SetEnabled(value)
    if not TomoModDB or not TomoModDB.gameMenuSkin then return end
    TomoModDB.gameMenuSkin.enabled = value
    -- Le bouton TomoMod existe indépendamment du skin
    EnsureTomoModButton()
    if value then
        if not isInitialized then
            GMS.Initialize()
        else
            wipe(skinnedFrames)
            wipe(skinnedButtons)
            SkinGameMenu()
        end
    end
end


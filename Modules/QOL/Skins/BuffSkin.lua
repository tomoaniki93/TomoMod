-- =====================================
-- BuffSkin.lua
-- Skins Blizzard buff/debuff icons (top-right)
-- with rounded 9-slice border + glow from Nameplate assets
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_BuffSkin = TomoMod_BuffSkin or {}
local BS = TomoMod_BuffSkin

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local NP_MEDIA   = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\"
local BORDER_TEX = NP_MEDIA .. "border.png"
local GLOW_TEX   = NP_MEDIA .. "background.png"

local BORDER_CORNER = 4          -- corner size for aura icons (smaller than nameplates)
local GLOW_MARGIN   = 0.48
local GLOW_CORNER   = 8
local GLOW_EXTEND   = 4

local isInitialized = false

-- Dedup: weak-keyed tables to avoid processing same button twice
local skinnedButtons = setmetatable({}, { __mode = "k" })

-- Per-button skin data (border textures, glow textures, bg)
local buttonSkins = setmetatable({}, { __mode = "k" })

-- Hook guards (local, NOT on Blizzard frames — taint safety)
local buffFrameShowHooked  = false
local debuffFrameShowHooked = false

-- Debounce
local updatePending = false

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.buffSkin or {}
end

local function IsEnabled()
    return S().enabled
end

-- =====================================
-- 9-SLICE BORDER (border.png)
-- =====================================

local function CreateRoundedBorder(parent, icon, r, g, b)
    r, g, b = r or 0, g or 0, b or 0
    local c = BORDER_CORNER

    local bf = CreateFrame("Frame", nil, parent)
    bf:SetFrameLevel(parent:GetFrameLevel() + 5)
    bf:SetPoint("TOPLEFT",     icon, "TOPLEFT",     -c * 0.5,  c * 0.5)
    bf:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT",  c * 0.5, -c * 0.5)

    local borders = {}
    local function Tex()
        local t = bf:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetTexture(BORDER_TEX)
        t:SetVertexColor(r, g, b, 1)
        borders[#borders + 1] = t
        return t
    end

    -- Corners
    local tl = Tex(); tl:SetSize(c, c); tl:SetPoint("TOPLEFT");     tl:SetTexCoord(0, 0.5, 0, 0.5)
    local tr = Tex(); tr:SetSize(c, c); tr:SetPoint("TOPRIGHT");    tr:SetTexCoord(0.5, 1, 0, 0.5)
    local bl = Tex(); bl:SetSize(c, c); bl:SetPoint("BOTTOMLEFT");  bl:SetTexCoord(0, 0.5, 0.5, 1)
    local br = Tex(); br:SetSize(c, c); br:SetPoint("BOTTOMRIGHT"); br:SetTexCoord(0.5, 1, 0.5, 1)

    -- Edges
    local top = Tex(); top:SetHeight(c)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(0.5, 0.5, 0, 0.5)

    local bot = Tex(); bot:SetHeight(c)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bot:SetTexCoord(0.5, 0.5, 0.5, 1)

    local lft = Tex(); lft:SetWidth(c)
    lft:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); lft:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    lft:SetTexCoord(0, 0.5, 0.5, 0.5)

    local rgt = Tex(); rgt:SetWidth(c)
    rgt:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); rgt:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    rgt:SetTexCoord(0.5, 1, 0.5, 0.5)

    return bf, borders
end

-- =====================================
-- GLOW (background.png, ADD blend)
-- =====================================

local function CreateGlow(parent, icon, r, g, b, a)
    r, g, b, a = r or 0, g or 0, b or 0, a or 0.6
    local gm = GLOW_MARGIN
    local gc = GLOW_CORNER
    local ext = GLOW_EXTEND

    local gf = CreateFrame("Frame", nil, parent)
    gf:SetFrameLevel(math.max(1, parent:GetFrameLevel() - 1))
    gf:SetPoint("TOPLEFT",     icon, "TOPLEFT",     -ext,  ext)
    gf:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT",  ext, -ext)

    local glows = {}
    local function GTex()
        local t = gf:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(GLOW_TEX)
        t:SetBlendMode("ADD")
        t:SetVertexColor(r, g, b, a)
        glows[#glows + 1] = t
        return t
    end

    -- Corners
    local gtl = GTex(); gtl:SetSize(gc, gc); gtl:SetPoint("TOPLEFT");     gtl:SetTexCoord(0, gm, 0, gm)
    local gtr = GTex(); gtr:SetSize(gc, gc); gtr:SetPoint("TOPRIGHT");    gtr:SetTexCoord(1 - gm, 1, 0, gm)
    local gbl = GTex(); gbl:SetSize(gc, gc); gbl:SetPoint("BOTTOMLEFT");  gbl:SetTexCoord(0, gm, 1 - gm, 1)
    local gbr = GTex(); gbr:SetSize(gc, gc); gbr:SetPoint("BOTTOMRIGHT"); gbr:SetTexCoord(1 - gm, 1, 1 - gm, 1)

    -- Edges
    local gtop = GTex(); gtop:SetHeight(gc)
    gtop:SetPoint("TOPLEFT", gtl, "TOPRIGHT"); gtop:SetPoint("TOPRIGHT", gtr, "TOPLEFT")
    gtop:SetTexCoord(gm, 1 - gm, 0, gm)

    local gbot = GTex(); gbot:SetHeight(gc)
    gbot:SetPoint("BOTTOMLEFT", gbl, "BOTTOMRIGHT"); gbot:SetPoint("BOTTOMRIGHT", gbr, "BOTTOMLEFT")
    gbot:SetTexCoord(gm, 1 - gm, 1 - gm, 1)

    local glft = GTex(); glft:SetWidth(gc)
    glft:SetPoint("TOPLEFT", gtl, "BOTTOMLEFT"); glft:SetPoint("BOTTOMLEFT", gbl, "TOPLEFT")
    glft:SetTexCoord(0, gm, gm, 1 - gm)

    local grgt = GTex(); grgt:SetWidth(gc)
    grgt:SetPoint("TOPRIGHT", gtr, "BOTTOMRIGHT"); grgt:SetPoint("BOTTOMRIGHT", gbr, "TOPRIGHT")
    grgt:SetTexCoord(1 - gm, 1, gm, 1 - gm)

    return gf, glows
end

-- =====================================
-- SKIN A SINGLE AURA BUTTON
-- =====================================

local function SkinButton(button, isBuff)
    if not button or skinnedButtons[button] then return end

    local settings = S()
    if isBuff and not settings.skinBuffs then return end
    if not isBuff and not settings.skinDebuffs then return end

    -- Find icon texture
    local icon = button.Icon or button.icon
    if not icon then return end

    -- Validate: must be a proper Frame
    if not button.CreateTexture or type(button.CreateTexture) ~= "function" then return end

    -- Crop icon edges for cleaner look
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Remove Blizzard circular mask so the full square icon is visible
    if icon.SetMask then icon:SetMask("") end
    if button.IconMask then button.IconMask:Hide() end
    if button.CircleMask then button.CircleMask:Hide() end

    -- Hide Blizzard overlays that darken the icon
    if button.IconOverlay and button.IconOverlay.SetAlpha then button.IconOverlay:SetAlpha(0) end
    if button.Highlight and button.Highlight.SetAlpha then button.Highlight:SetAlpha(0) end

    -- Hide Blizzard default border
    local blizzBorder = button.Border or button.border or button.IconBorder
    if blizzBorder and blizzBorder.SetAlpha then
        blizzBorder:SetAlpha(0)
    end

    -- Determine colors — teal border on all auras (addon accent)
    local borderR, borderG, borderB = 0.047, 0.824, 0.624
    local glowR, glowG, glowB, glowA = 0, 0, 0, 0    -- no glow by default

    if not isBuff then
        -- Debuffs: keep red glow to distinguish
        glowR, glowG, glowB, glowA = 0.8, 0.1, 0.1, 0.5
    elseif settings.buffGlow then
        -- Buffs with glow enabled: subtle teal glow
        glowR, glowG, glowB, glowA = 0.047, 0.824, 0.624, 0.3
    end

    -- Create dark background behind icon
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.9)

    -- Create 9-slice rounded border
    local borderFrame, borders = CreateRoundedBorder(button, icon, borderR, borderG, borderB)

    -- Create glow (only if alpha > 0)
    local glowFrame, glows
    if glowA > 0 then
        glowFrame, glows = CreateGlow(button, icon, glowR, glowG, glowB, glowA)
    end

    -- Store references
    buttonSkins[button] = {
        bg = bg,
        borderFrame = borderFrame,
        borders = borders,
        glowFrame = glowFrame,
        glows = glows,
        isBuff = isBuff,
    }

    skinnedButtons[button] = true
end

-- =====================================
-- FONT SETTINGS
-- =====================================

local function ApplyFontToButton(button)
    if not button then return end
    local settings = S()
    local fontSize = settings.fontSize or 12
    local fontOutline = settings.fontOutline or "OUTLINE"

    -- Duration text
    local duration = button.Duration or button.duration
    if duration and duration.SetFont then
        duration:SetFont(ADDON_FONT, fontSize, fontOutline)
    end

    -- Count text
    local count = button.Count or button.count
    if count and count.SetFont then
        count:SetFont(ADDON_FONT, fontSize, fontOutline)
    end
end

-- =====================================
-- PROCESS CONTAINERS
-- =====================================

local function ProcessAuraContainer(container, isBuff)
    if not container then return end
    local frames = { container:GetChildren() }
    for _, frame in ipairs(frames) do
        if frame.Icon or frame.icon then
            SkinButton(frame, isBuff)
            ApplyFontToButton(frame)
        end
    end
end

-- =====================================
-- FRAME HIDING
-- =====================================

local _frameHidingPendingRegen = false

local function ApplyFrameHiding()
    if InCombatLockdown() then
        if not _frameHidingPendingRegen then
            _frameHidingPendingRegen = true
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            f:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                _frameHidingPendingRegen = false
                ApplyFrameHiding()
            end)
        end
        return
    end

    local settings = S()

    -- BuffFrame hiding
    if BuffFrame then
        if settings.hideBuffFrame then
            BuffFrame:Hide()
        else
            BuffFrame:Show()
        end
        if not buffFrameShowHooked then
            buffFrameShowHooked = true
            hooksecurefunc(BuffFrame, "Show", function(self)
                C_Timer.After(0, function()
                    local s = S()
                    if s and s.hideBuffFrame then
                        self:Hide()
                    end
                end)
            end)
        end
    end

    -- DebuffFrame hiding
    if DebuffFrame then
        if settings.hideDebuffFrame then
            DebuffFrame:Hide()
        else
            DebuffFrame:Show()
        end
        if not debuffFrameShowHooked then
            debuffFrameShowHooked = true
            hooksecurefunc(DebuffFrame, "Show", function(self)
                C_Timer.After(0, function()
                    local s = S()
                    if s and s.hideDebuffFrame then
                        self:Hide()
                    end
                end)
            end)
        end
    end
end

-- =====================================
-- MAIN APPLY
-- =====================================

local function ApplyBuffSkin()
    if not IsEnabled() then return end

    ApplyFrameHiding()

    -- Buffs
    if BuffFrame and BuffFrame.AuraContainer then
        ProcessAuraContainer(BuffFrame.AuraContainer, true)
    end

    -- Debuffs
    if DebuffFrame and DebuffFrame.AuraContainer then
        ProcessAuraContainer(DebuffFrame.AuraContainer, false)
    end

    -- Temporary enchants (weapon buffs)
    if TemporaryEnchantFrame then
        local frames = { TemporaryEnchantFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            SkinButton(frame, true)
            ApplyFontToButton(frame)
        end
    end
end

-- Debounced update
local function ScheduleUpdate()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.15, function()
        updatePending = false
        ApplyBuffSkin()
    end)
end

-- =====================================
-- HOOKS (taint-safe via C_Timer.After)
-- =====================================

local function InstallHooks()
    if BuffFrame and BuffFrame.Update then
        hooksecurefunc(BuffFrame, "Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end

    if BuffFrame and BuffFrame.AuraContainer and BuffFrame.AuraContainer.Update then
        hooksecurefunc(BuffFrame.AuraContainer, "Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end

    if DebuffFrame and DebuffFrame.Update then
        hooksecurefunc(DebuffFrame, "Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end

    if DebuffFrame and DebuffFrame.AuraContainer and DebuffFrame.AuraContainer.Update then
        hooksecurefunc(DebuffFrame.AuraContainer, "Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end

    if type(AuraButton_Update) == "function" then
        hooksecurefunc("AuraButton_Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end
end

-- =====================================
-- PUBLIC API
-- =====================================

function BS.Initialize()
    if isInitialized then return end
    if not IsEnabled() then return end
    isInitialized = true

    -- Event: UNIT_AURA for dynamic updates
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:SetScript("OnEvent", function(self, event, arg)
        if event == "UNIT_AURA" and arg == "player" then
            ScheduleUpdate()
        end
    end)

    -- Initial apply + hooks (delayed to ensure frames exist)
    C_Timer.After(1, function()
        ApplyBuffSkin()
        InstallHooks()
    end)
end

function BS.ApplySettings()
    if not IsEnabled() then return end
    -- Clear dedup to force re-skin
    wipe(skinnedButtons)
    ApplyBuffSkin()
end

function BS.SetEnabled(value)
    if not TomoModDB or not TomoModDB.buffSkin then return end
    TomoModDB.buffSkin.enabled = value
    if value then
        wipe(skinnedButtons)
        if not isInitialized then
            BS.Initialize()
        else
            ApplyBuffSkin()
        end
    end
end

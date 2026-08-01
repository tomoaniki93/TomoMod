-- =====================================
-- TooltipSkin.lua
-- Skins the Blizzard GameTooltip
-- Dark background, class-colored names, guild color, hide realm/title
-- Inspired by BetterTooltips — adapted for TomoMod aesthetic
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_TooltipSkin = TomoMod_TooltipSkin or {}
local TS = TomoMod_TooltipSkin

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_TEXTURE   = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"

local isInitialized = false
local isHooked      = false
local isAnchorLocked = true -- hides the draggable "custom" anchor swatch outside Layout mode

-- Palette
local ACCENT     = { 0.047, 0.824, 0.624 }
local BG_COLOR   = { 0.06, 0.06, 0.08 }
local BORDER_CLR = { 0.20, 0.20, 0.24 }
local GUILD_CLR  = { 0.047, 0.824, 0.624 }

local gsub = string.gsub
local find = string.find

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.tooltipSkin or {}
end

local function IsEnabled()
    return S().enabled
end

-- =====================================
-- SAFE HELPERS (TWW secret-value proof)
-- =====================================

local function IsSecretValue(value)
    return type(issecurevalue) == "function" and issecurevalue(value)
        or type(issecretvalue) == "function" and issecretvalue(value)
end

local function StripColorCodes(text)
    if not text then return nil end
    if IsSecretValue(text) then return nil end
    text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    return gsub(text, "|r", "")
end

local function StripServerSuffix(nameText)
    if not nameText or nameText == "" then return nameText end
    if IsSecretValue(nameText) then return nameText end
    return gsub(nameText, "%-[^%-%s]+$", "")
end

-- =====================================
-- GET UNIT FROM TOOLTIP
-- =====================================

local function GetTooltipUnit(tooltip)
    if not tooltip or not tooltip.GetUnit then return nil end
    local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
    if not ok or type(unit) ~= "string" then return nil end
    -- A secret unit token is NOT rejected here. The token is only ever handed
    -- back to the game as an API argument and never read, so a secret one is
    -- perfectly usable -- and 12.x hands out secret tokens routinely, so
    -- filtering them silently disabled the reaction border for every unit.
    return unit
end

-- =====================================
-- SKIN BACKGROUND & BORDER
-- =====================================

local skinnedTooltips = setmetatable({}, { __mode = "k" })

local function SkinTooltipBackground(tooltip)
    if not tooltip then return end
    local s = S()

    -- Couleurs configurables (fallback sur les constantes par défaut)
    local bgC, bdC = s.bgColor or {}, s.borderColor or {}
    local bgR, bgG, bgB = bgC.r or BG_COLOR[1], bgC.g or BG_COLOR[2], bgC.b or BG_COLOR[3]
    local bdR, bdG, bdB = bdC.r or BORDER_CLR[1], bdC.g or BORDER_CLR[2], bdC.b or BORDER_CLR[3]

    -- Border tinted by the unit's reaction (class colour for players). This
    -- block runs on EVERY Show and always assigns a colour, which is what
    -- keeps it from going "sticky": moving the mouse from a hostile unit onto
    -- an item falls back to the configured border on the very next Show.
    if s.reactionBorder and TomoMod_TooltipInfo and TomoMod_TooltipInfo.ReactionColor then
        local unit = GetTooltipUnit(tooltip)
        if unit then
            local rr, rg, rb = TomoMod_TooltipInfo.ReactionColor(unit)
            if rr then bdR, bdG, bdB = rr, rg, rb end
        end
    end

    -- Approche SetBackdrop (API standard, correctement bornée au frame du tooltip).
    -- N'utilise PAS NineSlice.Center:SetAlpha() qui peut affecter une zone plus large
    -- que le tooltip en TWW 12.x et créer un rectangle noir sur l'écran.
    if tooltip.SetBackdrop then
        tooltip:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        tooltip:SetBackdropColor(bgR, bgG, bgB, s.bgAlpha or 0.97)
        tooltip:SetBackdropBorderColor(bdR, bdG, bdB, s.borderAlpha or 0.8)
    elseif tooltip.NineSlice then
        -- Fallback NineSlice : utilise SetVertexColor(r,g,b,a) sans SetAlpha() séparé
        if tooltip.NineSlice.Center then
            tooltip.NineSlice.Center:SetVertexColor(bgR, bgG, bgB, s.bgAlpha or 0.97)
        end
        local borderPieces = {
            "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
            "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
        }
        for _, pieceName in ipairs(borderPieces) do
            local piece = tooltip.NineSlice[pieceName]
            if piece then
                piece:SetVertexColor(bdR, bdG, bdB, s.borderAlpha or 0.8)
            end
        end
    end

    -- Ligne d'accent teal en haut du tooltip
    if not tooltip._tomoAccent then
        local accent = tooltip:CreateTexture(nil, "OVERLAY")
        accent:SetHeight(1)
        accent:SetPoint("TOPLEFT",  tooltip, "TOPLEFT",  4, -3)
        accent:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -4, -3)
        accent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.5)
        tooltip._tomoAccent = accent
    end
end

-- =====================================
-- SKIN HEALTH BAR
-- =====================================

local function SkinHealthBar(tooltip)
    local statusBar = tooltip.StatusBar or _G[tooltip:GetName() .. "StatusBar"]
    if not statusBar then return end

    local s = S()
    if s.hideHealthBar then
        statusBar:Hide()
        if not statusBar._tomoHideHooked then
            statusBar:HookScript("OnShow", function(self)
                if IsEnabled() and S().hideHealthBar then
                    self:Hide()
                end
            end)
            statusBar._tomoHideHooked = true
        end
        return
    end

    -- Style the health bar
    if not statusBar._tomoStyled then
        statusBar:SetStatusBarTexture(ADDON_TEXTURE)
        statusBar:SetStatusBarColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)

        local bg = statusBar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.10, 0.8)

        statusBar._tomoStyled = true
    end
end

-- =====================================
-- CLASS-COLORED PLAYER NAMES
-- =====================================

local function ApplyClassColorName(tooltip)
    local s = S()
    if not s.useClassColorNames then return end

    local unit = GetTooltipUnit(tooltip)
    if not unit then return end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or not isPlayer then return end

    local _, classToken = UnitClass(unit)
    if not classToken then return end

    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    if not color then return end

    local nameLine = _G[tooltip:GetName() .. "TextLeft1"]
    if nameLine then
        nameLine:SetTextColor(color.r, color.g, color.b)
    end
end

-- =====================================
-- HIDE SERVER / TITLE
-- =====================================

local function ApplyNameFormatting(tooltip)
    local s = S()
    local hideServer = s.hidePlayerServer
    local hideTitle  = s.hidePlayerTitle
    if not hideServer and not hideTitle then return end

    local unit = GetTooltipUnit(tooltip)
    if not unit then return end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or not isPlayer then return end

    local nameLine = _G[tooltip:GetName() .. "TextLeft1"]
    if not nameLine then return end

    local nameText
    if hideTitle then
        local name, realm = UnitName(unit)
        if not name or name == "" then return end
        if hideServer or not realm or realm == "" then
            nameText = name
        else
            nameText = name .. "-" .. realm
        end
    else
        nameText = UnitPVPName(unit) or GetUnitName(unit, true)
        if not nameText or nameText == "" then return end
        if hideServer then
            nameText = StripServerSuffix(nameText)
        end
    end

    if nameText and nameText ~= "" then
        nameLine:SetText(nameText)
    end
end

-- =====================================
-- GUILD NAME COLOR
-- =====================================

local function ApplyGuildColor(tooltip)
    local s = S()
    if not s.useGuildNameColor then return end

    local unit = GetTooltipUnit(tooltip)
    if not unit then return end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or not isPlayer then return end

    local guildColor = s.guildNameColor or GUILD_CLR
    local r = guildColor.r or guildColor[1] or GUILD_CLR[1]
    local g = guildColor.g or guildColor[2] or GUILD_CLR[2]
    local b = guildColor.b or guildColor[3] or GUILD_CLR[3]

    local guildName = GetGuildInfo(unit)
    local tooltipName = tooltip:GetName()

    for i = 2, math.min(tooltip:NumLines(), 4) do
        local leftText = _G[tooltipName .. "TextLeft" .. i]
        if leftText then
            local plain = StripColorCodes(leftText:GetText())
            if plain and plain ~= "" then
                if guildName and (plain == guildName or plain == "<" .. guildName .. ">") then
                    leftText:SetTextColor(r, g, b)
                    return
                end
            end
        end
    end
end

-- =====================================
-- FONT RESTYLING
-- =====================================

local function ApplyFonts(tooltip)
    local s = S()
    local fontSize = s.fontSize or 12
    local tooltipName = tooltip:GetName()

    for i = 1, tooltip:NumLines() do
        local leftText = _G[tooltipName .. "TextLeft" .. i]
        local rightText = _G[tooltipName .. "TextRight" .. i]

        if leftText then
            if i == 1 then
                pcall(leftText.SetFont, leftText, ADDON_FONT_BOLD, fontSize + 1, "")
            else
                pcall(leftText.SetFont, leftText, ADDON_FONT, fontSize, "")
            end
        end
        if rightText then
            pcall(rightText.SetFont, rightText, ADDON_FONT, fontSize, "")
        end
    end
end

-- =====================================
-- MASTER HOOK — applies all styling on Show/SetUnit
-- =====================================

local function OnTooltipShow(tooltip)
    if not IsEnabled() then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    -- 12.x: don't restyle compare/EncounterJournal tooltips — the synchronous
    -- SetFont/SetBackdrop pass mints "secret numbers" and taints the secret
    -- sell-price MoneyFrame arithmetic Blizzard runs on those tooltips.
    if TomoMod_IsCompareOrMoneyTooltip and TomoMod_IsCompareOrMoneyTooltip(tooltip) then return end

    SkinTooltipBackground(tooltip)
    SkinHealthBar(tooltip)
    ApplyFonts(tooltip)
    ApplyNameFormatting(tooltip)
    ApplyClassColorName(tooltip)
    ApplyGuildColor(tooltip)
end

local function OnTooltipSetUnit(tooltip)
    if not IsEnabled() then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end

    ApplyNameFormatting(tooltip)
    ApplyClassColorName(tooltip)
    ApplyGuildColor(tooltip)
end

-- =====================================
-- POSITIONNEMENT DE L'INFOBULLE
-- modes : default | cursor | corner | custom
-- (le suivi souris reste gere par CursorRing:OnUpdate ; ici on ne gere
--  que les ancrages statiques coin / personnalise)
-- =====================================
local TT_PAD = 16

local function EnsureTooltipMover()
    if TomoMod_TooltipMover then return TomoMod_TooltipMover end
    local m = CreateFrame("Frame", "TomoMod_TooltipMover", UIParent, "BackdropTemplate")
    m:SetSize(210, 38)
    m:SetFrameStrata("DIALOG")
    m:SetClampedToScreen(true)
    m:SetMovable(true)
    m:EnableMouse(true)
    m:RegisterForDrag("LeftButton")
    m:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    m:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.18)
    m:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
    local fs = m:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ADDON_FONT_BOLD, 12, "OUTLINE")
    fs:SetPoint("CENTER")
    fs:SetText("Infobulle - glisser pour placer")
    fs:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    m:SetScript("OnDragStart", m.StartMoving)
    m:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local s = S()
        -- GetLeft/GetBottom (jamais GetPoint) apres un deplacement
        local l, b = self:GetLeft(), self:GetBottom()
        if l and b then s.moverX, s.moverY = math.floor(l + 0.5), math.floor(b + 0.5) end
    end)
    local s = S()
    m:ClearAllPoints()
    if s.moverX and s.moverY then
        m:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", s.moverX, s.moverY)
    else
        m:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    end
    m:Hide()
    return m
end

-- Affiche/masque le cadre deplacable selon le mode ET l'etat verrouille.
-- [FIX] Auparavant affiche en permanence des que le mode "custom" etait choisi,
-- meme en dehors de tout mode d'edition/placement — un joueur a signale que le
-- repere teal restait visible en jeu en permanence. Il ne s'affiche desormais
-- que lorsque le mode Layout est actif pour cet ancrage (voir SetLocked/API
-- Movers), exactement comme les autres reperes deplacables de l'addon.
function TS.RefreshAnchor()
    local s = S()
    if (s.anchor or "default") ~= "custom" then
        if TomoMod_TooltipMover then TomoMod_TooltipMover:Hide() end
        return
    end
    if isAnchorLocked then
        if TomoMod_TooltipMover then TomoMod_TooltipMover:Hide() end
    else
        EnsureTooltipMover():Show()
    end
end

function TS.IsLocked()
    return isAnchorLocked
end

function TS.SetLocked(locked)
    isAnchorLocked = locked and true or false
    TS.RefreshAnchor()
end

function TS.ToggleLock()
    TS.SetLocked(not isAnchorLocked)
end

-- Ancrage statique (coin / custom). Souris & defaut : non geres ici.
local function ApplyTooltipAnchor(tooltip, parent)
    if not tooltip or not IsEnabled() then return end
    local s = S()
    local mode = s.anchor or "default"
    if mode == "corner" then
        local corner = s.anchorCorner or "BOTTOMRIGHT"
        local ox = corner:find("RIGHT") and -TT_PAD or TT_PAD
        local oy = corner:find("BOTTOM") and TT_PAD or -TT_PAD
        tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")
        tooltip:ClearAllPoints()
        tooltip:SetPoint(corner, UIParent, corner, ox, oy)
    elseif mode == "custom" then
        local m = EnsureTooltipMover()
        tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")
        tooltip:ClearAllPoints()
        tooltip:SetPoint("BOTTOMLEFT", m, "TOPLEFT", 0, 4)
    end
end

-- =====================================
-- PUBLIC API
-- =====================================

function TS.SetEnabled(value)
    if not TomoModDB or not TomoModDB.tooltipSkin then return end
    TomoModDB.tooltipSkin.enabled = value
end

function TS.ApplySettings()
    if TomoMod_TooltipInfo and TomoMod_TooltipInfo.ApplySettings then
        TomoMod_TooltipInfo.ApplySettings()
    end
    -- Settings take effect on next tooltip show (no refresh needed)
end

-- Registers the custom-anchor swatch with the addon's unified Layout Mode
-- toggle (TomoMod_Movers), so pressing "Layout" reveals it like every other
-- movable element, and it hides again automatically when Layout mode ends.
local function RegisterWithMovers()
    if not TomoMod_Movers or not TomoMod_Movers.RegisterEntry then return end
    TomoMod_Movers.RegisterEntry({
        label    = (TomoMod_L and TomoMod_L["mover_tooltip_anchor"]) or "Tooltip Anchor",
        unlock   = function() TS.SetLocked(false) end,
        lock     = function() TS.SetLocked(true) end,
        isActive = function()
            local s = S()
            return TomoModDB and TomoModDB.tooltipSkin and TomoModDB.tooltipSkin.enabled
                and (s.anchor or "default") == "custom"
        end,
    })
end

function TS.Initialize()
    if isInitialized then return end
    if not IsEnabled() then return end

    if not isHooked then
        isHooked = true

        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            ApplyTooltipAnchor(tooltip, parent)
        end)

        -- Hook GameTooltip
        hooksecurefunc(GameTooltip, "Show", function() OnTooltipShow(GameTooltip) end)
        hooksecurefunc(GameTooltip, "SetUnit", function() OnTooltipSetUnit(GameTooltip) end)

        -- Hook Shopping tooltips (item comparison)
        if ShoppingTooltip1 then
            hooksecurefunc(ShoppingTooltip1, "Show", function() OnTooltipShow(ShoppingTooltip1) end)
        end
        if ShoppingTooltip2 then
            hooksecurefunc(ShoppingTooltip2, "Show", function() OnTooltipShow(ShoppingTooltip2) end)
        end

        -- Hook ItemRefTooltip (linked items in chat)
        if ItemRefTooltip then
            hooksecurefunc(ItemRefTooltip, "Show", function() OnTooltipShow(ItemRefTooltip) end)
        end
    end

    TS.RefreshAnchor()
    RegisterWithMovers()

    -- The information layer rides on TooltipDataProcessor, not on our Show
    -- hook, but it shares this module's settings table and lifecycle.
    if TomoMod_TooltipInfo and TomoMod_TooltipInfo.Initialize then
        TomoMod_TooltipInfo.Initialize()
    end

    isInitialized = true
end

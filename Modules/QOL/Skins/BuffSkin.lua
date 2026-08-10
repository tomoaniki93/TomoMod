-- =====================================
-- BuffSkin.lua — v2 (ElvUI-style)
-- Backdrop dark bg + 1px border coloré par type de debuff
-- Compatible TWW 12.x (secret values guard)
-- =====================================

TomoMod_BuffSkin = TomoMod_BuffSkin or {}
local BS = TomoMod_BuffSkin

-- =====================================
-- LOCALS
-- =====================================

local ADDON_FONT  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FLAT_TEX    = "Interface\\Buttons\\WHITE8x8"

-- Couleurs de dispel (même palette qu'ElvUI / Blizzard standard)
local DISPEL_COLORS = {
    Magic   = { r = 0.20, g = 0.60, b = 1.00 },  -- bleu
    Poison  = { r = 0.10, g = 0.78, b = 0.10 },  -- vert
    Curse   = { r = 0.60, g = 0.10, b = 0.80 },  -- violet
    Disease = { r = 0.73, g = 0.46, b = 0.10 },  -- marron
    Enrage  = { r = 0.80, g = 0.20, b = 0.20 },  -- rouge sombre
}

-- Couleur de bord par défaut (buffs ou debuffs sans type connu)
local DEFAULT_BORDER  = { r = 0.12, g = 0.12, b = 0.12 }

-- Brand accent for player buffs. Was a hardcoded teal (#0CD29F) that
-- predated the brand tokens; it now follows U.BRAND like the rest of the
-- addon, so a change to the accent reaches the buff frame too.
local function Brand()
    local U = TomoMod_Utils
    local c = (U and U.BRAND) or { 0.180, 0.847, 0.518 }
    return c[1], c[2], c[3]
end

-- Remaining-time colours. Neutral above the green threshold: a buff with
-- twenty minutes left carries no information, and colouring it would spend
-- the player's attention on the one aura that does not need it.
-- The config UI's card tile. Reused rather than reinvented so the timer
-- badge is the same dark grey as every other TomoMod surface.
local function CardColors()
    local T = TomoMod_Widgets and TomoMod_Widgets.Theme
    return (T and T.cardBg) or { 0.090, 0.090, 0.115, 1 },
           (T and T.cardBorder) or { 0.20, 0.20, 0.26, 1 }
end

local function ThemeColor(key, fallback)
    local T = TomoMod_Widgets and TomoMod_Widgets.Theme
    local c = T and T[key]
    if c then return c[1], c[2], c[3] end
    return fallback[1], fallback[2], fallback[3]
end

local DURATION_NEUTRAL = { 0.90, 0.92, 0.91 }

-- Border ladder. No neutral band here, unlike the text: mint IS the
-- resting state, so a long buff still reads as a TomoMod-framed icon and
-- the border only starts warning as the aura runs down.
local function BorderDurationColor(remaining, settings)
    if remaining <= (settings.durationRed or 30) then
        return ThemeColor("red", { 0.88, 0.22, 0.22 })
    elseif remaining <= (settings.durationYellow or 120) then
        return ThemeColor("yellow", { 0.96, 0.80, 0.10 })
    end
    return Brand()
end

-- Fond sombre identique à ElvUI
local BG_COLOR = { r = 0.09, g = 0.09, b = 0.09, a = 0.95 }

-- Padding icône dans la border (1px comme ElvUI PixelMode)
local INSET = 2

local isInitialized   = false
local skinnedButtons  = setmetatable({}, { __mode = "k" })
local updatePending   = false
local hooksInstalled  = false
-- (buffHookDone/debuffHookDone removed — hooks consolidated in InstallHooks)

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
-- BACKDROP HELPER
-- Applique un backdrop dark + border colored sur un frame.
-- Mixin BackdropTemplateMixin si SetBackdrop absent (TWW).
-- =====================================

local function ApplyBackdrop(frame, r, g, b)
    if not frame then return end

    -- TWW: BackdropTemplate n'est pas hérité automatiquement sur les Buttons
    if not frame.SetBackdrop then
        if BackdropTemplateMixin then
            Mixin(frame, BackdropTemplateMixin)
        else
            return
        end
    end

    frame:SetBackdrop({
        bgFile   = FLAT_TEX,
        edgeFile = FLAT_TEX,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, BG_COLOR.a)
    frame:SetBackdropBorderColor(r or DEFAULT_BORDER.r, g or DEFAULT_BORDER.g, b or DEFAULT_BORDER.b, 1)
end

-- =====================================
-- COLOR PAR TYPE DE DEBUFF
-- dispelType est une string Blizzard ("Magic", "Poison", etc.)
-- En TWW, elle peut être un secret value → on pcall + type-check.
-- =====================================

local function GetBorderColor(button, isDebuff)
    local settings = S()

    -- Debuffs : couleur par type de dispel
    if isDebuff and settings.colorByType then
        local debuffType
        local ok = pcall(function()
            -- button.debuffType posé par AuraButton_UpdateType (Blizzard)
            -- button.dispelName posé par Blizzard (TWW) — on essaie les deux
            debuffType = button.debuffType or button.dispelName
        end)
        if ok and debuffType and type(debuffType) == "string" then
            local c = DISPEL_COLORS[debuffType]
            if c then return c.r, c.g, c.b end
        end
        -- Fallback debuff sans type : rouge sombre discret
        return 0.65, 0.12, 0.12
    end

    -- Buffs : accent de marque si activé, sinon dark border. The accent
    -- carries the remaining time, which is what lets the timer text be
    -- optional rather than load-bearing.
    if not isDebuff then
        if settings.brandBorder ~= false then
            local remaining = BS._Remaining and BS._Remaining(button)
            if remaining then
                return BorderDurationColor(remaining, settings)
            end
            return Brand()
        end
    end

    return DEFAULT_BORDER.r, DEFAULT_BORDER.g, DEFAULT_BORDER.b
end

-- =====================================
-- SKIN D'UN BOUTON
-- Applique backdrop + crop icône + nettoyage Blizzard
-- =====================================

local function SkinButton(button, isDebuff)
    if not button then return end

    local settings = S()
    if isDebuff and not settings.skinDebuffs then return end
    if not isDebuff and not settings.skinBuffs then return end

    local icon = button.Icon or button.icon
    if not icon then return end

    -- [FIX] The backdrop used to go on the button itself and the icon was
    -- stretched to fill it with TOPLEFT/BOTTOMRIGHT. Blizzard's aura button
    -- is not square -- it reserves height below the icon -- so both the
    -- icon and the border came out taller than wide. The frame now wraps
    -- the icon, and the icon is sized square from the button's width.
    if not button._tomoFrame then
        local f = CreateFrame("Frame", nil, button, "BackdropTemplate")
        f:SetFrameLevel(math.max(0, button:GetFrameLevel()))
        button._tomoFrame = f
    end

    local r, g, b = GetBorderColor(button, isDebuff)
    ApplyBackdrop(button._tomoFrame, r, g, b)

    -- [FIX] Always re-apply idempotent styling ops — Blizzard may recycle
    -- the frame (same pointer, new aura) and reset icon anchors/masks.
    -- The weak-table entry survives but Blizzard's re-init undoes our tweaks.

    -- Square edge taken from the button's width. GetWidth can be 0 before
    -- Blizzard has laid the container out, so fall back rather than
    -- collapsing the icon to nothing.
    local edge = button:GetWidth()
    if not edge or edge < 4 then edge = (icon:GetWidth() or 0) end
    if not edge or edge < 4 then edge = 30 end
    local inner = edge - INSET * 2

    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", INSET, -INSET)
    icon:SetSize(inner, inner)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetDrawLayer("ARTWORK", 0)

    -- The frame hugs the icon, so it inherits the square shape.
    button._tomoFrame:ClearAllPoints()
    button._tomoFrame:SetPoint("TOPLEFT",     icon, "TOPLEFT",     -INSET,  INSET)
    button._tomoFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT",  INSET, -INSET)

    -- Supprimer le masque circulaire Blizzard
    if icon.SetMask then icon:SetMask("") end
    if button.IconMask    then button.IconMask:Hide()    end
    if button.CircleMask  then button.CircleMask:Hide()  end

    -- Supprimer les overlays qui assombrissent l'icône
    if button.IconOverlay then button.IconOverlay:SetAlpha(0) end
    if button.Highlight   then button.Highlight:SetAlpha(0)   end

    -- Masquer le texte Symbol (type d'aura Blizzard) qui peut apparaître derrière l'icône
    if button.Symbol then button.Symbol:SetAlpha(0) end

    -- Supprimer la border Blizzard par défaut
    local blizzBorder = button.Border or button.border or button.IconBorder
    if blizzBorder then blizzBorder:SetAlpha(0) end

    -- Fine dark line just outside the accent border. Without it the mint
    -- edge bleeds into bright backgrounds and the icon loses its shape;
    -- with it the button reads as a framed tile at any zoom.
    if not button._tomoOuter then
        local outer = CreateFrame("Frame", nil, button, "BackdropTemplate")
        outer:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
        outer:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        outer:SetBackdropBorderColor(0, 0, 0, 0.9)
        button._tomoOuter = outer
    end
    button._tomoOuter:ClearAllPoints()
    button._tomoOuter:SetPoint("TOPLEFT",     button._tomoFrame, "TOPLEFT",     -1,  1)
    button._tomoOuter:SetPoint("BOTTOMRIGHT", button._tomoFrame, "BOTTOMRIGHT",  1, -1)

    -- Overlay de highlight souris (créé une seule fois)
    if not button._tomoHighlight then
        local hl = button:CreateTexture(nil, "HIGHLIGHT")
        hl:SetColorTexture(1, 1, 1, 0.15)
        hl:SetAllPoints(icon)
        button._tomoHighlight = hl
    end

    -- Police Poppins sur count et duration
    local fontSize = settings.fontSize or 11
    local outline  = "OUTLINE"
    local count    = button.Count or button.count
    if count and count.SetFont then
        count:SetFont(ADDON_FONT, fontSize, outline)
        count:SetDrawLayer("OVERLAY", 7)
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
        count:SetJustifyH("RIGHT")
    end
    local duration = button.Duration or button.duration
    if duration and duration.SetFont then
        duration:SetFont(ADDON_FONT, fontSize - 1, outline)
        duration:SetDrawLayer("OVERLAY", 7)

        if settings.showDuration == false then
            duration:SetAlpha(0)
            if button._tomoDurationCard then button._tomoDurationCard:Hide() end
        else
            duration:SetAlpha(1)

            -- The timer gets its own tile directly under the icon, matching
            -- the icon's width. Blizzard drops the text loose over whatever
            -- happens to be behind the buff frame; on a bright zone that is
            -- unreadable however thick the outline.
            if not button._tomoDurationCard then
                local card = CreateFrame("Frame", nil, button, "BackdropTemplate")
                card:SetFrameLevel(math.max(0, button:GetFrameLevel()))
                card:SetBackdrop({
                    bgFile   = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                button._tomoDurationCard = card
            end

            local card = button._tomoDurationCard
            local bg, edge = CardColors()
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT",  button._tomoFrame, "BOTTOMLEFT",  0, -2)
            card:SetPoint("TOPRIGHT", button._tomoFrame, "BOTTOMRIGHT", 0, -2)
            card:SetHeight(fontSize + 5)
            card:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
            card:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4] or 1)
            card:Show()

            duration:ClearAllPoints()
            duration:SetPoint("CENTER", card, "CENTER", 0, 0)
            duration:SetJustifyH("CENTER")
        end
    end

    skinnedButtons[button] = isDebuff and "debuff" or "buff"
end

-- =====================================
-- COULEUR DU TIMER SELON LE TEMPS RESTANT
--
-- The duration text is written by Blizzard's own update loop, so the
-- colour is re-applied on a throttled ticker rather than hooked: a hook
-- on every aura's SetText would fire far more often for no gain.
-- =====================================

local durationTicker

-- Aura fields can be secret in combat. Guard before any comparison, and
-- treat "unreadable" as "leave the colour alone" -- flashing a buff back
-- to white for one tick is worse than not updating it.
local function SafeNum(v)
    if v == nil then return nil end
    local builtin = rawget(_G, "issecretvalue")
    if type(builtin) == "function" then
        local ok, secret = pcall(builtin, v)
        if ok and secret then return nil end
    end
    return type(v) == "number" and v or nil
end

local function RemainingSeconds(button)
    local expiration

    local instanceID = button.auraInstanceID
    if instanceID and C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
        local ok, data = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,
            button.unit or "player", instanceID)
        if ok and data then expiration = SafeNum(data.expirationTime) end
    end
    if not expiration then expiration = SafeNum(button.expirationTime) end
    if not expiration or expiration <= 0 then return nil end   -- permanent aura

    return expiration - GetTime()
end

local function DurationColor(remaining, settings)
    if remaining <= (settings.durationRed or 30) then
        return ThemeColor("red", { 0.88, 0.22, 0.22 })
    elseif remaining <= (settings.durationYellow or 120) then
        return ThemeColor("yellow", { 0.96, 0.80, 0.10 })
    elseif remaining <= (settings.durationGreen or 600) then
        return Brand()
    end
    return DURATION_NEUTRAL[1], DURATION_NEUTRAL[2], DURATION_NEUTRAL[3]
end

-- GetBorderColor is declared above RemainingSeconds, so the resolver is
-- handed over through the module table rather than reordering the file.
BS._Remaining = RemainingSeconds

-- Forward declaration: the ticker below calls UpdateButtonColor, which is
-- defined further down. Without this the call compiles against a nil
-- global and fails on the first tick.
local UpdateButtonColor

local function UpdateDurationColors()
    local settings = S()
    if settings.colorDuration == false then return end

    for button in pairs(skinnedButtons) do
        if button:IsShown() then
            local duration = button.Duration or button.duration
            if duration and duration.SetTextColor then
                local remaining = RemainingSeconds(button)
                if remaining then
                    duration:SetTextColor(DurationColor(remaining, settings))
                else
                    duration:SetTextColor(DURATION_NEUTRAL[1], DURATION_NEUTRAL[2], DURATION_NEUTRAL[3])
                end
            end
            -- Borders tick on the same pass; otherwise they would only
            -- recolour when Blizzard happens to re-skin the button.
            if skinnedButtons[button] == "buff" then
                UpdateButtonColor(button)
            end
        end
    end
end

local function StopDurationTicker()
    if durationTicker then durationTicker:Cancel(); durationTicker = nil end
end

local function StartDurationTicker()
    StopDurationTicker()
    if not IsEnabled() then return end
    if S().colorDuration == false then return end
    durationTicker = C_Timer.NewTicker(0.25, UpdateDurationColors)
end

-- =====================================
-- MISE À JOUR DE LA COULEUR DE BORDER
-- Appelée à chaque update d'aura pour refléter le type de dispel.
-- =====================================

function UpdateButtonColor(button)
    if not skinnedButtons[button] then return end
    local frame = button._tomoFrame
    if not frame or not frame.SetBackdropBorderColor then return end

    local isDebuff = (skinnedButtons[button] == "debuff")
    local r, g, b  = GetBorderColor(button, isDebuff)
    frame:SetBackdropBorderColor(r, g, b, 1)

    -- Désaturation optionnelle des debuffs
    local icon = button.Icon or button.icon
    if icon and icon.SetDesaturated then
        if isDebuff and S().desaturateDebuffs then
            icon:SetDesaturated(true)
        else
            icon:SetDesaturated(false)
        end
    end
end

-- =====================================
-- TRAITEMENT DES CONTAINERS
-- =====================================

local function ProcessContainer(container, isDebuff)
    if not container then return end
    for _, child in ipairs({ container:GetChildren() }) do
        local icon = child.Icon or child.icon
        -- In Midnight, aura buttons use AuraButtonMixin with buttonInfo/auraInstanceID.
        -- Only skin visible buttons that have a valid icon texture set.
        if icon and child:IsShown() and icon:GetTexture() then
            SkinButton(child, isDebuff)
            UpdateButtonColor(child)
        end
    end
end

local function ApplyBuffSkin()
    if not IsEnabled() then return end

    local s = S()

    -- Buffs joueur
    if s.skinBuffs then
        if BuffFrame and BuffFrame.AuraContainer then
            ProcessContainer(BuffFrame.AuraContainer, false)
        end
    end

    -- Debuffs joueur
    if s.skinDebuffs then
        if DebuffFrame and DebuffFrame.AuraContainer then
            ProcessContainer(DebuffFrame.AuraContainer, true)
        end
    end

    -- Enchantements temporaires (weapon buffs)
    if s.skinBuffs and TemporaryEnchantFrame then
        for _, child in ipairs({ TemporaryEnchantFrame:GetChildren() }) do
            if child.Icon or child.icon then
                SkinButton(child, false)
                UpdateButtonColor(child)
            end
        end
    end
end

-- =====================================
-- FRAME HIDING — taint-safe (SetAlpha approach)
-- Uses SetAlpha(0) + EnableMouse(false) instead of Hide() to
-- prevent taint propagation on EditMode-managed frames.
-- Same pattern as ReputationBar, MythicTracker, Castbar fixes.
-- =====================================

local function HideFrameSafe(frame)
    frame:SetAlpha(0)
    if frame.EnableMouse then frame:EnableMouse(false) end
end

local function ShowFrameSafe(frame)
    frame:SetAlpha(1)
    if frame.EnableMouse then frame:EnableMouse(true) end
end

local function ApplyFrameHiding()
    local s = S()

    -- [PERF] Only apply initial state here; hooks are consolidated in InstallHooks()
    if BuffFrame then
        if s.hideBuffFrame then HideFrameSafe(BuffFrame) else ShowFrameSafe(BuffFrame) end
    end

    if DebuffFrame then
        if s.hideDebuffFrame then HideFrameSafe(DebuffFrame) else ShowFrameSafe(DebuffFrame) end
    end
end

-- =====================================
-- DEBOUNCE
-- =====================================

local function ScheduleUpdate()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.1, function()
        updatePending = false
        ApplyBuffSkin()
    end)
end

-- =====================================
-- HOOKS
-- AuraButton_Update hook = mettre à jour la couleur de border
-- quand Blizzard met à jour le type de l'aura.
-- =====================================

local function InstallHooks()
    -- Hook global AuraButton_Update (legacy, pre-Midnight)
    if type(AuraButton_Update) == "function" then
        hooksecurefunc("AuraButton_Update", function(button)
            if skinnedButtons[button] then
                local isDebuff = (skinnedButtons[button] == "debuff")
                    or (button:GetParent() and button:GetParent():GetParent() == DebuffFrame)
                SkinButton(button, isDebuff)
                UpdateButtonColor(button)
            end
        end)
    end

    -- Hook AuraButton_UpdateType (legacy, pre-Midnight)
    if type(AuraButton_UpdateType) == "function" then
        hooksecurefunc("AuraButton_UpdateType", function(button)
            UpdateButtonColor(button)
        end)
    end

    -- [PERF] Consolidated hooks: BuffFrame.Update and DebuffFrame.Update
    -- Previously had 2 hooks each (hiding + skinning). Now 1 hook each.
    -- Also integrates AuraContainer.Update to avoid redundant deferred calls.
    if BuffFrame and BuffFrame.Update then
        hooksecurefunc(BuffFrame, "Update", function()
            C_Timer.After(0, function()
                if S().hideBuffFrame then HideFrameSafe(BuffFrame) end
                ScheduleUpdate()
            end)
        end)
    end
    if DebuffFrame and DebuffFrame.Update then
        hooksecurefunc(DebuffFrame, "Update", function()
            C_Timer.After(0, function()
                if S().hideDebuffFrame then HideFrameSafe(DebuffFrame) end
                ScheduleUpdate()
            end)
        end)
    end

    -- AuraContainer hooks: call ScheduleUpdate directly (debounce handles dedup)
    if BuffFrame and BuffFrame.AuraContainer and BuffFrame.AuraContainer.Update then
        hooksecurefunc(BuffFrame.AuraContainer, "Update", ScheduleUpdate)
    end
    if DebuffFrame and DebuffFrame.AuraContainer and DebuffFrame.AuraContainer.Update then
        hooksecurefunc(DebuffFrame.AuraContainer, "Update", ScheduleUpdate)
    end

    -- [FIX] Hook TemporaryEnchantFrame for weapon enchant updates
    if TemporaryEnchantFrame and TemporaryEnchantFrame.Update then
        hooksecurefunc(TemporaryEnchantFrame, "Update", ScheduleUpdate)
    end
end

-- =====================================
-- API PUBLIQUE
-- =====================================

function BS.Initialize()
    if not IsEnabled() then return end

    -- [FIX] Hooks are installed once and persist across enable/disable toggles.
    -- Skin application is always repeatable.
    if not hooksInstalled then
        hooksInstalled = true

        -- [PERF] RegisterUnitEvent, not RegisterEvent: the handler only ever
        -- acted on "player", but an unfiltered UNIT_AURA wakes this frame for
        -- every unit whose auras change -- 20+ raid members plus every visible
        -- nameplate. Filtering at registration drops those dispatches entirely
        -- and keeps our insecure code out of Blizzard's BuffFrame/arena
        -- dispatch chain for the other units.
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
        eventFrame:SetScript("OnEvent", function()
            ScheduleUpdate()
        end)

        -- [FIX] Install hooks immediately — they just call ScheduleUpdate which
        -- debounces at 0.1s, so there's no timing concern.
        InstallHooks()
    end

    -- Defer skin application to let frames finish loading
    C_Timer.After(1, function()
        ApplyFrameHiding()
        ApplyBuffSkin()
    end)

    isInitialized = true
    StartDurationTicker()
end

function BS.ApplySettings()
    if not IsEnabled() then
        StopDurationTicker()
        return
    end
    wipe(skinnedButtons)
    ApplyFrameHiding()
    ApplyBuffSkin()
    StartDurationTicker()
end

function BS.SetEnabled(value)
    if not TomoModDB or not TomoModDB.buffSkin then return end
    TomoModDB.buffSkin.enabled = value
    if not value then StopDurationTicker() end
    if value then
        wipe(skinnedButtons)
        -- [FIX] Always call Initialize — hooks are guarded by hooksInstalled,
        -- so re-enabling after disable works correctly.
        BS.Initialize()
    end
end

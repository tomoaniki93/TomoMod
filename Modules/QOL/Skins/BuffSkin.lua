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
-- Teal accent pour les buffs du joueur
local BUFF_BORDER     = { r = 0.047, g = 0.824, b = 0.624 }

-- Fond sombre identique à ElvUI
local BG_COLOR = { r = 0.09, g = 0.09, b = 0.09, a = 0.95 }

-- Padding icône dans la border (1px comme ElvUI PixelMode)
local INSET = 2

local isInitialized   = false
local skinnedButtons  = setmetatable({}, { __mode = "k" })
local updatePending   = false
local buffHookDone    = false
local debuffHookDone  = false

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

    -- Buffs : teal accent si activé, sinon dark border
    if not isDebuff then
        local accent = settings.tealBorder ~= false  -- true par défaut
        if accent then
            return BUFF_BORDER.r, BUFF_BORDER.g, BUFF_BORDER.b
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

    -- Appliquer le backdrop ElvUI-style
    local r, g, b = GetBorderColor(button, isDebuff)
    ApplyBackdrop(button, r, g, b)

    if not skinnedButtons[button] then
        -- ── Icône insetée dans la border (comme ElvUI Icon:SetInside) ──────
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT",     button, "TOPLEFT",     INSET,  -INSET)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -INSET,  INSET)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetDrawLayer("ARTWORK", 0)

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

        -- ── Overlay de highlight souris (blanc translucide comme ElvUI) ────
        if not button._tomoHighlight then
            local hl = button:CreateTexture(nil, "HIGHLIGHT")
            hl:SetColorTexture(1, 1, 1, 0.15)
            hl:SetAllPoints(icon)
            button._tomoHighlight = hl
        end

        -- ── Police Poppins sur count et duration ────────────────────────────
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
        end

        -- ── Désaturation des debuffs ennemis (option) ────────────────────
        -- (appliquée dans UpdateButtonColor pour les debuffs uniquement)

        skinnedButtons[button] = isDebuff and "debuff" or "buff"
    end
end

-- =====================================
-- MISE À JOUR DE LA COULEUR DE BORDER
-- Appelée à chaque update d'aura pour refléter le type de dispel.
-- =====================================

local function UpdateButtonColor(button)
    if not skinnedButtons[button] then return end
    if not button.SetBackdropBorderColor then return end

    local isDebuff = (skinnedButtons[button] == "debuff")
    local r, g, b  = GetBorderColor(button, isDebuff)
    button:SetBackdropBorderColor(r, g, b, 1)

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
-- FRAME HIDING (inchangé, taint-safe)
-- =====================================

local _hidingPendingRegen = false

local function ApplyFrameHiding()
    if InCombatLockdown() then
        if not _hidingPendingRegen then
            _hidingPendingRegen = true
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            f:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                _hidingPendingRegen = false
                ApplyFrameHiding()
            end)
        end
        return
    end

    local s = S()

    if BuffFrame then
        if s.hideBuffFrame then BuffFrame:Hide() else BuffFrame:Show() end
        if not buffHookDone then
            buffHookDone = true
            hooksecurefunc(BuffFrame, "Show", function(self)
                C_Timer.After(0, function()
                    if S().hideBuffFrame then self:Hide() end
                end)
            end)
        end
    end

    if DebuffFrame then
        if s.hideDebuffFrame then DebuffFrame:Hide() else DebuffFrame:Show() end
        if not debuffHookDone then
            debuffHookDone = true
            hooksecurefunc(DebuffFrame, "Show", function(self)
                C_Timer.After(0, function()
                    if S().hideDebuffFrame then self:Hide() end
                end)
            end)
        end
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

    -- Hook BuffFrame.Update / DebuffFrame.Update (Midnight 12.x+)
    if BuffFrame and BuffFrame.Update then
        hooksecurefunc(BuffFrame, "Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end
    if DebuffFrame and DebuffFrame.Update then
        hooksecurefunc(DebuffFrame, "Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end

    -- Hook sur les containers Update pour attraper les nouveaux boutons
    if BuffFrame and BuffFrame.AuraContainer and BuffFrame.AuraContainer.Update then
        hooksecurefunc(BuffFrame.AuraContainer, "Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end
    if DebuffFrame and DebuffFrame.AuraContainer and DebuffFrame.AuraContainer.Update then
        hooksecurefunc(DebuffFrame.AuraContainer, "Update", function()
            C_Timer.After(0, ScheduleUpdate)
        end)
    end
end

-- =====================================
-- API PUBLIQUE
-- =====================================

function BS.Initialize()
    if isInitialized then return end
    if not IsEnabled() then return end
    isInitialized = true

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" and unit == "player" then
            ScheduleUpdate()
        end
    end)

    C_Timer.After(1, function()
        ApplyFrameHiding()
        ApplyBuffSkin()
        InstallHooks()
    end)
end

function BS.ApplySettings()
    if not IsEnabled() then return end
    wipe(skinnedButtons)
    ApplyFrameHiding()
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
            ApplyFrameHiding()
            ApplyBuffSkin()
        end
    end
end

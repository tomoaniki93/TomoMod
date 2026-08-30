-- =====================================================================
-- TeleportMenu.lua
-- Character Sheet shortcut for current-season Mythic+ dungeon teleports.
-- Uses TomoMod_DataKeys as the single source of season / teleport data.
-- =====================================================================

TomoMod_MythicTeleportMenu = TomoMod_MythicTeleportMenu or {}
local TM = TomoMod_MythicTeleportMenu
local DK = TomoMod_DataKeys

local ICON_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\TeleportMenu"
local FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local BG       = { 0.055, 0.060, 0.075, 0.98 }
local BG_CELL  = { 0.070, 0.075, 0.090, 0.98 }
local BORDER   = { 0.20, 0.22, 0.26, 0.90 }
local ACCENT   = { 0.05, 0.82, 0.62, 1.00 }
local TEXT     = { 0.94, 0.95, 0.97, 1.00 }
local DIM      = { 0.52, 0.54, 0.60, 1.00 }
local RED      = { 1.00, 0.28, 0.24, 1.00 }

local MAX_PORTALS = 8
local BUTTON_SIZE = 46
local CELL_W      = 58
local CELL_H      = 66
local COLS        = 4
local MENU_W      = 252
local MENU_H      = 166

local STRINGS = {
    enUS = {
        title = "Mythic+ Teleports",
        launcher = "Dungeon teleports",
        launcher_hint = "Click to open the current-season teleport menu.",
        known = "Click to teleport.",
        unknown = "Teleport not unlocked on this character.",
        combat = "Unavailable while in combat.",
    },
    frFR = {
        title = "Téléportations Mythic+",
        launcher = "Téléportations de donjon",
        launcher_hint = "Cliquez pour ouvrir les portails de la saison en cours.",
        known = "Cliquez pour vous téléporter.",
        unknown = "Téléportation non débloquée sur ce personnage.",
        combat = "Indisponible en combat.",
    },
    deDE = {
        title = "Mythisch+ Teleporte",
        launcher = "Dungeon-Teleporte",
        launcher_hint = "Klicken, um die Teleporte der aktuellen Saison zu öffnen.",
        known = "Klicken zum Teleportieren.",
        unknown = "Teleport auf diesem Charakter nicht freigeschaltet.",
        combat = "Im Kampf nicht verfügbar.",
    },
    esES = {
        title = "Teletransportes Mítico+",
        launcher = "Teletransportes de mazmorra",
        launcher_hint = "Haz clic para abrir los teletransportes de la temporada actual.",
        known = "Haz clic para teletransportarte.",
        unknown = "Teletransporte no desbloqueado en este personaje.",
        combat = "No disponible en combate.",
    },
    itIT = {
        title = "Teletrasporti Mitica+",
        launcher = "Teletrasporti spedizione",
        launcher_hint = "Clicca per aprire i teletrasporti della stagione corrente.",
        known = "Clicca per teletrasportarti.",
        unknown = "Teletrasporto non sbloccato su questo personaggio.",
        combat = "Non disponibile in combattimento.",
    },
    ptBR = {
        title = "Teletransportes Mítico+",
        launcher = "Teletransportes de masmorra",
        launcher_hint = "Clique para abrir os teletransportes da temporada atual.",
        known = "Clique para se teletransportar.",
        unknown = "Teletransporte não desbloqueado neste personagem.",
        combat = "Indisponível em combate.",
    },
}

local function T(key)
    local locale = GetLocale and GetLocale() or "enUS"
    local set = STRINGS[locale] or STRINGS.enUS
    return set[key] or STRINGS.enUS[key] or key
end

local function ApplyBackdrop(frame, bg, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bg or BG))
    frame:SetBackdropBorderColor(unpack(border or BORDER))
end

local function CharacterSkinEnabled()
    local db = TomoModDB and TomoModDB.characterSkin
    return db and db.enabled and db.skinCharacter
end

local function CharacterSheetVisible()
    return CharacterSkinEnabled()
        and _G.CharacterFrame and CharacterFrame:IsShown()
        and _G.PaperDollFrame and PaperDollFrame:IsShown()
end

local function GetSpellTextureSafe(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    if GetSpellTexture then
        local ok, texture = pcall(GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    return nil
end

local function GetMapTextureSafe(mapID)
    if not mapID or not C_ChallengeMode or not C_ChallengeMode.GetMapUIInfo then
        return nil
    end
    local ok, _, _, _, texture = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
    if ok then return texture end
    return nil
end

local function DungeonName(mapID)
    if DK and DK.GetDungeonName then
        return DK.GetDungeonName(mapID) or ("Dungeon " .. tostring(mapID))
    end
    return "Dungeon " .. tostring(mapID)
end

local function DungeonShort(mapID)
    if DK and DK.GetShortName then
        return DK.GetShortName(mapID) or "M+"
    end
    return "M+"
end

local function TeleportSpell(mapID)
    if DK and DK.GetTeleportSpellID then
        return DK.GetTeleportSpellID(mapID)
    end
end

local function TeleportKnown(spellID)
    if not spellID then return false end
    if DK and DK.IsTeleportKnown then
        return DK.IsTeleportKnown(spellID)
    end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    if IsSpellKnown and IsSpellKnown(spellID) then return true end
    return false
end

local function SeasonIDs()
    if DK and DK.RefreshFromAPI then
        DK.RefreshFromAPI()
    end
    if DK and DK.GetCurrentSeasonIDs then
        return DK.GetCurrentSeasonIDs() or {}
    end
    return {}
end

local function SetCellVisual(button, known)
    if known then
        button:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.85)
        button.icon:SetDesaturated(false)
        button.icon:SetAlpha(1)
        button.short:SetTextColor(unpack(TEXT))
    else
        button:SetBackdropBorderColor(unpack(BORDER))
        button.icon:SetDesaturated(true)
        button.icon:SetAlpha(0.35)
        button.short:SetTextColor(unpack(DIM))
    end
end

function TM:BuildMenu()
    if self.Frame or not _G.CharacterFrame then return self.Frame end

    local frame = CreateFrame("Frame", "TomoMod_MythicTeleportMenuFrame", UIParent, "BackdropTemplate")
    self.Frame = frame
    frame:SetSize(MENU_W, MENU_H)

    -- Keep the teleport palette outside/above the Character Sheet instead of
    -- covering the paper-doll/stat area.  It is parented to UIParent so the
    -- CharacterFrame cannot affect its strata, but it follows the Character
    -- Sheet scale and position.
    local function PositionMenu()
        if not CharacterFrame then return end
        local uiScale = UIParent:GetEffectiveScale() or 1
        local charScale = CharacterFrame:GetEffectiveScale() or uiScale
        frame:SetScale(charScale / uiScale)
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOM", CharacterFrame, "TOP", 0, 8)
    end
    frame.PositionMenu = PositionMenu
    PositionMenu()

    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:EnableKeyboard(false)
    ApplyBackdrop(frame, BG, BORDER)
    frame:Hide()

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetWidth(2)
    accent:SetColorTexture(unpack(ACCENT))

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 11, "")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText(T("title"))
    title:SetTextColor(unpack(TEXT))

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -6, -5)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(FONT_BOLD, 12, "")
    closeText:SetPoint("CENTER")
    closeText:SetText("x")
    closeText:SetTextColor(unpack(DIM))
    close:SetScript("OnEnter", function()
        closeText:SetTextColor(unpack(RED))
    end)
    close:SetScript("OnLeave", function()
        closeText:SetTextColor(unpack(DIM))
    end)
    close:SetScript("OnClick", function()
        if not InCombatLockdown() then frame:Hide() end
    end)

    self.Buttons = {}
    for i = 1, MAX_PORTALS do
        local button = CreateFrame("Button", "TomoMod_MythicTeleportButton" .. i, frame, "SecureActionButtonTemplate,BackdropTemplate")
        self.Buttons[i] = button
        button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        button:RegisterForClicks("AnyUp", "AnyDown")
        ApplyBackdrop(button, BG_CELL, BORDER)

        local col = (i - 1) % COLS
        local row = math.floor((i - 1) / COLS)
        button:SetPoint("TOPLEFT", 12 + col * CELL_W, -34 - row * CELL_H)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", -2, 2)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        local short = button:CreateFontString(nil, "OVERLAY")
        short:SetFont(FONT_BOLD, 8, "")
        short:SetPoint("TOP", button, "BOTTOM", 0, -3)
        short:SetWidth(CELL_W - 4)
        short:SetJustifyH("CENTER")
        button.short = short

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self._dungeonName or T("title"), unpack(TEXT))
            if InCombatLockdown() then
                GameTooltip:AddLine(T("combat"), unpack(RED))
            elseif self._known then
                GameTooltip:AddLine(T("known"), unpack(ACCENT))
            else
                GameTooltip:AddLine(T("unknown"), unpack(DIM))
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    CharacterFrame:HookScript("OnShow", function()
        PositionMenu()
    end)
    CharacterFrame:HookScript("OnHide", function()
        -- The teleport palette is parented to UIParent, so explicitly close it
        -- with the Character Sheet. Secure teleport buttons are never changed
        -- while combat lockdown is active.
        if not InCombatLockdown() then
            frame:Hide()
        end
    end)

    return frame
end

function TM:Refresh()
    if InCombatLockdown() then
        self._refreshPending = true
        return
    end

    local frame = self:BuildMenu()
    if not frame then return end

    local ids = SeasonIDs()
    for i = 1, MAX_PORTALS do
        local button = self.Buttons[i]
        local mapID = ids[i]

        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
        button._mapID = nil
        button._spellID = nil
        button._known = false
        button._dungeonName = nil

        if mapID then
            local spellID = TeleportSpell(mapID)
            local known = TeleportKnown(spellID)
            local texture = GetSpellTextureSafe(spellID) or GetMapTextureSafe(mapID)

            button._mapID = mapID
            button._spellID = spellID
            button._known = known
            button._dungeonName = DungeonName(mapID)
            button.short:SetText(DungeonShort(mapID))
            button.icon:SetTexture(texture or 134400)

            if known and spellID then
                button:SetAttribute("type", "spell")
                button:SetAttribute("spell", spellID)
            end

            SetCellVisual(button, known)
            button:Show()
        else
            button:Hide()
        end
    end

    self._refreshPending = nil
end

function TM:Toggle()
    if not CharacterSheetVisible() then
        if self.Frame and self.Frame:IsShown() and not InCombatLockdown() then
            self.Frame:Hide()
        end
        return
    end

    if InCombatLockdown() then
        if UIErrorsFrame then
            UIErrorsFrame:AddMessage(T("combat"), RED[1], RED[2], RED[3], 1)
        end
        return
    end

    local frame = self:BuildMenu()
    if not frame then return end

    if frame:IsShown() then
        frame:Hide()
    else
        self:Refresh()
        if frame.PositionMenu then frame:PositionMenu() end
        frame:Show()
    end
end

function TM:RefreshLauncherVisibility(subFrameName)
    local visible
    if subFrameName ~= nil then
        visible = CharacterSkinEnabled()
            and _G.CharacterFrame and CharacterFrame:IsShown()
            and subFrameName == "PaperDollFrame"
    else
        visible = CharacterSheetVisible()
    end

    if self.Launcher then
        self.Launcher:SetShown(visible and true or false)
    end

    if not visible and self.Frame and self.Frame:IsShown() then
        if InCombatLockdown() then
            self._hideMenuPending = true
        else
            self.Frame:Hide()
            self._hideMenuPending = nil
        end
    end
end

function TM:BuildLauncher()
    if self.Launcher or not _G.CharacterFrame then return self.Launcher end

    local button = CreateFrame("Button", "TomoMod_CharacterTeleportLauncher", CharacterFrame, "BackdropTemplate")
    self.Launcher = button
    -- Move the teleport launcher next to the close button and keep it smaller
    -- so it behaves like a discreet utility shortcut instead of a large header icon.
    button:SetSize(22, 22)
    if CharacterFrame.CloseButton then
        button:SetPoint("RIGHT", CharacterFrame.CloseButton, "LEFT", -4, 0)
    else
        button:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -32, -16)
    end
    button:SetFrameLevel(CharacterFrame:GetFrameLevel() + 35)
    button:EnableMouse(true)
    ApplyBackdrop(button, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(18, 18)
    icon:SetTexture(ICON_PATH)
    -- Keep the launcher deliberately subdued at rest, matching the Character
    -- Sheet close button instead of drawing more attention than the UI chrome.
    icon:SetVertexColor(0.60, 0.60, 0.60, 1)
    button.icon = icon

    button:SetScript("OnClick", function()
        TM:Toggle()
    end)
    button:SetScript("OnEnter", function(self)
        -- No separate hover overlay: tint the icon itself with TomoMod's accent.
        self.icon:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(T("launcher"), unpack(TEXT))
        GameTooltip:AddLine(T("launcher_hint"), unpack(DIM))
        if InCombatLockdown() then
            GameTooltip:AddLine(T("combat"), unpack(RED))
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(0.60, 0.60, 0.60, 1)
        GameTooltip:Hide()
    end)

    if _G.CharacterFrameMixin and _G.CharacterFrameMixin.ShowSubFrame and not self._subFrameHooked then
        self._subFrameHooked = true
        hooksecurefunc(_G.CharacterFrameMixin, "ShowSubFrame", function(_, name)
            TM:RefreshLauncherVisibility(name)
        end)
    end

    CharacterFrame:HookScript("OnShow", function()
        C_Timer.After(0, function()
            TM:RefreshLauncherVisibility()
            if CharacterSheetVisible() and not InCombatLockdown() then
                C_Timer.After(0.2, function()
                    if CharacterSheetVisible() then
                        TM:Refresh()
                    end
                end)
            end
        end)
    end)

    self:RefreshLauncherVisibility()
    self:BuildMenu()
    self:Refresh()
    return button
end

function TM:Initialize()
    if self._initialized then return end
    self._initialized = true

    local events = CreateFrame("Frame")
    self.EventFrame = events
    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("CHALLENGE_MODE_COMPLETED")

    events:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" and arg1 ~= "Blizzard_CharacterUI" then
            return
        end

        if event == "PLAYER_REGEN_ENABLED" then
            if TM._refreshPending or (TM.Frame and TM.Frame:IsShown()) then
                TM:Refresh()
            end
            if TM._hideMenuPending then
                TM._hideMenuPending = nil
                if TM.Frame and TM.Frame:IsShown() and not CharacterSheetVisible() then
                    TM.Frame:Hide()
                end
            end
            TM:RefreshLauncherVisibility()
            if TM.Frame and TM.Frame:IsShown() and (not CharacterFrame or not CharacterFrame:IsShown()) then
                TM.Frame:Hide()
            end
            return
        end

        if _G.CharacterFrame then
            C_Timer.After(0, function()
                TM:BuildLauncher()
                TM:RefreshLauncherVisibility()
                if event == "CHALLENGE_MODE_COMPLETED" then
                    C_Timer.After(1, function() TM:Refresh() end)
                end
            end)
        end
    end)

    if _G.CharacterFrame then
        C_Timer.After(0, function()
            TM:BuildLauncher()
            TM:RefreshLauncherVisibility()
        end)
    end
end

TM:Initialize()

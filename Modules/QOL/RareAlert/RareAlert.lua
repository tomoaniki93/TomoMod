-- =====================================
-- RareAlert.lua — Alerte de proximité des rares
-- =====================================
-- Avertit le joueur (son + bannière) quand un PNJ rare entre dans la portée de
-- la minimap, via l'API vignette de Blizzard (même source que RareScanner, sans
-- la base de données géante). Un clic gauche sur la bannière cible le rare, lui
-- pose la Tête de mort (marqueur 8) et crée un point de route ; clic droit ferme.
--
-- Notes TWW :
--   • Bouton sécurisé (SecureActionButtonTemplate) : la macro de ciblage ne peut
--     être posée qu'HORS combat. Si un rare apparaît en plein combat, la macro
--     est appliquée à la sortie de combat (PLAYER_REGEN_ENABLED).
--   • Aucun OnUpdate : 100 % piloté par événements (VIGNETTE_MINIMAP_UPDATED).
--   • Aucune arithmétique sur des valeurs secrètes.
-- =====================================

TomoMod_RareAlert = TomoMod_RareAlert or {}
local RA = TomoMod_RareAlert
local L  = TomoMod_L

local SKULL = 8  -- index du marqueur Tête de mort

-- Atlas de vignettes considérés comme "rare" (PNJ à tuer), d'après RareScanner.
-- Attention : la casse varie côté API ("VignetteKill" vs "vignettekillboss").
local RARE_ATLASES = {
    ["VignetteKill"]          = true,
    ["VignetteKillElite"]     = true,
    ["vignettekillboss"]      = true,
    ["DemonInvasion5"]        = true,
    ["nazjatar-nagaevent"]    = true,
    ["Warfront-NeutralHero"]  = true,
    ["Tormentors-Boss"]       = true,
}

local function IsRareAtlas(atlas)
    if not atlas then return false end
    if RARE_ATLASES[atlas] then return true end
    -- Robustesse : toute variante "vignettekill*" (casse libre), tout en
    -- excluant les coffres (VignetteLoot*) et les événements (VignetteEvent*).
    return atlas:lower():find("vignettekill", 1, true) ~= nil
end

local function DB() return TomoModDB and TomoModDB.rareAlert end

-- État du module
local banner        -- bannière (SecureActionButton)
local seen          -- déduplication : vignetteGUID -> true (réinitialisé par zone)
local pendingName       -- nom à appliquer à la macro à la sortie de combat
local hideTimer         -- C_Timer pour l'auto-masquage
local currentGUID       -- vignetteGUID actuellement affiché
local pendingHide       -- masquage différé (Hide interdit en combat)
local pendingShowGUID   -- affichage différé si le rare est apparu en combat

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

-- Macro sécurisée : cible le rare puis pose la Tête de mort (8). Le marqueur DOIT
-- être posé via /targetmarker (commande native, exécutée dans le contexte sécurisé
-- du bouton) : appeler SetRaidTarget() depuis du code addon est protégé et lève
-- ADDON_ACTION_FORBIDDEN (taint). TomoMod n'intercepte que /tm, pas /targetmarker.
local function BuildTargetMacro(name)
    return "/cleartarget\n/targetexact " .. (name or "") .. "\n/targetmarker " .. SKULL
end

-- =====================================
-- POSITION
-- =====================================
function RA.PositionBanner()
    if not banner then return end
    banner:ClearAllPoints()
    local d = DB()
    if d and d.position then
        banner:SetPoint(d.position.point or "CENTER", UIParent,
            d.position.relativePoint or "CENTER", d.position.x or 0, d.position.y or 0)
    else
        -- Défaut : haut-centre, bien visible
        banner:SetPoint("TOP", UIParent, "TOP", 0, -220)
    end
    banner:SetScale((d and d.scale) or 1.0)
end

-- =====================================
-- BANNIÈRE
-- =====================================
local function CreateBanner()
    if banner then return banner end

    banner = CreateFrame("Button", "TomoMod_RareAlertBanner", UIParent,
        "SecureActionButtonTemplate, BackdropTemplate")
    banner:SetSize(280, 46)
    banner:SetFrameStrata("HIGH")
    banner:SetFrameLevel(200)
    banner:SetClampedToScreen(true)
    banner:SetMovable(true)
    banner:RegisterForDrag("LeftButton")
    banner:RegisterForClicks("AnyUp", "AnyDown")
    banner:Hide()

    banner:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    banner:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    banner:SetBackdropBorderColor(0.180, 0.616, 0.847, 1)  -- teal #2e9dd8

    -- Icône Tête de mort à gauche
    local icon = banner:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    icon:SetSize(30, 30)
    icon:SetPoint("LEFT", banner, "LEFT", 8, 0)
    banner.icon = icon

    -- Nom du rare
    local title = banner:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 14, "OUTLINE")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetPoint("RIGHT", banner, "RIGHT", -8, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(0.95, 0.95, 0.97, 1)
    banner.title = title

    -- Clic gauche = macro de ciblage ; clic droit = fermer
    banner:SetAttribute("type1", "macro")
    banner:SetAttribute("type2", "closebanner")
    banner.closebanner = function() RA.HideAlert() end

    banner:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    banner:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local d = DB(); if not d then return end
        local sx, sy = self:GetCenter()
        local px, py = UIParent:GetCenter()
        if sx and sy and px and py then
            d.position = { point = "CENTER", relativePoint = "CENTER", x = sx - px, y = sy - py }
        end
    end)

    banner:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.6, 0.95, 0.85, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(self.rareName or "Rare", 0.180, 0.616, 0.847)
        GameTooltip:AddLine(L["rare_alert_tooltip"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    banner:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.180, 0.616, 0.847, 1)
        GameTooltip:Hide()
    end)

    -- Après le clic sécurisé : la cible ET le marqueur sont posés par la macro
    -- (/targetexact + /targetmarker). Ici on ne gère QUE le point de route, qui
    -- n'est pas protégé. NE PAS appeler SetRaidTarget() ici → taint.
    banner:SetScript("PostClick", function(self, button)
        if button == "RightButton" then return end
        if not self.rareName then return end
        if self.mapID and self.x and self.y
           and TomoMod_Waypoint and TomoMod_Waypoint.NewWaypoint then
            TomoMod_Waypoint.NewWaypoint(self.rareName, self.mapID, self.x * 100, self.y * 100)
        end
    end)

    RA.PositionBanner()
    return banner
end

-- =====================================
-- AFFICHER / MASQUER
-- =====================================
-- Le rare affiché est-il toujours présent (vivant / en portée) ?
local function VignettePresent(guid)
    if not (guid and C_VignetteInfo and C_VignetteInfo.GetVignettes) then return false end
    local list = C_VignetteInfo.GetVignettes()
    if not list then return false end
    for i = 1, #list do
        if list[i] == guid then return true end
    end
    return false
end

local function StartHideTimer(d)
    if hideTimer then hideTimer:Cancel() end
    local dur = (d and d.duration) or 20
    hideTimer = C_Timer.NewTimer(dur, function()
        hideTimer = nil
        RA.HideAlert()
    end)
end

function RA.ShowAlert(info, vignetteGUID)
    local d = DB(); if not d then return end
    if not banner then CreateBanner() end

    currentGUID    = vignetteGUID
    pendingHide    = nil
    banner.rareName = info.name or "Rare"

    -- Position du rare (pour le point de route au clic)
    banner.mapID, banner.x, banner.y = nil, nil, nil
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if mapID and C_VignetteInfo and C_VignetteInfo.GetVignettePosition then
        local pos = C_VignetteInfo.GetVignettePosition(vignetteGUID, mapID)
        if pos and pos.x and pos.y then
            banner.mapID, banner.x, banner.y = mapID, pos.x, pos.y
        end
    end

    banner.title:SetText(banner.rareName)

    -- Son (autorisé en combat)
    if d.sound ~= false then
        local snd = (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959
        PlaySound(snd, "Master")
    end

    -- Frame sécurisée : Show() ET SetAttribute sont INTERDITS en combat.
    -- Si le rare apparaît en plein combat, on diffère l'affichage + la macro à
    -- la sortie de combat (et seulement si le rare est encore présent).
    if InCombatLockdown() then
        pendingName     = banner.rareName
        pendingShowGUID = vignetteGUID
        return
    end

    banner:SetAttribute("macrotext", BuildTargetMacro(banner.rareName))
    pendingName = nil
    banner:Show()
    StartHideTimer(d)
end

function RA.HideAlert()
    -- Hide() est INTERDIT en combat sur une frame protégée (SecureActionButton)
    -- → on diffère le masquage à PLAYER_REGEN_ENABLED. C'était la cause de la
    -- bannière qui restait à l'écran après la mort du rare (timer déclenché en
    -- combat, Hide bloqué, plus rien ensuite pour masquer).
    if hideTimer then hideTimer:Cancel(); hideTimer = nil end
    if InCombatLockdown() then
        pendingHide = true
        return
    end
    pendingHide     = nil
    pendingShowGUID = nil
    currentGUID     = nil
    if banner then banner:Hide() end
end

-- =====================================
-- CONFIG HOOKS
-- =====================================
function RA.SetEnabled(enabled)
    if not enabled then RA.HideAlert() end
end

function RA.ApplySettings()
    if banner then RA.PositionBanner() end
end

-- =====================================
-- ÉVÉNEMENTS
-- =====================================
-- Les rares n'apparaissent qu'en monde ouvert : on n'alerte jamais en donjon
-- (« party ») ni en raid (« raid »).
local function InDungeonOrRaid()
    local _, instanceType = IsInInstance()
    return instanceType == "party" or instanceType == "raid"
end

local function OnEvent(_, event, arg1, arg2)
    if event == "VIGNETTE_MINIMAP_UPDATED" then
        local d = DB(); if not d or not d.enabled then return end
        if InDungeonOrRaid() then return end        -- pas d'alerte rare en donjon/raid
        local vignetteGUID, onMinimap = arg1, arg2
        if not vignetteGUID then return end

        -- Le rare actuellement affiché quitte la minimap (mort / hors portée) → masquer
        if currentGUID and vignetteGUID == currentGUID and not onMinimap then
            RA.HideAlert()
            return
        end

        if not onMinimap then return end           -- "proche" = présent sur la minimap
        if seen[vignetteGUID] then return end       -- déduplication
        if not (C_VignetteInfo and C_VignetteInfo.GetVignetteInfo) then return end
        local info = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
        if not info or not IsRareAtlas(info.atlasName) then return end
        seen[vignetteGUID] = true
        RA.ShowAlert(info, vignetteGUID)

    elseif event == "VIGNETTES_UPDATED" then
        -- La liste des vignettes a changé : si le rare affiché n'existe plus
        -- (tué / hors zone), on masque la bannière.
        if currentGUID and not VignettePresent(currentGUID) then
            RA.HideAlert()
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Sortie de combat : traiter les actions qui étaient interdites en combat.
        if pendingHide then
            RA.HideAlert()                      -- masque réellement maintenant
            return
        end
        if pendingShowGUID then
            local guid = pendingShowGUID
            pendingShowGUID = nil
            if banner and VignettePresent(guid) then
                banner:SetAttribute("macrotext", BuildTargetMacro(pendingName or banner.rareName))
                pendingName = nil
                banner:Show()
                StartHideTimer(DB())
            else
                pendingName = nil
                currentGUID = nil               -- le rare est mort/parti pendant le combat
            end
        elseif pendingName and banner then
            banner:SetAttribute("macrotext", BuildTargetMacro(pendingName))
            pendingName = nil
        end

    else  -- ZONE_CHANGED_NEW_AREA / PLAYER_ENTERING_WORLD
        wipe(seen)
        RA.HideAlert()
    end
end

function RA.Initialize()
    if not C_VignetteInfo then return end  -- client trop ancien : rien à faire
    seen = seen or {}
    if RA._ev then return end
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
    ev:RegisterEvent("VIGNETTES_UPDATED")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    ev:SetScript("OnEvent", OnEvent)
    RA._ev = ev
end

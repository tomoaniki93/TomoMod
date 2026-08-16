-- =====================================
-- Minimap.lua
-- =====================================

TomoMod_Minimap = TomoMod_Minimap or {}
local minimapBorder
local trackingButton
local _tmTrackingWantShown = false -- guards CreateTrackingButton's Hide/SetAlpha reassertion hooks
local _tmAlphaGuardTracking
local isLocked = true
local moverOverlay

-- =====================================
-- FORME DE LA MINIMAP (compatibilité boutons d'addon)
-- =====================================
-- Les boutons d'addon (LibDBIcon & co.) se positionnent par trigonométrie et
-- appellent GetMinimapShape() pour savoir si le bord est rond ou carré. Si la
-- fonction n'existe pas, ils supposent "ROUND" et se collent sur le cercle
-- inscrit — l'ancien anneau Blizzard — au lieu de notre bord carré.
-- On déclare donc GetMinimapShape DÈS LE CHARGEMENT (avant le PLAYER_LOGIN où
-- LibDBIcon positionne ses boutons), en renvoyant "SQUARE" quand notre minimap
-- est active. On préserve une éventuelle implémentation préexistante.
local _prevGetMinimapShape = GetMinimapShape
function GetMinimapShape()
    if TomoModDB and TomoModDB.minimap and TomoModDB.minimap.enabled ~= false then
        return "SQUARE"
    end
    if _prevGetMinimapShape then return _prevGetMinimapShape() end
    return "ROUND"
end

-- Force LibDBIcon à recalculer la position de ses boutons avec la nouvelle
-- forme (utile si LibDBIcon a déjà placé ses boutons avant que GetMinimapShape
-- soit déclaré — l'ordre de chargement des addons n'est pas garanti).
-- IMPORTANT : on saute les boutons que notre collecteur a déjà capturés dans la
-- boîte, sinon lib:Refresh les réancrerait au centre de la minimap (les sortant
-- de la boîte).
function TomoMod_Minimap.RefreshAddonButtonShapes()
    if not LibStub then return end
    local ldbi = LibStub("LibDBIcon-1.0", true)  -- true = silencieux si absent
    if not ldbi or not ldbi.objects then return end
    for name in pairs(ldbi.objects) do
        local btn = ldbi.objects[name]
        if ldbi.Refresh and not (btn and TomoMod_Minimap.IsButtonCollected and TomoMod_Minimap.IsButtonCollected(btn)) then
            pcall(ldbi.Refresh, ldbi, name)
        end
    end
end

-- Masquer la forme ronde et rendre carré
function TomoMod_Minimap.MakeSquare()
    Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
    Minimap:SetArchBlobRingScalar(0)
    Minimap:SetQuestBlobRingScalar(0)
    Minimap:SetSize(TomoModDB.minimap.size, TomoModDB.minimap.size)
    
    -- Cache les éléments ronds de Blizzard
    local framesToHide = {
        MinimapBorder,
        MinimapBorderTop,
        MinimapZoomIn,
        MinimapZoomOut,
        MiniMapTracking,
        MiniMapWorldMapButton,
        MinimapCompassTexture,
    }
    
    for _, frame in pairs(framesToHide) do
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
            frame:EnableMouse(false)
        end
    end
    
    -- Sécurité supplémentaire
    if MinimapBorder then MinimapBorder:Hide() end
    if MinimapBorderTop then MinimapBorderTop:Hide() end
    if MinimapZoomIn then MinimapZoomIn:Hide() end
    if MinimapZoomOut then MinimapZoomOut:Hide() end
    
    Minimap:SetClampedToScreen(true)
end

-- Créer la bordure personnalisée
function TomoMod_Minimap.CreateBorder()
    if not minimapBorder then
        minimapBorder = CreateFrame("Frame", "TomoModMinimapBorder", Minimap, "BackdropTemplate")
        minimapBorder:SetAllPoints(Minimap)
        minimapBorder:SetFrameLevel(Minimap:GetFrameLevel() + 1)
    end
    
    local r, g, b, a = 0, 0, 0, 1
    if TomoModDB.minimap.borderColor == "class" then
        r, g, b, a = TomoMod_Utils.GetClassColor()
    end
    
    minimapBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    minimapBorder:SetBackdropBorderColor(r, g, b, a)

    -- Sync InfoPanel bars border color
    if TomoMod_InfoPanel and TomoMod_InfoPanel.UpdateAppearance then
        TomoMod_InfoPanel.UpdateAppearance()
    end

    -- Sync la teinte du bouton de pistage
    if trackingButton and TomoMod_Minimap.CreateTrackingButton then
        TomoMod_Minimap.CreateTrackingButton()
    end
end

-- Appliquer le scale
function TomoMod_Minimap.ApplyScale()
    Minimap:SetScale(TomoModDB.minimap.scale)
end

-- =====================================
-- BOUTON DE PISTAGE (poste, mascottes, minerai, herbes…)
-- =====================================
-- Stratégie : déléguer au bouton natif moderne MinimapCluster.Tracking.Button
-- (chemin 11.0+/12.0, inclut automatiquement Townsfolk + pistage Chasseur).
-- Repli : reconstruire le menu via C_Minimap + MenuUtil si le natif est absent.

-- Ouvre le menu de pistage natif en simulant un clic sur le bouton Blizzard.
local function OpenNativeTrackingMenu()
    local cluster = MinimapCluster
    local nativeBtn = cluster and cluster.Tracking and cluster.Tracking.Button
    if not nativeBtn then return false end
    -- Le bouton natif est masqué/désactivé par notre reskin : on le réveille
    -- juste le temps de déclencher son OnMouseDown/OnClick, sans le ré-afficher.
    local handler = nativeBtn:GetScript("OnMouseDown") or nativeBtn:GetScript("OnClick")
    if not handler then return false end
    local ok = pcall(handler, nativeBtn, "LeftButton")
    return ok
end

-- Repli : lit la liste de pistage et bâtit un menu MenuUtil (système déjà
-- utilisé ailleurs dans TomoMod). Gère la table structurée 11.0+ ET
-- l'ancienne signature multi-valeurs.
local function ReadTrackingInfo(i)
    local info = C_Minimap.GetTrackingInfo(i)
    if type(info) == "table" then
        return info.name, info.texture or info.textureFileID, info.active, info.nested, info.filterID
    else
        -- ancienne signature : name, texture, active, category, nested, spellID
        local name, texture, active, _, nested = C_Minimap.GetTrackingInfo(i)
        return name, texture, active, nested
    end
end

local function OpenFallbackTrackingMenu(anchor)
    if not (MenuUtil and MenuUtil.CreateContextMenu and C_Minimap and C_Minimap.GetNumTrackingTypes) then
        return false
    end
    MenuUtil.CreateContextMenu(anchor, function(_, root)
        root:SetMinimumWidth(1)
        root:CreateTitle(MINIMAP_TRACKING_TITLE or TRACKING or "Pistage")
        local count = C_Minimap.GetNumTrackingTypes() or 0
        for i = 1, count do
            local name, _, _, nested = ReadTrackingInfo(i)
            -- On n'affiche que les entrées de niveau racine (nested == -1 ou nil)
            -- pour rester simple ; le menu natif gère les sous-catégories.
            if name and (nested == nil or nested < 0) then
                local idx = i
                root:CreateCheckbox(name,
                    function() local _, _, a = ReadTrackingInfo(idx); return a end,
                    function() local _, _, a = ReadTrackingInfo(idx); C_Minimap.SetTracking(idx, not a); return MenuResponse and MenuResponse.Refresh end)
            end
        end
    end)
    return true
end

-- =====================================
-- PANNEAU DE PISTAGE CUSTOM (style TomoMod)
-- =====================================
local trackingPanel   = nil
local trackingRowPool = {}
local TM_PANEL_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local TM_PANEL_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- Applique le toggle de pistage selon l'API disponible (filterID TWW ou index legacy).
local function TM_SetTracking(idx, active)
    local _, _, _, _, filterID = ReadTrackingInfo(idx)
    if filterID ~= nil then
        pcall(C_Minimap.SetTracking, filterID, active)
    else
        pcall(C_Minimap.SetTracking, idx, active)
    end
end

local function OpenTrackingPanel()
    local count = (C_Minimap and C_Minimap.GetNumTrackingTypes) and C_Minimap.GetNumTrackingTypes() or 0
    local entries = {}
    for i = 1, count do
        local name, tex, _, nested = ReadTrackingInfo(i)
        if name and (nested == nil or nested < 0) then
            entries[#entries + 1] = { idx = i, name = name, tex = tex }
        end
    end

    local PAD     = 8
    local ROW_H   = 24
    local PW      = 244
    local TITLE_H = 28
    local MAX_H   = 380
    local contH   = math.max(#entries * ROW_H, 1)
    local scrollH = math.min(contH, MAX_H)
    local panelH  = TITLE_H + 1 + PAD + scrollH + PAD

    -- Créer le panel une seule fois
    if not trackingPanel then
        trackingPanel = CreateFrame("Frame", "TomoModTrackingPanel", UIParent, "BackdropTemplate")
        trackingPanel:SetFrameStrata("DIALOG")
        trackingPanel:SetFrameLevel(100)
        trackingPanel:SetClampedToScreen(true)
        trackingPanel:Hide()

        -- Titre (teal accent)
        local t = trackingPanel:CreateFontString(nil, "OVERLAY")
        t:SetFont(TM_PANEL_FONT_BOLD, 11, "")
        t:SetPoint("TOPLEFT", PAD, -PAD)
        t:SetText(MINIMAP_TRACKING_TITLE or TRACKING or "Pistage")
        t:SetTextColor(0.05, 0.82, 0.62, 1)

        -- Séparateur horizontal
        local sep = trackingPanel:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetPoint("TOPLEFT",  PAD,  -TITLE_H)
        sep:SetPoint("TOPRIGHT", -PAD, -TITLE_H)
        sep:SetColorTexture(0.2, 0.2, 0.25, 0.8)

        -- ScrollFrame (défilement à la molette si liste longue)
        local sf = CreateFrame("ScrollFrame", nil, trackingPanel)
        sf:SetPoint("TOPLEFT",     PAD,  -(TITLE_H + 1 + PAD))
        sf:SetPoint("BOTTOMRIGHT", -PAD, PAD)
        sf:EnableMouseWheel(true)
        sf:SetScript("OnMouseWheel", function(self, d)
            local cur = self:GetVerticalScroll()
            self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - d * ROW_H)))
        end)
        trackingPanel._sf = sf

        local sc = CreateFrame("Frame", nil, sf)
        sc:SetWidth(PW - PAD * 2)
        sf:SetScrollChild(sc)
        trackingPanel._sc = sc
    end

    -- Style (couleur de bordure peut avoir changé)
    local r, g, b = 0.2, 0.2, 0.25
    if TomoModDB.minimap.borderColor == "class" then r, g, b = TomoMod_Utils.GetClassColor() end
    trackingPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    trackingPanel:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    trackingPanel:SetBackdropBorderColor(r, g, b, 1)
    trackingPanel:SetSize(PW, panelH)
    trackingPanel._sc:SetSize(PW - PAD * 2, contH)

    -- Masquer les lignes excédentaires du pool
    for n = #entries + 1, #trackingRowPool do
        if trackingRowPool[n] then trackingRowPool[n]:Hide() end
    end

    -- Créer / mettre à jour les lignes
    for i, entry in ipairs(entries) do
        if not trackingRowPool[i] then
            local row = CreateFrame("Button", nil, trackingPanel._sc)
            row:SetHeight(ROW_H)

            local hl = row:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints(); hl:SetColorTexture(0, 0, 0, 0)
            row.hl = hl

            local ico = row:CreateTexture(nil, "ARTWORK")
            ico:SetSize(16, 16); ico:SetPoint("LEFT", 0, 0)
            ico:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            row.ico = ico

            local chk = row:CreateTexture(nil, "OVERLAY")
            chk:SetSize(10, 10); chk:SetPoint("RIGHT", 0, 0)
            row.chk = chk

            local lbl = row:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(TM_PANEL_FONT, 10, "")
            lbl:SetPoint("LEFT", 22, 0); lbl:SetPoint("RIGHT", -18, 0)
            lbl:SetJustifyH("LEFT"); lbl:SetTextColor(0.9, 0.9, 0.9, 1)
            row.lbl = lbl

            row:SetScript("OnEnter", function(self)
                self.hl:SetColorTexture(0.05, 0.82, 0.62, 0.12)
                self.lbl:SetTextColor(1, 1, 1, 1)
            end)
            row:SetScript("OnLeave", function(self)
                self.hl:SetColorTexture(0, 0, 0, 0)
                self.lbl:SetTextColor(0.9, 0.9, 0.9, 1)
            end)
            trackingRowPool[i] = row
        end

        local row = trackingRowPool[i]
        row:SetParent(trackingPanel._sc)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        row:SetWidth(PW - PAD * 2)
        row.lbl:SetText(entry.name)
        if entry.tex then row.ico:SetTexture(entry.tex); row.ico:Show() else row.ico:Hide() end

        -- État de la checkbox
        local idx = entry.idx
        local function Refresh()
            local _, _, active = ReadTrackingInfo(idx)
            if active then
                row.chk:SetColorTexture(0.05, 0.82, 0.62, 1)
            else
                row.chk:SetColorTexture(0.3, 0.3, 0.35, 0.8)
            end
        end
        Refresh()
        row:SetScript("OnClick", function()
            local _, _, active = ReadTrackingInfo(idx)
            TM_SetTracking(idx, not active)
            C_Timer.After(0.05, Refresh)
        end)
        row:Show()
    end

    -- Ancrage : panel à gauche de la minimap, centré verticalement
    trackingPanel:ClearAllPoints()
    trackingPanel:SetPoint("RIGHT", Minimap, "LEFT", -4, 0)
    trackingPanel:Show()
end

local function ToggleTrackingPanel()
    if trackingPanel and trackingPanel:IsShown() then
        trackingPanel:Hide()
    else
        OpenTrackingPanel()
    end
end

function TomoMod_Minimap.CreateTrackingButton()
    -- Respecte le toggle ET le style choisi (TomoMod vs Blizzard natif)
    if TomoModDB.minimap.showTracking == false
       or (TomoModDB.minimap.trackingStyle or "tomomod") ~= "tomomod" then
        _tmTrackingWantShown = false
        if trackingButton then trackingButton:Hide() end
        if trackingPanel then trackingPanel:Hide() end
        if TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
        return
    end

    if not trackingButton then
        trackingButton = CreateFrame("Button", "TomoModMinimapTracking", Minimap)
        trackingButton:SetSize(22, 22)
        trackingButton:SetFrameLevel(Minimap:GetFrameLevel() + 5)

        -- Fond discret
        local bg = trackingButton:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.45)
        trackingButton.bg = bg

        -- Icône de pistage (compas TomoMod)
        local ico = trackingButton:CreateTexture(nil, "ARTWORK")
        ico:SetPoint("CENTER")
        ico:SetSize(16, 16)
        ico:SetTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\icons\\ico_minimap_tracking.tga")
        trackingButton.ico = ico

        -- Bordure fine
        local border = CreateFrame("Frame", nil, trackingButton, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        border:SetBackdropBorderColor(0, 0, 0, 0)
        trackingButton.border = border

        trackingButton:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0.7)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(MINIMAP_TRACKING_TITLE or TRACKING or "Pistage", 1, 1, 1)
            GameTooltip:Show()
        end)
        trackingButton:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0.45)
            GameTooltip:Hide()
        end)
        trackingButton:SetScript("OnMouseDown", function(self)
            ToggleTrackingPanel()
        end)

        -- [FIX] Defends against anything else (another addon walking minimap
        -- children, Blizzard's own square-minimap/skin code, Edit Mode, etc.)
        -- silently calling Hide()/SetAlpha(0) on OUR OWN button — a plain
        -- Hide() throws no Lua error, so this kind of interference would never
        -- show up in Diagnostics even though the button visibly disappears.
        -- Reassert visibility immediately whenever we still want it shown.
        trackingButton:HookScript("OnHide", function(self)
            if _tmTrackingWantShown and not InCombatLockdown() then
                self:Show()
            end
        end)
        hooksecurefunc(trackingButton, "SetAlpha", function(self, alpha)
            if _tmAlphaGuardTracking then return end
            if _tmTrackingWantShown and alpha == 0 then
                _tmAlphaGuardTracking = true
                self:SetAlpha(1)
                _tmAlphaGuardTracking = nil
            end
        end)
    end

    -- Position + échelle depuis la config (ré-appliquées à chaque appel pour le live)
    local corner, scale, x, y = TomoMod_Minimap.GetIndicatorCfg("tracking")
    trackingButton:ClearAllPoints()
    trackingButton:SetPoint(corner, Minimap, corner, x, y)
    trackingButton:SetScale(scale)

    -- Teinte couleur de classe (cohérent avec la bordure de minimap)
    local r, g, b = 0.9, 0.9, 0.9
    if TomoModDB.minimap.borderColor == "class" then
        r, g, b = TomoMod_Utils.GetClassColor()
    end
    trackingButton.border:SetBackdropBorderColor(0, 0, 0, 0)
    trackingButton.ico:SetVertexColor(r, g, b, 1)

    _tmTrackingWantShown = true
    trackingButton:SetAlpha(1)
    trackingButton:Show()
    if TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
end

-- =====================================
-- INDICATEURS NATIFS (courrier, difficulté, extension, commandes de craft)
-- =====================================
-- On réutilise les frames Blizzard existantes (qui gèrent déjà leur propre
-- logique d'affichage) en les ré-ancrant sur notre minimap carrée.
-- Noms confirmés sur le retail actuel (12.x) :
--   courrier      : MinimapCluster.IndicatorFrame.MailFrame
--   commandes     : MinimapCluster.IndicatorFrame.CraftingOrderFrame
--   difficulté    : MinimapCluster.InstanceDifficulty
--   extension     : ExpansionLandingPageMinimapButton

-- Résout une frame depuis un chemin "A.B.C" (renvoie nil si un maillon manque).
local function ResolveFrame(path)
    local node = _G
    for key in string.gmatch(path, "[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[key] or (type(node) == "table" and rawget(node, key))
        if node == nil then return nil end
    end
    return node
end

-- Lit la config (coin/échelle/décalage) d'un indicateur, avec valeurs de repli.
local DEFAULT_IND = {
    tracking   = { corner = "TOPLEFT",     scale = 1.0, x = 2,  y = -2 },
    mail       = { corner = "BOTTOMRIGHT", scale = 1.0, x = -2, y = 2  },
    crafting   = { corner = "BOTTOMRIGHT", scale = 1.0, x = -2, y = 26 },
    difficulty = { corner = "TOPRIGHT",    scale = 1.0, x = -2, y = -2 },
    expansion  = { corner = "BOTTOMLEFT",  scale = 1.0, x = 2,  y = 2  },
}

function TomoMod_Minimap.GetIndicatorCfg(key)
    local def = DEFAULT_IND[key] or { corner = "TOPLEFT", scale = 1.0, x = 0, y = 0 }
    local db  = TomoModDB.minimap and TomoModDB.minimap.indicators
    local cfg = db and db[key]
    if not cfg then return def.corner, def.scale, def.x, def.y end
    return cfg.corner or def.corner, cfg.scale or def.scale, cfg.x or def.x, cfg.y or def.y
end

-- Frames dont NOUS avons forcé l'alpha à 0. Blizzard pilote la visibilité
-- réelle de ces indicateurs (le drapeau de difficulté ne s'affiche qu'en
-- instance, l'icône de courrier qu'avec du courrier non lu) : un SetAlpha(1)
-- inconditionnel à chaque passe écrasait cette logique. C'est ce qui laissait
-- la difficulté affichée hors instance, et ce qui faisait passer l'option pour
-- cassée — une fois décochée puis recochée, notre unique SetAlpha(1) était
-- aussitôt défait par la mise à jour de Blizzard et l'icône ne revenait pas.
-- On ne défait donc plus que notre propre masquage, en restaurant exactement
-- l'alpha qu'on avait écrasé.
local _forcedHidden = {}

-- Maintient à 0 l'alpha d'un indicateur que le joueur a désactivé : Blizzard le
-- réaffiche de son côté (entrée en instance, courrier reçu) et un alpha posé une
-- seule fois ne tiendrait pas. On ne touche QUE l'alpha — ni la souris ni l'état
-- Shown, qui restent à Blizzard : c'est précisément le fait de lui confisquer
-- ces états qui produisait le bug d'origine.
local _holdHooked   = {}
local _holdAlphaFix = {}

local function HoldHidden(frame)
    if _holdHooked[frame] then return end
    _holdHooked[frame] = true
    hooksecurefunc(frame, "Show", function(self)
        if _forcedHidden[self] then self:SetAlpha(0) end
    end)
    hooksecurefunc(frame, "SetAlpha", function(self, alpha)
        if _holdAlphaFix[self] or alpha == 0 then return end
        if _forcedHidden[self] then
            _holdAlphaFix[self] = true
            self:SetAlpha(0)
            _holdAlphaFix[self] = nil
        end
    end)
end

-- [3.5.7] Blizzard's native indicators (mail, crafting orders, difficulty)
-- call self:GetParent():Layout() at the end of their own OnEvent handlers,
-- expecting MinimapCluster.IndicatorFrame's real Layout() method. Once
-- reparented onto Minimap/TomoModMinimapBorder for positioning, that call hit
-- a nil method ("attempt to call a nil value") -- Show()/Hide() already ran
-- by that point, so the crash cost nothing visible, but a stub is cheaper
-- than an error every mail/crafting update. A harmless no-op: we position
-- these indicators ourselves via SetPoint, so nothing needs Blizzard's own
-- layout pass to actually run.
local function noop() end
if not Minimap.Layout then Minimap.Layout = noop end

local function AnchorBlizzFrame(frame, show, key)
    if not frame then return end
    if show == false then
        frame:SetParent(TomoModMinimapBorder or Minimap)
        if TomoModMinimapBorder and not TomoModMinimapBorder.Layout then TomoModMinimapBorder.Layout = noop end
        frame:ClearAllPoints()
        if not _forcedHidden[frame] then
            _forcedHidden[frame] = { prevAlpha = frame:GetAlpha() }
        end
        frame:SetAlpha(0)
        HoldHidden(frame)
        return
    end
    local corner, scale, x, y = TomoMod_Minimap.GetIndicatorCfg(key)
    frame:SetParent(Minimap)
    local hidden = _forcedHidden[frame]
    if hidden then
        _forcedHidden[frame] = nil
        frame:SetAlpha(hidden.prevAlpha or 1)
    end
    frame:ClearAllPoints()
    frame:SetPoint(corner, Minimap, corner, x, y)
    if frame.SetScale then frame:SetScale(scale) end
    frame:SetFrameLevel(Minimap:GetFrameLevel() + 6)
end

local expansionHooked = false

function TomoMod_Minimap.ApplyNativeIndicators()
    local db = TomoModDB.minimap

    -- Courrier
    local mail = ResolveFrame("MinimapCluster.IndicatorFrame.MailFrame")
    AnchorBlizzFrame(mail, db.showMail ~= false, "mail")

    -- Commandes de craft
    local crafting = ResolveFrame("MinimapCluster.IndicatorFrame.CraftingOrderFrame")
    AnchorBlizzFrame(crafting, db.showCraftingOrder ~= false, "crafting")

    -- Difficulté d'instance
    local diff = ResolveFrame("MinimapCluster.InstanceDifficulty")
    AnchorBlizzFrame(diff, db.showDifficulty ~= false, "difficulty")

    -- Bouton d'extension / domaine (garnison, sanctuaire de classe, etc.).
    -- Il se redimensionne/repositionne tout seul : on le contraint via hooks.
    local expansion = ResolveFrame("ExpansionLandingPageMinimapButton")
    if expansion then
        if db.showExpansion ~= false then
            -- Même défaut que ci-dessus, en pire : la branche « masquer »
            -- posait un alpha 0 que rien ne restaurait ici, donc désactiver
            -- puis réactiver le bouton d'extension le laissait invisible
            -- définitivement.
            local hidden = _forcedHidden[expansion]
            if hidden then
                _forcedHidden[expansion] = nil
                expansion:SetAlpha(hidden.prevAlpha or 1)
            end
            local function Pin()
                local corner, scale, x, y = TomoMod_Minimap.GetIndicatorCfg("expansion")
                expansion:SetParent(Minimap)
                expansion:ClearAllPoints()
                expansion:SetPoint(corner, Minimap, corner, x, y)
                if expansion.SetScale then expansion:SetScale(scale) end
                expansion:SetFrameLevel(Minimap:GetFrameLevel() + 6)
            end
            Pin()
            if not expansionHooked then
                expansionHooked = true
                -- Blizzard recale la taille/position via ces méthodes : on repince après.
                if expansion.SetSize then
                    hooksecurefunc(expansion, "SetSize", function() if TomoModDB.minimap.showExpansion ~= false then Pin() end end)
                end
                if type(expansion.UpdateIconForGarrison) == "function" then
                    hooksecurefunc(expansion, "UpdateIconForGarrison", function() if TomoModDB.minimap.showExpansion ~= false then Pin() end end)
                end
                if type(expansion.SetLandingPageIconOffset) == "function" then
                    hooksecurefunc(expansion, "SetLandingPageIconOffset", function() if TomoModDB.minimap.showExpansion ~= false then Pin() end end)
                end
            end
        else
            expansion:SetParent(TomoModMinimapBorder or Minimap)
            expansion:ClearAllPoints()
            if not _forcedHidden[expansion] then
                _forcedHidden[expansion] = { prevAlpha = expansion:GetAlpha() }
            end
            expansion:SetAlpha(0)
            HoldHidden(expansion)
        end
    end
end

-- =====================================
-- COLLECTEUR DE BOUTONS D'ADDON
-- =====================================
-- Un bouton déclencheur sur la minimap ouvre une boîte qui regroupe tous les
-- boutons d'addon qui s'accrochent normalement autour de la minimap.
-- On reparente les vrais boutons dans la boîte (pas de copie), avec une
-- heuristique pour ne ramasser ni les frames Blizzard, ni nos propres frames,
-- ni les overlays de carte (GatherMate2, HandyNotes…).

local bagFrame, bagToggle
local bagUserOpened = false   -- true si l'utilisateur a ouvert le panneau de lui-même
local collectedButtons = {}      -- [frame] = true (déjà ramassé)
local collectedOrder = {}        -- liste ordonnée pour le layout
local savedButtonState = {}      -- [frame] = état d'origine (pour restauration)

-- Le collecteur a-t-il capturé ce bouton ? (utilisé par RefreshAddonButtonShapes)
function TomoMod_Minimap.IsButtonCollected(frame)
    return collectedButtons[frame] == true
end

-- =====================================
-- DÉTECTION DES BOUTONS D'ADDON
-- =====================================
-- Blacklist de NOMS EXACTS de frames Blizzard qui vivent sur la minimap mais ne
-- sont PAS des boutons d'addon. Remplace l'ancien matching par préfixe trop
-- large ("Minimap"/"MiniMap") qui excluait à tort les boutons d'addon nommés
-- "<Addon>MinimapButton".
local BLIZZ_MINIMAP_FRAMES = {
    ["MinimapZoomIn"] = true, ["MinimapZoomOut"] = true,
    ["MinimapNorthTag"] = true, ["MinimapCompassTexture"] = true,
    ["MiniMapWorldMapButton"] = true, ["MinimapZoneTextButton"] = true,
    ["MiniMapTracking"] = true, ["MiniMapTrackingButton"] = true, ["MiniMapTrackingFrame"] = true,
    ["MiniMapMailFrame"] = true, ["MiniMapMailIcon"] = true,
    ["GameTimeFrame"] = true, ["TimeManagerClockButton"] = true,
    ["MiniMapInstanceDifficulty"] = true, ["GuildInstanceDifficulty"] = true,
    ["MiniMapChallengeMode"] = true, ["MiniMapBattlefieldFrame"] = true,
    ["MiniMapLFGFrame"] = true, ["MiniMapVoiceChatFrame"] = true,
    ["QueueStatusButton"] = true, ["QueueStatusMinimapButton"] = true,
    ["AddonCompartmentFrame"] = true,
    ["ExpansionLandingPageMinimapButton"] = true,
    ["GarrisonLandingPageMinimapButton"] = true,
    ["Minimap"] = true, ["MinimapBackdrop"] = true, ["MinimapCluster"] = true,
}

-- Overlays / pins de carte connus (jamais des boutons)
local EXCLUDE_OVERLAYS = {
    ["GatherMatePin"] = true, ["HandyNotesPin"] = true, ["TomTomCrazyArrow"] = true,
    ["RoutesPin"] = true, ["GatherMate2Pin"] = true, ["Spy_MapNoteList_mini"] = true,
    ["TomTom"] = true, ["QuestPointerPOI"] = true, ["poiMinimap"] = true,
}
local PIN_PATTERNS = { "Pin$", "POI", "CrazyArrow", "BlobRing" }
local function IsPinFrame(name)
    if EXCLUDE_OVERLAYS[name] then return true end
    for _, pat in ipairs(PIN_PATTERNS) do
        if name:find(pat) then return true end
    end
    return false
end

local function IsBlacklisted(name)
    if not name or name == "" then return true end  -- frame anonyme = on ignore
    if BLIZZ_MINIMAP_FRAMES[name] then return true end
    if name:sub(1, 7) == "TomoMod" then return true end  -- nos propres frames
    if IsPinFrame(name) then return true end
    return false
end

-- Une frame est-elle un bouton d'addon de minimap à collecter ?
local function IsAddonButton(frame)
    if not frame or collectedButtons[frame] then return false end
    if frame == bagToggle or frame == bagFrame then return false end
    local name = frame:GetName()
    if IsBlacklisted(name) then return false end
    -- (3) Boutons d'addon standard (LibDBIcon & co.) : capture explicite,
    -- même s'ils sont des Frame non-Button ou cachés au moment du scan.
    if name:sub(1, 12) == "LibDBIcon10_" or name:find("MinimapButton") or name:find("Minimap_Button") then
        return true
    end
    local ftype = frame:GetObjectType()
    if ftype ~= "Button" and ftype ~= "Frame" then return false end
    if name:match("%d+$") then return false end       -- frame poolée/anonyme
    if not frame:IsShown() then return false end
    local w = frame:GetWidth() or 0
    if w < 18 or w > 48 then return false end
    if ftype == "Frame" and not (frame:HasScript("OnMouseDown") or frame:HasScript("OnClick")) then
        return false
    end
    return true
end

-- Scanne un parent à la recherche de boutons d'addon.
local function ScanParent(parent)
    if not parent or not parent.GetNumChildren then return end
    local n = parent:GetNumChildren()
    for i = 1, n do
        local child = select(i, parent:GetChildren())
        if child and IsAddonButton(child) then
            collectedButtons[child] = true
            collectedOrder[#collectedOrder + 1] = child
        end
    end
end

-- =====================================
-- (1) STRIP DÉCORATIONS + NORMALISATION ICÔNE
-- =====================================
-- IDs de textures décoratives (bordures/fonds génériques des boutons d'addon).
local JUNK_TEX_ID = {
    [136467] = true,  -- UI-Minimap-Background
    [136430] = true,  -- MiniMap-TrackingBorder
    [136477] = true,  -- UI-Minimap-ZoomButton-Highlight
}
local JUNK_TEX_PATH = {
    ["Interface\\Minimap\\MiniMap%-TrackingBorder"] = true,
    ["Interface\\Minimap\\UI%-Minimap%-Background"] = true,
    ["Interface\\Minimap\\UI%-Minimap%-ZoomButton%-Highlight"] = true,
}
local function IsJunkTexture(region)
    if not region or not region.IsObjectType or not region:IsObjectType("Texture") then return false end
    local id = region.GetTextureFileID and region:GetTextureFileID()
    if id and JUNK_TEX_ID[id] then return true end
    local path = region:GetTexture()
    if type(path) == "string" then
        for pat in pairs(JUNK_TEX_PATH) do
            if path:match(pat) then return true end
        end
    end
    return false
end

local function StripButtonDecorations(btn)
    local saved = savedButtonState[btn]
    if not saved then return end
    if not saved.junk then
        saved.junk = {}
        for _, region in ipairs({ btn:GetRegions() }) do
            if IsJunkTexture(region) then
                saved.junk[#saved.junk + 1] = { region = region, alpha = region:GetAlpha(), shown = region:IsShown() }
            end
        end
        local hl = btn.GetHighlightTexture and btn:GetHighlightTexture()
        if hl and IsJunkTexture(hl) then
            saved.junk[#saved.junk + 1] = { region = hl, alpha = hl:GetAlpha(), shown = hl:IsShown() }
        end
        -- snapshot de l'icône (points + texcoord) pour restauration
        local icon = btn.icon or btn.Icon
        if not icon then
            for _, region in ipairs({ btn:GetRegions() }) do
                if region:IsObjectType("Texture") and region:IsShown()
                   and region:GetAlpha() > 0 and not IsJunkTexture(region) then
                    icon = region; break
                end
            end
        end
        if icon then
            local pts = {}
            for i = 1, icon:GetNumPoints() do pts[i] = { icon:GetPoint(i) } end
            saved.icon = icon
            saved.iconPts = pts
            saved.iconTC = { icon:GetTexCoord() }
        end
    end
    -- masque les décorations (à chaque appel)
    for _, info in ipairs(saved.junk) do
        info.region:SetAlpha(0); info.region:Hide()
    end
    -- normalise l'icône pour remplir la case proprement
    if saved.icon then
        saved.icon:ClearAllPoints()
        saved.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        saved.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        pcall(saved.icon.SetTexCoord, saved.icon, 0.07, 0.93, 0.07, 0.93)
    end
end

-- Anneau fin (look uniforme TomoMod), créé une seule fois par bouton.
local function EnsureBagRing(btn)
    if not btn._tmBagRing then
        local ring = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        ring:SetAllPoints(btn)
        ring:SetFrameLevel(btn:GetFrameLevel() + 1)
        ring:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        btn._tmBagRing = ring
    end
    local r, g, b = 0.35, 0.35, 0.4
    if TomoModDB.minimap.borderColor == "class" then r, g, b = TomoMod_Utils.GetClassColor() end
    btn._tmBagRing:SetBackdropBorderColor(r, g, b, 0.55)
    btn._tmBagRing:Show()
end

local function RestoreButtonDecorations(btn)
    local saved = savedButtonState[btn]
    if not saved then return end
    if saved.junk then
        for _, info in ipairs(saved.junk) do
            info.region:SetAlpha(info.alpha)
            if info.shown then info.region:Show() end
        end
    end
    if saved.icon and saved.iconPts then
        saved.icon:ClearAllPoints()
        for _, pt in ipairs(saved.iconPts) do saved.icon:SetPoint(unpack(pt)) end
        if saved.iconTC and #saved.iconTC >= 8 then saved.icon:SetTexCoord(unpack(saved.iconTC)) end
    end
    if btn._tmBagRing then btn._tmBagRing:Hide() end
    -- restaure parent / strata / level / taille / ancrage
    if btn.SetFixedFrameStrata then btn:SetFixedFrameStrata(false) end
    if btn.SetFixedFrameLevel then btn:SetFixedFrameLevel(false) end
    if saved.parent then btn:SetParent(saved.parent) end
    if saved.strata then btn:SetFrameStrata(saved.strata) end
    if saved.level then btn:SetFrameLevel(saved.level) end
    if saved.w and saved.h then btn:SetSize(saved.w, saved.h) end
    if saved.point then
        btn:ClearAllPoints()
        pcall(btn.SetPoint, btn, saved.point, saved.relTo, saved.relPoint, saved.x, saved.y)
    end
    if btn.SetFixedFrameStrata then btn:SetFixedFrameStrata(true) end
    if btn.SetFixedFrameLevel then btn:SetFixedFrameLevel(true) end
    savedButtonState[btn] = nil
end

-- =====================================
-- (2) LAYOUT : reparent + déverrouillage strata/level LibDBIcon
-- =====================================
local function LayoutBag()
    local db = TomoModDB.minimap.buttonBag or {}
    local cols = math.max(1, db.columns or 1)
    local size = db.iconSize or 28
    local pad  = 4
    local count = #collectedOrder
    local baseLvl = bagFrame.content:GetFrameLevel()

    for i, btn in ipairs(collectedOrder) do
        -- snapshot de l'état d'origine (une seule fois)
        if not savedButtonState[btn] then
            local p, rel, rp, ox, oy = btn:GetPoint(1)
            savedButtonState[btn] = {
                parent = btn:GetParent(), strata = btn:GetFrameStrata(), level = btn:GetFrameLevel(),
                w = btn:GetWidth(), h = btn:GetHeight(),
                point = p, relTo = rel, relPoint = rp, x = ox, y = oy,
            }
        end

        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        btn:SetParent(bagFrame.content)
        -- (2) LibDBIcon verrouille strata/level : on déverrouille avant de réancrer
        if btn.SetFixedFrameStrata then btn:SetFixedFrameStrata(false) end
        if btn.SetFixedFrameLevel then btn:SetFixedFrameLevel(false) end
        btn:SetFrameStrata("DIALOG")
        btn:SetFrameLevel(baseLvl + 5)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", bagFrame.content, "TOPLEFT", col * (size + pad), -row * (size + pad))
        if btn.SetSize then btn:SetSize(size, size) end
        btn:SetAlpha(1)
        btn:Show()
        -- aligne les enfants sur le même calque
        for _, child in ipairs({ btn:GetChildren() }) do
            if child ~= btn._tmBagRing then
                child:SetFrameStrata("DIALOG")
                child:SetFrameLevel(baseLvl + 6)
            end
        end
        StripButtonDecorations(btn)
        EnsureBagRing(btn)
    end

    local rows = math.max(1, math.ceil(count / cols))
    local contentW = cols * size + (cols - 1) * pad
    local contentH = rows * size + (rows - 1) * pad
    if count == 0 then contentW, contentH = 120, 28 end
    bagFrame.content:SetSize(contentW, contentH)
    bagFrame:SetSize(contentW + 16, contentH + 45)   -- +45 = titre(28)+sep(1)+pad(8)+pad bas(8)
    if bagFrame.empty then bagFrame.empty:SetShown(count == 0) end
end

function TomoMod_Minimap.RefreshButtonBag()
    wipe(collectedButtons)
    wipe(collectedOrder)
    if not (bagFrame and bagFrame.content) then return end
    local db = TomoModDB.minimap
    if db.buttonBag and db.buttonBag.enabled == false then
        -- Collecteur désactivé : rendre les boutons déjà capturés à la minimap.
        -- Sans ça ils restaient orphelins dans la boîte masquée et ne revenaient
        -- jamais se coller à la minimap (« ça ne reste pas »).
        TomoMod_Minimap.ReleaseCollectedButtons()
        return
    end
    if (db.collectorStyle or "tomomod") ~= "tomomod" then  -- mode Blizzard : pas de collecte
        TomoMod_Minimap.ReleaseCollectedButtons()
        return
    end
    ScanParent(Minimap)
    ScanParent(MinimapBackdrop)
    ScanParent(MinimapCluster)
    LayoutBag()
    -- Auto-show au login/reload : affiche brièvement le panneau pour que les
    -- boutons s'y logent, puis le referme après 0.5 s — sauf si l'utilisateur
    -- l'a déjà ouvert manuellement (bagUserOpened).
    if #collectedOrder > 0 then
        bagFrame:Show()
        if not bagUserOpened then
            C_Timer.After(0.5, function()
                if not bagUserOpened and bagFrame then
                    bagFrame:Hide()
                end
            end)
        end
    end
end

-- Relâche tous les boutons capturés et les rend à la minimap (mode Blizzard / désactivation).
function TomoMod_Minimap.ReleaseCollectedButtons()
    for btn in pairs(savedButtonState) do
        RestoreButtonDecorations(btn)
    end
    wipe(collectedButtons)
    wipe(collectedOrder)
    if TomoMod_Minimap.RefreshAddonButtonShapes then
        TomoMod_Minimap.RefreshAddonButtonShapes()
    end
end

-- Ré-applique uniquement le layout (taille/colonnes) sans rescanner les parents.
-- À utiliser quand seuls des paramètres visuels changent (iconSize, columns) :
-- les boutons sont déjà sous bagFrame.content et un rescan ne les retrouverait pas.
function TomoMod_Minimap.RelayoutBag()
    if not (bagFrame and bagFrame.content) then return end
    local db = TomoModDB.minimap
    if db.buttonBag and db.buttonBag.enabled == false then return end
    if (db.collectorStyle or "tomomod") ~= "tomomod" then return end
    if #collectedOrder == 0 then return end
    LayoutBag()
end

-- =====================================
-- MASQUAGE DES ÉLÉMENTS NATIFS (pistage + collecteur Blizzard)
-- =====================================
local _nativeHooked = {}
local _alphaGuard    = {}   -- anti-récursion pour les hooks SetAlpha

local function ApplyNativeVisibility(frame, hide)
    if not frame then return end
    frame:SetAlpha(hide and 0 or 1)            -- SetAlpha autorisé même en combat
    if not InCombatLockdown() then
        frame:EnableMouse(not hide)
    end
end

-- Pose un hook Show + SetAlpha sur une frame native pour empêcher Blizzard
-- de la rendre visible après notre masquage (zone change, PLAYER_ENTERING_WORLD…).
-- getHide() doit renvoyer true quand la frame doit rester masquée.
local _mouseGuard = {}   -- anti-récursion pour le hook EnableMouse

local function HookNativeFrame(frame, getHide)
    if not frame or _nativeHooked[frame] then return end
    _nativeHooked[frame] = true
    hooksecurefunc(frame, "Show", function(self)
        if getHide() then self:SetAlpha(0) end
    end)
    -- SetAlpha est hookable : Blizzard peut appeler SetAlpha(1) sans passer par Show.
    -- On remet à 0 immédiatement, avec un garde anti-récursion.
    hooksecurefunc(frame, "SetAlpha", function(self, alpha)
        if _alphaGuard[self] or alpha == 0 then return end
        if getHide() then
            _alphaGuard[self] = true
            self:SetAlpha(0)
            _alphaGuard[self] = nil
        end
    end)
    -- [FIX] EnableMouse n'était appliqué qu'une seule fois (dans ApplyNativeVisibility),
    -- jamais réappliqué ensuite. Si Blizzard rappelle EnableMouse(false) de son côté
    -- après ça (survol, fermeture de menu, Edit Mode…), le bouton restait cliqué-mort
    -- même après avoir désactivé le style TomoMod pour le "révéler" — on le voyait
    -- réapparaître (alpha 1) mais impossible de cliquer dessus. On réaffirme désormais
    -- l'état voulu en continu, comme pour Show/SetAlpha ci-dessus.
    if frame.EnableMouse then
        hooksecurefunc(frame, "EnableMouse", function(self, enabled)
            if _mouseGuard[self] then return end
            if InCombatLockdown() then return end
            local wantEnabled = not getHide()
            if enabled ~= wantEnabled then
                _mouseGuard[self] = true
                self:EnableMouse(wantEnabled)
                _mouseGuard[self] = nil
            end
        end)
    end
end

function TomoMod_Minimap.HideNativeClutter()
    local db = TomoModDB.minimap
    if not db then return end
    local hideTracking  = (db.trackingStyle  or "tomomod") == "tomomod" and db.showTracking ~= false
    local hideCollector = (db.collectorStyle or "tomomod") == "tomomod" and (not db.buttonBag or db.buttonBag.enabled ~= false)

    local trackBliz = MinimapCluster and MinimapCluster.Tracking
    local trackBtn  = trackBliz and trackBliz.Button   -- bouton enfant (TWW 12.x)
    local compart   = _G.AddonCompartmentFrame

    ApplyNativeVisibility(trackBliz, hideTracking)
    ApplyNativeVisibility(trackBtn,  hideTracking)
    ApplyNativeVisibility(compart,   hideCollector)

    local function trackHide()
        local d = TomoModDB.minimap
        return (d.trackingStyle or "tomomod") == "tomomod" and d.showTracking ~= false
    end
    local function collectHide()
        local d = TomoModDB.minimap
        return (d.collectorStyle or "tomomod") == "tomomod" and (not d.buttonBag or d.buttonBag.enabled ~= false)
    end

    HookNativeFrame(trackBliz, trackHide)
    HookNativeFrame(trackBtn,  trackHide)
    HookNativeFrame(compart,   collectHide)

    -- [FIX] Réapplique explicitement l'état mouse voulu à chaque appel (pas seulement
    -- à la création du hook) : si Blizzard avait désactivé la souris entre-temps, un
    -- simple hook ne suffit pas tant qu'aucune méthode hookée n'est rappelée derrière.
    if trackBtn and not InCombatLockdown() then trackBtn:EnableMouse(not hideTracking) end
    if trackBliz and not InCombatLockdown() then trackBliz:EnableMouse(not hideTracking) end
end

-- [3.0.5] Positionne le déclencheur du collecteur. Extrait de CreateButtonBag
-- pour être ré-appelable : l'horloge visible est celle de l'InfoPanel
-- (TomoMod_ClockBar), créée au login — souvent APRÈS ce premier positionnement.
-- La native TimeManagerClockButton est masquée par l'InfoPanel, donc on cible
-- d'abord la barre TomoMod, puis la native (InfoPanel désactivé), sinon le coin.
function TomoMod_Minimap.PositionBagToggle()
    if not bagToggle then return end
    local db = TomoModDB.minimap.buttonBag or {}
    local anchorMode = db.anchor or "corner"
    local clock = _G.TomoMod_ClockBar or _G.TimeManagerClockButton
    local clockShown = clock and clock:IsShown()
    bagToggle:ClearAllPoints()

    if (anchorMode == "clock-left" or anchorMode == "clock-right") and clockShown then
        local gap = db.clockGap or 2
        local isBar = (clock == _G.TomoMod_ClockBar)  -- barre pleine largeur sous la minimap
        if isBar then
            -- L'heure est CENTRÉE dans une barre pleine largeur : on se place juste
            -- à gauche/droite du TEXTE de l'heure (pas au bord de la barre), et on
            -- relève le bouton au-dessus de la barre pour qu'il reste visible/cliquable.
            bagToggle:SetFrameStrata(clock:GetFrameStrata())
            bagToggle:SetFrameLevel((clock:GetFrameLevel() or 0) + 2)
            local timeText  = clock.timeText
            local timeLabel = clock.timeLabel or timeText
            if anchorMode == "clock-left" then
                if timeText then
                    bagToggle:SetPoint("RIGHT", timeText, "LEFT", -gap, 0)
                else
                    bagToggle:SetPoint("LEFT", clock, "LEFT", gap, 0)        -- repli : bord gauche
                end
            else
                if timeLabel then
                    bagToggle:SetPoint("LEFT", timeLabel, "RIGHT", gap, 0)
                else
                    bagToggle:SetPoint("RIGHT", clock, "RIGHT", -gap, 0)     -- repli : bord droit
                end
            end
        else
            -- Petite horloge native (InfoPanel désactivé) : on la flanque directement.
            if anchorMode == "clock-left" then
                bagToggle:SetPoint("RIGHT", clock, "LEFT", -gap, 0)
            else
                bagToggle:SetPoint("LEFT", clock, "RIGHT", gap, 0)
            end
        end
    else
        -- Mode minimap (coin) — comportement par défaut / repli
        local corner = db.corner or "BOTTOMLEFT"
        bagToggle:SetPoint(corner, Minimap, corner, db.x or 2, db.y or 26)
    end
    bagToggle:SetScale(db.scale or 1.0)
end

function TomoMod_Minimap.CreateButtonBag()
    local db = TomoModDB.minimap.buttonBag or {}
    local collectorStyle = TomoModDB.minimap.collectorStyle or "tomomod"

    if db.enabled == false or collectorStyle ~= "tomomod" then
        if bagToggle then bagToggle:Hide() end
        if bagFrame then bagFrame:Hide() end
        -- rend les boutons capturés à la minimap (mode Blizzard / désactivation)
        if TomoMod_Minimap.ReleaseCollectedButtons then TomoMod_Minimap.ReleaseCollectedButtons() end
        if TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
        return
    end

    -- Bouton déclencheur
    if not bagToggle then
        bagToggle = CreateFrame("Button", "TomoModMinimapButtonBag", Minimap)
        bagToggle:SetSize(22, 22)
        bagToggle:SetFrameLevel(Minimap:GetFrameLevel() + 5)

        local bg = bagToggle:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.45)
        bagToggle.bg = bg

        local ico = bagToggle:CreateTexture(nil, "ARTWORK")
        ico:SetPoint("CENTER")
        ico:SetSize(14, 14)
        -- icône collecteur TomoMod
        ico:SetTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\icons\\ico_minimap_collector.tga")
        bagToggle.ico = ico

        local border = CreateFrame("Frame", nil, bagToggle, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        border:SetBackdropBorderColor(0, 0, 0, 0)
        bagToggle.border = border

        bagToggle:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0.7)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(TomoMod_L["minimap_buttonbag"] or "Boutons d'addon", 1, 1, 1)
            GameTooltip:AddLine(TomoMod_L["minimap_buttonbag_hint"] or "Clic : afficher/masquer", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        bagToggle:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0.45)
            GameTooltip:Hide()
        end)
        bagToggle:SetScript("OnMouseDown", function()
            if bagFrame:IsShown() then
                bagUserOpened = false
                bagFrame:Hide()
            else
                bagUserOpened = true
                -- Si les boutons sont déjà collectés (reparentés sous bagFrame.content),
                -- un nouveau scan ne les retrouve pas → on relayout sans rescan.
                -- On rescanne uniquement si la liste est vide (première ouverture ou
                -- après un ReleaseCollectedButtons).
                if #collectedOrder == 0 then
                    TomoMod_Minimap.RefreshButtonBag()
                else
                    TomoMod_Minimap.RelayoutBag()
                end
                bagFrame:Show()
            end
        end)
    end

    -- La boîte
    if not bagFrame then
        bagFrame = CreateFrame("Frame", "TomoModMinimapButtonBagFrame", UIParent, "BackdropTemplate")
        bagFrame:SetFrameStrata("DIALOG")
        bagFrame:SetFrameLevel(100)
        bagFrame:SetClampedToScreen(true)
        bagFrame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        bagFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
        local aR, aG, aB = 0.2, 0.2, 0.25
        if TomoModDB.minimap.borderColor == "class" then aR, aG, aB = TomoMod_Utils.GetClassColor() end
        bagFrame:SetBackdropBorderColor(aR, aG, aB, 1)

        -- Titre (teal, Poppins SemiBold)
        local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
        local title = bagFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_BOLD, 11, "")
        title:SetPoint("TOPLEFT", 8, -8)
        title:SetText(TomoMod_L["minimap_buttonbag"] or "Boutons d'addon")
        title:SetTextColor(0.05, 0.82, 0.62, 1)

        -- Séparateur horizontal
        local sep = bagFrame:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetPoint("TOPLEFT",  8, -28)
        sep:SetPoint("TOPRIGHT", -8, -28)
        sep:SetColorTexture(0.2, 0.2, 0.25, 0.8)

        -- Zone de contenu (sous le titre + séparateur + padding)
        local content = CreateFrame("Frame", nil, bagFrame)
        content:SetPoint("TOPLEFT", 8, -37)   -- 28 titre + 1 sep + 8 pad
        bagFrame.content = content

        local empty = bagFrame:CreateFontString(nil, "OVERLAY")
        empty:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 11, "")
        empty:SetPoint("CENTER", 0, -15)
        --empty:SetText(TomoMod_L["minimap_buttonbag_empty"] or "Aucun bouton détecté")
        empty:SetTextColor(0.6, 0.6, 0.65, 1)
        empty:Hide()
        bagFrame.empty = empty

        bagFrame:Hide()
    end

    -- Position du déclencheur (extraite : ré-appelable après création tardive
    -- de l'horloge de l'InfoPanel — voir PositionBagToggle).
    TomoMod_Minimap.PositionBagToggle()
    -- Le panneau s'ouvre toujours à gauche de la minimap (cohérent avec le panel de pistage)
    bagFrame:ClearAllPoints()
    bagFrame:SetPoint("RIGHT", Minimap, "LEFT", -4, 0)

    -- Teinte
    local r, g, b = 0.9, 0.9, 0.9
    if TomoModDB.minimap.borderColor == "class" then r, g, b = TomoMod_Utils.GetClassColor() end
    bagToggle.border:SetBackdropBorderColor(0, 0, 0, 0)
    bagToggle.ico:SetVertexColor(r, g, b, 1)

    bagToggle:Show()
    if TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
end

-- Rendre compatible avec Edit Mode
function TomoMod_Minimap.SetupEditMode()
    if EditModeManagerFrame then
        Minimap:SetMovable(true)
        Minimap:SetUserPlaced(true)
        Minimap:SetClampedToScreen(true)
    end
end

-- =====================================
-- POSITION SAVE / RESTORE
-- =====================================

local _tmApplyingMinimapPos = false -- guards RestorePosition's own SetPoint from re-triggering the hook below
local _tmMinimapPosHooked    = false

local function SavePosition()
    local db = TomoModDB and TomoModDB.minimap
    if not db then return end
    -- [DRAG] Store the raw GetLeft()/GetBottom() edges (no scale factor).
    -- The Minimap lives under MinimapCluster and carries its own
    -- SetScale(db.scale), so Minimap:GetEffectiveScale() differs from
    -- UIParent's. SetPoint offsets are already interpreted in the Minimap's
    -- own scale, so re-applying these raw edges in RestorePosition round-trips
    -- exactly for any cluster/minimap scale. The former
    -- GetEffectiveScale()/UIParent ratio double-scaled the offset and pushed
    -- the minimap into a screen corner on every reload/reconnect.
    local left, bottom = Minimap:GetLeft(), Minimap:GetBottom()
    if left and bottom then
        db.position = { anchor = "BOTTOMLEFT", relTo = "BOTTOMLEFT",
                        x = left, y = bottom }
    end
end

local function RestorePosition()
    local db = TomoModDB and TomoModDB.minimap
    if not db or not db.position then return end
    local p = db.position
    _tmApplyingMinimapPos = true
    Minimap:ClearAllPoints()
    Minimap:SetPoint(p.anchor, UIParent, p.relTo, p.x, p.y)
    _tmApplyingMinimapPos = false
end

-- [FIX] "La minimap se déplace toute seule après un reload" — SetupEditMode()
-- marks the Minimap as movable/user-placed for Blizzard's Edit Mode (Minimap is
-- one of its managed systems), but Edit Mode can still call SetPoint on it at
-- any later point (PLAYER_ENTERING_WORLD, resizing other Edit Mode systems,
-- etc.), silently overriding our restored position — same root cause already
-- fixed for the Objective Tracker mover. Re-assert our saved anchor whenever
-- anything else calls SetPoint on the Minimap AND the result actually drifted
-- from our saved position.
-- [FIX 2] The naive "always reassert" version fought even Blizzard's own
-- harmless internal SetPoint calls (e.g. MinimapCluster adjusting layout when
-- the zone-name bar's text/width changes) — clearing/re-anchoring Minimap on
-- every single one of those caused a visible one-frame misalignment between
-- Minimap and its sibling MinimapCluster chrome (zone text, native icons)
-- overlapping our tracking button. Only correct the position when it has
-- actually drifted (beyond a small pixel tolerance) from what we saved, so
-- harmless in-place SetPoint calls are left alone.
local function InstallMinimapPositionHook()
    if _tmMinimapPosHooked then return end
    _tmMinimapPosHooked = true
    hooksecurefunc(Minimap, "SetPoint", function()
        if _tmApplyingMinimapPos then return end
        local db = TomoModDB and TomoModDB.minimap
        if not db or not db.position then return end
        local p = db.position
        local left, bottom = Minimap:GetLeft(), Minimap:GetBottom()
        if not left or not bottom then return end
        -- Same convention as SavePosition: raw frame-space edges, no scale.
        local curX, curY = left, bottom
        if math.abs(curX - (p.x or 0)) < 1 and math.abs(curY - (p.y or 0)) < 1 then
            return -- already where it should be — don't fight a harmless internal SetPoint
        end
        RestorePosition()
    end)
end

-- =====================================
-- MOVER OVERLAY
-- =====================================

local function CreateMoverOverlay()
    if moverOverlay then return end
    local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    moverOverlay = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
    moverOverlay:SetAllPoints(Minimap)
    moverOverlay:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    moverOverlay:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    moverOverlay:SetBackdropColor(0.047, 0.824, 0.624, 0.25)
    moverOverlay:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.8)
    local label = moverOverlay:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 12, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetText("Minimap")
    label:SetTextColor(1, 1, 1, 1)
    moverOverlay:Hide()
end

-- =====================================
-- LOCK / UNLOCK
-- =====================================

local function SetLocked(locked)
    isLocked = locked
    if locked then
        Minimap:SetScript("OnDragStart", nil)
        Minimap:SetScript("OnDragStop", nil)
        Minimap:RegisterForDrag()
        if moverOverlay then moverOverlay:Hide() end
        SavePosition()
    else
        CreateMoverOverlay()
        Minimap:RegisterForDrag("LeftButton")
        Minimap:SetScript("OnDragStart", function(self) self:StartMoving() end)
        Minimap:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            SavePosition()
        end)
        moverOverlay:Show()
    end
end

function TomoMod_Minimap.ToggleLock()
    SetLocked(not isLocked)
end

function TomoMod_Minimap.IsLocked()
    return isLocked
end

-- Appliquer tous les paramètres
function TomoMod_Minimap.ApplySettings()
    if not TomoModDB.minimap.enabled then return end
    
    TomoMod_Minimap.MakeSquare()
    TomoMod_Minimap.CreateBorder()
    TomoMod_Minimap.ApplyScale()
    TomoMod_Minimap.CreateTrackingButton()
    TomoMod_Minimap.ApplyNativeIndicators()
    TomoMod_Minimap.CreateButtonBag()
    TomoMod_Minimap.HideNativeClutter()
    TomoMod_Minimap.RefreshAddonButtonShapes()
    TomoMod_Minimap.SetupEditMode()
    RestorePosition()
    InstallMinimapPositionHook()
end

-- [FIX] Backstop in addition to the SetPoint hook above: Edit Mode can apply
-- its own saved Minimap layout on events well after our initial ApplySettings()
-- pass (loading screens, zoning, or simply firing later than expected), and it
-- isn't guaranteed to always go through a plain :SetPoint() call the hook can
-- intercept. Re-assert our saved position once more, with a short delay, on
-- every PLAYER_ENTERING_WORLD and whenever Edit Mode reports updated layouts.
local minimapPosBackstop = CreateFrame("Frame")
minimapPosBackstop:RegisterEvent("PLAYER_ENTERING_WORLD")
minimapPosBackstop:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
minimapPosBackstop:SetScript("OnEvent", function()
    if not (TomoModDB and TomoModDB.minimap and TomoModDB.minimap.enabled) then return end
    C_Timer.After(1, RestorePosition)
end)

-- Initialisation du module
function TomoMod_Minimap.Initialize()
    -- (1) Pré-masquage immédiat des boutons d'addon natifs AVANT que bagFrame
    --     existe : on parcourt les parents de la minimap et on cache tout ce
    --     qui serait collecté, pour éviter le flash de 0.5 s.
    -- [FIX] Ne rien masquer si le collecteur TomoMod est désactivé (buttonBag.enabled
    -- = false ou collectorStyle = "blizzard") : sinon les boutons des autres addons
    -- étaient rendus invisibles (alpha 0) à chaque reload sans jamais être restaurés
    -- (CreateButtonBag() retourne tôt et ReleaseCollectedButtons() ne connaît que les
    -- boutons capturés via LayoutBag, pas ceux masqués ici) — le collecteur semblait
    -- se "réactiver" tout seul après un reload alors qu'il était désactivé.
    local function CollectorIsEnabled()
        local db = TomoModDB and TomoModDB.minimap
        if not db then return true end
        return (db.collectorStyle or "tomomod") == "tomomod"
            and (not db.buttonBag or db.buttonBag.enabled ~= false)
    end
    local function PreHideAddonButtons(parent)
        if not CollectorIsEnabled() then return end
        if not parent or not parent.GetNumChildren then return end
        for i = 1, parent:GetNumChildren() do
            local child = select(i, parent:GetChildren())
            if child and not collectedButtons[child] then
                local name = child:GetName() or ""
                if name:sub(1, 7) ~= "TomoMod" and not BLIZZ_MINIMAP_FRAMES[name] then
                    local w = child:GetWidth() or 0
                    if w >= 18 and w <= 48 then
                        child:SetAlpha(0)
                    end
                end
            end
        end
    end
    PreHideAddonButtons(Minimap)
    PreHideAddonButtons(MinimapBackdrop)
    PreHideAddonButtons(MinimapCluster)

    -- (2) ApplySettings à t+0.5 s (laisse la DB s'initialiser)
    C_Timer.After(0.5, function()
        TomoMod_Minimap.ApplySettings()
        -- Scan immédiat juste après la création du bagFrame
        if TomoMod_Minimap.RefreshButtonBag then TomoMod_Minimap.RefreshButtonBag() end
        -- Re-ancre le déclencheur : l'horloge de l'InfoPanel existe maintenant
        if TomoMod_Minimap.PositionBagToggle then TomoMod_Minimap.PositionBagToggle() end
    end)

    -- (3) Scan différé pour les addons qui enregistrent leur bouton plus tard.
    C_Timer.After(3, function()
        if TomoMod_Minimap.RefreshAddonButtonShapes then TomoMod_Minimap.RefreshAddonButtonShapes() end
        if TomoMod_Minimap.RefreshButtonBag then TomoMod_Minimap.RefreshButtonBag() end
        if TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
        if TomoMod_Minimap.PositionBagToggle then TomoMod_Minimap.PositionBagToggle() end
    end)

    -- (4) Polling des addons chargés tard : re-scanne après chaque ADDON_LOADED
    -- (les boutons d'addon n'apparaissent pas tous au même moment). Débounce 0.2s.
    if not TomoMod_Minimap._poll then
        local poll = CreateFrame("Frame")
        poll:RegisterEvent("ADDON_LOADED")
        local pending = false
        poll:SetScript("OnEvent", function()
            if pending then return end
            pending = true
            C_Timer.After(0.2, function()
                pending = false
                if not (TomoModDB and TomoModDB.minimap and TomoModDB.minimap.enabled) then return end
                if TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
                if TomoMod_Minimap.RefreshButtonBag then TomoMod_Minimap.RefreshButtonBag() end
                if TomoMod_Minimap.PositionBagToggle then TomoMod_Minimap.PositionBagToggle() end
            end)
        end)
        TomoMod_Minimap._poll = poll
    end
end
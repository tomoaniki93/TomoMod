-- =====================================
-- Minimap.lua
-- =====================================

TomoMod_Minimap = TomoMod_Minimap or {}
local minimapBorder
local trackingButton
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

function TomoMod_Minimap.CreateTrackingButton()
    -- Respecte le toggle
    if TomoModDB.minimap.showTracking == false then
        if trackingButton then trackingButton:Hide() end
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

        -- Icône de pistage (œil/loupe Blizzard)
        local ico = trackingButton:CreateTexture(nil, "ARTWORK")
        ico:SetPoint("CENTER")
        ico:SetSize(16, 16)
        ico:SetTexture("Interface\\Minimap\\Tracking\\None")
        trackingButton.ico = ico

        -- Bordure fine
        local border = CreateFrame("Frame", nil, trackingButton, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
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
            if not OpenNativeTrackingMenu() then
                OpenFallbackTrackingMenu(self)
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
    trackingButton.border:SetBackdropBorderColor(r, g, b, 1)
    trackingButton.ico:SetVertexColor(r, g, b, 1)

    trackingButton:Show()
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

-- Ré-ancre une frame Blizzard selon la config DB d'un indicateur (ou la masque).
local function AnchorBlizzFrame(frame, show, key)
    if not frame then return end
    if show == false then
        frame:SetParent(TomoModMinimapBorder or Minimap)
        frame:ClearAllPoints()
        frame:SetAlpha(0)
        return
    end
    local corner, scale, x, y = TomoMod_Minimap.GetIndicatorCfg(key)
    frame:SetParent(Minimap)
    frame:SetAlpha(1)
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
            expansion:SetAlpha(0)
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
local collectedButtons = {}      -- [frame] = true (déjà ramassé)
local collectedOrder = {}        -- liste ordonnée pour le layout

-- Le collecteur a-t-il capturé ce bouton ? (utilisé par RefreshAddonButtonShapes)
function TomoMod_Minimap.IsButtonCollected(frame)
    return collectedButtons[frame] == true
end

-- Préfixes de noms à exclure (frames Blizzard + nos frames)
local EXCLUDE_PREFIXES = {
    "MiniMap", "Minimap", "GameTime", "ExpansionLandingPage", "GarrisonLanding",
    "QueueStatus", "AddonCompartment", "TimeManager", "HybridMinimap",
    "TomoMod", "MinimapCompass", "MinimapZone", "MinimapNorth", "MinimapCluster",
}

-- Noms exacts d'overlays connus (calques de carte, pas des boutons)
local EXCLUDE_OVERLAYS = {
    ["GatherMatePin"] = true, ["HandyNotesPin"] = true, ["TomTomCrazyArrow"] = true,
    ["RoutesPin"] = true, ["GatherMate2Pin"] = true, ["Spy_MapNoteList_mini"] = true,
    ["TomTom"] = true, ["QuestPointerPOI"] = true, ["poiMinimap"] = true,
}

local function ShouldExcludeByName(name)
    if not name or name == "" then return true end  -- pas de nom = on ignore (heuristique sûre)
    if EXCLUDE_OVERLAYS[name] then return true end
    for _, prefix in ipairs(EXCLUDE_PREFIXES) do
        if name:sub(1, #prefix) == prefix then return true end
    end
    return false
end

-- Une frame ressemble-t-elle à un bouton d'addon de minimap ?
local function IsAddonButton(frame)
    if not frame or collectedButtons[frame] then return false end
    if frame == bagToggle or frame == bagFrame then return false end
    local ftype = frame:GetObjectType()
    if ftype ~= "Button" and ftype ~= "Frame" then return false end
    local name = frame:GetName()
    if ShouldExcludeByName(name) then return false end
    -- Doit être visible et de taille « bouton »
    if not frame:IsShown() then return false end
    local w, h = frame:GetWidth(), frame:GetHeight()
    if not w or not h then return false end
    if w < 18 or w > 48 or h < 18 or h > 48 then return false end
    -- Doit être cliquable OU avoir un script clic (les vrais boutons d'addon le sont)
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

-- (Re)positionne les boutons ramassés dans la boîte en grille.
local function LayoutBag()
    local db = TomoModDB.minimap.buttonBag or {}
    local cols = math.max(1, db.columns or 5)
    local size = db.iconSize or 28
    local pad  = 4
    local count = #collectedOrder

    for i, btn in ipairs(collectedOrder) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        btn:SetParent(bagFrame.content)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", bagFrame.content, "TOPLEFT", col * (size + pad), -row * (size + pad))
        -- certains boutons forcent leur taille : on tente de normaliser
        if btn.SetSize then btn:SetSize(size, size) end
        btn:Show()
    end

    local rows = math.max(1, math.ceil(count / cols))
    local contentW = cols * size + (cols - 1) * pad
    local contentH = rows * size + (rows - 1) * pad
    if count == 0 then contentW, contentH = 120, 28 end
    bagFrame.content:SetSize(contentW, contentH)
    bagFrame:SetSize(contentW + 16, contentH + 16)
    if bagFrame.empty then bagFrame.empty:SetShown(count == 0) end
end

function TomoMod_Minimap.RefreshButtonBag()
    -- (re)scan : on repart de zéro
    wipe(collectedButtons)
    wipe(collectedOrder)
    if not (bagFrame and bagFrame.content) then return end
    ScanParent(Minimap)
    ScanParent(MinimapBackdrop)
    LayoutBag()
end

function TomoMod_Minimap.CreateButtonBag()
    local db = TomoModDB.minimap.buttonBag or {}

    if db.enabled == false then
        if bagToggle then bagToggle:Hide() end
        if bagFrame then bagFrame:Hide() end
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
        -- icône « grille / sacs »
        ico:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
        bagToggle.ico = ico

        local border = CreateFrame("Frame", nil, bagToggle, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
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
                bagFrame:Hide()
            else
                TomoMod_Minimap.RefreshButtonBag()
                bagFrame:Show()
            end
        end)
    end

    -- La boîte
    if not bagFrame then
        bagFrame = CreateFrame("Frame", "TomoModMinimapButtonBagFrame", UIParent, "BackdropTemplate")
        bagFrame:SetFrameStrata("DIALOG")
        bagFrame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        bagFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
        local aR, aG, aB = 0.2, 0.2, 0.25
        if TomoModDB.minimap.borderColor == "class" then aR, aG, aB = TomoMod_Utils.GetClassColor() end
        bagFrame:SetBackdropBorderColor(aR, aG, aB, 1)

        local content = CreateFrame("Frame", nil, bagFrame)
        content:SetPoint("TOPLEFT", 8, -8)
        bagFrame.content = content

        local empty = bagFrame:CreateFontString(nil, "OVERLAY")
        empty:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 11, "")
        empty:SetPoint("CENTER")
        empty:SetText(TomoMod_L["minimap_buttonbag_empty"] or "Aucun bouton détecté")
        empty:SetTextColor(0.6, 0.6, 0.65, 1)
        empty:Hide()
        bagFrame.empty = empty

        bagFrame:Hide()
    end

    -- Position du déclencheur (réutilise le système d'indicateurs si dispo)
    local corner, scale, x, y = "BOTTOMLEFT", db.scale or 1.0, db.x or 2, db.y or 26
    bagToggle:ClearAllPoints()
    bagToggle:SetPoint(db.corner or corner, Minimap, db.corner or corner, x, y)
    bagToggle:SetScale(scale)

    -- La boîte s'ancre au-dessus du déclencheur
    bagFrame:ClearAllPoints()
    bagFrame:SetPoint("BOTTOMLEFT", bagToggle, "TOPLEFT", 0, 4)

    -- Teinte
    local r, g, b = 0.9, 0.9, 0.9
    if TomoModDB.minimap.borderColor == "class" then r, g, b = TomoMod_Utils.GetClassColor() end
    bagToggle.border:SetBackdropBorderColor(r, g, b, 1)
    bagToggle.ico:SetVertexColor(r, g, b, 1)

    bagToggle:Show()
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

local function SavePosition()
    local db = TomoModDB and TomoModDB.minimap
    if not db then return end
    local point, _, relPoint, x, y = Minimap:GetPoint(1)
    if point then
        db.position = { anchor = point, relTo = relPoint, x = x, y = y }
    end
end

local function RestorePosition()
    local db = TomoModDB and TomoModDB.minimap
    if not db or not db.position then return end
    local p = db.position
    Minimap:ClearAllPoints()
    Minimap:SetPoint(p.anchor, UIParent, p.relTo, p.x, p.y)
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
    TomoMod_Minimap.RefreshAddonButtonShapes()
    TomoMod_Minimap.SetupEditMode()
    RestorePosition()
end

-- Initialisation du module
function TomoMod_Minimap.Initialize()
    C_Timer.After(0.5, function()
        TomoMod_Minimap.ApplySettings()
    end)
    -- Scan différé : laisse aux autres addons le temps de créer leurs boutons.
    C_Timer.After(5, function()
        if TomoMod_Minimap.RefreshAddonButtonShapes then TomoMod_Minimap.RefreshAddonButtonShapes() end
        if TomoMod_Minimap.RefreshButtonBag then TomoMod_Minimap.RefreshButtonBag() end
    end)
end
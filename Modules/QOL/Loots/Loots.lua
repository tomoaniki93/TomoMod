-- =====================================================================
-- Loots.lua — Loot Browser  (QOL Module)
-- Modules > QOL > Loots  |  /tm loot
-- Browses Encounter Journal (dungeons & raids) for the latest tier.
-- =====================================================================

local ADDON_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

TomoMod_Loots = TomoMod_Loots or {}
local LOOTS = TomoMod_Loots

-- ══ Theme (TomoMod dark palette + teal accent) ════════════════════════
local C = {
    BG       = { 0.06,  0.06,  0.08,  0.97 },
    BG_HDR   = { 0.08,  0.08,  0.11,  1.00 },
    BG_LEFT  = { 0.045, 0.045, 0.065, 1.00 },
    BG_INST  = { 0.07,  0.07,  0.09,  0.55 },
    BG_INS_H = { 0.047, 0.824, 0.624, 0.10 },
    BG_INS_A = { 0.047, 0.824, 0.624, 0.18 },
    ACCENT   = { 0.047, 0.824, 0.624, 1.00 },
    BORDER   = { 0.18,  0.18,  0.22,  0.70 },
    TEXT     = { 0.90,  0.92,  0.90,  1.00 },
    TEXT_DIM = { 0.38,  0.38,  0.43,  1.00 },
    TEXT_ACC = { 0.047, 0.824, 0.624, 1.00 },
    TAB_ACT  = { 0.047, 0.824, 0.624, 0.22 },
    TAB_INA  = { 0.04,  0.04,  0.06,  0.80 },
}

-- ══ Layout constants ══════════════════════════════════════════════════
local FRAME_W      = 840
local FRAME_H      = 560
local HEADER_H     = 48
local LEFT_W       = 210
local ITEM_SIZE    = 36
local ITEM_GAP     = 3
local ROW_H_INST   = 36
-- right panel scroll inner width (frame - left - vsep - scrollbar gap)
local SCROLL_INNER = FRAME_W - LEFT_W - 1 - 18
-- items per row inside scroll child (4 px left margin)
local ITEMS_PER_ROW = math.floor((SCROLL_INNER - 4 + ITEM_GAP) / (ITEM_SIZE + ITEM_GAP))

-- Item quality border colours
local Q_COLOR = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 0.90, 0.90, 0.90 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1.00, 0.50, 0.00 },
    [6] = { 0.90, 0.80, 0.50 },
}

-- Armor itemSubClassID → numeric: 1=Cloth 2=Leather 3=Mail 4=Plate  0=Misc (ring/neck/trinket)
-- CLASS_ARMOR_ID[playerClassID] = required itemSubClassID
local CLASS_ARMOR_ID = {
    [1]=4, [2]=4, [6]=4,            -- Plate  : Warrior, Paladin, DK
    [3]=3, [7]=3, [13]=3,           -- Mail   : Hunter, Shaman, Evoker
    [4]=2, [10]=2, [11]=2, [12]=2,  -- Leather: Rogue, Monk, Druid, DH
    [5]=1, [8]=1,  [9]=1,           -- Cloth  : Priest, Mage, Warlock
}

-- Difficulty selector data: { id, label }
local DIFF_LIST = {
    { id=17, label="Raid Find" },
    { id=14, label="Normal"    },
    { id=15, label="Héroïque"  },
    { id=16, label="Mythique"  },
}

-- BonusId de base (rank 1 = drop direct boss/fin de clé) par difficulté
-- Source: KeystoneLoot upgrade_tracks.lua (Season 16)
local DIFF_BONUS_ID = {
    [17] = 12777,  -- LFR      ilvl 233
    [14] = 12785,  -- Normal   ilvl 246
    [15] = 12793,  -- Héroïque ilvl 259
    [16] = 12801,  -- Mythique ilvl 272
}
local DUNGEON_BONUS_ID = 12785  -- Champion track rank 1 (ilvl 246)

-- Construit le lien hyperlink item avec le bon bonusId pour le tooltip ilvl
local function ItemLink(itemID, bonusId)
    if bonusId then
        return string.format("item:%d:0:0:0:0:0:0:0:0:0:0:0:1:%d", itemID, bonusId)
    end
    return "item:" .. itemID
end

-- Filter bar height (row1 + gap + row2 + padding)
local FILTER_BAR_H = 64  -- 7 + 22 + 6 + 22 + 7

-- Spec IDs per class (classID → { specID, ... })
local CLASS_SPECS = {
    [1]  = { 71,   72,   73   },       -- Warrior : Arms, Fury, Protection
    [2]  = { 65,   66,   70   },       -- Paladin : Holy, Protection, Retribution
    [3]  = { 253,  254,  255  },       -- Hunter  : Beast Mastery, Marksmanship, Survival
    [4]  = { 259,  260,  261  },       -- Rogue   : Assassination, Outlaw, Subtlety
    [5]  = { 256,  257,  258  },       -- Priest  : Discipline, Holy, Shadow
    [6]  = { 250,  251,  252  },       -- DK      : Blood, Frost, Unholy
    [7]  = { 262,  263,  264  },       -- Shaman  : Elemental, Enhancement, Restoration
    [8]  = { 62,   63,   64   },       -- Mage    : Arcane, Fire, Frost
    [9]  = { 265,  266,  267  },       -- Warlock : Affliction, Demonology, Destruction
    [10] = { 268,  269,  270  },       -- Monk    : Brewmaster, Windwalker, Mistweaver
    [11] = { 102,  103,  104,  105 },  -- Druid   : Balance, Feral, Guardian, Restoration
    [12] = { 577,  581        },       -- DH      : Havoc, Vengeance
    [13] = { 1467, 1468, 1473 },       -- Evoker  : Devastation, Preservation, Augmentation
}

-- ══ Icon escape helpers (locale-independent, work in Poppins FontStrings) ══

-- Build a |T...|t escape from an atlas name (e.g. "classicon-warrior").
-- Uses C_Texture.GetAtlasInfo to resolve atlas coordinates into a pixel-accurate escape.
local function AtlasIconStr(atlasName, size)
    size = size or 18
    local info = C_Texture.GetAtlasInfo(atlasName)
    if not info or not info.file then
        return string.format("|TInterface\\Icons\\INV_Misc_QuestionMark:%d:%d|t", size, size)
    end
    local texW = info.width  or 256
    local texH = info.height or 256
    local l = math.floor((info.leftTexCoord   or 0) * texW + 0.5)
    local r = math.floor((info.rightTexCoord  or 1) * texW + 0.5)
    local t = math.floor((info.topTexCoord    or 0) * texH + 0.5)
    local b = math.floor((info.bottomTexCoord or 1) * texH + 0.5)
    return string.format("|T%s:%d:%d:0:0:%d:%d:%d:%d:%d:%d|t",
        info.file, size, size, texW, texH, l, r, t, b)
end

-- Build a |T...|t escape from a raw fileDataID (e.g. from GetSpecializationInfoByID).
local function FileIconStr(fileID, size)
    size = size or 18
    return string.format("|T%d:%d:%d|t", fileID, size, size)
end

-- ══ Generic UI helpers ════════════════════════════════════════════════

local function FS(parent, font, size, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(font or ADDON_FONT, size or 11, flags or "OUTLINE")
    fs:SetShadowColor(0, 0, 0, 0.85)
    fs:SetShadowOffset(1, -1)
    return fs
end

local function Borders(f, r, g, b, a, sz)
    sz = sz or 1
    local edges = {
        { "TOPLEFT",    "TOPRIGHT",    true  },
        { "BOTTOMLEFT", "BOTTOMRIGHT", true  },
        { "TOPLEFT",    "BOTTOMLEFT",  false },
        { "TOPRIGHT",   "BOTTOMRIGHT", false },
    }
    for _, e in ipairs(edges) do
        local t = f:CreateTexture(nil, "BORDER")
        t:SetColorTexture(r, g, b, a or 0.7)
        t:SetPoint(e[1], f, e[1])
        t:SetPoint(e[2], f, e[2])
        if e[3] then t:SetHeight(sz) else t:SetWidth(sz) end
    end
end

local function Bg(f, r, g, b, a)
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints()
    t:SetColorTexture(r, g, b, a)
    return t
end

-- ══ Encounter Journal data helpers ════════════════════════════════════
-- All EJ calls are done lazily (frame is built only when /tm loot is used,
-- so PLAYER_LOGIN has already fired and EJ data is available).

local function EnsureEJLoaded()
    if not C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
        C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
    end
end

local function EJ_FetchInstances(isDungeon)
    local list = {}
    if isDungeon then
        -- Use ChallengeMode API: always up-to-date, keyed by MapChallengeModeID
        if not C_ChallengeMode or not C_ChallengeMode.GetMapTable then return list end
        local mapTable = C_ChallengeMode.GetMapTable()
        if not mapTable then return list end
        for _, mapID in ipairs(mapTable) do
            local name, _, _, icon = C_ChallengeMode.GetMapUIInfo(mapID)
            if name and name ~= "" then
                tinsert(list, { id = mapID, name = name, icon = icon })
            end
        end
    else
        -- Use EJ for raids (journalInstanceId is the EJ instance ID)
        EnsureEJLoaded()
        local numTiers = EJ_GetNumTiers and EJ_GetNumTiers() or 0
        if numTiers == 0 then return list end
        local i = 1
        while true do
            local id = EJ_GetInstanceByIndex(i, true, numTiers)  -- isRaid=true
            if not id or id == 0 then break end
            local name, _, _, btnIcon = EJ_GetInstanceInfo(id)
            if name and name ~= "" then
                tinsert(list, { id = id, name = name, icon = btnIcon })
            end
            i = i + 1
        end
    end
    return list
end

local function EJ_FetchBosses(instanceID)
    EnsureEJLoaded()
    local list = {}
    EJ_SelectInstance(instanceID)
    local i = 1
    while true do
        -- returns: name, description, encounterID, rootSectionID, link, ...
        local name, _, encID = EJ_GetEncounterInfoByIndex(i, instanceID)
        if not name then break end
        tinsert(list, { id = encID, name = name })
        i = i + 1
    end
    return list
end

-- Build an item list from a raw table of itemIDs (static data).
-- Uses GetItemInfo for icon/quality; defaults to quality 4 (rare) if uncached.
-- bonusId est stocké sur chaque item pour le tooltip ilvl correct.
local function ItemsFromIDs(idList, bonusId)
    if not idList then return {} end
    local list = {}
    for _, itemID in ipairs(idList) do
        local _, _, quality, _, _, _, _, _, _, icon = GetItemInfo(itemID)
        tinsert(list, { itemID = itemID, icon = icon, quality = quality or 4, bonusId = bonusId })
    end
    return list
end

local function GetDungeonItems(mapChallengeID)
    local data = TomoMod_LootsData and TomoMod_LootsData.dungeons
    return ItemsFromIDs(data and data[mapChallengeID], DUNGEON_BONUS_ID)
end

-- diff: 14=Normal 15=Heroic 16=Mythic 17=LFR  (nil = default to 15)
local function GetBossItems(ejEncounterID, diff)
    local data = TomoMod_LootsData and TomoMod_LootsData.raidBosses
    if not data then return {} end
    local bossData = data[ejEncounterID]
    if not bossData then return {} end
    local diffID = diff or 15
    -- fall back: 15 → 14 → first available
    local ids = bossData[diffID] or bossData[14] or bossData[15] or {}
    return ItemsFromIDs(ids, DIFF_BONUS_ID[diffID] or DIFF_BONUS_ID[15])
end

-- Returns true if itemID est utilisable par la classe (et éventuellement la spec) indiquées.
-- Priorité 1 : données ItemClasses (TomoMod_ItemClasses) — filtre exact par spec
-- Priorité 2 : fallback GetItemInfoInstant pour les armor type si données manquantes
local function ItemMatchesClass(itemID, classID, specID)
    if not classID then return true end

    local IDB = TomoMod_ItemClasses
    if IDB then
        local entry = IDB[itemID]
        if entry then
            -- L'item a des restrictions → la classe doit y figurer
            local specList = entry[classID]
            if not specList then return false end
            -- Si un filtre de spé est actif, vérifier la spé aussi
            if specID then
                for _, sid in ipairs(specList) do
                    if sid == specID then return true end
                end
                return false
            end
            return true
        end
        -- Entrée absente dans IDB = item universel (ring, neck, trinket…)
        return true
    end

    -- Fallback (IDB non chargé) : vérification armor type seulement
    local _, _, _, _, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemID)
    if not itemClassID then return true end
    if itemClassID ~= 4 then return true end
    if itemSubClassID == 0 then return true end
    local wanted = CLASS_ARMOR_ID[classID]
    if not wanted then return true end
    return itemSubClassID == wanted
end

-- ══ Favoris ═══════════════════════════════════════════════════════════

local function IsFavorite(itemID)
    return TomoModDB
        and TomoModDB.loots
        and TomoModDB.loots.favorites
        and TomoModDB.loots.favorites[itemID] ~= nil
end

local function ToggleFavorite(itemID, bonusId)
    if not TomoModDB then return end
    if not TomoModDB.loots          then TomoModDB.loots          = {} end
    if not TomoModDB.loots.favorites then TomoModDB.loots.favorites = {} end
    if TomoModDB.loots.favorites[itemID] ~= nil then
        TomoModDB.loots.favorites[itemID] = nil
    else
        TomoModDB.loots.favorites[itemID] = bonusId or true
    end
end

local function GetFavoritesCount()
    if not (TomoModDB and TomoModDB.loots and TomoModDB.loots.favorites) then return 0 end
    local n = 0
    for _ in pairs(TomoModDB.loots.favorites) do n = n + 1 end
    return n
end

-- ══ Item icon button ══════════════════════════════════════════════════

local function MakeItemBtn(parent, itemID, icon, quality, bonusId)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(ITEM_SIZE, ITEM_SIZE)

    Bg(btn, 0.06, 0.06, 0.08, 1)

    local itex = btn:CreateTexture(nil, "ARTWORK")
    itex:SetPoint("TOPLEFT",     btn, "TOPLEFT",     1, -1)
    itex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1,  1)
    if icon then
        itex:SetTexture(icon)
        itex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    btn._tex = itex

    local qc = Q_COLOR[quality] or Q_COLOR[3]
    Borders(btn, qc[1], qc[2], qc[3], 0.90, 1)

    local hi = btn:CreateTexture(nil, "HIGHLIGHT")
    hi:SetAllPoints()
    hi:SetColorTexture(1, 1, 1, 0.15)

    -- ── Indicateur pin (texture OVERLAY, pas un bouton imbriqué) ─────
    local PIN_TEX = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\pin_alert"
    local pinTex = btn:CreateTexture(nil, "OVERLAY")
    pinTex:SetSize(16, 16)
    pinTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, 2)
    pinTex:SetTexture(PIN_TEX)
    pinTex:SetAlpha(IsFavorite(itemID) and 1 or 0)

    local function RefreshPin()
        pinTex:SetAlpha(IsFavorite(itemID) and 1 or 0)
    end

    -- ── Interactions ─────────────────────────────────────────────────
    local link = ItemLink(itemID, bonusId)

    btn:SetScript("OnEnter", function(self)
        -- Aperçu du pin si pas encore épinglé
        if not IsFavorite(itemID) then pinTex:SetAlpha(0.35) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        RefreshPin()
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function(_, button)
        if IsShiftKeyDown() then
            -- Shift+clic : insérer le lien dans le chat
            local eb = (ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow())
                    or (ChatFrame1EditBox and ChatFrame1EditBox:IsShown() and ChatFrame1EditBox)
            if eb then eb:Insert(link) end
        else
            -- Clic gauche/droit : épingler / désépingler
            ToggleFavorite(itemID, bonusId)
            RefreshPin()
            LOOTS:_UpdateFavsTabLabel()
            if LOOTS.currentTab == "favs" then
                LOOTS:_ShowFavs()
            end
        end
    end)

    return btn
end

-- ══ Build ═════════════════════════════════════════════════════════════

function LOOTS:Build()
    if self.Frame then return end

    -- ── Main frame ──────────────────────────────────────────────────
    local F = CreateFrame("Frame", "TomoMod_LootsFrame", UIParent, "BackdropTemplate")
    self.Frame = F
    F:SetSize(FRAME_W, FRAME_H)
    F:SetFrameStrata("DIALOG")
    F:SetFrameLevel(200)
    F:SetClampedToScreen(true)
    F:SetMovable(true)
    F:EnableMouse(true)
    F:RegisterForDrag("LeftButton")
    F:SetScript("OnDragStart", function(s) s:StartMoving() end)
    F:SetScript("OnDragStop",  function(s)
        s:StopMovingOrSizing()
        LOOTS:SavePosition()
    end)
    F:SetPoint("CENTER")
    F:Hide()
    tinsert(UISpecialFrames, "TomoMod_LootsFrame")

    Bg(F, unpack(C.BG))
    Borders(F, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])

    -- top teal accent strip
    local ftop = F:CreateTexture(nil, "ARTWORK")
    ftop:SetHeight(2)
    ftop:SetPoint("TOPLEFT",  F, "TOPLEFT",  0, 0)
    ftop:SetPoint("TOPRIGHT", F, "TOPRIGHT", 0, 0)
    ftop:SetColorTexture(unpack(C.ACCENT))

    -- ── Header ──────────────────────────────────────────────────────
    local hdr = CreateFrame("Frame", nil, F)
    hdr:SetHeight(HEADER_H)
    hdr:SetPoint("TOPLEFT",  F, "TOPLEFT",  0, -2)
    hdr:SetPoint("TOPRIGHT", F, "TOPRIGHT", 0, -2)
    Bg(hdr, unpack(C.BG_HDR))

    local hico = hdr:CreateTexture(nil, "ARTWORK")
    hico:SetSize(26, 26)
    hico:SetPoint("LEFT", hdr, "LEFT", 12, 0)
    hico:SetTexture("Interface\\Icons\\Achievement_Dungeon_UlduarRaid_25man")
    hico:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local htitle = FS(hdr, ADDON_FONT_BOLD, 16, "OUTLINE")
    htitle:SetPoint("LEFT", hico, "RIGHT", 8, 0)
    htitle:SetTextColor(unpack(C.TEXT_ACC))
    htitle:SetText("Loots")

    local hsub = FS(hdr, ADDON_FONT, 9, "OUTLINE")
    hsub:SetPoint("LEFT", htitle, "RIGHT", 8, -2)
    hsub:SetTextColor(unpack(C.TEXT_DIM))
    hsub:SetText("Donjons & Raids — Saison actuelle")

    -- ── Close button ────────────────────────────────────────────────
    local xbtn = CreateFrame("Button", nil, F)
    xbtn:SetPoint("TOPRIGHT", F, "TOPRIGHT", -6, -6)
    xbtn:SetSize(22, 22)
    Bg(xbtn, unpack(C.BG_HDR))
    local xfs = FS(xbtn, ADDON_FONT_BOLD, 14, "OUTLINE")
    xfs:SetPoint("CENTER")
    xfs:SetText("×")
    xfs:SetTextColor(unpack(C.TEXT_DIM))
    Borders(xbtn, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])
    xbtn:SetScript("OnEnter", function() xfs:SetTextColor(unpack(C.TEXT_ACC)) end)
    xbtn:SetScript("OnLeave", function() xfs:SetTextColor(unpack(C.TEXT_DIM)) end)
    xbtn:SetScript("OnClick", function() F:Hide() end)

    -- ── Tab buttons ─────────────────────────────────────────────────
    local function MakeTab(label)
        local t = CreateFrame("Button", nil, hdr)
        t:SetSize(84, 26)
        Bg(t, unpack(C.TAB_INA))
        t._bg = t:CreateTexture(nil, "BACKGROUND")
        t._bg:SetAllPoints()
        t._bg:SetColorTexture(unpack(C.TAB_INA))
        t._fs = FS(t, ADDON_FONT, 11, "OUTLINE")
        t._fs:SetPoint("CENTER")
        t._fs:SetText(label)
        t._fs:SetTextColor(unpack(C.TEXT_DIM))
        Borders(t, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])
        t:SetScript("OnEnter", function(self)
            if not self._active then
                self._bg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.09)
                self._fs:SetTextColor(unpack(C.TEXT))
            end
        end)
        t:SetScript("OnLeave", function(self)
            if not self._active then
                self._bg:SetColorTexture(unpack(C.TAB_INA))
                self._fs:SetTextColor(unpack(C.TEXT_DIM))
            end
        end)
        return t
    end

    -- Trois onglets: Favoris | Donjons | Raids [×]
    -- Ancrés droite→gauche; TabRaid le plus proche du bouton fermeture
    self.TabRaid    = MakeTab("Raids")
    self.TabDungeon = MakeTab("Donjons")
    self.TabFavs    = MakeTab("Favoris")
    local tabY = -math.floor((HEADER_H - 26) / 2)
    self.TabRaid:SetPoint("TOPRIGHT", hdr,          "TOPRIGHT", -32, tabY)
    self.TabDungeon:SetPoint("RIGHT",  self.TabRaid,    "LEFT", -4,  0)
    self.TabFavs:SetPoint("RIGHT",    self.TabDungeon,  "LEFT", -4,  0)

    -- ── Header bottom separator ──────────────────────────────────────
    local hsep = F:CreateTexture(nil, "ARTWORK")
    hsep:SetHeight(1)
    hsep:SetPoint("TOPLEFT",  hdr, "BOTTOMLEFT",  0, 0)
    hsep:SetPoint("TOPRIGHT", hdr, "BOTTOMRIGHT", 0, 0)
    hsep:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.85)

    -- ── Global filter bar (class + spec + difficulty) ────────────────
    -- Spans the full frame width, sits between the header separator and
    -- the left/right content panels.  All filter choices apply to both tabs.
    local filterBar = CreateFrame("Frame", nil, F)
    filterBar:SetPoint("TOPLEFT",  hsep, "BOTTOMLEFT",  0, 0)
    filterBar:SetPoint("TOPRIGHT", hsep, "BOTTOMRIGHT", 0, 0)
    filterBar:SetHeight(FILTER_BAR_H)
    Bg(filterBar, C.BG_HDR[1], C.BG_HDR[2], C.BG_HDR[3], 0.80)
    self.FilterBar = filterBar

    -- Thin teal separator below filter bar
    local fbSep = F:CreateTexture(nil, "ARTWORK")
    fbSep:SetHeight(1)
    fbSep:SetPoint("TOPLEFT",  filterBar, "BOTTOMLEFT",  0, 0)
    fbSep:SetPoint("TOPRIGHT", filterBar, "BOTTOMRIGHT", 0, 0)
    fbSep:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.35)

    -- ── Filter button factory ─────────────────────────────────────────
    local function MakeFilterBtn(parent, label, w, h)
        local b = CreateFrame("Button", nil, parent)
        b:SetSize(w or 70, h or 22)
        b._bg = b:CreateTexture(nil, "BACKGROUND")
        b._bg:SetAllPoints()
        b._bg:SetColorTexture(unpack(C.BG_INST))
        b._fs = FS(b, ADDON_FONT, 10, "OUTLINE")
        b._fs:SetPoint("CENTER")
        b._fs:SetText(label)
        b._fs:SetTextColor(unpack(C.TEXT_DIM))
        Borders(b, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])
        b:SetScript("OnEnter", function(self)
            if not self._active then
                self._bg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.09)
                self._fs:SetTextColor(unpack(C.TEXT))
            end
        end)
        b:SetScript("OnLeave", function(self)
            if not self._active then
                self._bg:SetColorTexture(unpack(C.BG_INST))
                self._fs:SetTextColor(unpack(C.TEXT_DIM))
            end
        end)
        return b
    end

    -- ── Row 1 (y=-7, h=22): Class buttons (left) + Difficulty (right) ─
    self.ClassBtns = {}
    self.DiffBtns  = {}

    -- "Tous" class button
    local allBtn = MakeFilterBtn(filterBar, "Tous", 36, 22)
    allBtn:SetPoint("TOPLEFT", filterBar, "TOPLEFT", 8, -7)
    allBtn._class = nil
    allBtn:SetScript("OnClick", function()
        LOOTS.currentClass = nil
        if TomoModDB and TomoModDB.loots then TomoModDB.loots.filterClass = 0 end
        LOOTS:_SyncClassButtons()
        if LOOTS.currentTab == "favs" then
            LOOTS:_ShowFavs()
        elseif LOOTS.currentInst then
            LOOTS:SelectInstance(LOOTS.currentInst, LOOTS.currentInstName)
        end
    end)
    tinsert(self.ClassBtns, allBtn)

    -- One 22×22 button per class (icon via |T...|t escape in Poppins FontString)
    local prevClassBtn = allBtn
    for classID = 1, 13 do
        local _, classFile = GetClassInfo(classID)
        if classFile then
            local iconStr = AtlasIconStr("classicon-"..strlower(classFile), 18)
            local cb = MakeFilterBtn(filterBar, iconStr, 22, 22)
            cb._fs:SetFont(ADDON_FONT, 18, "")   -- font size controls |T| spacing
            cb:ClearAllPoints()
            cb:SetPoint("LEFT", prevClassBtn, "RIGHT", 3, 0)
            cb._class = classID
            local cc  = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
            local cr  = cc and cc.r or 0.5
            local cg  = cc and cc.g or 0.5
            local cbl = cc and cc.b or 0.5
            cb._bg:SetColorTexture(cr, cg, cbl, 0.18)
            local capturedID = classID
            cb:SetScript("OnClick", function()
                LOOTS.currentClass = capturedID
                if TomoModDB and TomoModDB.loots then TomoModDB.loots.filterClass = capturedID end
                LOOTS:_SyncClassButtons()
                if LOOTS.currentTab == "favs" then
                    LOOTS:_ShowFavs()
                elseif LOOTS.currentInst then
                    LOOTS:SelectInstance(LOOTS.currentInst, LOOTS.currentInstName)
                end
            end)
            cb:SetScript("OnEnter", function(self)
                if not self._active then
                    self._bg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.09)
                    self._fs:SetTextColor(unpack(C.TEXT))
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local cName = GetClassInfo(capturedID)
                GameTooltip:SetText(cName or "?", unpack(C.TEXT_ACC))
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function(self)
                if not self._active then
                    self._bg:SetColorTexture(cr, cg, cbl, 0.18)
                    self._fs:SetTextColor(unpack(C.TEXT_DIM))
                end
                GameTooltip:Hide()
            end)
            tinsert(self.ClassBtns, cb)
            prevClassBtn = cb
        end
    end

    -- Difficulty buttons: anchored right-to-left from frame right edge
    -- Display order (left→right): Raid Find | Normal | Héroïque | Mythique
    local diffX = 8
    for i = #DIFF_LIST, 1, -1 do
        local dInfo = DIFF_LIST[i]
        local db = MakeFilterBtn(filterBar, dInfo.label, 70, 22)
        db:SetPoint("TOPRIGHT", filterBar, "TOPRIGHT", -diffX, -7)
        diffX = diffX + 74
        db._diff = dInfo.id
        local capturedDiff = dInfo.id
        db:SetScript("OnClick", function()
            LOOTS.currentDiff = capturedDiff
            if TomoModDB and TomoModDB.loots then TomoModDB.loots.filterDiff = capturedDiff end
            LOOTS:_SyncDiffButtons()
            if LOOTS.currentInst and LOOTS.currentTab == "raid" then
                LOOTS:SelectInstance(LOOTS.currentInst, LOOTS.currentInstName)
            end
        end)
        tinsert(self.DiffBtns, db)
    end

    -- ── Row 2 (y=-35, h=22): Spec buttons (rebuilt when class changes) ─
    local specRow = CreateFrame("Frame", nil, filterBar)
    specRow:SetPoint("TOPLEFT",  filterBar, "TOPLEFT",  8, -(7 + 22 + 6))
    specRow:SetPoint("TOPRIGHT", filterBar, "TOPRIGHT", -8, -(7 + 22 + 6))
    specRow:SetHeight(22)
    self.SpecRow  = specRow
    self.SpecBtns = {}

    -- ── Left panel (instance list) ────────────────────────────────────
    local lf = CreateFrame("Frame", nil, F)
    lf:SetWidth(LEFT_W)
    lf:SetPoint("TOPLEFT",    filterBar, "BOTTOMLEFT",  0, -1)
    lf:SetPoint("BOTTOMLEFT", F,         "BOTTOMLEFT",  0,  0)
    Bg(lf, unpack(C.BG_LEFT))

    local vsep = F:CreateTexture(nil, "ARTWORK")
    vsep:SetWidth(1)
    vsep:SetPoint("TOPLEFT",    lf, "TOPRIGHT",    0, 0)
    vsep:SetPoint("BOTTOMLEFT", lf, "BOTTOMRIGHT", 0, 0)
    vsep:SetColorTexture(C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.5)

    local lscroll = CreateFrame("ScrollFrame", nil, lf)
    lscroll:SetPoint("TOPLEFT",     lf, "TOPLEFT",    0, -2)
    lscroll:SetPoint("BOTTOMRIGHT", lf, "BOTTOMRIGHT", 0,  2)
    lscroll:EnableMouseWheel(true)
    lscroll:SetScript("OnMouseWheel", function(self, d)
        local v, m = self:GetVerticalScroll(), self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(v - d * 22, m)))
    end)
    local lchild = CreateFrame("Frame", nil, lscroll)
    lchild:SetWidth(LEFT_W)
    lchild:SetHeight(1)
    lscroll:SetScrollChild(lchild)
    self.ListChild = lchild

    -- ── Right panel (item display) ────────────────────────────────────
    local rf = CreateFrame("Frame", nil, F)
    rf:SetPoint("TOPLEFT",     vsep, "TOPRIGHT",    0, 0)
    rf:SetPoint("BOTTOMRIGHT", F,    "BOTTOMRIGHT", 0, 0)

    -- Instance name label
    local instFS = FS(rf, ADDON_FONT_BOLD, 13, "OUTLINE")
    instFS:SetPoint("TOPLEFT", rf, "TOPLEFT", 10, -10)
    instFS:SetTextColor(unpack(C.TEXT_ACC))
    instFS:SetText("")
    self.InstNameFS = instFS

    -- Hint text shown when nothing is selected
    local hintFS = FS(rf, ADDON_FONT, 13, "OUTLINE")
    hintFS:SetPoint("CENTER", rf, "CENTER", 0, 0)
    hintFS:SetTextColor(unpack(C.TEXT_DIM))
    hintFS:SetText("← Sélectionner un donjon ou un raid")
    self.HintFS = hintFS

    -- Scrollbar track (visual)
    local sbTrack = rf:CreateTexture(nil, "BACKGROUND")
    sbTrack:SetWidth(4)
    sbTrack:SetPoint("TOPRIGHT",    rf, "TOPRIGHT",    -5, -30)
    sbTrack:SetPoint("BOTTOMRIGHT", rf, "BOTTOMRIGHT", -5,   4)
    sbTrack:SetColorTexture(0.10, 0.10, 0.14, 0.80)

    -- Item scroll frame (no in-panel filter bar: starts just below instFS)
    local iscroll = CreateFrame("ScrollFrame", nil, rf)
    iscroll:SetPoint("TOPLEFT",     rf, "TOPLEFT",     0,  -30)
    iscroll:SetPoint("BOTTOMRIGHT", rf, "BOTTOMRIGHT", -18,   4)
    iscroll:EnableMouseWheel(true)
    iscroll:SetScript("OnMouseWheel", function(self, d)
        local v, m = self:GetVerticalScroll(), self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(v - d * 44, m)))
    end)
    local ichild = CreateFrame("Frame", nil, iscroll)
    ichild:SetWidth(SCROLL_INNER)
    ichild:SetHeight(1)
    iscroll:SetScrollChild(ichild)
    self.ItemScroll = iscroll
    self.ItemChild  = ichild

    -- ── Initial state ─────────────────────────────────────────────────
    self.currentDiff     = 15    -- default Héroïque
    self.currentSpec     = nil
    self.currentInstName = nil

    -- Default class = player's class
    local _, playerClassFile = UnitClass("player")
    self.currentClass = nil
    for i = 1, 13 do
        local _, cf = GetClassInfo(i)
        if cf == playerClassFile then self.currentClass = i; break end
    end

    -- Restore persisted filters (overrides defaults)
    -- filterClass: 0 = "Tous", classID = specific class, nil = use default
    -- filterDiff : diffID, nil = use default
    local dbLoots = TomoModDB and TomoModDB.loots
    if dbLoots then
        if dbLoots.filterDiff and dbLoots.filterDiff ~= 0 then
            self.currentDiff = dbLoots.filterDiff
        end
        if dbLoots.filterClass == 0 then
            self.currentClass = nil   -- "Tous" explicitly chosen
        elseif dbLoots.filterClass and dbLoots.filterClass > 0 then
            self.currentClass = dbLoots.filterClass
        end
    end

    -- ── Wire tabs ─────────────────────────────────────────────────────
    self._activeItems = {}
    self.TabDungeon:SetScript("OnClick", function() LOOTS:SetTab("dungeon") end)
    self.TabRaid:SetScript("OnClick",    function() LOOTS:SetTab("raid")    end)
    self.TabFavs:SetScript("OnClick",    function() LOOTS:SetTab("favs")    end)

    self:_RestorePosition()
    self:_UpdateFavsTabLabel()
    self:SetTab("dungeon")
end

-- ══ Position persistence ══════════════════════════════════════════════

function LOOTS:SavePosition()
    if not self.Frame or not TomoModDB then return end
    local p, _, rp, x, y = self.Frame:GetPoint()
    TomoModDB.loots.position = { point = p, relPoint = rp, x = x, y = y }
end

function LOOTS:_RestorePosition()
    if not self.Frame or not TomoModDB then return end
    local pos = TomoModDB.loots and TomoModDB.loots.position
    if pos then
        self.Frame:ClearAllPoints()
        self.Frame:SetPoint(
            pos.point    or "CENTER",
            UIParent,
            pos.relPoint or "CENTER",
            pos.x        or 0,
            pos.y        or 0
        )
    end
end

-- ══ Filter sync helpers ═══════════════════════════════════════════════

function LOOTS:_SyncDiffButtons()
    for _, db in ipairs(self.DiffBtns or {}) do
        local active = (db._diff == self.currentDiff)
        db._active = active
        if active then
            db._bg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.20)
            db._fs:SetTextColor(unpack(C.TEXT_ACC))
        else
            db._bg:SetColorTexture(unpack(C.BG_INST))
            db._fs:SetTextColor(unpack(C.TEXT_DIM))
        end
    end
end

function LOOTS:_SyncClassButtons()
    for _, cb in ipairs(self.ClassBtns or {}) do
        local active = (cb._class == self.currentClass)
        cb._active = active
        if active then
            cb._bg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.30)
        else
            -- restore class color or dim
            if cb._class then
                local _, cf = GetClassInfo(cb._class)
                local cc = cf and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cf]
                local cr, cg, cbl = cc and cc.r or 0.5, cc and cc.g or 0.5, cc and cc.b or 0.5
                cb._bg:SetColorTexture(cr, cg, cbl, 0.18)
            else
                cb._bg:SetColorTexture(unpack(C.BG_INST))
            end
        end
    end
    self:_RebuildSpecButtons()
end

-- ══ Specialisation buttons (Row 2 of filter bar) ══════════════════════

-- Rebuild Row 2 for the currently selected class.
-- Buttons show spec icon (|T fileDataID:14:14|t) + spec name via Poppins FontString.
function LOOTS:_RebuildSpecButtons()
    -- Hide existing spec buttons
    for _, b in ipairs(self.SpecBtns or {}) do
        b:ClearAllPoints()
        b:Hide()
    end
    self.SpecBtns    = {}
    self.currentSpec = nil

    local classID = self.currentClass
    if not classID then return end
    local specs = CLASS_SPECS[classID]
    if not specs then return end

    local x = 0
    for _, specID in ipairs(specs) do
        local _, specName, _, specIcon = GetSpecializationInfoByID(specID)
        if specName then
            local iconTxt = specIcon and FileIconStr(specIcon, 14) or ""
            local label   = iconTxt .. (iconTxt ~= "" and " " or "") .. specName
            -- width: icon(14) + space(4) + ~6px per char
            local w = math.max(76, 18 + string.len(specName) * 6)
            local sb = CreateFrame("Button", nil, self.SpecRow)
            sb:SetSize(w, 22)
            sb:SetPoint("TOPLEFT", self.SpecRow, "TOPLEFT", x, 0)
            x = x + w + 4
            sb._bg = sb:CreateTexture(nil, "BACKGROUND")
            sb._bg:SetAllPoints()
            sb._bg:SetColorTexture(unpack(C.BG_INST))
            sb._fs = FS(sb, ADDON_FONT, 10, "OUTLINE")
            sb._fs:SetPoint("CENTER")
            sb._fs:SetText(label)
            sb._fs:SetTextColor(unpack(C.TEXT_DIM))
            Borders(sb, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])
            sb._spec = specID
            local capturedSpec = specID
            sb:SetScript("OnEnter", function(self)
                if not self._active then
                    self._bg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.09)
                    self._fs:SetTextColor(unpack(C.TEXT))
                end
            end)
            sb:SetScript("OnLeave", function(self)
                if not self._active then
                    self._bg:SetColorTexture(unpack(C.BG_INST))
                    self._fs:SetTextColor(unpack(C.TEXT_DIM))
                end
            end)
            sb:SetScript("OnClick", function()
                -- Toggle: click active spec to deselect
                if LOOTS.currentSpec == capturedSpec then
                    LOOTS.currentSpec = nil
                else
                    LOOTS.currentSpec = capturedSpec
                end
                LOOTS:_SyncSpecButtons()
                if LOOTS.currentTab == "favs" then
                    LOOTS:_ShowFavs()
                elseif LOOTS.currentInst then
                    LOOTS:SelectInstance(LOOTS.currentInst, LOOTS.currentInstName)
                end
            end)
            sb:Show()
            tinsert(self.SpecBtns, sb)
        end
    end
end

function LOOTS:_SyncSpecButtons()
    for _, sb in ipairs(self.SpecBtns or {}) do
        local active = (sb._spec == self.currentSpec)
        sb._active = active
        if active then
            sb._bg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.20)
            sb._fs:SetTextColor(unpack(C.TEXT_ACC))
        else
            sb._bg:SetColorTexture(unpack(C.BG_INST))
            sb._fs:SetTextColor(unpack(C.TEXT_DIM))
        end
    end
end

-- ══ Tab switching ═════════════════════════════════════════════════════

function LOOTS:SetTab(tab)
    self.currentTab  = tab
    self.currentInst = nil
    local isD = (tab == "dungeon")
    local isR = (tab == "raid")
    local isF = (tab == "favs")

    -- ── Visuel des onglets ───────────────────────────────────────────
    local tabDefs = {
        { t = self.TabDungeon, active = isD },
        { t = self.TabRaid,    active = isR },
        { t = self.TabFavs,    active = isF },
    }
    for _, td in ipairs(tabDefs) do
        td.t._active = td.active
        if td.active then
            td.t._bg:SetColorTexture(unpack(C.TAB_ACT))
            td.t._fs:SetTextColor(unpack(C.TEXT_ACC))
        else
            td.t._bg:SetColorTexture(unpack(C.TAB_INA))
            td.t._fs:SetTextColor(unpack(C.TEXT_DIM))
        end
    end

    self:_SyncDiffButtons()
    self:_SyncClassButtons()

    if isF then
        self:_RebuildFavsList()
        self:_ShowFavs()
    else
        self:_RebuildList(isD)
        self:_ClearItems()
    end
end

-- ══ Instance list ═════════════════════════════════════════════════════

function LOOTS:_RebuildList(isDungeon)
    local child = self.ListChild
    -- Hide (but don't delete) existing row frames
    if child._rows then
        for _, r in ipairs(child._rows) do
            r:ClearAllPoints()
            r:Hide()
        end
    end
    child._rows = {}

    local instances = EJ_FetchInstances(isDungeon)
    local y = 4

    for _, inst in ipairs(instances) do
        local row = CreateFrame("Button", nil, child)
        row:SetHeight(ROW_H_INST)
        row:SetPoint("TOPLEFT",  child, "TOPLEFT",  2, -y)
        row:SetPoint("TOPRIGHT", child, "TOPRIGHT", -2, -y)
        row._id = inst.id

        local rbg = row:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints()
        rbg:SetColorTexture(unpack(C.BG_INST))
        row._bg = rbg

        -- Instance icon
        local xOff = 6
        if inst.icon then
            local ico = row:CreateTexture(nil, "ARTWORK")
            ico:SetSize(ROW_H_INST - 10, ROW_H_INST - 10)
            ico:SetPoint("LEFT", row, "LEFT", 4, 0)
            ico:SetTexture(inst.icon)
            ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            xOff = ROW_H_INST - 2
        end

        local lbl = FS(row, ADDON_FONT, 10, "OUTLINE")
        lbl:SetPoint("LEFT",  row, "LEFT",  xOff, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -4,   0)
        lbl:SetJustifyH("LEFT")
        lbl:SetTextColor(unpack(C.TEXT))
        lbl:SetText(inst.name)
        lbl:SetWordWrap(false)
        lbl:SetMaxLines(1)

        Borders(row, C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.25)

        local id, iname = inst.id, inst.name
        row:SetScript("OnEnter", function()
            if id ~= LOOTS.currentInst then
                rbg:SetColorTexture(unpack(C.BG_INS_H))
            end
        end)
        row:SetScript("OnLeave", function()
            if id ~= LOOTS.currentInst then
                rbg:SetColorTexture(unpack(C.BG_INST))
            end
        end)
        row:SetScript("OnClick", function()
            LOOTS:SelectInstance(id, iname)
        end)

        tinsert(child._rows, row)
        y = y + ROW_H_INST + 2
    end

    child:SetHeight(math.max(y + 4, 10))
end

function LOOTS:_SyncListHighlight()
    if not self.ListChild._rows then return end
    for _, row in ipairs(self.ListChild._rows) do
        if row._id == self.currentInst then
            row._bg:SetColorTexture(unpack(C.BG_INS_A))
        else
            row._bg:SetColorTexture(unpack(C.BG_INST))
        end
    end
end

-- ══ Item display ══════════════════════════════════════════════════════

function LOOTS:_ClearItems()
    for _, f in ipairs(self._activeItems or {}) do
        f:ClearAllPoints()
        f:Hide()
    end
    wipe(self._activeItems)
    self.ItemChild:SetHeight(1)
    self.InstNameFS:SetText("")
    if self.HintFS then
        self.HintFS:SetText("|TInterface\\UI-SpellbookIcon-PrevPage:0|t Sélectionner un donjon ou un raid")
        self.HintFS:Show()
    end
end

-- Shared: render a flat item grid into child starting at y, return new y.
-- classFilter (optional): only show items matching the given playerClassID.
-- specFilter (optional): further restrict by specID.
local function RenderItemGrid(child, active, items, y, classFilter, specFilter)
    -- Apply class + spec filter
    if classFilter then
        local filtered = {}
        for _, item in ipairs(items) do
            if ItemMatchesClass(item.itemID, classFilter, specFilter) then
                tinsert(filtered, item)
            end
        end
        items = filtered
    end
    if #items == 0 then
        local nf = CreateFrame("Frame", nil, child)
        nf:SetHeight(20)
        nf:SetPoint("TOPLEFT",  child, "TOPLEFT",  4, -y)
        nf:SetPoint("TOPRIGHT", child, "TOPRIGHT", -4, -y)
        local nfs = nf:CreateFontString(nil, "OVERLAY")
        nfs:SetFont(ADDON_FONT, 10, "OUTLINE")
        nfs:SetShadowColor(0, 0, 0, 0.8)
        nfs:SetShadowOffset(1, -1)
        nfs:SetPoint("LEFT", nf, "LEFT", 0, 0)
        nfs:SetTextColor(unpack(C.TEXT_DIM))
        nfs:SetText("Aucun item disponible")
        tinsert(active, nf)
        return y + 22
    end
    local col = 0
    for _, item in ipairs(items) do
        local btn = MakeItemBtn(child, item.itemID, item.icon, item.quality, item.bonusId)
        btn:SetPoint("TOPLEFT", child, "TOPLEFT",
            4 + col * (ITEM_SIZE + ITEM_GAP), -y)
        tinsert(active, btn)
        col = col + 1
        if col >= ITEMS_PER_ROW then
            col = 0
            y = y + ITEM_SIZE + ITEM_GAP
        end
    end
    if col > 0 then y = y + ITEM_SIZE + ITEM_GAP end
    return y
end

function LOOTS:SelectInstance(id, name)
    self.currentInst     = id
    self.currentInstName = name
    self:_SyncListHighlight()
    self:_ClearItems()
    if self.HintFS then self.HintFS:Hide() end
    self.InstNameFS:SetText(name)
    self.ItemScroll:SetVerticalScroll(0)

    local child  = self.ItemChild
    local active = self._activeItems
    local y      = 8
    local cls    = self.currentClass
    local spec   = self.currentSpec

    if self.currentTab == "dungeon" then
        -- ── Dungeon: flat item grid from static data ──────────────────
        local items = GetDungeonItems(id)
        if #items == 0 then
            self.HintFS:SetText("Aucun item disponible pour ce donjon.")
            self.HintFS:Show()
        else
            y = RenderItemGrid(child, active, items, y, cls, spec)
        end
    else
        -- ── Raid: per-boss sections, items filtered by difficulty ─────
        local diff   = self.currentDiff
        local bosses = EJ_FetchBosses(id)
        if #bosses == 0 then
            self.HintFS:SetText("Aucun boss trouvé pour ce raid.")
            self.HintFS:Show()
            return
        end
        for _, boss in ipairs(bosses) do
            -- Boss header
            local hf = CreateFrame("Frame", nil, child)
            hf:SetHeight(22)
            hf:SetPoint("TOPLEFT",  child, "TOPLEFT",  4, -y)
            hf:SetPoint("TOPRIGHT", child, "TOPRIGHT", -4, -y)
            tinsert(active, hf)
            local hfs = hf:CreateFontString(nil, "OVERLAY")
            hfs:SetFont(ADDON_FONT_BOLD, 11, "OUTLINE")
            hfs:SetShadowColor(0, 0, 0, 0.8)
            hfs:SetShadowOffset(1, -1)
            hfs:SetPoint("LEFT", hf, "LEFT", 0, 0)
            hfs:SetTextColor(unpack(C.TEXT_ACC))
            hfs:SetText(boss.name)
            y = y + 22
            -- Accent separator
            local sf = CreateFrame("Frame", nil, child)
            sf:SetHeight(1)
            sf:SetPoint("TOPLEFT",  child, "TOPLEFT",  4, -y)
            sf:SetPoint("TOPRIGHT", child, "TOPRIGHT", -4, -y)
            local st = sf:CreateTexture(nil, "ARTWORK")
            st:SetAllPoints()
            st:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.22)
            tinsert(active, sf)
            y = y + 5
            -- Items
            y = RenderItemGrid(child, active, GetBossItems(boss.id, diff), y, cls, spec)
            y = y + 12
        end
    end

    child:SetHeight(math.max(y + 8, 10))
end

-- ══ Onglet Favoris ════════════════════════════════════════════════════

-- Met à jour le label de l'onglet avec le nombre de favoris
function LOOTS:_UpdateFavsTabLabel()
    if not self.TabFavs then return end
    local n = GetFavoritesCount()
    self.TabFavs._fs:SetText(n > 0 and ("Favoris (" .. n .. ")") or "Favoris")
end

-- Reconstruit le panneau gauche en mode Favoris (une ligne "N items")
function LOOTS:_RebuildFavsList()
    local child = self.ListChild
    if child._rows then
        for _, r in ipairs(child._rows) do r:ClearAllPoints(); r:Hide() end
    end
    child._rows = {}

    local n   = GetFavoritesCount()
    local lbl = n > 0 and (n .. " item" .. (n ~= 1 and "s" or "") .. " épinglé" .. (n ~= 1 and "s" or ""))
                       or "Aucun favori"

    local row = CreateFrame("Button", nil, child)
    row:SetHeight(ROW_H_INST)
    row:SetPoint("TOPLEFT",  child, "TOPLEFT",  2, -4)
    row:SetPoint("TOPRIGHT", child, "TOPRIGHT", -2, -4)
    row._id = "favs_all"

    local rbg = row:CreateTexture(nil, "BACKGROUND")
    rbg:SetAllPoints()
    rbg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.14)
    row._bg = rbg

    local lfs = FS(row, ADDON_FONT, 10, "OUTLINE")
    lfs:SetPoint("LEFT",  row, "LEFT",  8, 0)
    lfs:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    lfs:SetJustifyH("LEFT")
    lfs:SetTextColor(unpack(C.TEXT_ACC))
    lfs:SetText(lbl)
    lfs:SetWordWrap(false)
    lfs:SetMaxLines(1)

    Borders(row, C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.25)
    row:SetScript("OnClick", function() LOOTS:_ShowFavs() end)

    tinsert(child._rows, row)
    child:SetHeight(ROW_H_INST + 10)
end

-- Affiche les items favoris groupés par source (donjon / raid)
function LOOTS:_ShowFavs()
    self:_RebuildFavsList()
    self:_UpdateFavsTabLabel()

    -- Vider le panneau droit
    for _, f in ipairs(self._activeItems or {}) do f:ClearAllPoints(); f:Hide() end
    wipe(self._activeItems)
    self.ItemChild:SetHeight(1)
    self.ItemScroll:SetVerticalScroll(0)
    self.InstNameFS:SetText("Favoris")
    if self.HintFS then self.HintFS:Hide() end

    local favs = TomoModDB and TomoModDB.loots and TomoModDB.loots.favorites
    if not favs or not next(favs) then
        if self.HintFS then
            self.HintFS:SetText("Aucun favori — cliquez sur un item pour l'épingler")
            self.HintFS:Show()
        end
        return
    end

    -- ── Construire le reverse-lookup itemID → source ──────────────────
    EnsureEJLoaded()
    local srcMap = {}
    local LD = TomoMod_LootsData
    if LD then
        if LD.dungeons then
            for mapID, itemList in pairs(LD.dungeons) do
                local name
                if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                    name = C_ChallengeMode.GetMapUIInfo(mapID)
                end
                name = name or ("Donjon " .. mapID)
                for _, iid in ipairs(itemList) do
                    if not srcMap[iid] then
                        srcMap[iid] = { srcType = "dungeon", srcName = name }
                    end
                end
            end
        end
        if LD.raidBosses then
            for encID, diffTable in pairs(LD.raidBosses) do
                local name = EJ_GetEncounterInfo and EJ_GetEncounterInfo(encID)
                name = name or ("Boss " .. encID)
                local seen = {}
                for _, itemList in pairs(diffTable) do
                    for _, iid in ipairs(itemList) do
                        if not seen[iid] then
                            seen[iid] = true
                            if not srcMap[iid] then
                                srcMap[iid] = { srcType = "raid", srcName = name }
                            end
                        end
                    end
                end
            end
        end
    end

    -- ── Grouper les favoris par source ───────────────────────────────
    local groups    = {}   -- [key] = { srcType, srcName, items={} }
    local groupKeys = {}

    for itemID, stored in pairs(favs) do
        local id = type(itemID) == "number" and itemID or tonumber(itemID)
        if id then
            local bonusId = type(stored) == "number" and stored or nil
            local _, _, quality, _, _, _, _, _, _, icon = GetItemInfo(id)
            local src  = srcMap[id]
            local key  = src and (src.srcType .. "|" .. src.srcName) or "unknown"
            local sType = src and src.srcType or "unknown"
            local sName = src and src.srcName or "Source inconnue"
            if not groups[key] then
                groups[key] = { srcType = sType, srcName = sName, items = {} }
                tinsert(groupKeys, key)
            end
            tinsert(groups[key].items,
                { itemID = id, icon = icon, quality = quality or 4, bonusId = bonusId })
        end
    end

    -- Tri : donjons d'abord, puis raids ; alphabétique au sein de chaque type
    table.sort(groupKeys, function(a, b)
        local ga, gb = groups[a], groups[b]
        if ga.srcType ~= gb.srcType then return ga.srcType == "dungeon" end
        return ga.srcName < gb.srcName
    end)

    -- ── Rendu : une ligne par source ─────────────────────────────────
    local LABEL_W      = 170
    local SEP_W        = 1
    local SEP_GAP      = 5
    local ITEM_X       = LABEL_W + SEP_W + SEP_GAP * 2  -- début des icônes
    local FAV_PER_ROW  = math.max(1,
        math.floor((SCROLL_INNER - ITEM_X + ITEM_GAP) / (ITEM_SIZE + ITEM_GAP)))

    local child  = self.ItemChild
    local active = self._activeItems
    local cls    = self.currentClass
    local spec   = self.currentSpec
    local y      = 8

    for _, key in ipairs(groupKeys) do
        local grp = groups[key]

        -- Filtre classe/spec
        local items = {}
        for _, item in ipairs(grp.items) do
            if ItemMatchesClass(item.itemID, cls, spec) then
                tinsert(items, item)
            end
        end
        if #items == 0 then
            -- pas d'items pour ce filtre → groupe ignoré
        else
            local numRows = math.ceil(#items / FAV_PER_ROW)
            local groupH  = numRows * (ITEM_SIZE + ITEM_GAP)

            -- Label source (frame wrapper pour hide/show)
            local lblF = CreateFrame("Frame", nil, child)
            lblF:SetSize(LABEL_W, groupH)
            lblF:SetPoint("TOPLEFT", child, "TOPLEFT", 4, -y)
            local typeLabel = grp.srcType == "dungeon" and "Donjon" or "Raid"
            local lbl = lblF:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(ADDON_FONT, 10, "OUTLINE")
            lbl:SetShadowColor(0, 0, 0, 0.85)
            lbl:SetShadowOffset(1, -1)
            lbl:SetAllPoints()
            lbl:SetJustifyH("LEFT")
            lbl:SetJustifyV("MIDDLE")
            lbl:SetTextColor(unpack(C.TEXT_ACC))
            lbl:SetText(typeLabel .. " : " .. grp.srcName)
            lbl:SetWordWrap(true)
            tinsert(active, lblF)

            -- Séparateur vertical teal
            local sepF = child:CreateTexture(nil, "ARTWORK")
            sepF:SetWidth(SEP_W)
            sepF:SetPoint("TOPLEFT",     child, "TOPLEFT", LABEL_W + SEP_GAP, -y)
            sepF:SetPoint("BOTTOMLEFT",  child, "TOPLEFT", LABEL_W + SEP_GAP, -(y + groupH - ITEM_GAP))
            sepF:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.45)
            tinsert(active, sepF)

            -- Icônes d'items
            local col, row = 0, 0
            for _, item in ipairs(items) do
                local btn = MakeItemBtn(child, item.itemID, item.icon, item.quality, item.bonusId)
                btn:SetPoint("TOPLEFT", child, "TOPLEFT",
                    ITEM_X + col * (ITEM_SIZE + ITEM_GAP),
                    -(y + row * (ITEM_SIZE + ITEM_GAP)))
                tinsert(active, btn)
                col = col + 1
                if col >= FAV_PER_ROW then col = 0; row = row + 1 end
            end

            -- Ligne de séparation horizontale entre groupes
            local hLine = child:CreateTexture(nil, "ARTWORK")
            hLine:SetHeight(1)
            hLine:SetPoint("TOPLEFT",  child, "TOPLEFT",  4,             -(y + groupH + 4))
            hLine:SetPoint("TOPRIGHT", child, "TOPRIGHT", -4,            -(y + groupH + 4))
            hLine:SetColorTexture(C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.35)
            tinsert(active, hLine)

            y = y + groupH + 14
        end
    end

    child:SetHeight(math.max(y + 4, 10))
end

-- ══ Public API ════════════════════════════════════════════════════════

function LOOTS:Toggle()
    if not self.Frame then self:Build() end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
    end
end

function LOOTS:Initialize()
    -- Frame is built lazily on first /tm loot call.
    -- Nothing to do at login.
end

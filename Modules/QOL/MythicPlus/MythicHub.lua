-- =====================================================================
-- MythicHub.lua — Custom Mythic+ Overview Panel
-- Replaces Blizzard Great Vault shortcut on CharacterFrame.
-- Shows: M+ rating, season dungeon table (icon, name, level, rating,
--         best time), clickable teleport icons, Great Vault slots.
-- =====================================================================

local L = TomoMod_L
local DK = TomoMod_DataKeys

local ADDON_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

TomoMod_MythicHub = {}
local HUB = TomoMod_MythicHub

-- ═══════════════════════════════════════════════════════════════════════
--  THEME  (ObjectiveTracker / TomoMod dark panel)
-- ═══════════════════════════════════════════════════════════════════════
local C = {
    BG           = { 0.06, 0.06, 0.08, 0.96 },
    BG_HEADER    = { 0.08, 0.08, 0.11, 1.00 },
    BG_ROW_ODD   = { 0.07, 0.07, 0.09, 0.70 },
    BG_ROW_EVEN  = { 0.05, 0.05, 0.07, 0.70 },
    BG_VAULT     = { 0.05, 0.05, 0.07, 0.90 },
    ACCENT       = { 0.047, 0.824, 0.624, 1.00 },  -- tomo teal
    ACCENT_DIM   = { 0.047, 0.824, 0.624, 0.40 },
    BORDER       = { 0.25, 0.25, 0.30, 0.60 },
    TEXT_WHITE   = { 0.95, 0.95, 0.97, 1.00 },
    TEXT_GREY    = { 0.55, 0.55, 0.60, 1.00 },
    TEXT_DIM     = { 0.40, 0.40, 0.45, 1.00 },
    TEXT_ACCENT  = { 0.047, 0.824, 0.624, 1.00 },
    GOLD         = { 1.00, 0.82, 0.10, 1.00 },
    RED          = { 1.00, 0.30, 0.20, 1.00 },
    GREEN        = { 0.55, 0.90, 0.20, 1.00 },
}

-- ═══════════════════════════════════════════════════════════════════════
--  LAYOUT CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════
local FRAME_W        = 420
local HEADER_H       = 70
local COL_HEADER_H   = 18
local ROW_H          = 28
local VAULT_SECTION_H = 210
local VAULT_SLOT_SIZE = 48
local VAULT_GAP      = 10
local EDGE           = 1

-- Column layout (inside the dungeon table)
local COL = {
    ICON    = 28,
    NAME    = 160,
    LEVEL   = 44,
    RATING  = 50,
    TIME    = 110,
}

-- ═══════════════════════════════════════════════════════════════════════
--  VAULT ROW DEFS — discover real type values from API data
-- ═══════════════════════════════════════════════════════════════════════
local VAULT_TYPE_DUNGEON = 1   -- fallback
local VAULT_TYPE_RAID    = 3   -- fallback
local VAULT_TYPE_WORLD   = 6   -- fallback

local function DiscoverVaultTypes()
    if not C_WeeklyRewards then return end
    local activities = C_WeeklyRewards.GetActivities()
    if not activities then return end
    local seen = {}
    for _, act in ipairs(activities) do
        seen[act.type] = true
    end
    -- Sort type keys
    local keys = {}
    for k in pairs(seen) do keys[#keys + 1] = k end
    table.sort(keys)
    -- Expect 3 types: lowest = dungeons, middle = raid, highest = world
    if #keys >= 3 then
        VAULT_TYPE_DUNGEON = keys[1]
        VAULT_TYPE_RAID    = keys[2]
        VAULT_TYPE_WORLD   = keys[3]
    elseif #keys == 2 then
        VAULT_TYPE_DUNGEON = keys[1]
        VAULT_TYPE_RAID    = keys[2]
    elseif #keys == 1 then
        VAULT_TYPE_DUNGEON = keys[1]
    end
end

local function GetVaultRowDefs()
    return {
        {
            label = L["mhub_vault_raids"],
            type  = VAULT_TYPE_RAID,
            atlas = "weeklyrewards-background-raid",
        },
        {
            label = L["mhub_vault_dungeons"],
            type  = VAULT_TYPE_DUNGEON,
            atlas = "weeklyrewards-background-activities",
        },
        {
            label = L["mhub_vault_world"],
            type  = VAULT_TYPE_WORLD,
            atlas = "weeklyrewards-background-world",
        },
    }
end

local function GetVaultTypeName(vtype)
    if vtype == VAULT_TYPE_DUNGEON then return L["mhub_vault_dungeons"]
    elseif vtype == VAULT_TYPE_RAID then return L["mhub_vault_raids"]
    else return L["mhub_vault_world"] end
end

-- ═══════════════════════════════════════════════════════════════════════
--  M+ SCORE COLOR (matching Blizzard tiers)
-- ═══════════════════════════════════════════════════════════════════════
local function GetScoreColor(score)
    if score >= 2500 then return 1.00, 0.50, 0.00       -- orange
    elseif score >= 2000 then return 0.64, 0.21, 0.93   -- purple
    elseif score >= 1500 then return 0.00, 0.44, 0.87   -- blue
    elseif score >= 1000 then return 0.12, 1.00, 0.00   -- green
    elseif score >= 500  then return 1.00, 1.00, 1.00   -- white
    else return 0.55, 0.55, 0.55                          -- grey
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HELPER: Font string
-- ═══════════════════════════════════════════════════════════════════════
local function MakeFS(parent, font, size, flags, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY", "GameFontNormal")
    fs:SetFont(font or ADDON_FONT, size or 11, flags or "OUTLINE")
    fs:SetShadowColor(0, 0, 0, 0.9)
    fs:SetShadowOffset(1, -1)
    return fs
end

-- ═══════════════════════════════════════════════════════════════════════
--  HELPER: 1px borders on a frame
-- ═══════════════════════════════════════════════════════════════════════
local function MakeBorders(parent, r, g, b, a, sz)
    sz = sz or 1
    for _, info in ipairs({
        { "TOPLEFT",    "TOPRIGHT",    "h" },
        { "BOTTOMLEFT", "BOTTOMRIGHT", "h" },
        { "TOPLEFT",    "BOTTOMLEFT",  "v" },
        { "TOPRIGHT",   "BOTTOMRIGHT", "v" },
    }) do
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(r, g, b, a or 0.6)
        t:SetPoint(info[1], parent, info[1])
        t:SetPoint(info[2], parent, info[2])
        if info[3] == "h" then t:SetHeight(sz) else t:SetWidth(sz) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HELPER: Format time  mm:ss  or  h:mm:ss
-- ═══════════════════════════════════════════════════════════════════════
local function FormatTime(ms)
    if not ms or ms <= 0 then return "—" end
    local sec = math.floor(ms / 1000)
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%d:%02d", m, s)
end

-- ═══════════════════════════════════════════════════════════════════════
--  HELPER: Format time diff  (-mm:ss)  or (+mm:ss)
-- ═══════════════════════════════════════════════════════════════════════
local function FormatDelta(ms, timeLimit)
    if not ms or ms <= 0 or not timeLimit or timeLimit <= 0 then return "" end
    local diff = ms - (timeLimit * 1000)
    local absDiff = math.abs(diff)
    local sec = math.floor(absDiff / 1000)
    local m = math.floor(sec / 60)
    local s = sec % 60
    local sign = diff <= 0 and "-" or "+"
    return string.format("(%s%d:%02d)", sign, m, s)
end

-- ═══════════════════════════════════════════════════════════════════════
--  BUILD FRAME
-- ═══════════════════════════════════════════════════════════════════════
function HUB:Build()
    if self.Frame then return self.Frame end

    local seasonIDs = DK.GetCurrentSeasonIDs()
    local numDungeons = #seasonIDs
    local tableH = COL_HEADER_H + (numDungeons * ROW_H)
    local totalH = HEADER_H + 2 + tableH + 8 + VAULT_SECTION_H + 10

    -- ── Main Frame ───────────────────────────────────────────────────
    local F = CreateFrame("Frame", "TomoMod_MythicHubFrame", UIParent, "BackdropTemplate")
    self.Frame = F
    F:SetSize(FRAME_W, totalH)
    F:SetFrameStrata("DIALOG")
    F:SetFrameLevel(200)
    F:SetClampedToScreen(true)
    F:SetMovable(true)
    F:EnableMouse(true)
    F:RegisterForDrag("LeftButton")
    F:SetScript("OnDragStart", function(s) s:StartMoving() end)
    F:SetScript("OnDragStop",  function(s) s:StopMovingOrSizing() end)
    F:Hide()

    tinsert(UISpecialFrames, "TomoMod_MythicHubFrame")

    -- Background
    local bg = F:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(C.BG))

    MakeBorders(F, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])

    -- Left accent strip
    local accentL = F:CreateTexture(nil, "ARTWORK", nil, 1)
    accentL:SetWidth(2)
    accentL:SetPoint("TOPLEFT",    F, "TOPLEFT",    0, 0)
    accentL:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 0, 0)
    accentL:SetColorTexture(unpack(C.ACCENT))
    F._accentLine = accentL

    -- Close button (custom teal themed)
    local closeBtn = CreateFrame("Button", nil, F)
    closeBtn:SetPoint("TOPRIGHT", F, "TOPRIGHT", -4, -4)
    closeBtn:SetSize(18, 18)
    closeBtn:EnableMouse(true)

    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(unpack(C.BG_HEADER))

    local closeX = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeX:SetFont(ADDON_FONT_BOLD, 12, "OUTLINE")
    closeX:SetPoint("CENTER", 0, 0)
    closeX:SetText("x")
    closeX:SetTextColor(unpack(C.TEXT_GREY))

    MakeBorders(closeBtn, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])

    closeBtn:SetScript("OnEnter", function(self)
        closeX:SetTextColor(unpack(C.ACCENT))
        closeBg:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.15)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        closeX:SetTextColor(unpack(C.TEXT_GREY))
        closeBg:SetColorTexture(unpack(C.BG_HEADER))
    end)
    closeBtn:SetScript("OnClick", function() F:Hide() end)

    -- ── HEADER — M+ Rating centered ─────────────────────────────────
    local hdr = CreateFrame("Frame", nil, F)
    hdr:SetHeight(HEADER_H)
    hdr:SetPoint("TOPLEFT",  F, "TOPLEFT",  2, 0)
    hdr:SetPoint("TOPRIGHT", F, "TOPRIGHT", 0, 0)

    local hdrBg = hdr:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetAllPoints()
    hdrBg:SetColorTexture(unpack(C.BG_HEADER))

    local titleLabel = MakeFS(hdr, ADDON_FONT, 10, "OUTLINE")
    titleLabel:SetPoint("TOP", hdr, "TOP", 0, -8)
    titleLabel:SetTextColor(unpack(C.TEXT_GREY))
    titleLabel:SetText(L["mhub_title"])

    local ratingFS = MakeFS(hdr, ADDON_FONT_BOLD, 26, "OUTLINE")
    ratingFS:SetPoint("TOP", titleLabel, "BOTTOM", 0, -2)
    F._ratingFS = ratingFS

    -- Affix icons (right side of header)
    F._affixIcons = {}
    local MAX_AFFIXES = 4
    for i = 1, MAX_AFFIXES do
        local icon = hdr:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24)
        if i == 1 then
            icon:SetPoint("TOPRIGHT", hdr, "TOPRIGHT", -30, -10)
        else
            icon:SetPoint("RIGHT", F._affixIcons[i - 1], "LEFT", -6, 0)
        end
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:Hide()

        local lvlFS = MakeFS(hdr, ADDON_FONT, 8, "OUTLINE")
        lvlFS:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
        lvlFS:SetTextColor(unpack(C.TEXT_DIM))
        icon._labelFS = lvlFS
        lvlFS:Hide()

        F._affixIcons[i] = icon
    end

    -- Header bottom separator
    local sep1 = F:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(2)
    sep1:SetPoint("TOPLEFT",  hdr, "BOTTOMLEFT",  0, 0)
    sep1:SetPoint("TOPRIGHT", hdr, "BOTTOMRIGHT", 0, 0)
    sep1:SetColorTexture(unpack(C.ACCENT))

    -- ── DUNGEON TABLE — Column Headers ──────────────────────────────
    local colHdr = CreateFrame("Frame", nil, F)
    colHdr:SetHeight(COL_HEADER_H)
    colHdr:SetPoint("TOPLEFT",  sep1, "BOTTOMLEFT",  0, 0)
    colHdr:SetPoint("TOPRIGHT", sep1, "BOTTOMRIGHT", 0, 0)

    local colBg = colHdr:CreateTexture(nil, "BACKGROUND")
    colBg:SetAllPoints()
    colBg:SetColorTexture(0.04, 0.04, 0.06, 0.80)

    local cx = COL.ICON + 4
    local function ColLabel(text, w, justify)
        local fs = MakeFS(colHdr, ADDON_FONT, 9, "OUTLINE")
        fs:SetPoint("LEFT", colHdr, "LEFT", cx, 0)
        fs:SetWidth(w)
        fs:SetJustifyH(justify or "LEFT")
        fs:SetText(text)
        fs:SetTextColor(unpack(C.TEXT_GREY))
        cx = cx + w
        return fs
    end

    ColLabel(L["mhub_col_dungeon"], COL.NAME,   "LEFT")
    ColLabel(L["mhub_col_level"],   COL.LEVEL,  "CENTER")
    ColLabel(L["mhub_col_rating"],  COL.RATING, "CENTER")
    ColLabel(L["mhub_col_best"],    COL.TIME,   "RIGHT")

    local sep2 = F:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",  colHdr, "BOTTOMLEFT",  0, 0)
    sep2:SetPoint("TOPRIGHT", colHdr, "BOTTOMRIGHT", 0, 0)
    sep2:SetColorTexture(unpack(C.ACCENT_DIM))

    -- ── DUNGEON ROWS ────────────────────────────────────────────────
    F._rows = {}
    local prevAnchor = sep2

    for idx = 1, numDungeons do
        local row = CreateFrame("Button", nil, F)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  prevAnchor, "BOTTOMLEFT",  0, 0)
        row:SetPoint("TOPRIGHT", prevAnchor, "BOTTOMRIGHT", 0, 0)

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        local bgColor = (idx % 2 == 1) and C.BG_ROW_ODD or C.BG_ROW_EVEN
        rowBg:SetColorTexture(unpack(bgColor))

        -- Hover highlight
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.08)

        -- Dungeon icon
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row._icon = icon

        -- Teleport overlay (green tint if available)
        local tpOverlay = row:CreateTexture(nil, "OVERLAY")
        tpOverlay:SetSize(22, 22)
        tpOverlay:SetPoint("CENTER", icon, "CENTER")
        tpOverlay:SetColorTexture(0, 0, 0, 0)
        tpOverlay:Hide()
        row._tpOverlay = tpOverlay

        local colX = COL.ICON + 4

        -- Dungeon name
        local nameFS = MakeFS(row, ADDON_FONT, 11, "OUTLINE")
        nameFS:SetPoint("LEFT", row, "LEFT", colX, 0)
        nameFS:SetWidth(COL.NAME)
        nameFS:SetJustifyH("LEFT")
        nameFS:SetWordWrap(false)
        row._nameFS = nameFS
        colX = colX + COL.NAME

        -- Level
        local lvlFS = MakeFS(row, ADDON_FONT, 11, "OUTLINE")
        lvlFS:SetPoint("LEFT", row, "LEFT", colX, 0)
        lvlFS:SetWidth(COL.LEVEL)
        lvlFS:SetJustifyH("CENTER")
        row._lvlFS = lvlFS
        colX = colX + COL.LEVEL

        -- Rating
        local ratFS = MakeFS(row, ADDON_FONT, 11, "OUTLINE")
        ratFS:SetPoint("LEFT", row, "LEFT", colX, 0)
        ratFS:SetWidth(COL.RATING)
        ratFS:SetJustifyH("CENTER")
        row._ratFS = ratFS
        colX = colX + COL.RATING

        -- Best time
        local timeFS = MakeFS(row, ADDON_FONT, 10, "OUTLINE")
        timeFS:SetPoint("LEFT", row, "LEFT", colX, 0)
        timeFS:SetWidth(COL.TIME)
        timeFS:SetJustifyH("RIGHT")
        row._timeFS = timeFS

        -- Store data reference
        row._mapID = nil
        row._spellID = nil
        row._hasTeleport = false

        -- Click handler: teleport
        row:SetScript("OnClick", function(self)
            if self._hasTeleport and self._spellID then
                if IsSpellKnown(self._spellID) then
                    CastSpellByID(self._spellID)
                else
                    print(L["mhub_tp_not_learned"])
                end
            end
        end)

        -- Tooltip
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local name = self._nameFS:GetText() or "?"
            GameTooltip:SetText(name, unpack(C.TEXT_WHITE))
            if self._hasTeleport and self._spellID then
                if IsSpellKnown(self._spellID) then
                    GameTooltip:AddLine(L["mhub_tp_click"], C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
                else
                    GameTooltip:AddLine(L["mhub_tp_not_available"], C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3])
                end
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        F._rows[idx] = row
        prevAnchor = row
    end

    -- ── VAULT SEPARATOR ─────────────────────────────────────────────
    local sepV = F:CreateTexture(nil, "ARTWORK")
    sepV:SetHeight(1)
    sepV:SetPoint("TOPLEFT",  prevAnchor, "BOTTOMLEFT",  0, -8)
    sepV:SetPoint("TOPRIGHT", prevAnchor, "BOTTOMRIGHT", 0, -8)
    sepV:SetColorTexture(unpack(C.ACCENT_DIM))

    local vaultLabel = MakeFS(F, ADDON_FONT, 10, "OUTLINE")
    vaultLabel:SetPoint("TOP", sepV, "BOTTOM", 0, -4)
    vaultLabel:SetTextColor(unpack(C.TEXT_ACCENT))
    vaultLabel:SetText(L["mhub_vault_title"])

    -- ── GREAT VAULT — 3 rows × 3 slots ─────────────────────────────
    local VAULT_ROWS = GetVaultRowDefs()

    F._vaultSlots = {}

    -- Layout: label + 3 slots centered within the frame
    local LABEL_W       = 70
    local LABEL_GAP     = 8
    local SLOTS_BLOCK_W = (3 * VAULT_SLOT_SIZE) + (2 * VAULT_GAP)  -- 3×48 + 2×10 = 164
    local TOTAL_CONTENT = LABEL_W + LABEL_GAP + SLOTS_BLOCK_W      -- 70 + 8 + 164 = 242
    local LEFT_MARGIN   = math.floor((FRAME_W - TOTAL_CONTENT) / 2)
    local SLOT_STRIDE   = VAULT_SLOT_SIZE + VAULT_GAP
    local ROW_STRIDE    = VAULT_SLOT_SIZE + 16      -- slot height + ilvl text + gap
    local VAULT_TOP_Y   = -16                       -- offset from vaultLabel bottom

    -- Container frame anchored below the vault title, sized to fit all rows
    local vaultContainer = CreateFrame("Frame", nil, F)
    vaultContainer:SetPoint("TOPLEFT", vaultLabel, "BOTTOM", -(FRAME_W / 2), VAULT_TOP_Y)
    vaultContainer:SetSize(FRAME_W, #VAULT_ROWS * ROW_STRIDE)

    for ri, rowDef in ipairs(VAULT_ROWS) do
        local rowY = -((ri - 1) * ROW_STRIDE)

        -- Row background art frame (like Blizzard Great Vault)
        local rowBgFrame = CreateFrame("Frame", nil, vaultContainer)
        rowBgFrame:SetPoint("TOPLEFT", vaultContainer, "TOPLEFT", LEFT_MARGIN, rowY)
        rowBgFrame:SetSize(LABEL_W, VAULT_SLOT_SIZE)

        local rowArt = rowBgFrame:CreateTexture(nil, "BACKGROUND")
        rowArt:SetAllPoints()
        if rowDef.atlas then
            rowArt:SetAtlas(rowDef.atlas, false) -- false = stretch to fit frame
        end
        rowArt:SetAlpha(0.5)

        -- Dark overlay so text stays readable
        local rowOverlay = rowBgFrame:CreateTexture(nil, "BORDER")
        rowOverlay:SetAllPoints()
        rowOverlay:SetColorTexture(0, 0, 0, 0.45)

        MakeBorders(rowBgFrame, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])

        -- Row label — centered on the background art frame
        local rowLabel = MakeFS(rowBgFrame, ADDON_FONT_BOLD, 10, "OUTLINE")
        rowLabel:SetPoint("CENTER", rowBgFrame, "CENTER", 0, 0)
        rowLabel:SetWidth(LABEL_W - 4)
        rowLabel:SetJustifyH("CENTER")
        rowLabel:SetTextColor(unpack(C.TEXT_WHITE))
        rowLabel:SetText(rowDef.label)

        F._vaultSlots[ri] = {}

        for si = 1, 3 do
            local slotX = LEFT_MARGIN + LABEL_W + LABEL_GAP + ((si - 1) * SLOT_STRIDE)

            local slot = CreateFrame("Frame", nil, vaultContainer)
            slot:SetSize(VAULT_SLOT_SIZE, VAULT_SLOT_SIZE)
            slot:SetPoint("TOPLEFT", vaultContainer, "TOPLEFT", slotX, rowY)

            -- Slot background
            local slotBg = slot:CreateTexture(nil, "BACKGROUND")
            slotBg:SetAllPoints()
            slotBg:SetColorTexture(unpack(C.BG_VAULT))

            MakeBorders(slot, C.BORDER[1], C.BORDER[2], C.BORDER[3], C.BORDER[4])

            -- Icon texture (reward or locked)
            local iconTex = slot:CreateTexture(nil, "ARTWORK")
            iconTex:SetSize(VAULT_SLOT_SIZE - 6, VAULT_SLOT_SIZE - 6)
            iconTex:SetPoint("CENTER")
            iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            slot._icon = iconTex

            -- Checkmark overlay (if completed)
            local check = slot:CreateTexture(nil, "OVERLAY")
            check:SetSize(16, 16)
            check:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -1, -1)
            check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            check:Hide()
            slot._check = check

            -- Lock overlay (if not completed)
            local lock = slot:CreateTexture(nil, "OVERLAY")
            lock:SetSize(18, 18)
            lock:SetPoint("CENTER")
            lock:SetTexture("Interface\\PetBattles\\PetBattle-LockIcon")
            lock:SetDesaturated(true)
            lock:SetAlpha(0.5)
            lock:Hide()
            slot._lock = lock

            -- Progress text (e.g. "2/4")
            local progFS = MakeFS(slot, ADDON_FONT, 8, "OUTLINE")
            progFS:SetPoint("BOTTOM", slot, "BOTTOM", 0, 2)
            progFS:SetTextColor(unpack(C.TEXT_DIM))
            slot._progFS = progFS

            -- Item level text (below slot, constrained to slot width)
            local ilvlFS = MakeFS(vaultContainer, ADDON_FONT, 8, "OUTLINE")
            ilvlFS:SetPoint("TOP", slot, "BOTTOM", 0, -1)
            ilvlFS:SetWidth(VAULT_SLOT_SIZE + VAULT_GAP)
            ilvlFS:SetJustifyH("CENTER")
            ilvlFS:SetTextColor(unpack(C.TEXT_ACCENT))
            slot._ilvlFS = ilvlFS

            -- Tooltip
            slot:EnableMouse(true)
            slot._thresholdType = rowDef.type
            slot._slotIndex = si
            slot:SetScript("OnEnter", function(self)
                HUB:ShowVaultTooltip(self)
            end)
            slot:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            F._vaultSlots[ri][si] = slot
        end
    end

    return F
end

-- ═══════════════════════════════════════════════════════════════════════
--  POPULATE — Refresh dungeon data + vault
-- ═══════════════════════════════════════════════════════════════════════
function HUB:Refresh()
    local F = self.Frame
    if not F then return end

    DK.RefreshFromAPI()

    -- ── M+ Rating ────────────────────────────────────────────────────
    local overallScore = 0
    if C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore then
        overallScore = C_ChallengeMode.GetOverallDungeonScore() or 0
    end

    if overallScore > 0 then
        F._ratingFS:SetText(tostring(overallScore))
        local r, g, b = GetScoreColor(overallScore)
        F._ratingFS:SetTextColor(r, g, b, 1)
        F._accentLine:SetColorTexture(r, g, b, 0.80)
    else
        F._ratingFS:SetText("—")
        F._ratingFS:SetTextColor(unpack(C.TEXT_DIM))
        F._accentLine:SetColorTexture(unpack(C.ACCENT))
    end

    -- ── Affix Icons ────────────────────────────────────────────────
    if F._affixIcons and C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
        local affixes = C_MythicPlus.GetCurrentAffixes()
        -- Hide all first
        for _, ic in ipairs(F._affixIcons) do
            ic:Hide()
            if ic._labelFS then ic._labelFS:Hide() end
        end
        if affixes then
            for i, affixInfo in ipairs(affixes) do
                local ic = F._affixIcons[i]
                if not ic then break end
                local name, desc, texPath = C_ChallengeMode.GetAffixInfo(affixInfo.id)
                if texPath then
                    ic:SetTexture(texPath)
                    ic:Show()
                    if ic._labelFS and affixInfo.id then
                        ic._labelFS:SetText("+" .. (affixInfo.seasonLevel or ""))
                        ic._labelFS:Show()
                    end
                end
            end
        end
    end

    -- ── Dungeon Rows ─────────────────────────────────────────────────
    local seasonIDs = DK.GetCurrentSeasonIDs()

    -- Get per-dungeon best info
    local dungeonScores = {}
    if C_MythicPlus and C_MythicPlus.GetRunHistory then
        -- Use GetSeasonBestAffixScoreInfoForMap for each mapID
        for _, mapID in ipairs(seasonIDs) do
            dungeonScores[mapID] = { level = 0, score = 0, durationMS = 0, overTime = false }

            -- Best overall for this map
            if C_MythicPlus.GetSeasonBestAffixScoreInfoForMap then
                local affixScores = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mapID)
                if affixScores then
                    -- API returns an array of MythicPlusAffixScoreInfo — pick the best
                    local best = nil
                    if type(affixScores) == "table" then
                        if affixScores.score then
                            -- Single object (legacy format)
                            best = affixScores
                        else
                            for _, info in ipairs(affixScores) do
                                if not best or (info.score or 0) > (best.score or 0) then
                                    best = info
                                end
                            end
                        end
                    end
                    if best then
                        dungeonScores[mapID].level = best.level or 0
                        dungeonScores[mapID].score = best.score or 0
                        dungeonScores[mapID].durationMS = best.durationSec and (best.durationSec * 1000) or 0
                        dungeonScores[mapID].overTime = best.overTime or false
                    end
                end
            end

            -- Also try GetSeasonBestForMap (TWW 11.1: returns an info table, not two numbers)
            if C_MythicPlus.GetSeasonBestForMap then
                local result = C_MythicPlus.GetSeasonBestForMap(mapID)
                if result then
                    local bestLevel, bestDuration
                    if type(result) == "table" then
                        bestLevel = result.level
                        bestDuration = result.durationSec and (result.durationSec * 1000)
                    else
                        bestLevel = result
                    end
                    if bestLevel and bestLevel > (dungeonScores[mapID].level or 0) then
                        dungeonScores[mapID].level = bestLevel
                        dungeonScores[mapID].durationMS = bestDuration or 0
                    end
                end
            end
        end
    end

    -- Also try C_ChallengeMode.GetSpecificDungeonOverallScoreRoughlyByMapID or similar
    if C_ChallengeMode.GetSpecificDungeonScoreRoughlyByKeystone then
        -- Fallback for builds that expose this
    end

    for idx, mapID in ipairs(seasonIDs) do
        local row = F._rows[idx]
        if not row then break end

        row._mapID = mapID

        -- Dungeon icon
        local _, _, _, tex = C_ChallengeMode.GetMapUIInfo(mapID)
        if tex and tex > 0 then
            row._icon:SetTexture(tex)
        else
            row._icon:SetTexture("Interface\\Icons\\Achievement_ChallengeMode_Platinum")
        end

        -- Dungeon name
        local name = DK.GetDungeonName(mapID) or ("ID:" .. mapID)
        row._nameFS:SetText(name)
        row._nameFS:SetTextColor(unpack(C.TEXT_WHITE))

        -- Teleport spell
        local spellID = DK.GetTeleportSpellID(mapID)
        row._spellID = spellID
        row._hasTeleport = (spellID ~= nil)

        if spellID and IsSpellKnown(spellID) then
            row._nameFS:SetTextColor(unpack(C.TEXT_WHITE))
        elseif spellID then
            -- Has TP spell but not learned yet
            row._nameFS:SetTextColor(unpack(C.TEXT_WHITE))
        end

        -- Score data
        local info = dungeonScores[mapID]
        if info and info.level > 0 then
            -- Level (with * notation for timed upgrades)
            local lvlText = tostring(info.level)
            row._lvlFS:SetText(lvlText)
            row._lvlFS:SetTextColor(unpack(C.TEXT_WHITE))

            -- Rating
            if info.score and info.score > 0 then
                row._ratFS:SetText(tostring(math.floor(info.score)))
                local r, g, b = GetScoreColor(info.score)
                row._ratFS:SetTextColor(r, g, b, 1)
            else
                row._ratFS:SetText("—")
                row._ratFS:SetTextColor(unpack(C.TEXT_DIM))
            end

            -- Best time
            if info.durationMS and info.durationMS > 0 then
                local timeStr = FormatTime(info.durationMS)
                -- Get time limit for delta
                local _, _, tl = C_ChallengeMode.GetMapUIInfo(mapID)
                local delta = ""
                if tl and tl > 0 then
                    delta = " " .. FormatDelta(info.durationMS, tl)
                end
                row._timeFS:SetText(timeStr .. delta)
                if info.overTime then
                    row._timeFS:SetTextColor(unpack(C.RED))
                else
                    row._timeFS:SetTextColor(unpack(C.TEXT_GREY))
                end
            else
                row._timeFS:SetText("—")
                row._timeFS:SetTextColor(unpack(C.TEXT_DIM))
            end
        else
            row._lvlFS:SetText("—")
            row._lvlFS:SetTextColor(unpack(C.TEXT_DIM))
            row._ratFS:SetText("—")
            row._ratFS:SetTextColor(unpack(C.TEXT_DIM))
            row._timeFS:SetText("—")
            row._timeFS:SetTextColor(unpack(C.TEXT_DIM))
        end
    end

    -- ── Great Vault ──────────────────────────────────────────────────
    self:RefreshVault()
end

-- ═══════════════════════════════════════════════════════════════════════
--  VAULT LOGIC
-- ═══════════════════════════════════════════════════════════════════════
function HUB:RefreshVault()
    local F = self.Frame
    if not F or not F._vaultSlots then return end

    -- Ensure Blizzard addon is loaded for C_WeeklyRewards
    if not C_WeeklyRewards then return end

    -- Load Blizzard_WeeklyRewards if not already loaded
    if not C_AddOns.IsAddOnLoaded("Blizzard_WeeklyRewards") then
        local loaded = C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
        if not loaded then return end
    end

    -- Force a data refresh so we get up-to-date vault info
    if WeeklyRewardsFrame and WeeklyRewardsFrame.FullRefresh then
        WeeklyRewardsFrame:FullRefresh()
    end

    local activities = C_WeeklyRewards.GetActivities()
    if not activities then return end

    local hasGenerated = C_WeeklyRewards.HasGeneratedRewards()

    -- Organize by type + threshold index
    local byType = {}
    for _, act in ipairs(activities) do
        if not byType[act.type] then byType[act.type] = {} end
        byType[act.type][act.index] = act
    end

    DiscoverVaultTypes()
    local VAULT_ROWS = GetVaultRowDefs()

    for ri, rowDef in ipairs(VAULT_ROWS) do
        for si = 1, 3 do
            local slot = F._vaultSlots[ri] and F._vaultSlots[ri][si]
            if not slot then break end

            local act = byType[rowDef.type] and byType[rowDef.type][si]

            if act then
                slot._activityData = act  -- store for tooltip
                local completed = act.progress >= act.threshold

                if completed then
                    -- Uniform chest icon for all completed slots
                    slot._icon:SetTexture("Interface\\Icons\\Inv_misc_treasurechest04b")
                    slot._icon:SetDesaturated(false)
                    slot._icon:SetAlpha(1)
                    slot._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                    slot._check:Show()
                    slot._lock:Hide()
                    slot._progFS:SetText(act.progress .. "/" .. act.threshold)
                    slot._progFS:SetTextColor(unpack(C.GREEN))

                    -- Still show item level from example reward
                    local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(act.id)
                    local ilvl = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink) or nil
                    if ilvl and ilvl > 0 then
                        slot._ilvlFS:SetText(tostring(ilvl))
                        slot._ilvlFS:SetTextColor(unpack(C.TEXT_ACCENT))
                    else
                        slot._ilvlFS:SetText("")
                    end
                else
                    -- Not completed — same chest icon but desaturated
                    slot._icon:SetTexture("Interface\\Icons\\Inv_misc_treasurechest04b")
                    slot._icon:SetDesaturated(true)
                    slot._icon:SetAlpha(0.4)
                    slot._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    slot._check:Hide()
                    slot._lock:Show()
                    slot._progFS:SetText(act.progress .. "/" .. act.threshold)
                    slot._progFS:SetTextColor(unpack(C.TEXT_DIM))
                    slot._ilvlFS:SetText("")
                end
            else
                -- No activity data
                slot._icon:SetTexture("Interface\\Icons\\Inv_misc_treasurechest04b")
                slot._icon:SetDesaturated(true)
                slot._icon:SetAlpha(0.20)
                slot._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                slot._check:Hide()
                slot._lock:Show()
                slot._progFS:SetText("")
                slot._ilvlFS:SetText("")
                slot._activityData = nil
            end
        end
    end
end

function HUB:SetSlotCompleteNoItem(slot)
    slot._icon:SetTexture("Interface\\Icons\\Inv_misc_treasurechest04b")
    slot._icon:SetDesaturated(false)
    slot._icon:SetAlpha(0.80)
    slot._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

-- ═══════════════════════════════════════════════════════════════════════
--  VAULT TOOLTIP
-- ═══════════════════════════════════════════════════════════════════════
function HUB:ShowVaultTooltip(slot)
    GameTooltip:SetOwner(slot, "ANCHOR_RIGHT", -3, -6)

    local act = slot._activityData
    if not act then
        GameTooltip:SetText(L["mhub_vault_locked"], unpack(C.TEXT_GREY))
        GameTooltip:Show()
        return
    end

    local completed = act.progress >= act.threshold
    local typeName = GetVaultTypeName(act.type)
    local isDungeon = (act.type == VAULT_TYPE_DUNGEON)

    if completed then
        -- Completed slot — show reward preview
        GameTooltip:SetText(WEEKLY_REWARDS_CURRENT_REWARD or (typeName .. " — " .. COMPLETE), 1, 1, 1)

        local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(act.id)
        if itemLink then
            local ilvl = C_Item.GetDetailedItemLevelInfo(itemLink)
            if ilvl then
                if isDungeon then
                    -- Show level info for M+
                    local level = act.level or 0
                    if level > 0 then
                        GameTooltip:AddLine(string.format(WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC or "Item Level %d (Mythic+ %d)", ilvl, level), 1, 1, 1)
                    else
                        GameTooltip:AddLine(string.format("Item Level %d", ilvl), 1, 1, 1)
                    end
                else
                    GameTooltip:AddLine(string.format("Item Level %d", ilvl), 1, 1, 1)
                end

                -- Check if upgrade is possible
                if C_WeeklyRewards.GetNextActivitiesIncrease then
                    local hasData, nextTierID, nextLevel, nextIlvl = C_WeeklyRewards.GetNextActivitiesIncrease(act.activityTierID or act.id, act.level or 0)
                    if hasData and nextIlvl then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL or "Improve to Item Level %d", nextIlvl), C.GREEN[1], C.GREEN[2], C.GREEN[3])
                    end
                end
            end
        end

        -- Add top M+ runs for dungeon slots
        if isDungeon then
            self:AddTopRunsToTooltip(act.threshold)
        end
    else
        -- Incomplete slot — show requirements
        GameTooltip:SetText(WEEKLY_REWARDS_UNLOCK_REWARD or "Unlock Reward", 1, 1, 1)

        if isDungeon then
            if act.index == 1 then
                GameTooltip:AddLine(GREAT_VAULT_REWARDS_MYTHIC_INCOMPLETE or "Complete Mythic dungeons to unlock", 1, 0.82, 0)
            else
                local remaining = act.threshold - act.progress
                local globalStr = (act.index == 2) and (GREAT_VAULT_REWARDS_MYTHIC_COMPLETED_FIRST or "Complete %d more")
                                                    or (GREAT_VAULT_REWARDS_MYTHIC_COMPLETED_SECOND or "Complete %d more")
                GameTooltip:AddLine(string.format(globalStr, remaining), 1, 0.82, 0)
            end

            -- Show current reward level if partially complete
            if act.progress > 0 and WeeklyRewardsUtil and WeeklyRewardsUtil.GetLowestLevelInTopDungeonRuns then
                local lowestLevel = WeeklyRewardsUtil.GetLowestLevelInTopDungeonRuns(act.threshold)
                if lowestLevel then
                    GameTooltip:AddLine(" ")
                    if lowestLevel == (WeeklyRewardsUtil.HeroicLevel or 0) then
                        GameTooltip:AddLine(string.format(GREAT_VAULT_REWARDS_CURRENT_LEVEL_HEROIC or "Current reward: Heroic (top %d)", act.threshold), 1, 1, 1)
                    else
                        GameTooltip:AddLine(string.format(GREAT_VAULT_REWARDS_CURRENT_LEVEL_MYTHIC or "Current reward: Mythic+ %d (top %d)", lowestLevel, act.threshold), 1, 1, 1)
                    end
                end
            end

            self:AddTopRunsToTooltip(act.threshold)
        else
            local remaining = act.threshold - act.progress
            GameTooltip:AddLine(string.format("%d / %d", act.progress, act.threshold), C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3])
        end
    end

    GameTooltip:Show()
end

-- Show top M+ runs in tooltip (like ChonkyCharacterSheet)
function HUB:AddTopRunsToTooltip(threshold)
    if not C_MythicPlus or not C_MythicPlus.GetRunHistory then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS or "Top %d Runs This Week", threshold), 1, 0.82, 0)

    local runHistory = C_MythicPlus.GetRunHistory(false, true)
    if runHistory and #runHistory > 0 then
        table.sort(runHistory, function(a, b)
            if a.level == b.level then
                return a.mapChallengeModeID < b.mapChallengeModeID
            end
            return a.level > b.level
        end)

        for i = 1, threshold do
            if runHistory[i] then
                local name = C_ChallengeMode.GetMapUIInfo(runHistory[i].mapChallengeModeID)
                GameTooltip:AddLine(
                    string.format(WEEKLY_REWARDS_MYTHIC_RUN_INFO or "+%d %s", runHistory[i].level, name or "?"),
                    0.8, 0.8, 0.8
                )
            end
        end

        -- Fill remaining with heroic/mythic runs if needed
        local missingRuns = threshold - #runHistory
        if missingRuns > 0 and C_WeeklyRewards.GetNumCompletedDungeonRuns then
            local numHeroic, numMythic = C_WeeklyRewards.GetNumCompletedDungeonRuns()
            while numMythic > 0 and missingRuns > 0 do
                GameTooltip:AddLine(string.format(WEEKLY_REWARDS_MYTHIC or "Mythic %d", WeeklyRewardsUtil and WeeklyRewardsUtil.MythicLevel or 0), 0.6, 0.6, 0.6)
                numMythic = numMythic - 1
                missingRuns = missingRuns - 1
            end
            while numHeroic > 0 and missingRuns > 0 do
                GameTooltip:AddLine(WEEKLY_REWARDS_HEROIC or "Heroic", 0.6, 0.6, 0.6)
                numHeroic = numHeroic - 1
                missingRuns = missingRuns - 1
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  PUBLIC API
-- ═══════════════════════════════════════════════════════════════════════
function HUB:Toggle()
    local F = self:Build()
    if F:IsShown() then
        F:Hide()
    else
        self:Refresh()
        -- Position: anchored to CharacterFrame if open, else center
        F:ClearAllPoints()
        if CharacterFrame and CharacterFrame:IsShown() then
            F:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 4, 0)
        else
            F:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
        end
        F:Show()
    end
end

function HUB:Show()
    local F = self:Build()
    self:Refresh()
    F:ClearAllPoints()
    if CharacterFrame and CharacterFrame:IsShown() then
        F:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 4, 0)
    else
        F:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    end
    F:Show()
end

function HUB:Hide()
    if self.Frame then self.Frame:Hide() end
end

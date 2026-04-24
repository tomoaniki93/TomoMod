-- ============================================================
-- RFPreview.lua — Live Raid Frame preview strip
-- Shows 20 fake raid members that mirror TomoModDB.raidFrames
-- in real time as config options change.
--
-- Architecture (mirrors UFPreview):
--   CreatePreviewMember(parent)         → builds one fake frame table
--   ApplyMember(pf, idx, db, ...)       → reads DB, updates visuals
--   RFP.Create(parent)                  → builds the strip, returns it
--   RFP.Refresh()                       → public, re-applies all members
-- ============================================================

TomoMod_RFPreview = {}
local RFP = TomoMod_RFPreview
local L   = TomoMod_L

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- Hard-coded class colors (avoids RAID_CLASS_COLORS taint)
local CLASS_COLORS = {
    { 0.96, 0.55, 0.73 },  -- Paladin      (Holy — healer)
    { 0.00, 0.44, 0.87 },  -- Shaman       (Resto — healer)
    { 0.78, 0.61, 0.43 },  -- Warrior      (Protection — tank)
    { 0.67, 0.83, 0.45 },  -- Hunter       (DPS)
    { 0.58, 0.51, 0.79 },  -- Warlock      (DPS)
    { 0.96, 0.55, 0.73 },  -- Paladin      (Ret — DPS)
    { 0.90, 0.90, 0.90 },  -- Priest       (Holy — healer)
    { 0.77, 0.12, 0.23 },  -- Death Knight (tank)
    { 0.41, 0.80, 0.94 },  -- Mage         (DPS)
    { 1.00, 0.49, 0.04 },  -- Druid        (DPS)
    { 0.00, 1.00, 0.59 },  -- Monk         (Brewmaster — tank)
    { 0.00, 0.44, 0.87 },  -- Shaman       (Ele — DPS)
    { 0.64, 0.19, 0.79 },  -- Demon Hunter (DPS)
    { 1.00, 0.96, 0.41 },  -- Rogue        (DPS)
    { 0.20, 0.58, 0.50 },  -- Evoker       (DPS)
    { 0.41, 0.80, 0.94 },  -- Mage         (DPS)
    { 0.00, 1.00, 0.59 },  -- Monk         (MW — healer)
    { 0.78, 0.61, 0.43 },  -- Warrior      (DPS)
    { 1.00, 0.49, 0.04 },  -- Druid        (Balance — DPS)
    { 0.67, 0.83, 0.45 },  -- Hunter       (DPS)
}

local NAMES = {
    "Tomoyuki", "Aelindra", "Broxtar", "Cynara",  "Draleth",
    "Elowen",   "Fyrath",   "Garissa", "Helyon",  "Isolde",
    "Jaxren",   "Kelvara",  "Luneth",  "Mordak",  "Nyssara",
    "Orvyn",    "Pyrael",   "Quelith", "Ryndra",  "Sylvar",
}

-- Faked HP for visual variety
local MOCK_HP = {
    100, 85, 60, 45, 90,
    100, 72, 55, 80, 30,
     95, 88, 40, 70, 65,
    100, 78, 62, 87, 50,
}

-- Roles (per group of 5: [1]=TANK, [2]=HEALER, [3-5]=DAMAGER)
-- Groups 3 & 4 have no tank
local MOCK_ROLES = {
    "TANK",    "HEALER",   "DAMAGER", "DAMAGER", "DAMAGER",  -- G1
    "TANK",    "HEALER",   "DAMAGER", "DAMAGER", "DAMAGER",  -- G2
    "HEALER",  "DAMAGER",  "DAMAGER", "DAMAGER", "DAMAGER",  -- G3
    "DAMAGER", "HEALER",   "DAMAGER", "DAMAGER", "DAMAGER",  -- G4
}

-- Which fake members to show a dispel highlight on (index → debuff type)
local MOCK_DISPEL = {
    [3]  = { r=0.20, g=0.50, b=1.00 },  -- Magic   (blue)
    [8]  = { r=0.20, g=0.75, b=0.20 },  -- Poison  (green)
    [13] = { r=0.65, g=0.20, b=0.80 },  -- Curse   (purple)
}

-- Which frames to show absorb/heal prediction indicators on
local MOCK_ABSORB    = { [5]=true, [10]=true, [15]=true, [20]=true }
local MOCK_HEALPRED  = { [2]=true, [7]=true,  [12]=true, [17]=true }

local MOCK_COUNT  = 20
local NUM_GROUPS  = 4
local GROUP_SIZE  = 5

local HOT_COLORS = { {0.20, 0.80, 0.30}, {0.80, 0.80, 0.10}, {0.20, 0.50, 1.00} }

-- ============================================================
-- Build one fake raid member frame (no secure template needed)
-- ============================================================
local function CreatePreviewMember(parent)
    local pf = {}

    pf.frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    pf.frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    pf.frame:SetBackdropColor(0.04, 0.04, 0.06, 0.92)
    pf.frame:SetBackdropBorderColor(0.12, 0.12, 0.14, 1)

    -- Health bar
    pf.health = CreateFrame("StatusBar", nil, pf.frame)
    pf.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    pf.healthBg = pf.health:CreateTexture(nil, "BACKGROUND")
    pf.healthBg:SetAllPoints()

    -- Absorb indicator (thin bright right edge)
    pf.absorb = pf.health:CreateTexture(nil, "OVERLAY")
    pf.absorb:SetPoint("TOPRIGHT",    pf.health, "TOPRIGHT",    0, 0)
    pf.absorb:SetPoint("BOTTOMRIGHT", pf.health, "BOTTOMRIGHT", 0, 0)
    pf.absorb:SetColorTexture(0.75, 0.75, 1.00, 0.65)
    pf.absorb:Hide()

    -- Heal prediction indicator (green right edge)
    pf.healPred = pf.health:CreateTexture(nil, "OVERLAY")
    pf.healPred:SetPoint("TOPRIGHT",    pf.health, "TOPRIGHT",    0, 0)
    pf.healPred:SetPoint("BOTTOMRIGHT", pf.health, "BOTTOMRIGHT", 0, 0)
    pf.healPred:SetColorTexture(0.08, 0.82, 0.25, 0.55)
    pf.healPred:Hide()

    -- Name text (anchored to TOP of health bar — matches actual RF)
    pf.name = pf.health:CreateFontString(nil, "OVERLAY")
    pf.name:SetPoint("TOP", 0, -1)
    pf.name:SetJustifyH("CENTER")
    pf.name:SetWordWrap(false)
    pf.name:SetMaxLines(1)
    pf.name:SetTextColor(1, 1, 1, 0.90)

    -- Health text (bottom-center of health bar)
    pf.healthText = pf.health:CreateFontString(nil, "OVERLAY")
    pf.healthText:SetPoint("BOTTOM", 0, 1)
    pf.healthText:SetJustifyH("CENTER")
    pf.healthText:SetTextColor(1, 1, 1, 0.65)

    -- Power bar
    pf.power = CreateFrame("StatusBar", nil, pf.frame)
    pf.power:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    pf.powerBg = pf.power:CreateTexture(nil, "BACKGROUND")
    pf.powerBg:SetAllPoints()
    pf.powerBg:SetColorTexture(0.03, 0.03, 0.08, 1)
    pf.power:Hide()

    -- Role icon (small colored square top-left)
    pf.roleIcon = pf.frame:CreateTexture(nil, "OVERLAY")
    pf.roleIcon:SetPoint("TOPLEFT", 2, -2)
    pf.roleIcon:Hide()

    -- HoT dots (up to 3, bottom of frame)
    pf.hotDots = {}
    for i = 1, 3 do
        local dot = pf.frame:CreateTexture(nil, "OVERLAY")
        dot:SetSize(4, 4)
        dot:Hide()
        pf.hotDots[i] = dot
    end

    -- Dispel border highlight
    pf.dispelBorder = CreateFrame("Frame", nil, pf.frame, "BackdropTemplate")
    pf.dispelBorder:SetAllPoints()
    pf.dispelBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    pf.dispelBorder:SetBackdropBorderColor(0, 0, 0, 0)

    return pf
end

-- ============================================================
-- Apply DB settings + mock data to one fake member
-- ============================================================
local function ApplyMember(pf, idx, db, frameW, frameH, scaledPowerH, scale)
    local hp   = MOCK_HP[idx]    or 75
    local role = MOCK_ROLES[idx] or "DAMAGER"
    local cc   = CLASS_COLORS[idx] or CLASS_COLORS[1]

    -- Heights: power lives at the bottom, health fills the rest
    local healthH = frameH - (scaledPowerH > 0 and (scaledPowerH + 1) or 0)
    if healthH < 4 then healthH = 4 end

    pf.frame:SetSize(frameW, frameH)

    -- ── Health bar ──────────────────────────────────────────
    pf.health:ClearAllPoints()
    pf.health:SetPoint("TOPLEFT", pf.frame, "TOPLEFT", 0, 0)
    pf.health:SetSize(frameW, healthH)
    pf.health:SetMinMaxValues(0, 100)
    pf.health:SetValue(hp)

    local colorMode = db.healthColor or "class"
    local r, g, b
    if colorMode == "class" then
        r, g, b = cc[1], cc[2], cc[3]
    elseif colorMode == "gradient" then
        local t = hp / 100
        r = math.max(0, 1 - t * 1.2)
        g = math.min(1, t * 1.1)
        b = 0.05
    else  -- green
        r, g, b = 0.15, 0.75, 0.20
    end
    pf.health:SetStatusBarColor(r, g, b, 0.88)
    pf.healthBg:SetColorTexture(r * 0.12, g * 0.12, b * 0.12, 1)
    pf.frame:SetBackdropBorderColor(r * 0.28 + 0.08, g * 0.28 + 0.08, b * 0.28 + 0.08, 0.9)

    -- ── Absorb indicator ────────────────────────────────────
    local showAbsorb = db.showAbsorb == true and MOCK_ABSORB[idx]
    pf.absorb:SetShown(showAbsorb == true)
    if showAbsorb then
        pf.absorb:SetWidth(math.max(1, math.floor(frameW * 0.09 + 0.5)))
    end

    -- ── Heal prediction indicator ───────────────────────────
    local showHealPred = db.showHealPrediction == true and MOCK_HEALPRED[idx]
    pf.healPred:SetShown(showHealPred == true)
    if showHealPred then
        pf.healPred:SetWidth(math.max(1, math.floor(frameW * 0.13 + 0.5)))
    end

    -- ── Name ────────────────────────────────────────────────
    local showName = db.showName ~= false
    pf.name:SetShown(showName)
    if showName then
        local fs = math.max(5, math.floor((db.fontSize or 10) * scale + 0.5))
        pf.name:SetFont(FONT, fs, "OUTLINE")
        local name = NAMES[idx] or ("P" .. idx)
        local maxLen = db.nameMaxLength or 0
        if maxLen > 0 and #name > maxLen then
            name = name:sub(1, maxLen)
        end
        pf.name:SetText(name)
    end

    -- ── Health text ─────────────────────────────────────────
    local showHPText = db.showHealthText == true
    pf.healthText:SetShown(showHPText)
    if showHPText then
        local fs = math.max(5, math.floor((db.fontSize or 10) * scale * 0.82 + 0.5))
        pf.healthText:SetFont(FONT, fs, "OUTLINE")
        local fmt = db.healthTextFormat or "percent"
        if fmt == "percent" then
            pf.healthText:SetText(hp .. "%")
        elseif fmt == "current" then
            pf.healthText:SetText(math.floor(hp * 0.82) .. "K")
        elseif fmt == "deficit" then
            if hp < 100 then pf.healthText:SetText("-" .. (100 - hp) .. "%")
            else              pf.healthText:SetText("") end
        else
            pf.healthText:SetText(hp .. "%")
        end
    end

    -- ── Power bar ────────────────────────────────────────────
    local isHealer = (role == "HEALER")
    local showPower = db.showPower and isHealer and scaledPowerH > 0
    pf.power:SetShown(showPower == true)
    if showPower then
        pf.power:ClearAllPoints()
        pf.power:SetPoint("BOTTOMLEFT",  pf.frame, "BOTTOMLEFT",  0, 0)
        pf.power:SetPoint("BOTTOMRIGHT", pf.frame, "BOTTOMRIGHT", 0, 0)
        pf.power:SetHeight(scaledPowerH)
        pf.power:SetMinMaxValues(0, 100)
        pf.power:SetValue(50 + (idx * 13) % 45)
        pf.power:SetStatusBarColor(0.18, 0.48, 1.00, 0.88)
    end

    -- ── Role icon ────────────────────────────────────────────
    local showRole = db.showRoleIcon == true
    pf.roleIcon:SetShown(showRole)
    if showRole then
        local iconSize = math.max(4, math.floor(8 * scale + 0.5))
        pf.roleIcon:SetSize(iconSize, iconSize)
        if role == "TANK" then
            pf.roleIcon:SetColorTexture(0.20, 0.55, 1.00, 0.90)
        elseif role == "HEALER" then
            pf.roleIcon:SetColorTexture(0.20, 0.85, 0.25, 0.90)
        else
            pf.roleIcon:SetColorTexture(0.85, 0.20, 0.20, 0.90)
        end
    end

    -- ── HoT dots ─────────────────────────────────────────────
    local showHoTs = db.showHoTs == true
    local hotSize  = showHoTs and math.max(3, math.floor((db.hotSize or 10) * scale + 0.5)) or 0
    -- Healers get 2 dots, some DPS get 1
    local numHoTs = showHoTs and (isHealer and 2 or (idx % 4 == 0 and 1 or 0)) or 0
    for i = 1, 3 do
        local dot = pf.hotDots[i]
        if i <= numHoTs then
            dot:SetSize(hotSize, hotSize)
            dot:ClearAllPoints()
            dot:SetPoint("BOTTOMLEFT", pf.frame, "BOTTOMLEFT", (i - 1) * (hotSize + 1), -(hotSize + 1))
            local hc = HOT_COLORS[i]
            dot:SetColorTexture(hc[1], hc[2], hc[3], 0.88)
            dot:Show()
        else
            dot:Hide()
        end
    end

    -- ── Dispel border ─────────────────────────────────────────
    local dc = db.showDispel == true and MOCK_DISPEL[idx]
    if dc then
        pf.dispelBorder:SetBackdropBorderColor(dc.r, dc.g, dc.b, 0.90)
    else
        pf.dispelBorder:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

-- ============================================================
-- Strip layout constants
-- ============================================================
local STRIP_H_MIN  = 80
local HEADER_H     = 22   -- height of the "APERÇU EN DIRECT" header row
local CONTENT_TOP  = 30   -- Y offset (negative) from strip top to first row
local SIDE_PAD     = 14   -- left/right padding inside the strip
local BOTTOM_PAD   = 10   -- padding below last row
local LABEL_GAP    = 3    -- gap between group label bottom and member top

-- ============================================================
-- Create the preview strip
-- ============================================================
function RFP.Create(parent)
    local T  = TomoMod_Widgets and TomoMod_Widgets.Theme
    local aR = T and T.accent[1] or 0.047
    local aG = T and T.accent[2] or 0.824
    local aB = T and T.accent[3] or 0.624

    local strip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    strip:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
    strip:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    strip:SetHeight(STRIP_H_MIN)
    strip:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    strip:SetBackdropColor(0.048, 0.048, 0.062, 1)
    strip:SetBackdropBorderColor(aR, aG, aB, 0.16)

    -- "APERÇU EN DIRECT" label
    local header = strip:CreateFontString(nil, "OVERLAY")
    header:SetFont(FONT_BOLD, 9, "OUTLINE")
    header:SetPoint("TOPLEFT", 12, -8)
    header:SetTextColor(aR, aG, aB, 0.55)
    header:SetText(L["preview_header"] or "APERÇU EN DIRECT")

    -- Pulsing live dot
    local dot = strip:CreateTexture(nil, "OVERLAY")
    dot:SetSize(5, 5)
    dot:SetPoint("LEFT", header, "RIGHT", 6, 0)
    dot:SetColorTexture(aR, aG, aB, 1)
    local dotVis = true
    local dotTicker = C_Timer.NewTicker(1.2, function()
        dotVis = not dotVis
        dot:SetAlpha(dotVis and 0.9 or 0.20)
    end)
    strip:SetScript("OnHide", function()
        if dotTicker then dotTicker:Cancel(); dotTicker = nil end
    end)

    -- Separator at the bottom edge
    local sep = strip:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT",  strip, "BOTTOMLEFT",  0, 0)
    sep:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", 0, 0)
    sep:SetColorTexture(aR * 0.55, aG * 0.55, aB * 0.55, 0.25)

    -- Group labels (G1 … G4) — shown in grid mode
    local groupLabels = {}
    for g = 1, NUM_GROUPS do
        local lbl = strip:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_BOLD, 7, "OUTLINE")
        lbl:SetTextColor(aR * 0.7, aG * 0.7, aB * 0.7, 0.55)
        lbl:SetText((L["rf_preview_group"] or "G") .. g)
        groupLabels[g] = lbl
    end

    -- 20 fake member frames
    local members = {}
    for i = 1, MOCK_COUNT do
        members[i] = CreatePreviewMember(strip)
    end

    -- ── Refresh ───────────────────────────────────────────────
    local function Refresh()
        local db = TomoModDB and TomoModDB.raidFrames
        if not db then return end

        -- Wait until the strip has a real width; retry if layout hasn't settled yet
        local availW = strip:GetWidth()
        if availW < 20 then
            C_Timer.After(0.05, Refresh)
            return
        end
        availW = availW - 2 * SIDE_PAD

        local layout       = db.layout      or "grid"
        local spacing      = db.spacing     or 2
        local groupSpacing = db.groupSpacing or 6
        local powerH       = (db.showPower and db.powerHeight or 0)

        -- ── Compute scale ──────────────────────────────────────
        local scale
        if layout == "grid" then
            -- 4 columns of frames + 3 inter-group gaps
            local nominalW = NUM_GROUPS * db.width + (NUM_GROUPS - 1) * groupSpacing
            scale = math.max(0.28, math.min(0.96, availW / nominalW))
        else
            -- List: show as 2 side-by-side columns of 10 (compact)
            local nominalW = 2 * db.width + groupSpacing
            scale = math.max(0.28, math.min(0.96, availW / nominalW))
        end

        local frameW       = math.max(12, math.floor(db.width   * scale + 0.5))
        local frameH       = math.max(6,  math.floor(db.height  * scale + 0.5))
        local sPowerH      = powerH > 0 and math.max(1, math.floor(powerH * scale + 0.5)) or 0
        local sSpacing     = math.max(1, math.floor(spacing      * scale + 0.5))
        local sGrpSpacing  = math.max(2, math.floor(groupSpacing * scale + 0.5))

        -- ── Apply visuals ──────────────────────────────────────
        for i = 1, MOCK_COUNT do
            ApplyMember(members[i], i, db, frameW, frameH, sPowerH, scale)
        end

        -- ── Position members ───────────────────────────────────
        local maxRows
        if layout == "grid" then
            maxRows = GROUP_SIZE
            for g = 1, NUM_GROUPS do
                local colX = SIDE_PAD + (g - 1) * (frameW + sGrpSpacing)
                local firstMember = members[(g - 1) * GROUP_SIZE + 1]
                -- Group label above first member of this column
                groupLabels[g]:ClearAllPoints()
                groupLabels[g]:SetPoint("BOTTOMLEFT", firstMember.frame, "TOPLEFT", 1, LABEL_GAP)
                groupLabels[g]:Show()
                -- Place members
                for row = 1, GROUP_SIZE do
                    local idx = (g - 1) * GROUP_SIZE + row
                    local f = members[idx].frame
                    f:ClearAllPoints()
                    f:SetPoint("TOPLEFT", strip, "TOPLEFT",
                        colX,
                        -(CONTENT_TOP + (row - 1) * (frameH + sSpacing))
                    )
                end
            end
        else
            -- List: 2 columns of 10
            maxRows = 10
            local col2X = SIDE_PAD + frameW + sGrpSpacing
            for g = 1, NUM_GROUPS do
                groupLabels[g]:Hide()
            end
            for i = 1, MOCK_COUNT do
                local colX = (i <= 10) and SIDE_PAD or col2X
                local row  = (i <= 10) and i or (i - 10)
                local f = members[i].frame
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", strip, "TOPLEFT",
                    colX,
                    -(CONTENT_TOP + (row - 1) * (frameH + sSpacing))
                )
            end
        end

        -- ── Resize strip to fit content ────────────────────────
        local contentH = maxRows * frameH + (maxRows - 1) * sSpacing
        local newH = CONTENT_TOP + contentH + BOTTOM_PAD
        if newH < STRIP_H_MIN then newH = STRIP_H_MIN end
        strip:SetHeight(newH)
    end

    strip.Refresh = Refresh
    RFP.Refresh   = Refresh

    RFP.ForceRefresh = function()
        C_Timer.After(0, Refresh)
    end

    strip:SetScript("OnShow", function() C_Timer.After(0, Refresh) end)
    C_Timer.After(0, Refresh)

    return strip
end

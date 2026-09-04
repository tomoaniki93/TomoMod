-- =====================================================================
-- TomoMod Healer Studio -- dedicated LoadOnDemand editor for the
-- configurable Party/Raid healer indicators.
--
-- Window chrome comes from Forge.Studio, every control from the shared
-- widget kit, every string from TomoMod_L. Nothing here reads an aura or
-- touches a live cell: edits land in TomoModDB.healerStudio and are pushed
-- to the frames through HI.Commit.
--
-- The drag surface is local rather than Forge.Canvas: the canvas is driven
-- by ForgeRegistry element descriptors, and healer slots are per-spell
-- rows in a saved table, not registry elements. Folding them into the
-- registry is the AstralForge party/raid job, not this one.
-- =====================================================================

local W = TomoMod_Widgets
if not W then
    TomoMod_HealerStudio = { loadError = "TomoMod_Widgets indisponible" }
    return
end

local Forge = TomoMod_Forge
if not (Forge and Forge.Studio) then
    TomoMod_HealerStudio = { loadError = "TomoMod_Forge incomplet" }
    return
end

local HI = TomoMod_HealerIndicators
if not HI then
    TomoMod_HealerStudio = { loadError = "HealerIndicators indisponible" }
    return
end

local L     = TomoMod_L
local BRAND = Forge.BRAND
local FONT  = Forge.FONT

local floor, max, min = math.floor, math.max, math.min
local ipairs, pairs = ipairs, pairs

local S = { mode = "party", class = nil, selected = nil }
TomoMod_HealerStudio = S

local PANEL_W, PANEL_H = 1120, 760
local SIDE_W  = 272
local STAGE_H = 268
local MIN_SIZE, MAX_SIZE = HI.MIN_SIZE, HI.MAX_SIZE

local frame, sidebarList, inspectorHost
local previewCell, previewHealth, previewPower
local rowButtons   = {}
local previewIcons = {}

local WHITE8 = "Interface\\Buttons\\WHITE8x8"

-- ---------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------
local function Clamp(v, lo, hi) return max(lo, min(hi, v)) end

-- SetText() on a FontString with no font assigned throws "Font not set", and
-- SetFont() returns false rather than erroring when the client refuses the
-- file -- so a bare SetFont is not proof there is a font. Every duration
-- string in the preview goes through this, and it is called at creation,
-- before the first SetText, not only when the size changes.
local function ApplyFont(fs, size)
    if not fs then return end
    size = max(6, size or 9)
    if not fs:SetFont(FONT, size, "OUTLINE") then
        fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    end
end

local function Round(v)
    if v >= 0 then return floor(v + 0.5) end
    return -floor(-v + 0.5)
end

local function CategoryText(category)
    return L["hs_cat_" .. (category or "hot")]
end

local function ClassName(token)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token
end

local function CanEdit()
    -- The studio itself is unprotected, but a layout change asks the aura
    -- engine to build and resize containers, and it refuses both while
    -- auras are restricted. Editing in combat would silently half-apply.
    if InCombatLockdown() then
        print("|cff2e9dd8TomoMod|r : " .. L["hs_combat"])
        return false
    end
    return true
end

-- Structural change: the enabled set moved, the cached active list has to
-- be rebuilt.
local function Commit()
    HI.Commit(S.mode)
end

-- Geometry-only change: the runtime reads size / anchor / offset straight
-- off the same entry table, so only the push to the live frames is needed.
local function Touch()
    HI.Touch(S.mode)
end

local function CellSize()
    local db = TomoModDB and TomoModDB[S.mode == "raid" and "raidFrames" or "partyFrames"]
    db = db or {}
    if S.mode == "raid" then
        return tonumber(db.width) or 72, tonumber(db.height) or 36
    end
    return tonumber(db.width) or 180, tonumber(db.height) or 42
end

-- The preview is a magnified cell: one logical pixel is `scale` screen
-- pixels, and every offset written back to the database is divided by it.
local function PreviewScale()
    local w, h = CellSize()
    return Clamp(min(560 / max(w, 1), 200 / max(h, 1)), 1.5, 5.0)
end

local function Entry()
    if not S.selected then return nil end
    return HI.GetEntry(S.mode, S.class, S.selected)
end

-- ---------------------------------------------------------------------
-- Preview
-- ---------------------------------------------------------------------
local function PlaceIcon(icon, entry)
    if not previewCell or not icon or not entry then return end
    local scale = PreviewScale()
    local size = Clamp(tonumber(entry.size) or 12, MIN_SIZE, MAX_SIZE)
    icon:SetSize(size * scale, size * scale)

    -- The runtime draws the remaining time at a fixed 9pt whatever the icon
    -- size, so the preview scales 9 rather than the icon: at 50px the number
    -- really is that small next to the art, and the point of the preview is
    -- to let that be judged before committing to it.
    if icon.duration then
        local modeDB = HI.GetModeDB(S.mode)
        ApplyFont(icon.duration, 9 * scale)
        icon.duration:SetShown(not (modeDB and modeDB.showDuration == false))
    end
    icon:ClearAllPoints()
    local point = entry.point or "TOPLEFT"
    icon:SetPoint(point, previewCell, point,
        (tonumber(entry.x) or 0) * scale, (tonumber(entry.y) or 0) * scale)
end

-- Nearest 3x3 anchor for a dropped icon, so a corner drop stays pinned to
-- that corner when the cell is resized later.
local function PickAnchor(cx, cy)
    local pcx, pcy = previewCell:GetCenter()
    if not pcx or not pcy then return "CENTER" end
    local w, h = previewCell:GetWidth(), previewCell:GetHeight()

    local horizontal = ""
    if cx < pcx - w / 6 then horizontal = "LEFT"
    elseif cx > pcx + w / 6 then horizontal = "RIGHT" end

    local vertical = ""
    if cy > pcy + h / 6 then vertical = "TOP"
    elseif cy < pcy - h / 6 then vertical = "BOTTOM" end

    local point = vertical .. horizontal
    if point == "" then point = "CENTER" end
    return point
end

-- Screen coordinates of a frame's own anchor corner. GetLeft/GetBottom
-- only -- GetPoint is meaningless after StartMoving/StopMovingOrSizing.
local function AnchorCoords(f, point)
    local left, right   = f:GetLeft(), f:GetRight()
    local bottom, top   = f:GetBottom(), f:GetTop()
    if not left or not right or not bottom or not top then return nil, nil end

    local x
    if point:find("LEFT", 1, true) then x = left
    elseif point:find("RIGHT", 1, true) then x = right
    else x = (left + right) * 0.5 end

    local y
    if point:find("TOP", 1, true) then y = top
    elseif point:find("BOTTOM", 1, true) then y = bottom
    else y = (bottom + top) * 0.5 end
    return x, y
end

local function SaveDrag(icon, spellID)
    local entry = HI.GetEntry(S.mode, S.class, spellID)
    if not entry or not previewCell then return end
    if not CanEdit() then PlaceIcon(icon, entry); return end

    local pLeft, pRight = previewCell:GetLeft(), previewCell:GetRight()
    local pBottom, pTop = previewCell:GetBottom(), previewCell:GetTop()
    local cx, cy = icon:GetCenter()
    if not pLeft or not pRight or not pBottom or not pTop or not cx or not cy then
        PlaceIcon(icon, entry)
        return
    end

    local halfW, halfH = icon:GetWidth() * 0.5, icon:GetHeight() * 0.5
    cx = Clamp(cx, pLeft + halfW, pRight - halfW)
    cy = Clamp(cy, pBottom + halfH, pTop - halfH)

    -- Park the clamped icon at an absolute centre, read its chosen corner,
    -- then translate that back into logical cell coordinates.
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)

    local point = PickAnchor(cx, cy)
    local iconX, iconY = AnchorCoords(icon, point)
    local hostX, hostY = AnchorCoords(previewCell, point)
    local scale = PreviewScale()
    if iconX and hostX then
        entry.point = point
        entry.x = Round((iconX - hostX) / scale)
        entry.y = Round((iconY - hostY) / scale)
    end

    PlaceIcon(icon, entry)
    Touch()
    S.Refresh()
end

local function EnsureIcon(spellID)
    local icon = previewIcons[spellID]
    if icon then return icon end

    icon = CreateFrame("Button", nil, previewCell, "BackdropTemplate")
    icon:SetMovable(true)
    icon:RegisterForDrag("LeftButton")
    icon:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    icon:SetBackdropColor(0, 0, 0, 0)

    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("TOPLEFT", 1, -1)
    icon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- A stand-in value, not a live one: nothing in the studio reads an aura.
    -- The font comes first: EnsureIcon runs before PlaceIcon, so leaving the
    -- sizing call to do it means this SetText lands on a fontless string.
    icon.duration = icon:CreateFontString(nil, "OVERLAY")
    ApplyFont(icon.duration, 9)
    icon.duration:SetPoint("CENTER")
    icon.duration:SetTextColor(1, 1, 1, 1)
    icon.duration:SetText("12")

    icon:SetScript("OnMouseDown", function()
        S.selected = spellID
        S.Refresh()
    end)
    icon:SetScript("OnDragStart", function(self)
        if not CanEdit() then return end
        S.selected = spellID
        self:StartMoving()
    end)
    icon:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveDrag(self, spellID)
    end)

    previewIcons[spellID] = icon
    return icon
end

function S.RefreshPreview()
    if not previewCell then return end

    local logicalW, logicalH = CellSize()
    local scale = PreviewScale()
    previewCell:SetSize(logicalW * scale, logicalH * scale)

    previewHealth:ClearAllPoints()
    previewHealth:SetPoint("TOPLEFT", previewCell, "TOPLEFT", 2, -2)
    previewHealth:SetPoint("BOTTOMRIGHT", previewCell, "BOTTOMRIGHT", -2,
        max(7, logicalH * scale * 0.16))
    previewPower:ClearAllPoints()
    previewPower:SetPoint("LEFT", previewCell, "BOTTOMLEFT", 2, 3)
    previewPower:SetPoint("RIGHT", previewCell, "BOTTOMRIGHT", -2, 3)
    previewPower:SetHeight(Clamp(logicalH * scale * 0.08, 3, 7))

    local classDB = HI.EnsureClass(S.mode, S.class)
    local visible = {}
    if classDB then
        for _, spellID in ipairs(HI.GetSpellsForClass(S.class)) do
            local entry = classDB.spells[spellID]
            if entry and entry.enabled then
                local icon = EnsureIcon(spellID)
                local _, texture = HI.GetSpellDisplay(spellID)
                icon.texture:SetTexture(texture)
                PlaceIcon(icon, entry)
                if spellID == S.selected then
                    icon:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 1)
                else
                    icon:SetBackdropBorderColor(0, 0, 0, 0.85)
                end
                icon:Show()
                visible[spellID] = true
            end
        end
    end
    for spellID, icon in pairs(previewIcons) do
        if not visible[spellID] then icon:Hide() end
    end
end

-- ---------------------------------------------------------------------
-- Sidebar: one row per aura, checkbox toggles it on the cell
-- ---------------------------------------------------------------------
local function EnsureRow(index)
    local b = rowButtons[index]
    if b then return b end

    b = CreateFrame("Button", nil, sidebarList, "BackdropTemplate")
    b:SetHeight(34)
    b:SetBackdrop({ bgFile = WHITE8 })

    b.check = CreateFrame("Button", nil, b, "BackdropTemplate")
    b.check:SetSize(16, 16)
    b.check:SetPoint("LEFT", 8, 0)
    b.check:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    b.check:SetBackdropColor(0.07, 0.08, 0.10, 1)
    b.check.fill = b.check:CreateTexture(nil, "ARTWORK")
    b.check.fill:SetPoint("TOPLEFT", 3, -3)
    b.check.fill:SetPoint("BOTTOMRIGHT", -3, 3)
    b.check.fill:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 1)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(24, 24)
    b.icon:SetPoint("LEFT", b.check, "RIGHT", 8, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.name = b:CreateFontString(nil, "OVERLAY")
    b.name:SetFont(FONT, 11, "")
    b.name:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 8, -1)
    b.name:SetPoint("RIGHT", b, "RIGHT", -6, 0)
    b.name:SetJustifyH("LEFT")
    b.name:SetWordWrap(false)

    b.category = b:CreateFontString(nil, "OVERLAY")
    b.category:SetFont(FONT, 9, "")
    b.category:SetPoint("BOTTOMLEFT", b.icon, "BOTTOMRIGHT", 8, 1)
    b.category:SetTextColor(0.42, 0.44, 0.5, 1)

    b:SetScript("OnClick", function(self)
        if not self.spellID then return end
        S.selected = self.spellID
        S.Refresh()
    end)
    b.check:SetScript("OnClick", function(self)
        local row = self:GetParent()
        if not row.spellID or not CanEdit() then return end
        local entry = HI.GetEntry(S.mode, S.class, row.spellID)
        if not entry then return end
        entry.enabled = not entry.enabled
        S.selected = row.spellID
        Commit()
        S.Refresh()
    end)

    rowButtons[index] = b
    return b
end

function S.RefreshSidebar()
    if not sidebarList then return end
    for _, b in ipairs(rowButtons) do b:Hide() end

    local spells  = HI.GetSpellsForClass(S.class)
    local classDB = HI.EnsureClass(S.mode, S.class)
    local y = -4

    for index, spellID in ipairs(spells) do
        local b = EnsureRow(index)
        local entry = classDB and classDB.spells[spellID]
        local name, texture, category = HI.GetSpellDisplay(spellID)
        local selected = (spellID == S.selected)

        b.spellID = spellID
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 6, y)
        b:SetPoint("TOPRIGHT", -6, y)
        b:SetBackdropColor(BRAND[1], BRAND[2], BRAND[3], selected and 0.22 or 0)
        b.icon:SetTexture(texture)
        b.name:SetText(name)
        b.name:SetTextColor(selected and 1 or 0.72, selected and 1 or 0.74, selected and 1 or 0.78, 1)
        b.category:SetText(CategoryText(category))
        b.check.fill:SetShown((entry and entry.enabled) and true or false)
        if entry and entry.enabled then
            b.check:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 1)
        else
            b.check:SetBackdropBorderColor(0.24, 0.26, 0.30, 1)
        end
        b:Show()
        y = y - 36
    end
end

-- ---------------------------------------------------------------------
-- Inspector
-- ---------------------------------------------------------------------
function S.RefreshInspector()
    if not inspectorHost then return end

    -- WoW frames are not destroyable: the previous panel goes into a hidden
    -- bin, same pattern as AstralForge. The bin must exist BEFORE the
    -- reparent, or the first rebuild reparents to nil.
    if not inspectorHost._bin then
        local bin = CreateFrame("Frame", nil, inspectorHost)
        bin:Hide()
        inspectorHost._bin = bin
    end
    if inspectorHost._scroll then
        inspectorHost._scroll:Hide()
        inspectorHost._scroll:ClearAllPoints()
        inspectorHost._scroll:SetParent(inspectorHost._bin)
    end

    local scroll = W.CreateScrollPanel(inspectorHost)
    inspectorHost._scroll = scroll
    local c = scroll.child
    local y = -10

    local root   = HI.GetRootDB()
    local modeDB = HI.GetModeDB(S.mode)

    local _, ny = W.CreateCheckbox(c, L["hs_enable"], modeDB and modeDB.enabled, y, function(v)
        if not CanEdit() then S.Refresh(); return end
        HI.SetModeEnabled(S.mode, v, S.class)
        S.Refresh()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["hs_healer_only"], root and root.onlyHealerSpec ~= false, y, function(v)
        if not CanEdit() then S.Refresh(); return end
        local r = HI.GetRootDB()
        if r then r.onlyHealerSpec = v and true or false end
        HI.Commit()
        S.Refresh()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["hs_show_duration"],
        modeDB and modeDB.showDuration ~= false, y, function(v)
            if not CanEdit() then S.Refresh(); return end
            local m = HI.GetModeDB(S.mode)
            if m then m.showDuration = v and true or false end
            -- Geometry-only push: the setting lives in the mode table the
            -- runtime already reads by reference, so the cached active list
            -- stays valid and only the frames need telling.
            Touch()
            S.RefreshPreview()
        end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["hs_show_duration_info"], y)
    y = ny

    local _, ny = W.CreateInfoText(c,
        (modeDB and modeDB.enabled) and L["hs_mode_on"] or L["hs_mode_off"], y)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local entry = Entry()
    if not entry then
        local _, ny2 = W.CreateInfoText(c, L["hs_select"], y)
        c:SetHeight(-ny2 + 20)
        return
    end

    local spellID = S.selected
    local name = HI.GetSpellDisplay(spellID)
    local _, ny = W.CreateSubLabel(c, name, y)
    y = ny

    local _, ny = W.CreateSlider(c, L["hs_size"], entry.size or 12, MIN_SIZE, MAX_SIZE, 1, y,
        function(v)
            if not CanEdit() then return end
            local e = Entry(); if not e then return end
            e.size = Clamp(v, MIN_SIZE, MAX_SIZE)
            Touch()
            S.RefreshPreview()
        end, "%.0f")
    y = ny

    local anchorOptions = {}
    for _, point in ipairs(HI.ANCHOR_POINTS) do
        anchorOptions[#anchorOptions + 1] = { value = point, text = point }
    end
    local _, ny = W.CreateDropdown(c, L["hs_anchor"], anchorOptions, entry.point or "TOPLEFT", y,
        function(v)
            if not CanEdit() then return end
            local e = Entry(); if not e then return end
            e.point = v
            Touch()
            S.RefreshPreview()
        end)
    y = ny

    -- Offsets are logical cell pixels, so the useful range is the cell
    -- itself; anything wider just pushes the icon off the frame.
    local cw, ch = CellSize()
    local _, ny = W.CreateSlider(c, L["hs_offset_x"], entry.x or 0, -Round(cw), Round(cw), 1, y,
        function(v)
            if not CanEdit() then return end
            local e = Entry(); if not e then return end
            e.x = Round(v)
            Touch()
            S.RefreshPreview()
        end, "%.0f")
    y = ny

    local _, ny = W.CreateSlider(c, L["hs_offset_y"], entry.y or 0, -Round(ch), Round(ch), 1, y,
        function(v)
            if not CanEdit() then return end
            local e = Entry(); if not e then return end
            e.y = Round(v)
            Touch()
            S.RefreshPreview()
        end, "%.0f")
    y = ny

    local _, ny = W.CreateButton(c, L["hs_reset_position"], 200, y, function()
        if not CanEdit() then return end
        HI.ResetSpellPosition(S.mode, S.class, spellID)
        Commit()
        S.Refresh()
    end)
    y = ny

    c:SetHeight(-y + 20)
end

-- ---------------------------------------------------------------------
-- Refresh
-- ---------------------------------------------------------------------
function S.Refresh()
    if not frame then return end
    HI.EnsureClass(S.mode, S.class)

    local spells = HI.GetSpellsForClass(S.class)
    if S.selected and not HI.GetEntry(S.mode, S.class, S.selected) then
        S.selected = nil
    end
    if not S.selected then S.selected = spells[1] end

    S.RefreshSidebar()
    S.RefreshPreview()
    S.RefreshInspector()
end

local function SetMode(mode)
    S.mode = (mode == "raid") and "raid" or "party"
    S.Refresh()
end

local function SetClass(class)
    if not HI.IsHealerClass(class) then return end
    S.class = class
    S.selected = nil
    S.Refresh()
end

-- ---------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------
local function BuildWindow()
    local shell = Forge.Studio.CreateShell({
        name         = "TomoModHealerStudioFrame",
        title        = "|cff2e9dd8Healer|r Studio",
        width        = PANEL_W,
        height       = PANEL_H,
        sideWidth    = SIDE_W,
        crudHeight   = 96,
        accent       = BRAND,
        sidebarTitle = L["hs_list"],
        selector = {
            label   = L["hs_mode"],
            options = {
                { value = "party", text = L["hs_mode_party"] },
                { value = "raid",  text = L["hs_mode_raid"] },
            },
            get = function() return S.mode end,
            set = SetMode,
        },
        footerButtons = {
            { text = L["hs_preset"], width = 190, callback = function()
                if not CanEdit() then return end
                HI.ApplyStarterPreset(S.mode, S.class)
                Commit()
                S.Refresh()
            end },
            { text = L["hs_reset_class"], width = 190, callback = function()
                if not CanEdit() then return end
                HI.ResetClass(S.mode, S.class, false)
                Commit()
                S.Refresh()
            end },
        },
        hint = L["hs_hint"],
    })

    frame       = shell.frame
    sidebarList = shell.sidebarList
    local contentHost = shell.contentHost

    local classOptions = {}
    for _, token in ipairs(HI.CLASS_ORDER) do
        classOptions[#classOptions + 1] = { value = token, text = ClassName(token) }
    end
    W.CreateDropdown(shell.crudHost, L["hs_class"], classOptions, S.class, -6, SetClass)

    local stageHost = CreateFrame("Frame", nil, contentHost, "BackdropTemplate")
    stageHost:SetPoint("TOPLEFT", 12, -12)
    stageHost:SetPoint("TOPRIGHT", -12, -12)
    stageHost:SetHeight(STAGE_H)
    stageHost:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    stageHost:SetBackdropColor(0.02, 0.03, 0.04, 1)
    stageHost:SetBackdropBorderColor(0.14, 0.15, 0.19, 1)

    previewCell = CreateFrame("Frame", nil, stageHost, "BackdropTemplate")
    previewCell:SetPoint("CENTER")
    previewCell:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    previewCell:SetBackdropColor(0.08, 0.095, 0.105, 1)
    previewCell:SetBackdropBorderColor(0.42, 0.48, 0.52, 1)

    previewHealth = previewCell:CreateTexture(nil, "BACKGROUND")
    previewHealth:SetColorTexture(0.12, 0.40, 0.24, 1)
    previewPower = previewCell:CreateTexture(nil, "BACKGROUND")
    previewPower:SetColorTexture(0.12, 0.32, 0.55, 1)
    local previewName = previewCell:CreateFontString(nil, "ARTWORK")
    previewName:SetFont(FONT, 11, "")
    previewName:SetPoint("CENTER", 0, 2)
    previewName:SetText(UnitName("player") or "TomoAniki")

    inspectorHost = CreateFrame("Frame", nil, contentHost)
    inspectorHost:SetPoint("TOPLEFT", stageHost, "BOTTOMLEFT", 0, -10)
    inspectorHost:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -12, 10)

    frame:SetScript("OnShow", function() S.Refresh() end)
end

function S.Open(mode)
    if InCombatLockdown() then
        print("|cff2e9dd8TomoMod|r : " .. L["hs_combat"])
        return
    end

    local playerClass = HI.GetPlayerClass()
    if not S.class then
        S.class = HI.IsHealerClass(playerClass) and playerClass or HI.CLASS_ORDER[1]
    end
    S.mode = (mode == "raid") and "raid" or "party"

    if not frame then BuildWindow() end
    S.Refresh()
    frame:Show()
    frame:Raise()
end

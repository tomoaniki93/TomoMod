-- [Compat] WoW: Forever has no Mythic+ content. The frames below register
-- CHALLENGE_MODE_* events this client does not define, which throws on
-- the first RegisterEvent and again on every retry.
-- See Core/Compat.lua.
if TomoMod_Compat and TomoMod_Compat.Blocked("mythicplus") then return end

-- =====================================================================
-- MythicKeys.lua  Party Key Viewer + Roulette
-- Keystone data comes from KeySync.lua, TomoMod's own sharing module.
-- /tmt key -> list party keystones in group chat
-- /tm key  -> keystone roulette UI (legacy shortcut)
-- /tmt kr  -> keystone roulette UI
-- =====================================================================

local L = TomoMod_L
-- Keystone data now comes from TomoMod's own sync module (KeySync.lua),
-- which exposes the same four functions this file already used.
local openRaidLib = TomoMod_KeySync

local PREFIX = "|cff2e9dd8Tomo|r|cFF3377CCMod|r"

-- Keep a namespaced global + local alias for backward compatibility (/tm key)
TomoMod_MythicKeys = TomoMod_MythicKeys or {}
local MK = TomoMod_MythicKeys
MK.enabled = false
MK.keyData = {}

-- Also expose as TomoMod_MythicPartyKeys for the MythicTracker /tmt integration
TomoMod_MythicPartyKeys = MK

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

local function GetSettings()
    if not TomoModDB or not TomoModDB.MythicKeys then return nil end
    return TomoModDB.MythicKeys
end

local function GetKeyColor(level)
    if not level or level == 0 then return 0.7, 0.7, 0.7 end
    if level >= 12 then return 1.0, 0.5, 0.0 end
    if level >= 10 then return 0.64, 0.21, 0.93 end
    if level >= 7  then return 0.0, 0.44, 0.87 end
    if level >= 5  then return 0.12, 0.75, 0.26 end
    return 1, 1, 1
end

local function GetDungeonIcon(mapID)
    local _, _, _, icon = C_ChallengeMode.GetMapUIInfo(mapID)
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetDungeonShortName(mapID)
    if TomoMod_DataKeys then return TomoMod_DataKeys.GetShortName(mapID) end
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    return name and name:sub(1, 4):upper() or "???"
end

local function GetDungeonFullName(mapID)
    if TomoMod_DataKeys then return TomoMod_DataKeys.GetDungeonName(mapID) end
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    return name or "???"
end

---------------------------------------------------------------------------
-- COLLECT PARTY KEYSTONES
---------------------------------------------------------------------------

local function CollectPartyKeystones()
    if not openRaidLib then return {} end

    local results = {}
    local allKeys = openRaidLib.GetAllKeystonesInfo()

    -- Player first
    local myInfo = openRaidLib.GetKeystoneInfo("player")
    local myName = UnitName("player")
    if myInfo and myInfo.level and myInfo.level > 0 then
        local _, class = UnitClass("player")
        results[#results + 1] = {
            name  = myName,
            class = class,
            unit  = "player",
            level = myInfo.level,
            mapID = myInfo.challengeMapID or myInfo.mythicPlusMapID,
        }
    end

    -- Party members
    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers - 1 do
        local unit = "party" .. i
        local uName, realm = UnitName(unit)
        if uName then
            local fullName = uName
            if realm and realm ~= "" then
                fullName = uName .. "-" .. realm
            end
            local info = allKeys[fullName] or allKeys[uName]
            if info and info.level and info.level > 0 then
                -- [12.1] nil here simply means the row draws without a
                -- class colour; every consumer already guards on it.
                local class = TomoMod_Utils and TomoMod_Utils.UnitClassToken(unit)
                results[#results + 1] = {
                    name  = uName,
                    class = class,
                    unit  = unit,
                    level = info.level,
                    mapID = info.challengeMapID or info.mythicPlusMapID,
                }
            end
        end
    end
    return results
end

local function RequestKeystones()
    if openRaidLib then
        openRaidLib.RequestKeystoneDataFromParty()
    end
end

---------------------------------------------------------------------------
-- SEND PARTY KEYS TO CHAT  (/tmt key)
---------------------------------------------------------------------------

function MK:SendKeysToChat()
    if not openRaidLib then
        print(PREFIX .. ": " .. (L["tmt_key_not_available"] or "keystone sync not available"))
        return
    end

    if not IsInGroup() then
        print(PREFIX .. ": " .. (L["tmt_key_not_in_group"] or "Not in a group"))
        return
    end

    local keys = CollectPartyKeystones()
    if #keys == 0 then
        print(PREFIX .. ": " .. (L["tmt_key_none_found"] or "No keys found"))
        return
    end

    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"

    SendChatMessage("-- TomoMod - Party Keys --", channel)
    for _, k in ipairs(keys) do
        local dungeonName = GetDungeonFullName(k.mapID)
        local short = GetDungeonShortName(k.mapID)
        local msg = string.format("  %s : +%d %s (%s)", k.name, k.level, dungeonName, short)
        SendChatMessage(msg, channel)
    end
    SendChatMessage("---------------------------", channel)
end

---------------------------------------------------------------------------
-- KEYSTONE ROULETTE UI
---------------------------------------------------------------------------

local RouletteFrame
local rouletteEntries = {}
local rouletteKeys    = {}
local ROULETTE_W      = 372
local ROW_H           = 46
local ROW_GAP         = 3
local HEADER_H        = 54
local FOOTER_H        = 86
local SPIN_STEPS      = 20
local SPIN_INTERVAL   = 0.08

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ROULETTE_TEXT = {
    title      = L["key_roulette_title"],
    subtitle   = L["key_roulette_subtitle"],
    spin       = L["key_roulette_spin"],
    ready      = L["key_roulette_ready"],
    refreshing = L["key_roulette_refreshing"],
    empty      = L["key_roulette_empty"],
}

-- MythicKeys loads before MythicTracker in QOL.xml. Resolve the palette when
-- the frame is actually opened, not while this file is parsed; otherwise the
-- old hard-coded green fallback permanently wins for the whole session.
local function GetRoulettePalette()
    if TomoMod_MythicTracker and TomoMod_MythicTracker.BuildPalette then
        local ok, palette = pcall(TomoMod_MythicTracker.BuildPalette, TomoMod_MythicTracker)
        if ok and type(palette) == "table" and palette.ACCENT then
            return palette
        end
    end

    local U  = TomoMod_Utils
    local TH = TomoMod_Widgets and TomoMod_Widgets.Theme
    local brand = (U and U.BRAND) or { 0.180, 0.616, 0.847 }
    local border = (TH and TH.border) or { 0.18, 0.18, 0.22 }
    local text = (TH and TH.text) or { 0.90, 0.92, 0.94 }
    local dim = (TH and TH.textDim) or { 0.48, 0.50, 0.55 }
    return {
        BG         = { 0.025, 0.035, 0.045, 0.97 },
        BG_HEADER  = { 0.040, 0.070, 0.085, 1.00 },
        BG_ROW_ALT = { 0.045, 0.060, 0.075, 0.78 },
        ACCENT     = { brand[1], brand[2], brand[3], 1.00 },
        BORDER     = { border[1], border[2], border[3], 0.95 },
        TEXT_WHITE = { text[1], text[2], text[3], 1.00 },
        TEXT_GREY  = { dim[1], dim[2], dim[3], 1.00 },
    }
end

local function MakeFS(parent, size, bold)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(bold and FONT_BOLD or FONT, size or 11, "OUTLINE")
    fs:SetShadowColor(0, 0, 0, 0.85)
    fs:SetShadowOffset(1, -1)
    return fs
end

local function SetBackdrop(frame, bg, border)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function SetRowSelected(row, selected)
    if not row then return end
    local C = GetRoulettePalette()
    row.highlight:SetAlpha(selected and 0.18 or 0)
    if selected then
        row:SetBackdropBorderColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.95)
    else
        row:SetBackdropBorderColor(C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.55)
    end
end

-- Build the roulette frame (once)
local function EnsureRouletteFrame()
    if RouletteFrame then return end

    local C = GetRoulettePalette()
    local F = CreateFrame("Frame", "TomoMod_KeyRoulette", UIParent, "BackdropTemplate")
    RouletteFrame = F
    F:SetSize(ROULETTE_W, HEADER_H + FOOTER_H + ROW_H)
    F:SetPoint("CENTER")
    F:SetFrameStrata("DIALOG")
    F:SetFrameLevel(300)
    F:SetMovable(true)
    F:EnableMouse(true)
    F:RegisterForDrag("LeftButton")
    F:SetClampedToScreen(true)
    F:SetScript("OnDragStart", function(self) self:StartMoving() end)
    F:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    SetBackdrop(F, C.BG, C.BORDER)

    -- Thin brand line instead of the old green strip.
    F.accent = F:CreateTexture(nil, "ARTWORK")
    F.accent:SetHeight(2)
    F.accent:SetPoint("TOPLEFT", F, "TOPLEFT", 1, -1)
    F.accent:SetPoint("TOPRIGHT", F, "TOPRIGHT", -1, -1)
    F.accent:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)

    F.header = CreateFrame("Frame", nil, F)
    F.header:SetPoint("TOPLEFT", F, "TOPLEFT", 1, -3)
    F.header:SetPoint("TOPRIGHT", F, "TOPRIGHT", -1, -3)
    F.header:SetHeight(HEADER_H - 3)
    F.header.bg = F.header:CreateTexture(nil, "BACKGROUND")
    F.header.bg:SetAllPoints()
    F.header.bg:SetColorTexture(C.BG_HEADER[1], C.BG_HEADER[2], C.BG_HEADER[3], C.BG_HEADER[4] or 1)

    F.title = MakeFS(F.header, 13, true)
    F.title:SetPoint("TOPLEFT", F.header, "TOPLEFT", 12, -9)
    F.title:SetText(ROULETTE_TEXT.title)
    F.title:SetTextColor(C.TEXT_WHITE[1], C.TEXT_WHITE[2], C.TEXT_WHITE[3], 1)

    F.subtitle = MakeFS(F.header, 9, false)
    F.subtitle:SetPoint("TOPLEFT", F.title, "BOTTOMLEFT", 0, -2)
    F.subtitle:SetText(ROULETTE_TEXT.subtitle)
    F.subtitle:SetTextColor(C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3], 1)

    local closeBtn = CreateFrame("Button", nil, F.header, "BackdropTemplate")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", F.header, "TOPRIGHT", -8, -8)
    SetBackdrop(closeBtn, { 0.055, 0.065, 0.080, 0.95 }, { C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.65 })
    closeBtn.text = MakeFS(closeBtn, 12, true)
    closeBtn.text:SetPoint("CENTER", 0, 0)
    closeBtn.text:SetText("X")
    closeBtn.text:SetTextColor(C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3], 1)
    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.85)
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.65)
        self.text:SetTextColor(C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3], 1)
    end)
    closeBtn:SetScript("OnClick", function() F:Hide() end)

    F.rows = CreateFrame("Frame", nil, F)
    F.rows:SetPoint("TOPLEFT", F, "TOPLEFT", 8, -HEADER_H - 5)
    F.rows:SetPoint("TOPRIGHT", F, "TOPRIGHT", -8, -HEADER_H - 5)

    F.footer = CreateFrame("Frame", nil, F)
    F.footer:SetSize(ROULETTE_W - 16, FOOTER_H)

    F.resultBox = CreateFrame("Frame", nil, F.footer, "BackdropTemplate")
    F.resultBox:SetPoint("TOPLEFT", F.footer, "TOPLEFT", 0, -5)
    F.resultBox:SetPoint("TOPRIGHT", F.footer, "TOPRIGHT", 0, -5)
    F.resultBox:SetHeight(29)
    SetBackdrop(F.resultBox, { 0.035, 0.050, 0.060, 0.96 }, { C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.55 })

    F.resultFS = MakeFS(F.resultBox, 10, true)
    F.resultFS:SetPoint("CENTER", F.resultBox, "CENTER", 0, 0)
    F.resultFS:SetWidth(ROULETTE_W - 38)
    F.resultFS:SetJustifyH("CENTER")
    F.resultFS:SetText(ROULETTE_TEXT.ready)
    F.resultFS:SetTextColor(C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3], 1)

    F.spinBtn = CreateFrame("Button", nil, F.footer, "BackdropTemplate")
    F.spinBtn:SetPoint("BOTTOMLEFT", F.footer, "BOTTOMLEFT", 0, 7)
    F.spinBtn:SetPoint("BOTTOMRIGHT", F.footer, "BOTTOMRIGHT", 0, 7)
    F.spinBtn:SetHeight(32)
    SetBackdrop(F.spinBtn, C.ACCENT, { C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1 })

    F.spinBtn.text = MakeFS(F.spinBtn, 11, true)
    F.spinBtn.text:SetPoint("CENTER")
    F.spinBtn.text:SetText(ROULETTE_TEXT.spin)
    F.spinBtn.text:SetTextColor(0.98, 0.99, 1.00, 1)

    F.spinBtn:SetScript("OnEnter", function(self)
        if not self:IsEnabled() then return end
        local r = math.min(1, C.ACCENT[1] * 1.18 + 0.08)
        local g = math.min(1, C.ACCENT[2] * 1.18 + 0.08)
        local b = math.min(1, C.ACCENT[3] * 1.18 + 0.08)
        self:SetBackdropColor(r, g, b, 1)
    end)
    F.spinBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], C.ACCENT[4] or 1)
    end)

    F:Hide()
end

-- Create / reuse a roulette row
local function GetRouletteRow(index)
    if rouletteEntries[index] then return rouletteEntries[index] end

    local C = GetRoulettePalette()
    local parent = RouletteFrame.rows
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * (ROW_H + ROW_GAP))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(index - 1) * (ROW_H + ROW_GAP))

    local rowBG = index % 2 == 0 and C.BG_ROW_ALT or { 0.030, 0.042, 0.052, 0.80 }
    SetBackdrop(row, rowBG, { C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.55 })

    row.highlight = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.highlight:SetPoint("TOPLEFT", 1, -1)
    row.highlight:SetPoint("BOTTOMRIGHT", -1, 1)
    row.highlight:SetColorTexture(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
    row.highlight:SetAlpha(0)

    row.iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.iconFrame:SetSize(34, 34)
    row.iconFrame:SetPoint("LEFT", row, "LEFT", 6, 0)
    SetBackdrop(row.iconFrame, { 0, 0, 0, 0.70 }, { C.BORDER[1], C.BORDER[2], C.BORDER[3], 0.80 })

    row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", 2, -2)
    row.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.dungeonFS = MakeFS(row, 11, true)
    row.dungeonFS:SetPoint("TOPLEFT", row.iconFrame, "TOPRIGHT", 8, -4)
    row.dungeonFS:SetWidth(265)
    row.dungeonFS:SetHeight(16)
    row.dungeonFS:SetJustifyH("LEFT")
    row.dungeonFS:SetTextColor(C.TEXT_WHITE[1], C.TEXT_WHITE[2], C.TEXT_WHITE[3], 1)

    row.nameFS = MakeFS(row, 9, false)
    row.nameFS:SetPoint("BOTTOMLEFT", row.iconFrame, "BOTTOMRIGHT", 8, 4)
    row.nameFS:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    row.nameFS:SetHeight(14)
    row.nameFS:SetJustifyH("LEFT")

    row.levelFS = MakeFS(row, 12, true)
    row.levelFS:SetPoint("RIGHT", row, "RIGHT", -9, 0)
    row.levelFS:SetJustifyH("RIGHT")

    rouletteEntries[index] = row
    return row
end

-- Populate the roulette with current party keys
local function PopulateRoulette()
    local keys = CollectPartyKeystones()
    rouletteKeys = keys
    EnsureRouletteFrame()

    local C = GetRoulettePalette()
    for _, row in ipairs(rouletteEntries) do
        row:Hide()
        SetRowSelected(row, false)
    end

    if #keys == 0 then
        local rowsH = ROW_H
        RouletteFrame:SetHeight(HEADER_H + rowsH + FOOTER_H + 13)
        RouletteFrame.rows:SetHeight(rowsH)
        local row = GetRouletteRow(1)
        row.iconFrame:Hide()
        row.dungeonFS:ClearAllPoints()
        row.dungeonFS:SetPoint("CENTER", row, "CENTER", 0, 0)
        row.dungeonFS:SetWidth(ROULETTE_W - 44)
        row.dungeonFS:SetJustifyH("CENTER")
        row.dungeonFS:SetText(ROULETTE_TEXT.empty)
        row.dungeonFS:SetTextColor(C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3], 1)
        row.nameFS:Hide()
        row.levelFS:Hide()
        row:Show()

        RouletteFrame.footer:ClearAllPoints()
        RouletteFrame.footer:SetPoint("TOPLEFT", RouletteFrame.rows, "BOTTOMLEFT", 0, -4)
        RouletteFrame.spinBtn:Disable()
        RouletteFrame.spinBtn:SetAlpha(0.42)
        RouletteFrame.resultFS:SetText(ROULETTE_TEXT.empty)
        RouletteFrame.resultFS:SetTextColor(C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3], 1)
        RouletteFrame:Show()
        return
    end

    local rowsH = #keys * ROW_H + math.max(0, #keys - 1) * ROW_GAP
    RouletteFrame:SetHeight(HEADER_H + rowsH + FOOTER_H + 13)
    RouletteFrame.rows:SetHeight(rowsH)

    for i, k in ipairs(keys) do
        local row = GetRouletteRow(i)
        local icon = GetDungeonIcon(k.mapID)
        local dungeonName = GetDungeonFullName(k.mapID)
        local short = GetDungeonShortName(k.mapID)
        local kr, kg, kb = GetKeyColor(k.level)
        local classColor = k.class and RAID_CLASS_COLORS[k.class]
        local colorStr = classColor and classColor.colorStr or "FFFFFFFF"

        row.iconFrame:Show()
        row.icon:SetTexture(icon)
        row.dungeonFS:ClearAllPoints()
        row.dungeonFS:SetPoint("TOPLEFT", row.iconFrame, "TOPRIGHT", 8, -4)
        row.dungeonFS:SetWidth(265)
        row.dungeonFS:SetJustifyH("LEFT")
        row.dungeonFS:SetText(dungeonName)
        row.dungeonFS:SetTextColor(C.TEXT_WHITE[1], C.TEXT_WHITE[2], C.TEXT_WHITE[3], 1)
        row.nameFS:Show()
        row.nameFS:SetText("|c" .. colorStr .. k.name .. "|r  |cff7c8794" .. short .. "|r")
        row.levelFS:Show()
        row.levelFS:SetText("+" .. k.level)
        row.levelFS:SetTextColor(kr, kg, kb, 1)
        SetRowSelected(row, false)
        row:Show()
    end

    RouletteFrame.footer:ClearAllPoints()
    RouletteFrame.footer:SetPoint("TOPLEFT", RouletteFrame.rows, "BOTTOMLEFT", 0, -4)
    RouletteFrame.spinBtn:Enable()
    RouletteFrame.spinBtn:SetAlpha(1)
    RouletteFrame.spinBtn.text:SetText(ROULETTE_TEXT.spin)
    RouletteFrame.resultFS:SetText(ROULETTE_TEXT.ready)
    RouletteFrame.resultFS:SetTextColor(C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3], 1)
    RouletteFrame:Show()
end

---------------------------------------------------------------------------
-- SPIN ANIMATION
---------------------------------------------------------------------------

local spinning = false

local function ClearHighlights()
    for _, row in ipairs(rouletteEntries) do
        SetRowSelected(row, false)
    end
end

local function HighlightRow(index)
    ClearHighlights()
    SetRowSelected(rouletteEntries[index], true)
end

local function DoSpin()
    if spinning or #rouletteKeys == 0 then return end
    spinning = true

    local C = GetRoulettePalette()
    RouletteFrame.spinBtn:Disable()
    RouletteFrame.spinBtn:SetAlpha(0.45)
    RouletteFrame.resultFS:SetText("")

    local winnerIdx = math.random(1, #rouletteKeys)
    local totalCycles = 3
    local totalSteps = totalCycles * #rouletteKeys + (winnerIdx - 1)
    if totalSteps < SPIN_STEPS then totalSteps = SPIN_STEPS end

    local step = 0
    local baseInterval = SPIN_INTERVAL

    local function Tick()
        step = step + 1
        local current = ((step - 1) % #rouletteKeys) + 1
        HighlightRow(current)

        if step >= totalSteps then
            spinning = false
            RouletteFrame.spinBtn:Enable()
            RouletteFrame.spinBtn:SetAlpha(1)

            local w = rouletteKeys[winnerIdx]
            local dungeonName = GetDungeonFullName(w.mapID)
            local kr, kg, kb = GetKeyColor(w.level)
            RouletteFrame.resultFS:SetText(
                string.format("|cff%02x%02x%02x%s +%d|r  -  %s",
                    math.floor(kr * 255 + 0.5),
                    math.floor(kg * 255 + 0.5),
                    math.floor(kb * 255 + 0.5),
                    dungeonName, w.level, w.name)
            )
            RouletteFrame.resultFS:SetTextColor(C.TEXT_WHITE[1], C.TEXT_WHITE[2], C.TEXT_WHITE[3], 1)

            if IsInGroup() then
                local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
                local msg = string.format("[TomoMod Roulette] >> %s +%d (%s) <<",
                    dungeonName, w.level, w.name)
                SendChatMessage(msg, channel)
            end
            return
        end

        local remaining = totalSteps - step
        local delay = baseInterval
        if remaining < 8 then
            delay = baseInterval + (8 - remaining) * 0.04
        end
        C_Timer.After(delay, Tick)
    end

    C_Timer.After(baseInterval, Tick)
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------

function MK:Enable()
    self.enabled = true
end

function MK:Toggle()
    -- /tm key now opens the roulette UI
    self:ShowKeyRoulette()
end

function MK:ShowKeyRoulette()
    if not openRaidLib then
        print(PREFIX .. ": " .. (L["tmt_key_not_available"] or "keystone sync not available"))
        return
    end

    EnsureRouletteFrame()
    local C = GetRoulettePalette()
    RouletteFrame.resultFS:SetText(ROULETTE_TEXT.refreshing)
    RouletteFrame.resultFS:SetTextColor(C.TEXT_GREY[1], C.TEXT_GREY[2], C.TEXT_GREY[3], 1)
    RouletteFrame:Show()

    RequestKeystones()

    -- Small delay to let data arrive, then populate. The frame opens at once so
    -- the click never looks lost while KeySync waits for party responses.
    C_Timer.After(1.5, function()
        PopulateRoulette()
        RouletteFrame.spinBtn:SetScript("OnClick", function() DoSpin() end)
    end)
end

---------------------------------------------------------------------------
-- EVENTS  request keystones from party on join/roster change
---------------------------------------------------------------------------

local pkEvents = CreateFrame("Frame")
pkEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
pkEvents:RegisterEvent("GROUP_ROSTER_UPDATE")
pkEvents:RegisterEvent("GROUP_JOINED")
pkEvents:SetScript("OnEvent", function(_, event)
    if not openRaidLib then return end
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, RequestKeystones)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "GROUP_JOINED" then
        C_Timer.After(2, RequestKeystones)
    end
end)

-- Update roulette live when new keystone data arrives
if openRaidLib then
    openRaidLib.RegisterCallback("TomoMod_MythicKeys", "KeystoneUpdate", function()
        if RouletteFrame and RouletteFrame:IsShown() and not spinning then
            C_Timer.After(0.5, PopulateRoulette)
        end
    end)
end

---------------------------------------------------------------------------
-- Module registration (backward compat)
---------------------------------------------------------------------------

TomoMod_RegisterModule("MythicKeys", MK)

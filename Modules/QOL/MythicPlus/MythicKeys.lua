-- =====================================================================
-- MythicKeys.lua  Party Key Viewer + Roulette (LibOpenRaid)
-- Replaces the old multi-protocol key viewer with LibOpenRaid.
-- /tm key  -> list party keystones in group chat
-- /tmt kr  -> keystone roulette UI with random pick
-- =====================================================================

local L = TomoMod_L
local openRaidLib = LibStub and LibStub:GetLibrary("LibOpenRaid-1.0", true)

local PREFIX = "|cff0cd29fTomo|r|cFF3377CCMod|r"

-- Keep the MK global for backward compatibility (/tm key)
MK = MK or {}
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
-- COLLECT PARTY KEYSTONES (LibOpenRaid)
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
                local _, class = UnitClass(unit)
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
-- SEND PARTY KEYS TO CHAT  (/tm key  or  /tmt key)
---------------------------------------------------------------------------

function MK:SendKeysToChat()
    if not openRaidLib then
        print(PREFIX .. ": LibOpenRaid " .. (L["tmt_key_not_available"] or "not available"))
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
local ROULETTE_W      = 280
local ROW_H           = 30
local HEADER_H        = 36
local FOOTER_H        = 62
local SPIN_STEPS      = 20
local SPIN_INTERVAL   = 0.08

local C_TMT = TomoMod_MythicTracker and TomoMod_MythicTracker.C or {
    BG_HEADER   = { 0.04, 0.08, 0.16, 1.00 },
    ACCENT      = { 0.33, 0.70, 0.00, 1.00 },
    BORDER      = { 0.25, 0.25, 0.30, 0.70 },
    BG_ROW_ALT  = { 0.05, 0.09, 0.16, 0.50 },
}

local function MakeFS(parent, size, flags, anchor, relTo, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or 12, flags or "OUTLINE")
    fs:SetShadowColor(0, 0, 0, 0.9)
    fs:SetShadowOffset(1, -1)
    if anchor then
        fs:SetPoint(anchor, relTo or parent, anchor, x or 0, y or 0)
    end
    return fs
end

-- Build the roulette frame (once)
local function EnsureRouletteFrame()
    if RouletteFrame then return end

    local C = C_TMT

    local F = CreateFrame("Frame", "TomoMod_KeyRoulette", UIParent, "BackdropTemplate")
    RouletteFrame = F
    F:SetSize(ROULETTE_W, HEADER_H + FOOTER_H + 20)
    F:SetPoint("CENTER")
    F:SetFrameStrata("DIALOG")
    F:SetFrameLevel(300)
    F:SetMovable(true)
    F:EnableMouse(true)
    F:RegisterForDrag("LeftButton")
    F:SetClampedToScreen(true)
    F:SetScript("OnDragStart", function(s) s:StartMoving() end)
    F:SetScript("OnDragStop",  function(s) s:StopMovingOrSizing() end)

    F:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    F:SetBackdropColor(0, 0, 0, 0.92)
    F:SetBackdropBorderColor(unpack(C.BORDER))

    -- Left accent
    local accent = F:CreateTexture(nil, "ARTWORK")
    accent:SetWidth(3)
    accent:SetPoint("TOPLEFT",    F, "TOPLEFT",    0, 0)
    accent:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 0, 0)
    accent:SetColorTexture(unpack(C.ACCENT))

    -- Header
    local hdrBG = F:CreateTexture(nil, "BACKGROUND")
    hdrBG:SetSize(ROULETTE_W, HEADER_H)
    hdrBG:SetPoint("TOPLEFT")
    hdrBG:SetColorTexture(unpack(C.BG_HEADER))

    F.title = MakeFS(F, 13, "OUTLINE")
    F.title:SetPoint("LEFT", F, "TOPLEFT", 10, -HEADER_H / 2)
    F.title:SetText("|cff0cd29fTomo|r|cFF3377CCMod|r  |cFFAAAAAAKeystone Roulette|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, F)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", F, "TOPRIGHT", -4, -7)
    local closeX = MakeFS(closeBtn, 13, "OUTLINE")
    closeX:SetPoint("CENTER")
    closeX:SetText("|cFFCC3322X|r")
    closeBtn:SetScript("OnClick", function() F:Hide() end)

    -- Rows container
    F.rows = CreateFrame("Frame", nil, F)
    F.rows:SetPoint("TOPLEFT", F, "TOPLEFT", 0, -HEADER_H)
    F.rows:SetPoint("TOPRIGHT", F, "TOPRIGHT", 0, -HEADER_H)

    -- Footer (spin button + result)
    F.footer = CreateFrame("Frame", nil, F)
    F.footer:SetSize(ROULETTE_W, FOOTER_H)

    -- Spin button
    F.spinBtn = CreateFrame("Button", nil, F.footer, "BackdropTemplate")
    F.spinBtn:SetSize(120, 28)
    F.spinBtn:SetPoint("TOP", F.footer, "TOP", 0, -8)
    F.spinBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    F.spinBtn:SetBackdropColor(unpack(C.ACCENT))
    F.spinBtn:SetBackdropBorderColor(unpack(C.BORDER))

    F.spinBtn.text = MakeFS(F.spinBtn, 12, "OUTLINE")
    F.spinBtn.text:SetPoint("CENTER")
    F.spinBtn.text:SetTextColor(1, 1, 1, 1)

    F.spinBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.45, 0.82, 0.10, 1)
    end)
    F.spinBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(C.ACCENT))
    end)

    -- Result text
    F.resultFS = MakeFS(F, 12, "OUTLINE")
    F.resultFS:SetPoint("BOTTOM", F, "BOTTOM", 0, 6)
    F.resultFS:SetText("")

    F:Hide()
end

-- Create / reuse a roulette row
local function GetRouletteRow(index)
    if rouletteEntries[index] then return rouletteEntries[index] end

    local C = C_TMT
    local parent = RouletteFrame.rows
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(ROULETTE_W - 6, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -(index - 1) * ROW_H)

    -- alternating bg
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    if index % 2 == 0 then
        row.bg:SetColorTexture(unpack(C.BG_ROW_ALT))
    else
        row.bg:SetColorTexture(0, 0, 0, 0)
    end

    -- Highlight overlay (used during spin)
    row.highlight = row:CreateTexture(nil, "ARTWORK")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(unpack(C.ACCENT))
    row.highlight:SetAlpha(0)

    -- Icon
    row.icon = row:CreateTexture(nil, "ARTWORK", nil, 1)
    row.icon:SetSize(ROW_H - 4, ROW_H - 4)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Key level on icon
    row.keyLevel = MakeFS(row, 11, "OUTLINE")
    row.keyLevel:SetPoint("CENTER", row.icon, "CENTER", 0, 0)

    -- Dungeon short name
    row.dungeonFS = MakeFS(row, 11, "OUTLINE")
    row.dungeonFS:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.dungeonFS:SetWidth(52)
    row.dungeonFS:SetJustifyH("LEFT")

    -- Player name
    row.nameFS = MakeFS(row, 11, "OUTLINE")
    row.nameFS:SetPoint("LEFT", row.dungeonFS, "RIGHT", 4, 0)
    row.nameFS:SetJustifyH("LEFT")

    -- Level text (right side)
    row.levelFS = MakeFS(row, 12, "OUTLINE")
    row.levelFS:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.levelFS:SetJustifyH("RIGHT")

    rouletteEntries[index] = row
    return row
end

-- Populate the roulette with current party keys
local function PopulateRoulette()
    local keys = CollectPartyKeystones()
    rouletteKeys = keys

    EnsureRouletteFrame()

    -- Hide old rows
    for _, row in ipairs(rouletteEntries) do
        row:Hide()
    end

    if #keys == 0 then
        RouletteFrame:SetHeight(HEADER_H + FOOTER_H + ROW_H)
        RouletteFrame.rows:SetHeight(ROW_H)
        local row = GetRouletteRow(1)
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.keyLevel:SetText("")
        row.dungeonFS:SetText("")
        row.nameFS:SetText(L["tmt_key_none_found"] or "No keys found")
        row.nameFS:SetTextColor(0.6, 0.6, 0.6)
        row.levelFS:SetText("")
        row.highlight:SetAlpha(0)
        row:Show()

        RouletteFrame.spinBtn:Disable()
        RouletteFrame.spinBtn.text:SetText(L["tmt_kr_spin"] or "SPIN")
        RouletteFrame.spinBtn:SetAlpha(0.4)
        RouletteFrame.resultFS:SetText("")
        RouletteFrame.footer:ClearAllPoints()
        RouletteFrame.footer:SetPoint("TOPLEFT", RouletteFrame.rows, "BOTTOMLEFT", 0, 0)
        RouletteFrame:Show()
        return
    end

    local rowsH = #keys * ROW_H
    RouletteFrame:SetHeight(HEADER_H + rowsH + FOOTER_H)
    RouletteFrame.rows:SetHeight(rowsH)

    for i, k in ipairs(keys) do
        local row = GetRouletteRow(i)
        local icon = GetDungeonIcon(k.mapID)
        local short = GetDungeonShortName(k.mapID)
        local kr, kg, kb = GetKeyColor(k.level)
        local classColor = RAID_CLASS_COLORS[k.class]
        local colorStr = classColor and classColor.colorStr or "FFFFFFFF"

        row.icon:SetTexture(icon)
        row.keyLevel:SetText("+" .. k.level)
        row.keyLevel:SetTextColor(kr, kg, kb)
        row.dungeonFS:SetText(short)
        row.dungeonFS:SetTextColor(1, 1, 1)
        row.nameFS:SetText("|c" .. colorStr .. k.name .. "|r")
        row.levelFS:SetText(string.format("|cff%02x%02x%02x+%d|r", kr * 255, kg * 255, kb * 255, k.level))
        row.highlight:SetAlpha(0)
        row:Show()
    end

    RouletteFrame.footer:ClearAllPoints()
    RouletteFrame.footer:SetPoint("TOPLEFT", RouletteFrame.rows, "BOTTOMLEFT", 0, 0)

    RouletteFrame.spinBtn:Enable()
    RouletteFrame.spinBtn:SetAlpha(1)
    RouletteFrame.spinBtn.text:SetText(L["tmt_kr_spin"] or "SPIN")
    RouletteFrame.resultFS:SetText("")

    RouletteFrame:Show()
end

---------------------------------------------------------------------------
-- SPIN ANIMATION
---------------------------------------------------------------------------

local spinning = false

local function ClearHighlights()
    for _, row in ipairs(rouletteEntries) do
        row.highlight:SetAlpha(0)
    end
end

local function HighlightRow(index)
    ClearHighlights()
    local row = rouletteEntries[index]
    if row then
        row.highlight:SetAlpha(0.35)
    end
end

local function DoSpin()
    if spinning or #rouletteKeys == 0 then return end
    spinning = true

    RouletteFrame.spinBtn:Disable()
    RouletteFrame.spinBtn:SetAlpha(0.4)
    RouletteFrame.resultFS:SetText("")

    -- Pick winner ahead of time
    local winnerIdx = math.random(1, #rouletteKeys)

    -- Compute total steps: cycle through all entries several times then land on winner
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
            -- Landed on winner
            spinning = false
            RouletteFrame.spinBtn:Enable()
            RouletteFrame.spinBtn:SetAlpha(1)

            local w = rouletteKeys[winnerIdx]
            local dungeonName = GetDungeonFullName(w.mapID)
            local kr, kg, kb = GetKeyColor(w.level)
            RouletteFrame.resultFS:SetText(
                string.format("|cff%02x%02x%02x%s +%d|r -- %s",
                    kr * 255, kg * 255, kb * 255,
                    dungeonName, w.level, w.name)
            )

            -- Announce to group
            if IsInGroup() then
                local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
                local msg = string.format("[TomoMod Roulette] >> %s +%d (%s) <<",
                    dungeonName, w.level, w.name)
                SendChatMessage(msg, channel)
            end
            return
        end

        -- Slow down progressively towards the end
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
        print(PREFIX .. ": LibOpenRaid " .. (L["tmt_key_not_available"] or "not available"))
        return
    end

    RequestKeystones()

    -- Small delay to let data arrive, then populate
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

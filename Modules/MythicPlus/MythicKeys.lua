--------------------------------------------------
-- TM Key Tracker
--------------------------------------------------

TomoMod_PartyKeystoneTracker = {}

MK = MK or {}

-- Anti-spam scan
local lastScan = 0
local SCAN_COOLDOWN = 5

--------------------------------------------------
-- Utils
--------------------------------------------------

local function GetKeyColor(level)
    if not level then return 1,1,1 end
    if level >= 20 then
        return 1, 0.5, 0
    elseif level >= 15 then
        return 0.64, 0.21, 0.93
    elseif level >= 10 then
        return 0, 0.44, 0.87
    else
        return 0.12, 1, 0.12
    end
end

--------------------------------------------------
-- Main Frame
--------------------------------------------------

local TMKeyFrame = CreateFrame("Frame", "TMKeyFrame", UIParent, "BackdropTemplate")
TMKeyFrame:SetSize(320, 420)
TMKeyFrame:SetPoint("CENTER")
TMKeyFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 14,
})
TMKeyFrame:SetBackdropColor(0, 0, 0, 0.85)
TMKeyFrame:Hide()
TMKeyFrame:SetMovable(true)
TMKeyFrame:EnableMouse(true)
TMKeyFrame:RegisterForDrag("LeftButton")
TMKeyFrame:SetScript("OnDragStart", TMKeyFrame.StartMoving)
TMKeyFrame:SetScript("OnDragStop", TMKeyFrame.StopMovingOrSizing)

local title = TMKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("TM – Mythic Keys")

TMKeyFrame.text = TMKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
TMKeyFrame.text:SetPoint("TOPLEFT", 15, -40)
TMKeyFrame.text:SetJustifyH("LEFT")
TMKeyFrame.text:SetWidth(290)
TMKeyFrame.text:SetText("")

TMKeyFrame.chatLines = {}

--------------------------------------------------
-- Buttons
--------------------------------------------------

local refreshBtn = CreateFrame("Button", nil, TMKeyFrame, "GameMenuButtonTemplate")
refreshBtn:SetSize(120, 25)
refreshBtn:SetPoint("BOTTOM", 0, 15)
refreshBtn:SetText("Refresh")

local sendBtn = CreateFrame("Button", nil, TMKeyFrame, "GameMenuButtonTemplate")
sendBtn:SetSize(120, 25)
sendBtn:SetPoint("BOTTOM", 0, 45)
sendBtn:SetText("Envoyer chat")

--------------------------------------------------
-- Mini Frame (Mythic+ UI)
--------------------------------------------------

local MiniKeyFrame = CreateFrame("Frame", "TMKeyMiniFrame", UIParent, "BackdropTemplate")
MiniKeyFrame:SetSize(220, 120)
MiniKeyFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
})
MiniKeyFrame:SetBackdropColor(0, 0, 0, 0.9)
MiniKeyFrame:Hide()

MiniKeyFrame.text = MiniKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MiniKeyFrame.text:SetPoint("TOPLEFT", 10, -10)
MiniKeyFrame.text:SetJustifyH("LEFT")
MiniKeyFrame.text:SetWidth(200)
MiniKeyFrame.text:SetText("")

--------------------------------------------------
-- Core Logic
--------------------------------------------------

local function ScanGroupKeys(force)
    if not force and (GetTime() - lastScan < SCAN_COOLDOWN) then return end
    lastScan = GetTime()

    local text = ""
    local chatLines = {}

    if not IsInGroup() then
        TMKeyFrame.text:SetText("Tu n'es pas en groupe.")
        MiniKeyFrame.text:SetText("")
        return
    end

    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid"..i or "party"..i
        if UnitExists(unit) then
            local name = UnitName(unit)
            NotifyInspect(unit)

            local mapID, level = C_MythicPlus.GetOwnedKeystoneInfo(unit)
            if mapID and level then
                local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
                local r,g,b = GetKeyColor(level)

                text = text .. string.format(
                    "|cff%02x%02x%02x%s : %s +%d|r\n",
                    r*255, g*255, b*255, name, mapName, level
                )

                table.insert(chatLines, name.." : "..mapName.." +"..level)
            else
                text = text .. name.." : pas de clé\n"
                table.insert(chatLines, name.." : pas de clé")
            end
        end
    end

    TMKeyFrame.text:SetText(text)
    MiniKeyFrame.text:SetText(text)
    TMKeyFrame.chatLines = chatLines
end

function MK:Enable()
    if self.enabled then return end
    self.enabled = true

    -- création frames si pas déjà faites
    if self.CreateFrames then self:CreateFrames() end

    -- auto refresh
    if TomoModDB.MythicKeys.autoRefresh then
        self:StartAutoRefresh()
    end
end

function MK:Toggle()
    if not self.MainFrame then return end
    if self.MainFrame:IsShown() then
        self.MainFrame:Hide()
    else
        self.MainFrame:Show()
    end
end

--------------------------------------------------
-- Chat Send
--------------------------------------------------

local function SendKeysToChat()
    if not TMKeyFrame.chatLines or #TMKeyFrame.chatLines == 0 then return end
    local channel = IsInRaid() and "RAID" or "PARTY"
    SendChatMessage("📊 Clés Mythic+ du groupe :", channel)
    for _, line in ipairs(TMKeyFrame.chatLines) do
        SendChatMessage(line, channel)
    end
end

--------------------------------------------------
-- Button Scripts
--------------------------------------------------

refreshBtn:SetScript("OnClick", function()
    ScanGroupKeys(true)
end)

sendBtn:SetScript("OnClick", function()
    SendKeysToChat()
end)

--------------------------------------------------
-- Commands
--------------------------------------------------

SLASH_TMKEY1 = "/tm"
SlashCmdList["TMKEY"] = function(msg)
    if msg == "key" then
        if TMKeyFrame:IsShown() then
            TMKeyFrame:Hide()
        else
            TMKeyFrame:Show()
            ScanGroupKeys(true)
        end
    end
end

--------------------------------------------------
-- Auto Refresh & Events
--------------------------------------------------

local ticker
local function StartAutoRefresh()
    if ticker then return end
    ticker = C_Timer.NewTicker(15, function()
        ScanGroupKeys()
    end)
end

local function StopAutoRefresh()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

eventFrame:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" and arg == "Blizzard_ChallengesUI" then
        MiniKeyFrame:SetPoint("TOPLEFT", ChallengesFrame, "TOPRIGHT", 10, 0)
        hooksecurefunc(ChallengesFrame, "Show", function()
            MiniKeyFrame:Show()
            ScanGroupKeys(true)
        end)
        hooksecurefunc(ChallengesFrame, "Hide", function()
            MiniKeyFrame:Hide()
        end)
    elseif event == "CHALLENGE_MODE_START" then
        StopAutoRefresh()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        StartAutoRefresh()
    else
        ScanGroupKeys()
    end
end)

---------------------------------------------------

TomoMod_RegisterModule("MythicKeys", MK)
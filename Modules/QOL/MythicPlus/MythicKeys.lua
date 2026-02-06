--------------------------------------------------
-- TM Key Tracker
-- Utilise les addon comms pour partager les cles
-- entre les membres du groupe.
--------------------------------------------------

local ADDON_PREFIX = "TMKeyTracker"
local SCAN_COOLDOWN = 5

MK = MK or {}
MK.enabled = false
MK.keyData = {}
MK.chatLines = {}

local lastScan = 0
local ticker = nil

-- References aux frames (creees dans CreateFrames)
local TMKeyFrame, MiniKeyFrame

--------------------------------------------------
-- Utils
--------------------------------------------------

local function GetSettings()
    if not TomoModDB or not TomoModDB.MythicKeys then
        return nil
    end
    return TomoModDB.MythicKeys
end

local function GetKeyColor(level)
    if not level then return 1, 1, 1 end
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

local function GetAddonChannel()
    if IsInGroup(LE_LFG_LIST_CATEGORY) then
        return "INSTANCE_CHAT"
    elseif IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    end
    return nil
end

local function GetChatChannel()
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

--------------------------------------------------
-- Lecture de la cle du joueur local
--------------------------------------------------

local function GetMyKeystoneInfo()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    if not mapID then return nil end

    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    if not level or level == 0 then return nil end

    local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
    return mapID, mapName or "???", level
end

--------------------------------------------------
-- Addon Comms (partage des cles entre joueurs)
--------------------------------------------------

local function BroadcastMyKey()
    local channel = GetAddonChannel()
    if not channel then return end

    local mapID, mapName, level = GetMyKeystoneInfo()
    local payload
    if mapID then
        payload = string.format("%d:%d:%s", mapID, level, mapName)
    else
        payload = "NONE"
    end

    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, payload, channel)
end

local function RequestGroupKeys()
    local channel = GetAddonChannel()
    if not channel then return end
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "REQUEST", channel)
end

local function OnAddonMessage(prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then return end

    local shortName = Ambiguate(sender, "short")

    if message == "REQUEST" then
        BroadcastMyKey()
        return
    end

    if message == "NONE" then
        MK.keyData[shortName] = nil
    else
        local mapID, level, mapName = strsplit(":", message, 3)
        mapID = tonumber(mapID)
        level = tonumber(level)
        if mapID and level and mapName then
            MK.keyData[shortName] = {
                mapID   = mapID,
                mapName = mapName,
                level   = level,
            }
        end
    end
end

--------------------------------------------------
-- Affichage
--------------------------------------------------

local function RefreshDisplay()
    if not TMKeyFrame then return end

    -- Toujours mettre a jour notre propre cle
    local myName = UnitName("player")
    local mapID, mapName, level = GetMyKeystoneInfo()
    if mapID then
        MK.keyData[myName] = { mapID = mapID, mapName = mapName, level = level }
    else
        MK.keyData[myName] = nil
    end

    if not IsInGroup() then
        TMKeyFrame.text:SetText("Tu n'es pas en groupe.")
        if MiniKeyFrame then MiniKeyFrame.text:SetText("Pas en groupe.") end
        MK.chatLines = {}
        return
    end

    local text = ""
    local chatLines = {}

    -- Construire la liste des membres
    local members = {}
    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers do
        local unit
        if IsInRaid() then
            unit = "raid" .. i
        else
            if i < numMembers then
                unit = "party" .. i
            else
                unit = "player"
            end
        end
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name then
                table.insert(members, name)
            end
        end
    end

    for _, name in ipairs(members) do
        local data = MK.keyData[name]
        if data then
            local r, g, b = GetKeyColor(data.level)
            text = text .. string.format(
                "|cff%02x%02x%02x%s : %s +%d|r\n",
                r * 255, g * 255, b * 255,
                name, data.mapName, data.level
            )
            table.insert(chatLines, string.format("%s : %s +%d", name, data.mapName, data.level))
        else
            text = text .. string.format("|cff888888%s : pas de cle|r\n", name)
            table.insert(chatLines, name .. " : pas de cle")
        end
    end

    TMKeyFrame.text:SetText(text)
    if MiniKeyFrame then MiniKeyFrame.text:SetText(text) end
    MK.chatLines = chatLines
end

--------------------------------------------------
-- Scan (demande + affichage)
--------------------------------------------------

local function ScanGroupKeys(force)
    if not force and (GetTime() - lastScan < SCAN_COOLDOWN) then return end
    lastScan = GetTime()

    RequestGroupKeys()

    -- Delai pour laisser les reponses arriver
    C_Timer.After(1.5, RefreshDisplay)
end

--------------------------------------------------
-- Envoi en chat
--------------------------------------------------

local function SendKeysToChat()
    if not MK.chatLines or #MK.chatLines == 0 then
        print("|cff0cd29fTomoMod Keys:|r Aucune cle a envoyer.")
        return
    end

    local channel = GetChatChannel()
    if not channel then
        print("|cff0cd29fTomoMod Keys:|r Tu dois etre en groupe.")
        return
    end

    SendChatMessage("--- Cles Mythic+ du groupe ---", channel)
    for _, line in ipairs(MK.chatLines) do
        SendChatMessage(line, channel)
    end
end

--------------------------------------------------
-- Auto Refresh
--------------------------------------------------

local function StartAutoRefresh()
    if ticker then return end
    ticker = C_Timer.NewTicker(15, function()
        ScanGroupKeys(false)
    end)
end

local function StopAutoRefresh()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

MK.StartAutoRefresh = StartAutoRefresh
MK.StopAutoRefresh  = StopAutoRefresh

--------------------------------------------------
-- Frame Creation
--------------------------------------------------

function MK:CreateFrames()
    if TMKeyFrame then return end

    -- Main Frame
    TMKeyFrame = CreateFrame("Frame", "TMKeyFrame", UIParent, "BackdropTemplate")
    TMKeyFrame:SetSize(320, 420)
    TMKeyFrame:SetPoint("CENTER")
    TMKeyFrame:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
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

    -- Fermer avec Echap
    tinsert(UISpecialFrames, "TMKeyFrame")

    local title = TMKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("TM \226\128\147 Mythic Keys")

    TMKeyFrame.text = TMKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    TMKeyFrame.text:SetPoint("TOPLEFT", 15, -40)
    TMKeyFrame.text:SetJustifyH("LEFT")
    TMKeyFrame.text:SetWidth(290)
    TMKeyFrame.text:SetText("")

    -- Boutons
    local sendBtn = CreateFrame("Button", nil, TMKeyFrame, "GameMenuButtonTemplate")
    sendBtn:SetSize(120, 25)
    sendBtn:SetPoint("BOTTOM", -65, 15)
    sendBtn:SetText("Envoyer chat")
    sendBtn:SetScript("OnClick", function() SendKeysToChat() end)

    local refreshBtn = CreateFrame("Button", nil, TMKeyFrame, "GameMenuButtonTemplate")
    refreshBtn:SetSize(120, 25)
    refreshBtn:SetPoint("BOTTOM", 65, 15)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function() ScanGroupKeys(true) end)

    -- Mini Frame
    local settings = GetSettings()
    if settings and settings.miniFrame then
        MiniKeyFrame = CreateFrame("Frame", "TMKeyMiniFrame", UIParent, "BackdropTemplate")
        MiniKeyFrame:SetSize(220, 120)
        MiniKeyFrame:SetBackdrop({
            bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
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
    end

    self.MainFrame = TMKeyFrame
end

--------------------------------------------------
-- MK:UpdateMiniFrame (appele depuis le config panel)
--------------------------------------------------

function MK:UpdateMiniFrame()
    local settings = GetSettings()
    if not settings then return end

    if settings.miniFrame and not MiniKeyFrame then
        -- Recreer si necessaire au prochain reload
        print("|cff0cd29fTomoMod Keys:|r Changement applique au prochain /reload.")
    elseif not settings.miniFrame and MiniKeyFrame then
        MiniKeyFrame:Hide()
    end
end

--------------------------------------------------
-- MK:Enable / MK:Toggle (appeles depuis Init.lua)
--------------------------------------------------

function MK:Enable()
    if self.enabled then return end
    self.enabled = true

    self:CreateFrames()

    local settings = GetSettings()
    if settings and settings.autoRefresh then
        StartAutoRefresh()
    end
end

function MK:Toggle()
    if not self.MainFrame then
        self:CreateFrames()
    end
    if not self.MainFrame then return end

    if self.MainFrame:IsShown() then
        self.MainFrame:Hide()
    else
        self.MainFrame:Show()
        ScanGroupKeys(true)
    end
end

--------------------------------------------------
-- Events
--------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
    if event == "CHAT_MSG_ADDON" then
        OnAddonMessage(arg1, arg2, arg3, arg4)

    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_ChallengesUI" then
        if ChallengesFrame and MiniKeyFrame then
            MiniKeyFrame:SetPoint("TOPLEFT", ChallengesFrame, "TOPRIGHT", 10, 0)

            ChallengesFrame:HookScript("OnShow", function()
                local settings = GetSettings()
                if settings and settings.miniFrame and MiniKeyFrame then
                    MiniKeyFrame:Show()
                    ScanGroupKeys(true)
                end
            end)
            ChallengesFrame:HookScript("OnHide", function()
                if MiniKeyFrame then
                    MiniKeyFrame:Hide()
                end
            end)
        end

    elseif event == "CHALLENGE_MODE_START" then
        StopAutoRefresh()

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        StartAutoRefresh()
        C_Timer.After(3, function() ScanGroupKeys(true) end)

    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Nettoyer les joueurs partis
        local currentMembers = {}
        local numMembers = GetNumGroupMembers()
        for i = 1, numMembers do
            local unit = IsInRaid() and ("raid" .. i)
                or (i < numMembers and ("party" .. i) or "player")
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name then currentMembers[name] = true end
            end
        end
        currentMembers[UnitName("player")] = true

        for name in pairs(MK.keyData) do
            if not currentMembers[name] then
                MK.keyData[name] = nil
            end
        end

        ScanGroupKeys(false)

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            BroadcastMyKey()
            RefreshDisplay()
        end)
    end
end)

--------------------------------------------------
-- Enregistrement du module
--------------------------------------------------

TomoMod_RegisterModule("MythicKeys", MK)
--------------------------------------------------
-- TM Key Tracker
-- Multi-protocol keystone tracker:
--  1) TMKeyTracker addon comm (TomoMod users)
--  2) AstralKeys protocol listener (most popular key addon)
--  3) AngryKeystones protocol listener
--  4) Chat keystone link parser (universal — no addon needed)
-- 5-line max display for M+ groups.
--------------------------------------------------

local ADDON_PREFIX    = "TMKeyTracker"
local ASTRAL_PREFIX   = "AstralKeys"
local ANGRY_PREFIX    = "AngryKeystones"
local SCAN_COOLDOWN   = 5
local MAX_LINES       = 5

MK = MK or {}
MK.enabled   = false
MK.keyData   = {}     -- [shortName] = { mapID, mapName, level, source }
MK.chatLines = {}

local lastScan = 0
local ticker   = nil

-- References aux frames
local TMKeyFrame, MiniKeyFrame

--------------------------------------------------
-- Utils
--------------------------------------------------

local function GetSettings()
    if not TomoModDB or not TomoModDB.MythicKeys then return nil end
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

-- Build ordered list of current group members (max 5)
local function GetGroupMembers()
    local members = {}
    local myName = UnitName("player")
    local added = {}

    if not IsInGroup() then
        if myName then
            members[1] = { name = myName, unit = "player" }
        end
        return members
    end

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
            if name and not added[name] then
                added[name] = true
                table.insert(members, { name = name, unit = unit })
            end
        end
    end

    -- Ensure player is always included
    if not added[myName] then
        table.insert(members, { name = myName, unit = "player" })
    end

    -- Cap to MAX_LINES
    while #members > MAX_LINES do
        table.remove(members)
    end

    return members
end

--------------------------------------------------
-- Local player keystone
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
-- Store key data (central)
--------------------------------------------------

local function StoreKey(name, mapID, mapName, level, source)
    if not name or not mapID or not level then return end
    -- Don't overwrite our own protocol with weaker source
    local existing = MK.keyData[name]
    if existing and existing.source == "TMKey" and source ~= "TMKey" then
        return
    end
    MK.keyData[name] = {
        mapID   = mapID,
        mapName = mapName or "???",
        level   = level,
        source  = source or "unknown",
    }
end

local function ClearKey(name)
    MK.keyData[name] = nil
end

--------------------------------------------------
-- Protocol 1: TMKeyTracker (our own)
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

local function HandleTMKeyMessage(message, sender)
    local shortName = Ambiguate(sender, "short")

    if message == "REQUEST" then
        BroadcastMyKey()
        return
    end

    if message == "NONE" then
        ClearKey(shortName)
    else
        local sMapID, sLevel, mapName = strsplit(":", message, 3)
        local mapID = tonumber(sMapID)
        local level = tonumber(sLevel)
        if mapID and level and mapName then
            StoreKey(shortName, mapID, mapName, level, "TMKey")
        end
    end
end

--------------------------------------------------
-- Protocol 2: AstralKeys listener
-- Common formats:
--   SYNC: "name-realm:class:mapID:level:weekBest:timestamp"
--   PUSH: "mapID:level:name-realm"
--   Various sync formats depending on version
--------------------------------------------------

local function HandleAstralKeysMessage(message, sender)
    local shortSender = Ambiguate(sender, "short")

    -- Try multi-field format (sync)
    local parts = { strsplit(":", message) }
    if #parts >= 4 then
        -- Could be "name-realm:classID:mapID:level:weekBest:timestamp"
        local mapID = tonumber(parts[3])
        local level = tonumber(parts[4])
        if mapID and level and level > 0 and level < 50 and mapID > 0 then
            local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
            if mapName then
                local playerName = parts[1]
                if playerName then
                    local name = strsplit("-", playerName)
                    if name and name ~= "" then
                        StoreKey(name, mapID, mapName, level, "AstralKeys")
                        return
                    end
                end
            end
        end

        -- Alternative: first two fields are mapID:level
        mapID = tonumber(parts[1])
        level = tonumber(parts[2])
        if mapID and level and level > 0 and level < 50 and mapID > 0 then
            local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
            if mapName then
                StoreKey(shortSender, mapID, mapName, level, "AstralKeys")
                return
            end
        end
    end
end

--------------------------------------------------
-- Protocol 3: AngryKeystones listener
--------------------------------------------------

local function HandleAngryKeystonesMessage(message, sender)
    local shortSender = Ambiguate(sender, "short")
    local parts = { strsplit(":", message) }
    for i = 1, #parts - 1 do
        local mapID = tonumber(parts[i])
        local level = tonumber(parts[i + 1])
        if mapID and level and level > 0 and level < 50 and mapID > 100 then
            local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
            if mapName then
                StoreKey(shortSender, mapID, mapName, level, "AngryKeystones")
                return
            end
        end
    end
end

--------------------------------------------------
-- Protocol 4: Chat keystone link parser
-- Parses |Hkeystone:itemID:mapID:level:...|h links
-- Works universally — no addon needed on sender
--------------------------------------------------

local function ParseKeystoneLink(message, sender)
    local shortSender = Ambiguate(sender, "short")

    -- Pattern: keystone:itemID:mapID:level:affixes...
    local mapID, level = message:match("|Hkeystone:%d+:(%d+):(%d+)")
    if not mapID then
        mapID, level = message:match("keystone:%d+:(%d+):(%d+)")
    end

    if mapID and level then
        mapID = tonumber(mapID)
        level = tonumber(level)
        if mapID and level and level > 0 then
            local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
            if mapName then
                StoreKey(shortSender, mapID, mapName, level, "ChatLink")
            end
        end
    end
end

--------------------------------------------------
-- Combined addon message handler
--------------------------------------------------

local function OnAddonMessage(prefix, message, _, sender)
    if prefix == ADDON_PREFIX then
        HandleTMKeyMessage(message, sender)
    elseif prefix == ASTRAL_PREFIX then
        HandleAstralKeysMessage(message, sender)
    elseif prefix == ANGRY_PREFIX then
        HandleAngryKeystonesMessage(message, sender)
    end
end

--------------------------------------------------
-- Display
--------------------------------------------------

local function RefreshDisplay()
    if not TMKeyFrame then return end

    -- Always update our own key
    local myName = UnitName("player")
    local mapID, mapName, level = GetMyKeystoneInfo()
    if mapID then
        StoreKey(myName, mapID, mapName, level, "TMKey")
    else
        ClearKey(myName)
    end

    -- Get group members
    local members = GetGroupMembers()

    if not IsInGroup() then
        -- Solo: show just player key
        if MK.keyData[myName] then
            local d = MK.keyData[myName]
            local r, g, b = GetKeyColor(d.level)
            local line = string.format("|cff%02x%02x%02x%s : %s +%d|r", r*255, g*255, b*255, myName, d.mapName, d.level)
            TMKeyFrame.text:SetText(line)
            if MiniKeyFrame then MiniKeyFrame.text:SetText(line) end
        else
            TMKeyFrame.text:SetText(TomoMod_L["mk_no_key_self"])
            if MiniKeyFrame then MiniKeyFrame.text:SetText(TomoMod_L["mk_no_key_self"]) end
        end
        MK.chatLines = {}
        return
    end

    local text = ""
    local chatLines = {}
    local lineCount = 0

    for _, member in ipairs(members) do
        if lineCount >= MAX_LINES then break end
        local name = member.name
        local data = MK.keyData[name]

        -- Class color for name
        local _, classFile = UnitClass(member.unit)
        local nameColor = "ffffff"
        if classFile then
            local cc = RAID_CLASS_COLORS[classFile]
            if cc then
                nameColor = string.format("%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)
            end
        end

        if data then
            local r, g, b = GetKeyColor(data.level)
            text = text .. string.format(
                "|cff%s%s|r : |cff%02x%02x%02x%s +%d|r\n",
                nameColor, name,
                r * 255, g * 255, b * 255,
                data.mapName, data.level
            )
            table.insert(chatLines, string.format("%s : %s +%d", name, data.mapName, data.level))
        else
            text = text .. string.format("|cff%s%s|r : |cff666666—|r\n", nameColor, name)
            table.insert(chatLines, name .. " : —")
        end
        lineCount = lineCount + 1
    end

    TMKeyFrame.text:SetText(text)
    if MiniKeyFrame then MiniKeyFrame.text:SetText(text) end
    MK.chatLines = chatLines
end

--------------------------------------------------
-- Scan (request + display)
--------------------------------------------------

local function ScanGroupKeys(force)
    if not force and (GetTime() - lastScan < SCAN_COOLDOWN) then return end
    lastScan = GetTime()

    BroadcastMyKey()
    RequestGroupKeys()

    C_Timer.After(1.5, RefreshDisplay)
end

--------------------------------------------------
-- Send keys to chat
--------------------------------------------------

local function SendKeysToChat()
    if not MK.chatLines or #MK.chatLines == 0 then
        print("|cff0cd29fTomoMod Keys:|r " .. TomoMod_L["msg_keys_no_key"])
        return
    end

    local channel = GetChatChannel()
    if not channel then
        print("|cff0cd29fTomoMod Keys:|r " .. TomoMod_L["msg_keys_not_in_group"])
        return
    end

    SendChatMessage("--- M+ Keys ---", channel)
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

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BORDER_TEX = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\border.png"
local BORDER_CORNER = 4

local function Create9SliceBorder(parent, r, g, b, a)
    a = a or 1
    local parts = {}
    local function Tex()
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetTexture(BORDER_TEX)
        if r then t:SetVertexColor(r, g, b, a) end
        parts[#parts + 1] = t
        return t
    end

    local tl = Tex(); tl:SetSize(BORDER_CORNER, BORDER_CORNER)
    tl:SetPoint("TOPLEFT"); tl:SetTexCoord(0, 0.5, 0, 0.5)
    local tr = Tex(); tr:SetSize(BORDER_CORNER, BORDER_CORNER)
    tr:SetPoint("TOPRIGHT"); tr:SetTexCoord(0.5, 1, 0, 0.5)
    local bl = Tex(); bl:SetSize(BORDER_CORNER, BORDER_CORNER)
    bl:SetPoint("BOTTOMLEFT"); bl:SetTexCoord(0, 0.5, 0.5, 1)
    local br = Tex(); br:SetSize(BORDER_CORNER, BORDER_CORNER)
    br:SetPoint("BOTTOMRIGHT"); br:SetTexCoord(0.5, 1, 0.5, 1)

    local top = Tex(); top:SetHeight(BORDER_CORNER)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(0.5, 0.5, 0, 0.5)
    local bot = Tex(); bot:SetHeight(BORDER_CORNER)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bot:SetTexCoord(0.5, 0.5, 0.5, 1)
    local left = Tex(); left:SetWidth(BORDER_CORNER)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    left:SetTexCoord(0, 0.5, 0.5, 0.5)
    local right = Tex(); right:SetWidth(BORDER_CORNER)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    right:SetTexCoord(0.5, 1, 0.5, 0.5)

    return parts
end

function MK:CreateFrames()
    if TMKeyFrame then return end

    -- Main Frame (compact 5-line design)
    TMKeyFrame = CreateFrame("Frame", "TMKeyFrame", UIParent)
    TMKeyFrame:SetSize(260, 180)
    TMKeyFrame:SetPoint("CENTER")
    TMKeyFrame:SetFrameStrata("DIALOG")
    TMKeyFrame:SetFrameLevel(200)

    -- Background
    local bg = TMKeyFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.92)

    -- 9-slice border
    Create9SliceBorder(TMKeyFrame)

    TMKeyFrame:Hide()
    TMKeyFrame:SetMovable(true)
    TMKeyFrame:EnableMouse(true)
    TMKeyFrame:RegisterForDrag("LeftButton")
    TMKeyFrame:SetScript("OnDragStart", TMKeyFrame.StartMoving)
    TMKeyFrame:SetScript("OnDragStop", TMKeyFrame.StopMovingOrSizing)

    -- Fermer avec Echap
    tinsert(UISpecialFrames, "TMKeyFrame")

    -- Title bar
    local titleBg = TMKeyFrame:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", 1, -1)
    titleBg:SetPoint("TOPRIGHT", -1, -1)
    titleBg:SetHeight(22)
    titleBg:SetColorTexture(0.1, 0.1, 0.15, 1)

    local title = TMKeyFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 11, "OUTLINE")
    title:SetPoint("TOP", 0, -5)
    title:SetText("|cff0cd29fTM|r — M+ Keys")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, TMKeyFrame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function() TMKeyFrame:Hide() end)

    -- Protocol indicator
    local protoLabel = TMKeyFrame:CreateFontString(nil, "OVERLAY")
    protoLabel:SetFont(FONT, 8, "OUTLINE")
    protoLabel:SetPoint("TOPLEFT", 6, -5)
    protoLabel:SetTextColor(0.4, 0.4, 0.4)
    protoLabel:SetText("Multi")
    TMKeyFrame.protoLabel = protoLabel

    -- Key list text (5 lines max)
    TMKeyFrame.text = TMKeyFrame:CreateFontString(nil, "OVERLAY")
    TMKeyFrame.text:SetFont(FONT, 11, "")
    TMKeyFrame.text:SetPoint("TOPLEFT", 12, -30)
    TMKeyFrame.text:SetJustifyH("LEFT")
    TMKeyFrame.text:SetWidth(236)
    TMKeyFrame.text:SetSpacing(3)
    TMKeyFrame.text:SetText("")

    -- Buttons
    local btnWidth = 110
    local btnY = 12

    local sendBtn = CreateFrame("Button", nil, TMKeyFrame)
    sendBtn:SetSize(btnWidth, 22)
    sendBtn:SetPoint("BOTTOMLEFT", btnY, 10)

    local sendBg = sendBtn:CreateTexture(nil, "BACKGROUND")
    sendBg:SetAllPoints()
    sendBg:SetColorTexture(0.15, 0.15, 0.2, 1)
    Create9SliceBorder(sendBtn, 0.3, 0.3, 0.35, 1)

    local sendText = sendBtn:CreateFontString(nil, "OVERLAY")
    sendText:SetFont(FONT, 10, "OUTLINE")
    sendText:SetPoint("CENTER")
    sendText:SetText(TomoMod_L["mk_btn_send"])
    sendBtn:SetScript("OnClick", function() SendKeysToChat() end)
    sendBtn:SetScript("OnEnter", function() sendBg:SetColorTexture(0.25, 0.25, 0.3, 1) end)
    sendBtn:SetScript("OnLeave", function() sendBg:SetColorTexture(0.15, 0.15, 0.2, 1) end)

    local refreshBtn = CreateFrame("Button", nil, TMKeyFrame)
    refreshBtn:SetSize(btnWidth, 22)
    refreshBtn:SetPoint("BOTTOMRIGHT", -btnY, 10)

    local refBg = refreshBtn:CreateTexture(nil, "BACKGROUND")
    refBg:SetAllPoints()
    refBg:SetColorTexture(0.15, 0.15, 0.2, 1)
    Create9SliceBorder(refreshBtn, 0.3, 0.3, 0.35, 1)

    local refText = refreshBtn:CreateFontString(nil, "OVERLAY")
    refText:SetFont(FONT, 10, "OUTLINE")
    refText:SetPoint("CENTER")
    refText:SetText(TomoMod_L["mk_btn_refresh"])
    refreshBtn:SetScript("OnClick", function() ScanGroupKeys(true) end)
    refreshBtn:SetScript("OnEnter", function() refBg:SetColorTexture(0.25, 0.25, 0.3, 1) end)
    refreshBtn:SetScript("OnLeave", function() refBg:SetColorTexture(0.15, 0.15, 0.2, 1) end)

    -- Mini Frame (for ChallengesUI sidebar)
    local settings = GetSettings()
    if settings and settings.miniFrame then
        MiniKeyFrame = CreateFrame("Frame", "TMKeyMiniFrame", UIParent)
        MiniKeyFrame:SetSize(220, 110)

        local miniBg = MiniKeyFrame:CreateTexture(nil, "BACKGROUND")
        miniBg:SetAllPoints()
        miniBg:SetColorTexture(0.05, 0.05, 0.08, 0.92)
        Create9SliceBorder(MiniKeyFrame)

        MiniKeyFrame:Hide()

        local miniTitle = MiniKeyFrame:CreateFontString(nil, "OVERLAY")
        miniTitle:SetFont(FONT, 9, "OUTLINE")
        miniTitle:SetPoint("TOP", 0, -4)
        miniTitle:SetText("|cff0cd29fM+ Keys|r")

        MiniKeyFrame.text = MiniKeyFrame:CreateFontString(nil, "OVERLAY")
        MiniKeyFrame.text:SetFont(FONT, 10, "")
        MiniKeyFrame.text:SetPoint("TOPLEFT", 8, -18)
        MiniKeyFrame.text:SetJustifyH("LEFT")
        MiniKeyFrame.text:SetWidth(204)
        MiniKeyFrame.text:SetSpacing(2)
        MiniKeyFrame.text:SetText("")
    end

    self.MainFrame = TMKeyFrame
end

--------------------------------------------------
-- MK:UpdateMiniFrame
--------------------------------------------------

function MK:UpdateMiniFrame()
    local settings = GetSettings()
    if not settings then return end

    if settings.miniFrame and not MiniKeyFrame then
        print("|cff0cd29fTomoMod Keys:|r " .. TomoMod_L["msg_keys_reload"])
    elseif not settings.miniFrame and MiniKeyFrame then
        MiniKeyFrame:Hide()
    end
end

--------------------------------------------------
-- MK:Enable / MK:Toggle
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

-- Chat events for keystone link parsing (universal detection)
eventFrame:RegisterEvent("CHAT_MSG_PARTY")
eventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
eventFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")

-- Register all addon prefixes
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
pcall(C_ChatInfo.RegisterAddonMessagePrefix, ASTRAL_PREFIX)
pcall(C_ChatInfo.RegisterAddonMessagePrefix, ANGRY_PREFIX)

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
    if event == "CHAT_MSG_ADDON" then
        OnAddonMessage(arg1, arg2, arg3, arg4)

    elseif event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER"
        or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER"
        or event == "CHAT_MSG_INSTANCE_CHAT" or event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then
        -- arg1 = message, arg2 = senderName
        local message = arg1
        local sender = arg2
        if message and sender and message:find("keystone:") then
            ParseKeystoneLink(message, sender)
            C_Timer.After(0.2, RefreshDisplay)
        end

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
        -- Clean departed members
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
-- Module registration
--------------------------------------------------

TomoMod_RegisterModule("MythicKeys", MK)

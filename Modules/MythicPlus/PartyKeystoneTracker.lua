--------------------------------------------------
-- PartyKeystoneTracker
-- Shows Mythic+ keys of party members in PVEFrame
--------------------------------------------------

local addonName = ...
local LibOpenRaid = LibStub and LibStub("LibOpenRaid-1.0", true)
if not LibOpenRaid then return end

--------------------------------------------------
-- CONFIG
--------------------------------------------------
local FRAME_WIDTH = 170
local BUTTON_SIZE = 20
local ENTRY_HEIGHT = 26
local MAX_ENTRIES = 5

--------------------------------------------------
-- HELPERS
--------------------------------------------------
local function IsEnabled()
    return true
end

local function GetDungeonInfo(mapID)
    if not mapID then
        return "Interface\\Icons\\INV_Misc_QuestionMark", "???"
    end

    local name, _, _, icon = C_ChallengeMode.GetMapUIInfo(mapID)
    local short = name and name:match("^(%S+)") or "???"
    return icon, short
end

local function GetKeyColor(level)
    if not level or level <= 0 then
        return 0.7, 0.7, 0.7
    elseif level >= 12 then
        return 1, 0.5, 0
    elseif level >= 10 then
        return 0.6, 0.2, 0.9
    elseif level >= 7 then
        return 0, 0.44, 0.87
    elseif level >= 5 then
        return 0.12, 0.75, 0.26
    end
    return 1, 1, 1
end

--------------------------------------------------
-- FRAME
--------------------------------------------------
local Frame = CreateFrame("Frame", "PartyKeystoneTrackerFrame", UIParent, "BackdropTemplate")
Frame:SetSize(FRAME_WIDTH, BUTTON_SIZE)
Frame:SetFrameStrata("HIGH")
Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
Frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
Frame:SetBackdropBorderColor(0.2, 0.8, 0.6, 1)
Frame:Hide()

--------------------------------------------------
-- TITLE
--------------------------------------------------
local title = Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOP", Frame, "TOP", 0, -4)
title:SetText("Party Keys")

--------------------------------------------------
-- BUTTONS
--------------------------------------------------
local buttons = {}

local function CreateEntry(index)
    local b = CreateFrame("Button", nil, Frame)
    b:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    b:SetPoint("TOPLEFT", Frame, "TOPLEFT", 6, -18 - (index * ENTRY_HEIGHT))

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()

    b.level = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.level:SetPoint("CENTER", b, "CENTER", 0, 0)

    b.name = Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.name:SetPoint("LEFT", b, "RIGHT", 6, 0)

    return b
end

for i = 1, MAX_ENTRIES do
    buttons[i] = CreateEntry(i - 1)
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------
local function HideAll()
    for i = 1, MAX_ENTRIES do
        buttons[i]:Hide()
        buttons[i].name:Hide()
    end
end

local function Update()
    if not IsEnabled() or InCombatLockdown() or IsInRaid() then
        Frame:Hide()
        return
    end

    HideAll()

    local allKeys = LibOpenRaid.GetAllKeystonesInfo()
    local entries = {}

    -- Player first
    local myKey = LibOpenRaid.GetKeystoneInfo("player")
    if myKey and myKey.level and myKey.level > 0 then
        table.insert(entries, {
            unit = "player",
            name = UnitName("player"),
            info = myKey
        })
    end

    -- Party members
    for i = 1, GetNumGroupMembers() - 1 do
        local unit = "party" .. i
        local name = UnitName(unit)
        if name then
            local info = allKeys[name]
            if info and info.level and info.level > 0 then
                table.insert(entries, {
                    unit = unit,
                    name = name,
                    info = info
                })
            end
        end
    end

    if #entries == 0 then
        Frame:Hide()
        return
    end

    for i, entry in ipairs(entries) do
        local b = buttons[i]
        if not b then break end

        local icon, short = GetDungeonInfo(entry.info.challengeMapID)
        local r, g, bcol = GetKeyColor(entry.info.level)

        b.icon:SetTexture(icon)
        b.level:SetText("+" .. entry.info.level)
        b.level:SetTextColor(r, g, bcol)
        b.name:SetText(short .. " - " .. entry.name)

        b:Show()
        b.name:Show()
    end

    Frame:SetHeight(20 + (#entries * ENTRY_HEIGHT))
    Frame:Show()
end

--------------------------------------------------
-- EVENTS
--------------------------------------------------
local e = CreateFrame("Frame")
e:RegisterEvent("PLAYER_ENTERING_WORLD")
e:RegisterEvent("GROUP_ROSTER_UPDATE")
e:RegisterEvent("ADDON_LOADED")

e:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_GroupFinder" then
        Frame:SetPoint("TOPRIGHT", PVEFrame, "BOTTOMRIGHT", 0, 0)
    end
    C_Timer.After(0.5, Update)
end)

--------------------------------------------------
-- Chat command: /ks [say|group|guild|raid]
--------------------------------------------------
SLASH_PARTYKEYSTONETRACKER1 = "/ks"

SlashCmdList.PARTYKEYSTONETRACKER = function(msg)
    msg = (msg or ""):lower()

    if not LibOpenRaid then
        print("|cffff0000[Keys]|r LibOpenRaid not available.")
        return
    end

    --------------------------------------------------
    -- Determine output channel
    --------------------------------------------------
    local channel
    if msg == "say" then
        channel = "SAY"
    elseif msg == "guild" then
        channel = IsInGuild() and "GUILD" or nil
    elseif msg == "raid" then
        channel = IsInRaid() and "RAID" or nil
    elseif msg == "group" then
        if IsInRaid() then
            channel = "RAID"
        elseif IsInGroup() then
            channel = "PARTY"
        end
    end

    --------------------------------------------------
    -- Collect keystones
    --------------------------------------------------
    local entries = {}

    local myKey = LibOpenRaid.GetKeystoneInfo("player")
    if myKey and myKey.level and myKey.level > 0 then
        table.insert(entries, {
            name = UnitName("player"),
            level = myKey.level,
            mapID = myKey.challengeMapID,
        })
    end

    if IsInGroup() then
        local allKeys = LibOpenRaid.GetAllKeystonesInfo()
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            local name, realm = UnitName(unit)
            if name then
                local fullName = realm and realm ~= "" and name .. "-" .. realm or name
                local info = allKeys[fullName] or allKeys[name]
                if info and info.level and info.level > 0 then
                    table.insert(entries, {
                        name = name,
                        level = info.level,
                        mapID = info.challengeMapID,
                    })
                end
            end
        end
    end

    if #entries == 0 then
        print("|cffaaaaaa[Keys]|r No Mythic+ keys found.")
        return
    end

    --------------------------------------------------
    -- Sort by level
    --------------------------------------------------
    table.sort(entries, function(a, b)
        return a.level > b.level
    end)

    --------------------------------------------------
    -- Build output lines
    --------------------------------------------------
    local lines = {}
    table.insert(lines, "Party Mythic+ Keys:")

    for _, entry in ipairs(entries) do
        local dungeonName = "???"
        if entry.mapID then
            local name = C_ChallengeMode.GetMapUIInfo(entry.mapID)
            dungeonName = name or "???"
        end

        table.insert(lines, string.format(
            "+%d %s - %s",
            entry.level,
            dungeonName,
            entry.name
        ))
    end

    --------------------------------------------------
    -- Output
    --------------------------------------------------
    if channel then
        for _, line in ipairs(lines) do
            SendChatMessage(line, channel)
        end
    else
        -- Default: print locally
        print("|cff00ff00[Party Keys]|r")
        for _, line in ipairs(lines) do
            print(line)
        end
        print("|cffaaaaaaUse /ks say | group | guild | raid|r")
    end
end

--------------------------------------------------
-- LibOpenRaid callback
--------------------------------------------------
LibOpenRaid.RegisterCallback(addonName, "KeystoneUpdate", function()
    C_Timer.After(0.5, Update)
end)
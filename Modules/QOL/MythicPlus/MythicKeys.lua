--------------------------------------------------
-- MythicKeys.lua — Groupe M+ Key Viewer
-- Style: AstralKeys-inspired visual rows
--   [Dungeon Icon] [Player Name] [Dungeon] [+Level]
--
-- Protocols supported:
--   1) TMKeyTracker  — TomoMod users
--   2) AstralKeys    — most popular key addon
--   3) AngryKeystones
--   4) Chat keystone link parser (no addon needed)
--------------------------------------------------

local ADDON_PREFIX  = "TMKeyTracker"
local ASTRAL_PREFIX = "AstralKeys"
local ANGRY_PREFIX  = "AngryKeystones"

local SCAN_COOLDOWN = 5
local MAX_MEMBERS   = 5

-- Fonts & Assets
local FONT_BOLD   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local FONT_MED    = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local BORDER_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\border.png"

-- Colors
local COLOR_TEAL  = { r=0.05, g=0.82, b=0.62 }
local COLOR_RESET = "|r"

MK = MK or {}
MK.enabled   = false
MK.keyData   = {}   -- [shortName] = { mapID, mapName, level, classFile, source }
MK.chatLines = {}

local lastScan    = 0
local autoTicker  = nil
local MainFrame   = nil
local MiniFrame   = nil
local rowFrames   = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function GetSettings()
    if not TomoModDB or not TomoModDB.MythicKeys then return nil end
    return TomoModDB.MythicKeys
end

local function GetLevelColor(level)
    if not level then return 1, 1, 1 end
    if level >= 20 then return 1.0, 0.50, 0.00
    elseif level >= 15 then return 0.64, 0.21, 0.93
    elseif level >= 10 then return 0.40, 0.70, 1.00
    else return 0.40, 1.00, 0.40 end
end

local function GetLevelTierLabel(level)
    if not level then return "" end
    if level >= 20 then return "[+++]" end
    if level >= 15 then return "[++]" end
    if level >= 10 then return "[+]" end
    return ""
end

local function GetAddonChannel()
    if IsInGroup(LE_LFG_LIST_CATEGORY) then return "INSTANCE_CHAT"
    elseif IsInRaid() then return "RAID"
    elseif IsInGroup() then return "PARTY"
    end
    return nil
end

local function GetChatChannel()
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

-- Guild chat available when player is in a guild
local function CanSendGuild()
    return IsInGuild() and (GetGuildInfo("player") ~= nil)
end

local function GetGroupMembers()
    local members = {}
    local myName  = UnitName("player")
    local added   = {}

    if not IsInGroup() then
        local _, classFile = UnitClass("player")
        table.insert(members, { name = myName, unit = "player", classFile = classFile })
        return members
    end

    local total = GetNumGroupMembers()
    for i = 1, total do
        local unit
        if IsInRaid() then
            unit = "raid" .. i
        else
            unit = (i < total) and ("party" .. i) or "player"
        end
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and not added[name] then
                added[name] = true
                local _, classFile = UnitClass(unit)
                table.insert(members, { name = name, unit = unit, classFile = classFile })
            end
        end
        if #members >= MAX_MEMBERS then break end
    end

    if not added[myName] and #members < MAX_MEMBERS then
        local _, classFile = UnitClass("player")
        table.insert(members, { name = myName, unit = "player", classFile = classFile })
    end

    return members
end

local function GetDungeonTexture(mapID)
    if not mapID or not C_ChallengeMode or not C_ChallengeMode.GetMapUIInfo then return nil end
    local ok, _, _, _, tex = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
    return (ok and tex) or nil
end

--------------------------------------------------
-- My keystone
--------------------------------------------------

local function GetMyKeystoneInfo()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    if not mapID then return nil end
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    if not level or level == 0 then return nil end
    local mapName = TomoMod_DataKeys.GetDisplayName(mapID)
    return mapID, mapName, level
end

--------------------------------------------------
-- Store / Clear
--------------------------------------------------

local function StoreKey(name, mapID, mapName, level, classFile, source)
    if not name or not mapID or not level then return end
    local existing = MK.keyData[name]
    if existing and existing.source == "TMKey" and source ~= "TMKey" then return end
    MK.keyData[name] = {
        mapID     = mapID,
        mapName   = mapName or "???",
        level     = level,
        classFile = classFile or (existing and existing.classFile),
        source    = source or "unknown",
    }
end

local function ClearKey(name)
    MK.keyData[name] = nil
end

--------------------------------------------------
-- Protocol 1: TMKeyTracker
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
    if message == "REQUEST" then BroadcastMyKey(); return end
    if message == "NONE" then ClearKey(shortName); return end
    local sMapID, sLevel = strsplit(":", message, 3)
    local mapID = tonumber(sMapID)
    local level = tonumber(sLevel)
    if mapID and level then
        local mapName = TomoMod_DataKeys.GetDisplayName(mapID)
        StoreKey(shortName, mapID, mapName, level, nil, "TMKey")
    end
end

--------------------------------------------------
-- Protocol 2: AstralKeys
--------------------------------------------------

local function HandleAstralKeysMessage(message, sender)
    local shortSender = Ambiguate(sender, "short")
    local parts = { strsplit(":", message) }

    if #parts >= 4 then
        local mapID = tonumber(parts[3])
        local level = tonumber(parts[4])
        if mapID and mapID > 0 and level and level > 0 and level < 50 then
            local mapName = TomoMod_DataKeys.GetDisplayName(mapID)
            if not mapName:find("^ID:") then
                local rawName = parts[1] or ""
                local playerName = strsplit("-", rawName)
                if playerName and playerName ~= "" then
                    StoreKey(playerName, mapID, mapName, level, nil, "AstralKeys")
                    return
                end
            end
        end
    end

    if #parts >= 2 then
        local mapID = tonumber(parts[1])
        local level = tonumber(parts[2])
        if mapID and mapID > 0 and level and level > 0 and level < 50 then
            local mapName = TomoMod_DataKeys.GetDisplayName(mapID)
            if not mapName:find("^ID:") then
                StoreKey(shortSender, mapID, mapName, level, nil, "AstralKeys")
            end
        end
    end
end

--------------------------------------------------
-- Protocol 3: AngryKeystones
--------------------------------------------------

local function HandleAngryKeystonesMessage(message, sender)
    local shortSender = Ambiguate(sender, "short")
    local parts = { strsplit(":", message) }
    for i = 1, #parts - 1 do
        local mapID = tonumber(parts[i])
        local level = tonumber(parts[i + 1])
        if mapID and level and level > 0 and level < 50 and mapID > 100 then
            local mapName = TomoMod_DataKeys.GetDisplayName(mapID)
            if mapName then
                StoreKey(shortSender, mapID, mapName, level, nil, "AngryKeystones")
                return
            end
        end
    end
end

--------------------------------------------------
-- Protocol 4: Chat keystone link parser
--------------------------------------------------

local function ParseKeystoneLink(message, sender)
    local shortSender = Ambiguate(sender, "short")
    local mapID, level = message:match("|Hkeystone:%d+:(%d+):(%d+)")
    if not mapID then
        mapID, level = message:match("keystone:%d+:(%d+):(%d+)")
    end
    if mapID and level then
        mapID = tonumber(mapID); level = tonumber(level)
        if mapID and level and level > 0 then
            local mapName = TomoMod_DataKeys.GetDisplayName(mapID)
            if mapName then
                StoreKey(shortSender, mapID, mapName, level, nil, "ChatLink")
            end
        end
    end
end

--------------------------------------------------
-- Addon message router
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
-- Send to chat
--------------------------------------------------

local function SendKeysToChat(forceChannel)
    -- Build chat lines from current keyData if empty
    if not MK.chatLines or #MK.chatLines == 0 then
        local myName = UnitName("player")
        local data   = MK.keyData[myName]
        if not data then
            print("|cff0cd29fTomoMod Keys:|r " .. TomoMod_L["msg_keys_no_key"])
            return
        end
        -- Solo: just our own key
        local tier  = GetLevelTierLabel(data.level)
        local dname = TomoMod_DataKeys.GetDisplayName(data.mapID)
        MK.chatLines = { string.format("%s : %s +%d %s", myName, dname, data.level, tier) }
    end

    local channel = forceChannel or GetChatChannel()

    if not channel then
        -- Not in a group — try guild, else print locally
        if CanSendGuild() then
            channel = "GUILD"
        else
            -- Solo with no guild: just print to chat frame
            print("|cff0cd29f[M+ Keys]|r")
            for _, line in ipairs(MK.chatLines) do print(line) end
            return
        end
    end

    SendChatMessage("[M+ Keys]", channel)
    for _, line in ipairs(MK.chatLines) do
        SendChatMessage(line, channel)
    end
end

-- Guild variant (always sends to GUILD regardless of group)
local function SendKeysToChatGuild()
    if not CanSendGuild() then
        print("|cff0cd29fTomoMod Keys:|r Pas en guilde.")
        return
    end
    SendKeysToChat("GUILD")
end

--------------------------------------------------
-- UI helpers
--------------------------------------------------

local BCORNER = 4
local function Create9Slice(parent, r, g, b, a)
    a = a or 1
    local function T()
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetTexture(BORDER_TEX)
        if r then t:SetVertexColor(r, g, b, a) end
        return t
    end
    local tl = T(); tl:SetSize(BCORNER, BCORNER); tl:SetPoint("TOPLEFT");     tl:SetTexCoord(0,0.5,0,0.5)
    local tr = T(); tr:SetSize(BCORNER, BCORNER); tr:SetPoint("TOPRIGHT");    tr:SetTexCoord(0.5,1,0,0.5)
    local bl = T(); bl:SetSize(BCORNER, BCORNER); bl:SetPoint("BOTTOMLEFT");  bl:SetTexCoord(0,0.5,0.5,1)
    local br = T(); br:SetSize(BCORNER, BCORNER); br:SetPoint("BOTTOMRIGHT"); br:SetTexCoord(0.5,1,0.5,1)
    local top = T(); top:SetHeight(BCORNER)
    top:SetPoint("TOPLEFT",tl,"TOPRIGHT"); top:SetPoint("TOPRIGHT",tr,"TOPLEFT"); top:SetTexCoord(0.5,0.5,0,0.5)
    local bot = T(); bot:SetHeight(BCORNER)
    bot:SetPoint("BOTTOMLEFT",bl,"BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT",br,"BOTTOMLEFT"); bot:SetTexCoord(0.5,0.5,0.5,1)
    local lft = T(); lft:SetWidth(BCORNER)
    lft:SetPoint("TOPLEFT",tl,"BOTTOMLEFT"); lft:SetPoint("BOTTOMLEFT",bl,"TOPLEFT"); lft:SetTexCoord(0,0.5,0.5,0.5)
    local rgt = T(); rgt:SetWidth(BCORNER)
    rgt:SetPoint("TOPRIGHT",tr,"BOTTOMRIGHT"); rgt:SetPoint("BOTTOMRIGHT",br,"TOPRIGHT"); rgt:SetTexCoord(0.5,1,0.5,0.5)
end

local function CreateSimpleBorder(frame, r, g, b, a)
    r, g, b, a = r or 0, g or 0, b or 0, a or 0.9
    local function E(p1, p2, w, h)
        local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    E("TOPLEFT","TOPRIGHT",nil,1)
    E("BOTTOMLEFT","BOTTOMRIGHT",nil,1)
    E("TOPLEFT","BOTTOMLEFT",1,nil)
    E("TOPRIGHT","BOTTOMRIGHT",1,nil)
end

local function CreateButton(parent, w, h, label, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.10, 0.10, 0.16, 1)
    btn.bg = bg
    Create9Slice(btn, 0.22, 0.22, 0.30, 1)
    local txt = btn:CreateFontString(nil, "OVERLAY")
    txt:SetFont(FONT_MED, 10, "OUTLINE")
    txt:SetPoint("CENTER")
    txt:SetTextColor(0.85, 0.85, 0.85, 1)
    txt:SetText(label)
    btn.label = txt
    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(0.15, 0.15, 0.22, 1)
        txt:SetTextColor(COLOR_TEAL.r, COLOR_TEAL.g, COLOR_TEAL.b, 1)
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(0.10, 0.10, 0.16, 1)
        txt:SetTextColor(0.85, 0.85, 0.85, 1)
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

--------------------------------------------------
-- Key Row (360px wide × 42px tall)
--  [icon 34px] | [name / dungeon 180px] | [+level 60px]
--------------------------------------------------

local ROW_H   = 42
local FRAME_W = 360

local function CreateKeyRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(FRAME_W, ROW_H)

    -- alternating background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(
        index % 2 == 0 and 0.08 or 0.055,
        index % 2 == 0 and 0.08 or 0.055,
        index % 2 == 0 and 0.12 or 0.090,
        0.7
    )
    row.rowBg = bg

    -- ── Dungeon icon (34×34, left pad 7) ─────────────────────
    local iconHolder = CreateFrame("Frame", nil, row)
    iconHolder:SetSize(34, 34)
    iconHolder:SetPoint("LEFT", 7, 0)
    iconHolder:SetFrameLevel(row:GetFrameLevel() + 1)

    local iconBg = iconHolder:CreateTexture(nil, "BACKGROUND")
    iconBg:SetAllPoints()
    iconBg:SetColorTexture(0.12, 0.12, 0.18, 1)
    row.iconBg = iconBg

    local icon = iconHolder:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    icon:Hide()
    row.icon = icon
    row.iconHolder = iconHolder

    -- Icon 1px border
    CreateSimpleBorder(iconHolder, 0, 0, 0, 0.8)

    -- ── Player name (bold, class colored) ─────────────────────
    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(FONT_BOLD, 11, "OUTLINE")
    nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 50, -8)
    nameText:SetWidth(195)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    row.nameText = nameText

    -- ── Dungeon short name (smaller, dimmer) ──────────────────
    local dungeonText = row:CreateFontString(nil, "OVERLAY")
    dungeonText:SetFont(FONT_MED, 10, "OUTLINE")
    dungeonText:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 50, 8)
    dungeonText:SetWidth(195)
    dungeonText:SetJustifyH("LEFT")
    dungeonText:SetWordWrap(false)
    dungeonText:SetTextColor(0.55, 0.55, 0.60, 1)
    row.dungeonText = dungeonText

    -- ── Level badge (right, 58px wide) ────────────────────────
    local badge = CreateFrame("Frame", nil, row)
    badge:SetSize(58, 28)
    badge:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    badge:SetFrameLevel(row:GetFrameLevel() + 2)

    local badgeBg = badge:CreateTexture(nil, "BACKGROUND")
    badgeBg:SetAllPoints()
    badgeBg:SetColorTexture(0.05, 0.05, 0.08, 1)
    badge.bg = badgeBg
    CreateSimpleBorder(badge)

    local levelText = badge:CreateFontString(nil, "OVERLAY")
    levelText:SetFont(FONT_BOLD, 15, "OUTLINE")
    levelText:SetPoint("CENTER")
    levelText:SetJustifyH("CENTER")
    badge.text = levelText
    badge:Hide()
    row.badge = badge

    -- "—" when no key
    local noKeyText = row:CreateFontString(nil, "OVERLAY")
    noKeyText:SetFont(FONT_MED, 13, "OUTLINE")
    noKeyText:SetPoint("RIGHT", row, "RIGHT", -24, 0)
    noKeyText:SetTextColor(0.30, 0.30, 0.35, 1)
    noKeyText:SetText("—")
    noKeyText:Hide()
    row.noKeyText = noKeyText

    -- Bottom separator
    local sep = row:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT", 6, 0)
    sep:SetPoint("BOTTOMRIGHT", -6, 0)
    sep:SetColorTexture(0.12, 0.12, 0.18, 0.8)

    row:Hide()
    return row
end

local function UpdateRow(row, member, data)
    if not row then return end

    -- Name color from class
    local r, g, b = 0.80, 0.80, 0.80
    if member.classFile and RAID_CLASS_COLORS[member.classFile] then
        local c = RAID_CLASS_COLORS[member.classFile]
        r, g, b = c.r, c.g, c.b
    end
    row.nameText:SetText(member.name)
    row.nameText:SetTextColor(r, g, b, 1)

    if data then
        local tex = GetDungeonTexture(data.mapID)
        if tex then
            row.icon:SetTexture(tex)
            row.icon:Show()
        else
            row.icon:Hide()
        end

        local sName = TomoMod_DataKeys.GetShortName(data.mapID) or data.mapName
        if not sName or sName:find("^ID:") then sName = data.mapName end
        if not sName or sName:find("^ID:") then sName = "???" end
        row.dungeonText:SetText(sName)
        row.dungeonText:SetTextColor(0.60, 0.60, 0.65, 1)

        local lr, lg, lb = GetLevelColor(data.level)
        row.badge.text:SetText("+" .. data.level)
        row.badge.text:SetTextColor(lr, lg, lb, 1)
        -- Subtle tinted badge bg
        row.badge.bg:SetColorTexture(lr*0.06, lg*0.06, lb*0.06, 1)
        row.badge:Show()
        row.noKeyText:Hide()
    else
        row.icon:Hide()
        row.dungeonText:SetText(TomoMod_L["mk_no_key_self"])
        row.dungeonText:SetTextColor(0.38, 0.38, 0.42, 1)
        row.badge:Hide()
        row.noKeyText:Show()
    end

    row:Show()
end

--------------------------------------------------
-- Refresh display
--------------------------------------------------

local function BuildChatLines(members)
    local lines = {}
    for _, member in ipairs(members) do
        local data = MK.keyData[member.name]
        if data then
            local tier  = GetLevelTierLabel(data.level)
            local dname = TomoMod_DataKeys.GetDisplayName(data.mapID)
            if dname:find("^ID:") then dname = data.mapName ~= "???" and data.mapName or "???" end
            table.insert(lines, string.format("%s : %s +%d %s", member.name, dname, data.level, tier))
        else
            table.insert(lines, member.name .. " : —")
        end
    end
    return lines
end

local function RefreshDisplay()
    if not MainFrame then return end

    TomoMod_DataKeys.RefreshFromAPI()

    -- Own key
    local myName = UnitName("player")
    local mapID, mapName, level = GetMyKeystoneInfo()
    if mapID then
        -- If name still unresolved, attempt a direct API query
        if mapName:find("^ID:") then
            if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                local ok, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
                if ok and name and name ~= "" then
                    mapName = name
                else
                    mapName = "???"   -- cleaner than "ID:2441"
                end
            else
                mapName = "???"
            end
        end
        local _, myClass = UnitClass("player")
        StoreKey(myName, mapID, mapName, level, myClass, "TMKey")
    else
        ClearKey(myName)
    end

    local members = GetGroupMembers()

    for i = 1, MAX_MEMBERS do
        local row    = rowFrames[i]
        local member = members[i]
        if row then
            if member then
                local data = MK.keyData[member.name]
                if data and member.classFile and not data.classFile then
                    data.classFile = member.classFile
                end
                if data and data.classFile then member.classFile = data.classFile end
                UpdateRow(row, member, data)
            else
                row:Hide()
            end
        end
    end

    MK.chatLines = BuildChatLines(members)

    -- Update guild button color (grayed when not in guild)
    if MainFrame and MainFrame.guildBtn then
        if CanSendGuild() then
            MainFrame.guildBtn.label:SetTextColor(0.67, 0.87, 1.0, 1)
        else
            MainFrame.guildBtn.label:SetTextColor(0.40, 0.40, 0.45, 1)
        end
    end

    -- Dynamic height
    local visCount  = math.min(#members, MAX_MEMBERS)
    local HEADER_H  = 32
    local FOOTER_H  = 46
    local PAD       = 8
    local newH = HEADER_H + 2 + PAD + (visCount * ROW_H) + PAD + FOOTER_H
    MainFrame:SetHeight(math.max(newH, 150))

    -- Mini frame text update
    if MiniFrame and MiniFrame:IsShown() and MiniFrame.text then
        local txt = ""
        for _, member in ipairs(members) do
            local data = MK.keyData[member.name]
            local cf   = member.classFile
            local hex  = "cccccc"
            if cf and RAID_CLASS_COLORS[cf] then
                local c = RAID_CLASS_COLORS[cf]
                hex = string.format("%02x%02x%02x", c.r*255, c.g*255, c.b*255)
            end
            if data then
                local lr, lg, lb = GetLevelColor(data.level)
                local lhex = string.format("%02x%02x%02x", lr*255, lg*255, lb*255)
                local sn = TomoMod_DataKeys.GetShortName(data.mapID) or data.mapName
                txt = txt .. string.format("|cff%s%s|r  |cff%s+%d|r  %s\n", hex, member.name, lhex, data.level, sn)
            else
                txt = txt .. string.format("|cff%s%s|r  |cff444444—|r\n", hex, member.name)
            end
        end
        MiniFrame.text:SetText(txt)
    end
end

--------------------------------------------------
-- Scan
--------------------------------------------------

local function ScanGroupKeys(force)
    if not force and (GetTime() - lastScan < SCAN_COOLDOWN) then return end
    lastScan = GetTime()
    BroadcastMyKey()
    RequestGroupKeys()
    C_Timer.After(1.5, RefreshDisplay)
end

local function StartAutoRefresh()
    if autoTicker then return end
    autoTicker = C_Timer.NewTicker(15, function() ScanGroupKeys(false) end)
end

local function StopAutoRefresh()
    if autoTicker then autoTicker:Cancel(); autoTicker = nil end
end

MK.StartAutoRefresh = StartAutoRefresh
MK.StopAutoRefresh  = StopAutoRefresh

--------------------------------------------------
-- MAIN FRAME
--------------------------------------------------

local function CreateMainFrame()
    if MainFrame then return end

    local HEADER_H = 32
    local FOOTER_H = 46
    local PAD      = 8

    MainFrame = CreateFrame("Frame", "TomoMod_MythicKeys", UIParent)
    MainFrame:SetSize(FRAME_W, HEADER_H + 2 + PAD + ROW_H + PAD + FOOTER_H)
    MainFrame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    MainFrame:SetFrameStrata("DIALOG")
    MainFrame:SetFrameLevel(200)
    MainFrame:SetClampedToScreen(true)
    MainFrame:SetMovable(true)
    MainFrame:EnableMouse(true)
    MainFrame:RegisterForDrag("LeftButton")
    MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
    MainFrame:SetScript("OnDragStop",  MainFrame.StopMovingOrSizing)
    MainFrame:Hide()
    tinsert(UISpecialFrames, "TomoMod_MythicKeys")

    -- Root background
    local bg = MainFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.040, 0.040, 0.065, 0.97)
    Create9Slice(MainFrame)

    -- Header band
    local hdr = MainFrame:CreateTexture(nil, "ARTWORK")
    hdr:SetPoint("TOPLEFT", 1, -1)
    hdr:SetPoint("TOPRIGHT", -1, -1)
    hdr:SetHeight(HEADER_H)
    hdr:SetColorTexture(0.065, 0.065, 0.105, 1)

    -- Teal accent under header
    local accent = MainFrame:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 1, -(HEADER_H + 1))
    accent:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -1, -(HEADER_H + 1))
    accent:SetHeight(2)
    accent:SetColorTexture(COLOR_TEAL.r, COLOR_TEAL.g, COLOR_TEAL.b, 0.85)

    -- Title
    local titleTxt = MainFrame:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(FONT_BOLD, 12, "OUTLINE")
    titleTxt:SetPoint("LEFT", MainFrame, "TOPLEFT", 12, -(HEADER_H / 2))
    titleTxt:SetTextColor(COLOR_TEAL.r, COLOR_TEAL.g, COLOR_TEAL.b, 1)
    titleTxt:SetText("M+ Keys")

    -- "Multi" label
    local multiTxt = MainFrame:CreateFontString(nil, "OVERLAY")
    multiTxt:SetFont(FONT_MED, 8, "OUTLINE")
    multiTxt:SetPoint("RIGHT", MainFrame, "TOPRIGHT", -30, -(HEADER_H / 2))
    multiTxt:SetTextColor(0.30, 0.30, 0.40, 1)
    multiTxt:SetText("Multi-protocol")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, MainFrame)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -5, -6)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function() MainFrame:Hide() end)

    -- Row container
    local rowsBox = CreateFrame("Frame", nil, MainFrame)
    rowsBox:SetPoint("TOPLEFT",  MainFrame, "TOPLEFT",  0, -(HEADER_H + 2 + PAD))
    rowsBox:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", 0, -(HEADER_H + 2 + PAD))
    rowsBox:SetHeight(MAX_MEMBERS * ROW_H)
    MainFrame.rowsBox = rowsBox

    for i = 1, MAX_MEMBERS do
        local row = CreateKeyRow(rowsBox, i)
        row:SetPoint("TOPLEFT", rowsBox, "TOPLEFT", 0, -(i - 1) * ROW_H)
        rowFrames[i] = row
    end

    -- Footer separator
    local footSep = MainFrame:CreateTexture(nil, "ARTWORK")
    footSep:SetPoint("BOTTOMLEFT",  MainFrame, "BOTTOMLEFT",  1, FOOTER_H)
    footSep:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -1, FOOTER_H)
    footSep:SetHeight(1)
    footSep:SetColorTexture(0.10, 0.10, 0.16, 1)

    -- Buttons  (3 buttons across the footer)
    local btnW3 = math.floor((FRAME_W - 28) / 3)

    -- [Send groupe] — disabled visually when solo
    local sendBtn = CreateButton(MainFrame, btnW3, 28,
        TomoMod_L["mk_btn_send"],
        function() SendKeysToChat() end)
    sendBtn:SetPoint("BOTTOMLEFT", MainFrame, "BOTTOMLEFT", 8, 9)
    MainFrame.sendBtn = sendBtn

    -- [Send guilde] — always visible, grayed when not in guild
    local guildBtn = CreateButton(MainFrame, btnW3, 28,
        "|cffaaddff/g|r Guilde",
        function() SendKeysToChatGuild() end)
    guildBtn:SetPoint("LEFT", sendBtn, "RIGHT", 6, 0)
    MainFrame.guildBtn = guildBtn

    -- [Refresh]
    local refreshBtn = CreateButton(MainFrame, btnW3, 28,
        TomoMod_L["mk_btn_refresh"],
        function() ScanGroupKeys(true) end)
    refreshBtn:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -8, 9)

    MK.MainFrame = MainFrame
end

--------------------------------------------------
-- MINI FRAME
--------------------------------------------------

local function CreateMiniFrame()
    if MiniFrame then return end

    MiniFrame = CreateFrame("Frame", "TomoMod_MythicKeysMini", UIParent)
    MiniFrame:SetSize(210, 140)
    MiniFrame:Hide()

    local bg = MiniFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.040, 0.040, 0.065, 0.97)
    Create9Slice(MiniFrame)

    local title = MiniFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 10, "OUTLINE")
    title:SetPoint("TOP", 0, -6)
    title:SetTextColor(COLOR_TEAL.r, COLOR_TEAL.g, COLOR_TEAL.b, 1)
    title:SetText("M+ Keys")

    local accent = MiniFrame:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT",  MiniFrame, "TOPLEFT",  2, -20)
    accent:SetPoint("TOPRIGHT", MiniFrame, "TOPRIGHT", -2, -20)
    accent:SetHeight(1)
    accent:SetColorTexture(COLOR_TEAL.r, COLOR_TEAL.g, COLOR_TEAL.b, 0.6)

    MiniFrame.text = MiniFrame:CreateFontString(nil, "OVERLAY")
    MiniFrame.text:SetFont(FONT_MED, 10, "")
    MiniFrame.text:SetPoint("TOPLEFT", 8, -26)
    MiniFrame.text:SetWidth(194)
    MiniFrame.text:SetJustifyH("LEFT")
    MiniFrame.text:SetSpacing(4)
    MiniFrame.text:SetText("")
end

--------------------------------------------------
-- PUBLIC API
--------------------------------------------------

function MK:Enable()
    if self.enabled then return end
    self.enabled = true
    CreateMainFrame()
    CreateMiniFrame()
    local s = GetSettings()
    if s and s.autoRefresh then StartAutoRefresh() end
end

function MK:Toggle()
    if not MainFrame then
        CreateMainFrame()
        CreateMiniFrame()
    end
    if MainFrame:IsShown() then
        MainFrame:Hide()
    else
        MainFrame:Show()
        ScanGroupKeys(true)
    end
end

function MK:Refresh()
    RefreshDisplay()
end

function MK:UpdateMiniFrame()
    local s = GetSettings()
    if not s then return end
    if not s.miniFrame and MiniFrame then MiniFrame:Hide() end
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
eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_PARTY")
eventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
eventFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
pcall(C_ChatInfo.RegisterAddonMessagePrefix, ASTRAL_PREFIX)
pcall(C_ChatInfo.RegisterAddonMessagePrefix, ANGRY_PREFIX)

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)

    if event == "CHAT_MSG_ADDON" then
        OnAddonMessage(arg1, arg2, arg3, arg4)

    elseif event == "CHAT_MSG_PARTY"         or event == "CHAT_MSG_PARTY_LEADER"
        or event == "CHAT_MSG_RAID"          or event == "CHAT_MSG_RAID_LEADER"
        or event == "CHAT_MSG_INSTANCE_CHAT" or event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then
        local ok, found = pcall(function()
            if arg1 and arg2 and arg1:find("keystone:") then
                ParseKeystoneLink(arg1, arg2)
                return true
            end
        end)
        if ok and found then C_Timer.After(0.2, RefreshDisplay) end

    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_ChallengesUI" then
        CreateMiniFrame()
        if ChallengesFrame and MiniFrame then
            MiniFrame:SetPoint("TOPLEFT", ChallengesFrame, "TOPRIGHT", 8, 0)
            ChallengesFrame:HookScript("OnShow", function()
                local s = GetSettings()
                if s and s.miniFrame and MiniFrame then
                    MiniFrame:Show()
                    ScanGroupKeys(true)
                end
            end)
            ChallengesFrame:HookScript("OnHide", function()
                if MiniFrame then MiniFrame:Hide() end
            end)
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        local current = {}
        local total = GetNumGroupMembers()
        for i = 1, total do
            local unit = IsInRaid() and ("raid"..i)
                or (i < total and ("party"..i) or "player")
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name then current[name] = true end
            end
        end
        current[UnitName("player")] = true
        for name in pairs(MK.keyData) do
            if not current[name] then MK.keyData[name] = nil end
        end
        ScanGroupKeys(true)

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            BroadcastMyKey()
            RefreshDisplay()
        end)
        C_Timer.After(4, function()
            if IsInGroup() then ScanGroupKeys(true) end
        end)

    elseif event == "CHALLENGE_MODE_START" then
        StopAutoRefresh()

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        StartAutoRefresh()
        C_Timer.After(3, function() ScanGroupKeys(true) end)

    elseif event == "CHALLENGE_MODE_MAPS_UPDATE" then
        TomoMod_DataKeys.RefreshFromAPI()
        RefreshDisplay()
    end
end)

--------------------------------------------------
-- Module registration
--------------------------------------------------

TomoMod_RegisterModule("MythicKeys", MK)

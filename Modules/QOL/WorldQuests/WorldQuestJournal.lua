-- WorldQuestJournal.lua — TomoMod World Quests inside Blizzard's quest journal.
TomoMod_WorldQuestTab = TomoMod_WorldQuestTab or {}
local WQT = TomoMod_WorldQuestTab
local L = TomoMod_L

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE = "Interface\\Buttons\\WHITE8x8"
local ROW_HEIGHT, CUSTOM_MODE = 48, "TOMOMOD_WORLD_QUESTS"

local GOLD, GEAR, POWER, REP, PET, CURRENCY, ANIMA, OTHER = 1, 2, 3, 4, 5, 6, 7, 8
local SORT_TIME, SORT_ZONE, SORT_NAME, SORT_REWARD = 1, 2, 3, 4
local C = {
    bg = { 0.045, 0.047, 0.060, 0.985 }, panel = { 0.070, 0.073, 0.092, 0.97 },
    row = { 0.084, 0.088, 0.110, 0.82 }, alt = { 0.098, 0.102, 0.128, 0.82 },
    hover = { 0.180, 0.616, 0.847, 0.15 }, border = { 0.18, 0.20, 0.25, 0.92 },
    accent = { 0.180, 0.616, 0.847, 1 }, text = { 0.92, 0.94, 0.97, 1 },
    dim = { 0.56, 0.60, 0.67, 1 }, urgent = { 1.00, 0.34, 0.25, 1 },
    warning = { 1.00, 0.67, 0.16, 1 },
}
local QUALITY = {
    [Enum.WorldQuestQuality.Common] = { 0.72, 0.75, 0.80, 1 },
    [Enum.WorldQuestQuality.Rare] = { 0.00, 0.58, 1.00, 1 },
    [Enum.WorldQuestQuality.Epic] = { 0.72, 0.32, 1.00, 1 },
}

local initialized, active = false, false
local tab, panel, scroll, child, scrollbar, emptyText, countText, searchBox
local rows, cache, sortButtons = {}, {}, {}
local currentSort, ascending, search = SORT_TIME, true, ""
local refreshToken = 0

local function DB() return TomoModDB and TomoModDB.worldQuestTab end
local function Enabled() local db = DB(); return db and db.enabled end
local function Lower(value) return string.lower(tostring(value or "")) end
local function Backdrop(frame, bg, border)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(unpack(bg or C.panel)); frame:SetBackdropBorderColor(unpack(border or C.border))
end

local function TimeText(seconds)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then return L["wq_expired"] or "Expired", C.urgent end
    if seconds >= 86400 then return string.format("%dd %dh", math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600)), C.text end
    if seconds >= 3600 then return string.format("%dh %dm", math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)), C.text end
    if seconds >= 900 then return string.format("%dm", math.floor(seconds / 60)), C.warning end
    return string.format("%dm", math.max(1, math.floor(seconds / 60))), C.urgent
end

local function ClassifyReward(questID)
    for index = 1, (GetNumQuestLogRewards(questID) or 0) do
        local _, _, quantity, quality, _, itemID = GetQuestLogRewardInfo(index, questID)
        if itemID then
            local _, _, _, itemLevel, _, _, _, _, equipLoc = C_Item.GetItemInfo(itemID)
            if equipLoc and equipLoc ~= "" then
                local tip = C_TooltipInfo and C_TooltipInfo.GetQuestLogItem and C_TooltipInfo.GetQuestLogItem("reward", index, questID)
                if tip and tip.lines then
                    for _, line in ipairs(tip.lines) do
                        if line.type == Enum.TooltipDataLineType.ItemLevel and line.itemLevel then itemLevel = line.itemLevel; break end
                    end
                end
                return GEAR, itemLevel or 0, itemID, quantity or 1, quality
            end
            local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
            return classID == 17 and PET or OTHER, quantity or 1, itemID, quantity or 1, quality
        end
    end
    local currencies = C_QuestLog.GetQuestRewardCurrencies(questID)
    if currencies then
        for _, reward in ipairs(currencies) do
            if reward.currencyID then
                local anima = reward.currencyID == 1813 or reward.currencyID == 1816 or reward.currencyID == 1817 or reward.currencyID == 1728
                local amount = reward.totalRewardAmount or 0
                return anima and ANIMA or CURRENCY, amount, reward.currencyID, amount
            end
        end
    end
    local money = GetQuestLogRewardMoney(questID) or 0
    if money > 0 then return GOLD, money, nil, money end
    if C_QuestLog.GetQuestRewardReputation then
        local reputation = C_QuestLog.GetQuestRewardReputation(questID)
        if reputation and #reputation > 0 then return REP, 0, nil, 0 end
    end
    return OTHER, 0, nil, 0
end

local function RewardText(data)
    if data.rewardType == GOLD then
        local gold, silver = math.floor(data.rewardValue / 10000), math.floor(data.rewardValue % 10000 / 100)
        return gold > 0 and string.format("%dg %ds", gold, silver) or string.format("%ds", silver), 133784
    elseif data.rewardType == GEAR then
        return data.rewardValue > 0 and string.format("ilvl %d", data.rewardValue) or (L["wq_reward_gear"] or "Gear"), C_Item.GetItemIconByID(data.rewardID)
    elseif data.rewardType == CURRENCY or data.rewardType == ANIMA then
        local info = C_CurrencyInfo.GetCurrencyInfo(data.rewardID)
        return info and string.format("%d %s", data.rewardValue, info.name) or tostring(data.rewardValue), info and info.iconFileID
    elseif data.rewardID then
        return C_Item.GetItemNameByID(data.rewardID) or (L["wq_reward_other"] or "Other"), C_Item.GetItemIconByID(data.rewardID)
    elseif data.rewardType == REP then return L["wq_reward_reputation"] or "Reputation", 236681
    elseif data.rewardType == PET then return L["wq_reward_pet"] or "Pet", 132599
    end
    return L["wq_reward_other"] or "Other", 134400
end

local function Collect()
    local mapID = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if not mapID and C_Map.GetBestMapForUnit then mapID = C_Map.GetBestMapForUnit("player") end
    if not mapID then return {} end
    local list, seen = {}, {}
    local function Scan(scanMapID)
        local tasks = C_TaskQuest.GetQuestsOnMap(scanMapID)
        if not tasks then return end
        for _, info in ipairs(tasks) do
            local id = info.questID
            if id and not seen[id] and HaveQuestData(id) and QuestUtils_IsQuestWorldQuest(id) then
                seen[id] = true
                local title, factionID = C_TaskQuest.GetQuestInfoByQuestID(id)
                local tag, questMapID = C_QuestLog.GetQuestTagInfo(id), info.mapID or scanMapID
                local mapInfo, factionName = C_Map.GetMapInfo(questMapID), ""
                if factionID and factionID > 0 and C_Reputation.GetFactionDataByID then
                    local faction = C_Reputation.GetFactionDataByID(factionID); factionName = faction and faction.name or ""
                end
                local rewardType, value, rewardID, quantity, quality = ClassifyReward(id)
                list[#list + 1] = {
                    questID = id, title = title or string.format("Quest %d", id), mapID = questMapID,
                    zone = mapInfo and mapInfo.name or "", faction = factionName,
                    time = C_TaskQuest.GetQuestTimeLeftSeconds(id) or 0,
                    rewardType = rewardType, rewardValue = value, rewardID = rewardID,
                    rewardQuantity = quantity, rewardQuality = quality,
                    quality = tag and tag.quality or Enum.WorldQuestQuality.Common,
                    elite = tag and tag.isElite or false,
                }
            end
        end
    end
    Scan(mapID)
    local children = C_Map.GetMapChildrenInfo(mapID, nil, true)
    if children then for _, map in ipairs(children) do Scan(map.mapID) end end
    return list
end

local function Passes(data)
    local db = DB(); if not db then return true end
    if db.filterGold == false and data.rewardType == GOLD then return false end
    if db.filterGear == false and data.rewardType == GEAR then return false end
    if db.filterAP == false and data.rewardType == POWER then return false end
    if db.filterRep == false and data.rewardType == REP then return false end
    if db.filterPet == false and data.rewardType == PET then return false end
    if db.filterCurrency == false and data.rewardType == CURRENCY then return false end
    if db.filterAnima == false and data.rewardType == ANIMA then return false end
    if db.filterOther == false and data.rewardType == OTHER then return false end
    if (db.minTimeMinutes or 0) > 0 and data.time < db.minTimeMinutes * 60 then return false end
    if search ~= "" and not string.find(Lower(data.title .. " " .. data.zone .. " " .. data.faction), search, 1, true) then return false end
    return true
end

local function Sort(list)
    table.sort(list, function(a, b)
        if a == b then return false end
        if not a then return false end
        if not b then return true end
        local av, bv
        if currentSort == SORT_TIME then av, bv = tonumber(a.time) or 0, tonumber(b.time) or 0
        elseif currentSort == SORT_ZONE then av, bv = Lower(a.zone), Lower(b.zone)
        elseif currentSort == SORT_NAME then av, bv = Lower(a.title), Lower(b.title)
        else
            av = (tonumber(a.rewardType) or OTHER) * 1000000 + (tonumber(a.rewardValue) or 0)
            bv = (tonumber(b.rewardType) or OTHER) * 1000000 + (tonumber(b.rewardValue) or 0)
        end
        if av == bv then return (tonumber(a.questID) or 0) < (tonumber(b.questID) or 0) end
        if ascending then return av < bv end
        return av > bv
    end)
end

local function ButtonState(button, selected)
    button.selected = selected
    button.bg:SetColorTexture(unpack(selected and { C.accent[1], C.accent[2], C.accent[3], 0.23 } or C.row))
    button.label:SetTextColor(unpack(selected and C.accent or C.dim))
    button.line:SetShown(selected)
end

local function FlatButton(parent, text, width, callback)
    local button = CreateFrame("Button", nil, parent); button:SetSize(width, 22)
    button.bg = button:CreateTexture(nil, "BACKGROUND"); button.bg:SetAllPoints(); button.bg:SetColorTexture(unpack(C.row))
    button.label = button:CreateFontString(nil, "OVERLAY"); button.label:SetFont(FONT_BOLD, 9, ""); button.label:SetPoint("CENTER"); button.label:SetText(text)
    button.line = button:CreateTexture(nil, "OVERLAY"); button.line:SetHeight(2); button.line:SetPoint("BOTTOMLEFT"); button.line:SetPoint("BOTTOMRIGHT"); button.line:SetColorTexture(unpack(C.accent)); button.line:Hide()
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self) if not self.selected then self.bg:SetColorTexture(unpack(C.hover)) end end)
    button:SetScript("OnLeave", function(self) ButtonState(self, self.selected) end)
    return button
end

local function Row(parent, index)
    local row = CreateFrame("Button", nil, parent); row:SetHeight(ROW_HEIGHT)
    row.bg = row:CreateTexture(nil, "BACKGROUND"); row.bg:SetPoint("TOPLEFT", 1, -1); row.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    row.hover = row:CreateTexture(nil, "HIGHLIGHT"); row.hover:SetPoint("TOPLEFT", 1, -1); row.hover:SetPoint("BOTTOMRIGHT", -1, 1); row.hover:SetColorTexture(unpack(C.hover))
    row.quality = row:CreateTexture(nil, "ARTWORK"); row.quality:SetWidth(3); row.quality:SetPoint("TOPLEFT", 1, -1); row.quality:SetPoint("BOTTOMLEFT", 1, 1)
    row.iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate"); row.iconFrame:SetSize(34, 34); row.iconFrame:SetPoint("LEFT", 8, 0); Backdrop(row.iconFrame, C.bg, C.border)
    row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK"); row.icon:SetPoint("TOPLEFT", 2, -2); row.icon:SetPoint("BOTTOMRIGHT", -2, 2); row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.name = row:CreateFontString(nil, "OVERLAY"); row.name:SetFont(FONT_BOLD, 10, ""); row.name:SetPoint("TOPLEFT", row.iconFrame, "TOPRIGHT", 8, -2); row.name:SetPoint("RIGHT", -74, 0); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false); row.name:SetTextColor(unpack(C.text))
    row.zone = row:CreateFontString(nil, "OVERLAY"); row.zone:SetFont(FONT, 9, ""); row.zone:SetPoint("BOTTOMLEFT", row.iconFrame, "BOTTOMRIGHT", 8, 2); row.zone:SetPoint("RIGHT", -74, 0); row.zone:SetJustifyH("LEFT"); row.zone:SetWordWrap(false); row.zone:SetTextColor(unpack(C.dim))
    row.reward = row:CreateFontString(nil, "OVERLAY"); row.reward:SetFont(FONT_BOLD, 9, ""); row.reward:SetPoint("TOPRIGHT", -8, -8); row.reward:SetWidth(66); row.reward:SetJustifyH("RIGHT"); row.reward:SetWordWrap(false); row.reward:SetTextColor(unpack(C.accent))
    row.time = row:CreateFontString(nil, "OVERLAY"); row.time:SetFont(FONT, 9, ""); row.time:SetPoint("BOTTOMRIGHT", -8, 8); row.time:SetWidth(66); row.time:SetJustifyH("RIGHT")
    row:SetScript("OnEnter", function(self)
        if not self.data then return end
        local reward = RewardText(self.data)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.data.title, 1, 1, 1)
        GameTooltip:AddLine((L["wq_zone"] or "Zone") .. ": " .. self.data.zone, 0.68, 0.72, 0.78)
        if self.data.faction ~= "" then GameTooltip:AddLine((L["wq_faction"] or "Faction") .. ": " .. self.data.faction, 0.45, 0.82, 0.68) end
        GameTooltip:AddLine((L["wq_reward"] or "Reward") .. ": " .. reward, 0.18, 0.72, 1)
        if self.data.elite then GameTooltip:AddLine(L["wq_elite"] or "Elite World Quest", 1, 0.55, 0.16) end
        GameTooltip:AddLine(L["wq_click_hint"] or "Click: track and show on the map", 0.48, 0.52, 0.58); GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
        if not self.data then return end
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then C_SuperTrack.SetSuperTrackedQuestID(self.data.questID) end
        if WorldMapFrame and self.data.mapID then WorldMapFrame:SetMapID(self.data.mapID) end
    end)
    return row
end

local function SelectSort(id)
    if currentSort == id then ascending = not ascending else currentSort, ascending = id, true end
    for sortID, button in pairs(sortButtons) do ButtonState(button, sortID == currentSort) end
    WQT.RefreshList(false)
end

local function CreatePanel()
    if panel or not QuestMapFrame then return panel end
    local anchor = QuestMapFrame.ContentsAnchor or QuestMapFrame
    panel = CreateFrame("Frame", "TomoMod_WorldQuestJournalPanel", QuestMapFrame, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -29); panel:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -22, 0); Backdrop(panel, C.bg, C.border)
    local accent = panel:CreateTexture(nil, "OVERLAY"); accent:SetHeight(2); accent:SetPoint("TOPLEFT", 1, -1); accent:SetPoint("TOPRIGHT", -1, -1); accent:SetColorTexture(unpack(C.accent))
    local toolbar = CreateFrame("Frame", nil, panel); toolbar:SetHeight(62); toolbar:SetPoint("TOPLEFT", 1, -2); toolbar:SetPoint("TOPRIGHT", -1, -2)
    local toolbarBG = toolbar:CreateTexture(nil, "BACKGROUND"); toolbarBG:SetAllPoints(); toolbarBG:SetColorTexture(unpack(C.panel))
    local title = toolbar:CreateFontString(nil, "OVERLAY"); title:SetFont(FONT_BOLD, 12, ""); title:SetPoint("TOPLEFT", 8, -8); title:SetText(L["wq_panel_title"] or "World Quests"); title:SetTextColor(unpack(C.text))
    local refresh = FlatButton(toolbar, L["wq_refresh_short"] or "R", 22, function() WQT.RefreshList(true) end); refresh:SetPoint("TOPRIGHT", -7, -5)
    searchBox = CreateFrame("EditBox", nil, toolbar, "BackdropTemplate"); searchBox:SetHeight(22); searchBox:SetPoint("TOPLEFT", title, "TOPRIGHT", 8, 3); searchBox:SetPoint("RIGHT", refresh, "LEFT", -5, 0); searchBox:SetAutoFocus(false); searchBox:SetFont(FONT, 9, ""); searchBox:SetTextInsets(6, 5, 0, 0); searchBox:SetTextColor(unpack(C.text)); Backdrop(searchBox, C.bg, C.border)
    searchBox.hint = searchBox:CreateFontString(nil, "OVERLAY"); searchBox.hint:SetFont(FONT, 9, ""); searchBox.hint:SetPoint("LEFT", 6, 0); searchBox.hint:SetText(SEARCH or "Search"); searchBox.hint:SetTextColor(unpack(C.dim))
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function(self) search = Lower(self:GetText()); self.hint:SetShown(search == ""); WQT.RefreshList(false) end)
    local defs = { { SORT_TIME, L["wq_sort_time"] or "Time" }, { SORT_REWARD, L["wq_sort_reward"] or "Reward" }, { SORT_ZONE, L["wq_sort_zone"] or "Zone" }, { SORT_NAME, L["wq_sort_name"] or "Name" } }
    local previous
    for _, def in ipairs(defs) do
        local button = FlatButton(toolbar, def[2], 62, function() SelectSort(def[1]) end)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 3, 0) else button:SetPoint("BOTTOMLEFT", 7, 5) end
        sortButtons[def[1]], previous = button, button
    end
    for id, button in pairs(sortButtons) do ButtonState(button, id == currentSort) end
    local status = CreateFrame("Frame", nil, panel); status:SetHeight(24); status:SetPoint("BOTTOMLEFT", 1, 1); status:SetPoint("BOTTOMRIGHT", -1, 1)
    local statusBG = status:CreateTexture(nil, "BACKGROUND"); statusBG:SetAllPoints(); statusBG:SetColorTexture(unpack(C.panel))
    local line = status:CreateTexture(nil, "ARTWORK"); line:SetHeight(1); line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT"); line:SetColorTexture(unpack(C.border))
    countText = status:CreateFontString(nil, "OVERLAY"); countText:SetFont(FONT, 9, ""); countText:SetPoint("LEFT", 8, 0); countText:SetTextColor(unpack(C.dim))
    scrollbar = CreateFrame("Slider", nil, panel); scrollbar:SetOrientation("VERTICAL"); scrollbar:SetWidth(10); scrollbar:SetPoint("TOPRIGHT", toolbar, "BOTTOMRIGHT", -2, -3); scrollbar:SetPoint("BOTTOMRIGHT", status, "TOPRIGHT", -2, 3); scrollbar:SetMinMaxValues(0, 0); scrollbar:SetValueStep(ROW_HEIGHT); scrollbar:SetObeyStepOnDrag(false)
    local track = scrollbar:CreateTexture(nil, "BACKGROUND"); track:SetWidth(3); track:SetPoint("TOP"); track:SetPoint("BOTTOM"); track:SetColorTexture(0, 0, 0, 0.38)
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY"); thumb:SetTexture(WHITE); thumb:SetColorTexture(unpack(C.accent)); thumb:SetSize(5, 32); scrollbar:SetThumbTexture(thumb)
    scroll = CreateFrame("ScrollFrame", nil, panel); scroll:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 3, -3); scroll:SetPoint("BOTTOMRIGHT", status, "TOPRIGHT", -13, 3)
    child = CreateFrame("Frame", nil, scroll); child:SetSize(250, 1); scroll:SetScrollChild(child); scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta) scrollbar:SetValue(scrollbar:GetValue() - delta * ROW_HEIGHT * 3) end)
    scroll:SetScript("OnSizeChanged", function(_, width) child:SetWidth(math.max(1, width)); WQT.UpdateScrollRange() end)
    scrollbar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
    emptyText = scroll:CreateFontString(nil, "OVERLAY"); emptyText:SetFont(FONT, 10, ""); emptyText:SetPoint("CENTER", panel, "CENTER", 0, -8); emptyText:SetWidth(220); emptyText:SetJustifyH("CENTER"); emptyText:SetTextColor(unpack(C.dim)); emptyText:SetText(L["wq_empty"] or "No World Quests match these filters.")
    panel:SetScript("OnShow", function() WQT.RefreshList(true) end); panel:Hide(); return panel
end

function WQT.UpdateScrollRange()
    if not scroll or not child or not scrollbar then return end
    local maximum = math.max(0, child:GetHeight() - scroll:GetHeight()); scrollbar:SetMinMaxValues(0, maximum); scrollbar:SetShown(maximum > 0)
    if scrollbar:GetValue() > maximum then scrollbar:SetValue(maximum) end
end

function WQT.RefreshList(fetch)
    if not panel or not panel:IsShown() then return end
    if fetch ~= false then cache = Collect() end
    local filtered = {}; for _, data in ipairs(cache) do if Passes(data) then filtered[#filtered + 1] = data end end; Sort(filtered)
    local maximum = (DB() and DB().maxQuestsShown) or 50; if maximum > 0 then for i = #filtered, maximum + 1, -1 do filtered[i] = nil end end
    for _, row in ipairs(rows) do row:Hide() end
    for index, data in ipairs(filtered) do
        local row = rows[index]; if not row then row = Row(child, index); rows[index] = row end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT); row:SetPoint("TOPRIGHT", 0, -(index - 1) * ROW_HEIGHT)
        row.bg:SetColorTexture(unpack(index % 2 == 0 and C.alt or C.row)); row.quality:SetColorTexture(unpack(QUALITY[data.quality] or QUALITY[Enum.WorldQuestQuality.Common]))
        row.name:SetText((data.elite and "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:11:11:0:0|t " or "") .. data.title); row.zone:SetText(data.zone ~= "" and data.zone or data.faction)
        local reward, icon = RewardText(data); row.reward:SetText(reward); row.icon:SetTexture(icon or 134400)
        local remaining, color = TimeText(data.time); row.time:SetText(remaining); row.time:SetTextColor(unpack(color)); row.data = data; row:Show()
    end
    child:SetHeight(math.max(1, #filtered * ROW_HEIGHT)); emptyText:SetShown(#filtered == 0)
    countText:SetText(string.format(L["wq_status_count"] or "Showing %d / %d quests", #filtered, #cache)); WQT.UpdateScrollRange()
end

local function PositionTab()
    if not tab or not QuestMapFrame then return end
    tab:ClearAllPoints(); local anchor
    if QuestMapFrame.TabButtons then for _, candidate in ipairs(QuestMapFrame.TabButtons) do if candidate and candidate:IsShown() then anchor = candidate end end end
    if anchor then tab:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3) else tab:SetPoint("TOPLEFT", QuestMapFrame, "TOPRIGHT", 0, -84) end
end

local function CheckTab(checked)
    if not tab then return end
    if tab.SetChecked then tab:SetChecked(checked) end
    if tab.Icon then tab.Icon:SetAlpha(checked and 1 or 0.58) end
end

local function CreateTab()
    if tab or not QuestMapFrame then return tab end
    tab = CreateFrame("Button", "TomoMod_WorldQuestJournalTab", QuestMapFrame, "LargeSideTabButtonTemplate")
    if SidePanelTabButtonMixin then Mixin(tab, SidePanelTabButtonMixin) end
    tab.displayMode, tab.activeAtlas, tab.inactiveAtlas = CUSTOM_MODE, "Worldquest-icon", "Worldquest-icon"
    if tab.Icon then tab.Icon:SetAtlas("Worldquest-icon", true); tab.Icon:SetSize(24, 24) end
    tab:SetScript("OnMouseDown", function(self, button) if SidePanelTabButtonMixin and SidePanelTabButtonMixin.OnMouseDown then SidePanelTabButtonMixin.OnMouseDown(self, button) end end)
    tab:SetScript("OnMouseUp", function(self, button, inside) if SidePanelTabButtonMixin and SidePanelTabButtonMixin.OnMouseUp then SidePanelTabButtonMixin.OnMouseUp(self, button, inside) end; if button == "LeftButton" and inside then WQT.Show() end end)
    tab:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(L["wq_panel_title"] or "World Quests", 1, 1, 1); GameTooltip:Show(); if self.Icon then self.Icon:SetAlpha(1) end end)
    tab:SetScript("OnLeave", function(self) GameTooltip:Hide(); if self.Icon and not active then self.Icon:SetAlpha(0.58) end end)
    PositionTab(); CheckTab(false); return tab
end

function WQT.Show()
    if not Enabled() then return end
    CreatePanel(); CreateTab(); if not panel then return end
    if QuestMapFrame and QuestMapFrame.SetDisplayMode then QuestMapFrame:SetDisplayMode() end
    active = true; panel:Show(); CheckTab(true); WQT.RefreshList(true)
end
function WQT.Hide(returnToQuests)
    active = false; if panel then panel:Hide() end; CheckTab(false)
    if returnToQuests and QuestMapFrame and QuestMapFrame.SetDisplayMode and QuestLogDisplayMode then QuestMapFrame:SetDisplayMode(QuestLogDisplayMode.Quests) end
end
function WQT.Toggle() if active then WQT.Hide(true) else WQT.Show() end end
function WQT.IsShown() return active and panel and panel:IsShown() end

local function Register()
    CreatePanel(); CreateTab(); PositionTab()
    if EventRegistry and not WQT._modeHooked then
        WQT._modeHooked = true
        EventRegistry:RegisterCallback("QuestLog.SetDisplayMode", function(_, mode) if mode ~= nil and active then WQT.Hide(false) end; PositionTab() end, WQT)
    end
    local questLog = WorldMapFrame and WorldMapFrame.QuestLog
    if questLog and not questLog._tomoWQHooked then
        questLog._tomoWQHooked = true
        questLog:HookScript("OnShow", function() PositionTab(); local db = DB(); if db and db.enabled and db.autoShow then C_Timer.After(0, WQT.Show) end end)
        questLog:HookScript("OnHide", function() active = false; if panel then panel:Hide() end; CheckTab(false) end)
    end
    local events = CreateFrame("Frame"); events:RegisterEvent("QUEST_LOG_UPDATE"); events:RegisterEvent("TASK_PROGRESS_UPDATE"); events:RegisterEvent("QUEST_DATA_LOAD_RESULT")
    events:SetScript("OnEvent", function() if active then refreshToken = refreshToken + 1; local token = refreshToken; C_Timer.After(0.2, function() if active and token == refreshToken then WQT.RefreshList(true) end end) end end)
    C_Timer.NewTicker(60, function() if active then for _, data in ipairs(cache) do data.time = C_TaskQuest.GetQuestTimeLeftSeconds(data.questID) or 0 end; WQT.RefreshList(false) end end)
end

function WQT.Initialize()
    if initialized or not Enabled() then return end
    initialized = true
    local function Ready() C_Timer.After(0, Register) end
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_WorldMap") then Ready() else EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", Ready) end
end
function WQT.ApplySettings()
    if not Enabled() then if tab then tab:Hide() end; if active then WQT.Hide(true) end; return end
    if not initialized then WQT.Initialize() end
    if tab then tab:Show(); PositionTab() end
    if active then WQT.RefreshList(true) end
end

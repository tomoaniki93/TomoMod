-- =====================================
-- TooltipIDs.lua
-- Affiche les IDs de sorts, items, buffs/debuffs,
-- enchantements, montures, talents, etc. dans les tooltips
-- =====================================

TomoMod_TooltipIDs = TomoMod_TooltipIDs or {}
local TID = TomoMod_TooltipIDs

-- =====================================
-- VARIABLES
-- =====================================
local isInitialized = false
local COLOR = "|cff00ccff"  -- cyan
local LABEL_SPELL = "Spell ID:"
local LABEL_ITEM  = "Item ID:"
local LABEL_AURA  = "Aura ID:"
local LABEL_QUEST = "Quest ID:"
local LABEL_NPC   = "NPC ID:"
local LABEL_MOUNT = "Mount ID:"
local LABEL_CURRENCY = "Currency ID:"
local LABEL_ACHIEVEMENT = "Achievement ID:"

-- Track what we already added to avoid duplicates on tooltip refresh
local addedIDs = {}

-- =====================================
-- HELPERS
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.tooltipIDs then return nil end
    return TomoModDB.tooltipIDs
end

local function AddLine(tooltip, label, id)
    if not tooltip or not id then return end
    local key = label .. tostring(id)
    if addedIDs[key] then return end
    addedIDs[key] = true
    tooltip:AddLine(COLOR .. label .. " |r" .. id)
    tooltip:Show()
end

-- Extract NPC ID from GUID: "Creature-0-xxxx-xxxx-xxxx-xxxxxx-NPCID-xxxx"
local function GetNPCIDFromGUID(guid)
    if not guid then return nil end
    local _, _, _, _, _, npcID = strsplit("-", guid)
    return tonumber(npcID)
end

-- =====================================
-- TOOLTIP HOOKS
-- =====================================

-- Spells (action bar, spellbook)
local function OnTooltipSetSpell(tooltip, data)
    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.showSpellID then return end

    if data and data.id then
        AddLine(tooltip, LABEL_SPELL, data.id)
    end
end

-- Items (bags, equipped, links)
local function OnTooltipSetItem(tooltip, data)
    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.showItemID then return end

    if data and data.id then
        AddLine(tooltip, LABEL_ITEM, data.id)
    end
end

-- Units (NPCs, players)
local function OnTooltipSetUnit(tooltip, data)
    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.showNPCID then return end

    local _, unit = tooltip:GetUnit()
    if not unit then return end

    -- TWW: unit can be a secret value in combat
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or isPlayer then return end

    local ok2, guid = pcall(UnitGUID, unit)
    if not ok2 or not guid then return end

    local npcID = GetNPCIDFromGUID(guid)
    if npcID then
        AddLine(tooltip, LABEL_NPC, npcID)
    end
end

-- Auras (buffs/debuffs via SetUnitAura / SetUnitBuffByAuraInstanceID etc.)
local function HookAuraTooltip(tooltip)
    -- Hook SetUnitBuff
    if tooltip.SetUnitBuff then
        hooksecurefunc(tooltip, "SetUnitBuff", function(self, unit, index, filter)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showSpellID then return end
            local data = C_UnitAuras.GetBuffDataByIndex(unit, index, filter)
            if data and data.spellId then
                AddLine(self, LABEL_AURA, data.spellId)
            end
        end)
    end

    -- Hook SetUnitDebuff
    if tooltip.SetUnitDebuff then
        hooksecurefunc(tooltip, "SetUnitDebuff", function(self, unit, index, filter)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showSpellID then return end
            local data = C_UnitAuras.GetDebuffDataByIndex(unit, index, filter)
            if data and data.spellId then
                AddLine(self, LABEL_AURA, data.spellId)
            end
        end)
    end

    -- Hook SetUnitBuffByAuraInstanceID (TWW)
    if tooltip.SetUnitBuffByAuraInstanceID then
        hooksecurefunc(tooltip, "SetUnitBuffByAuraInstanceID", function(self, unit, auraInstanceID)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showSpellID then return end
            local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
            if data and data.spellId then
                AddLine(self, LABEL_AURA, data.spellId)
            end
        end)
    end

    -- Hook SetUnitDebuffByAuraInstanceID (TWW)
    if tooltip.SetUnitDebuffByAuraInstanceID then
        hooksecurefunc(tooltip, "SetUnitDebuffByAuraInstanceID", function(self, unit, auraInstanceID)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showSpellID then return end
            local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
            if data and data.spellId then
                AddLine(self, LABEL_AURA, data.spellId)
            end
        end)
    end
end

-- Quests (QuestMapLogTitleButton, etc.)
local function HookQuestTooltip()
    if QuestMapFrame and QuestMapFrame.QuestsFrame then
        hooksecurefunc("QuestMapLogTitleButton_OnEnter", function(self)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showQuestID then return end
            local questID = self.questID
            if questID then
                AddLine(GameTooltip, LABEL_QUEST, questID)
            end
        end)
    end
end

-- Mounts
local function HookMountTooltip()
    if MountJournal and MountJournal.ListScrollbox then
        -- TWW uses ScrollBox
        hooksecurefunc("MountJournal_UpdateDetailedMountTooltip", function(self)
            -- not all versions have this
        end)
    end
    -- Hook via MountJournal selected mount display
    if MountJournal then
        hooksecurefunc("MountJournal_ShowMountTooltip", function(self, mountID)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showMountID then return end
            if mountID then
                AddLine(GameTooltip, LABEL_MOUNT, mountID)
            end
        end)
    end
end

-- Currency
local function HookCurrencyTooltip(tooltip)
    if tooltip.SetCurrencyByID then
        hooksecurefunc(tooltip, "SetCurrencyByID", function(self, currencyID)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showCurrencyID then return end
            if currencyID then
                AddLine(self, LABEL_CURRENCY, currencyID)
            end
        end)
    end
    if tooltip.SetCurrencyToken then
        hooksecurefunc(tooltip, "SetCurrencyToken", function(self, index)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showCurrencyID then return end
            local info = C_CurrencyInfo.GetCurrencyListInfo(index)
            if info and info.currencyID then
                AddLine(self, LABEL_CURRENCY, info.currencyID)
            end
        end)
    end
end

-- Achievement
local function HookAchievementTooltip(tooltip)
    if tooltip.SetAchievementByID then
        hooksecurefunc(tooltip, "SetAchievementByID", function(self, achievementID)
            local settings = GetSettings()
            if not settings or not settings.enabled or not settings.showAchievementID then return end
            if achievementID then
                AddLine(self, LABEL_ACHIEVEMENT, achievementID)
            end
        end)
    end
end

-- Clear tracked IDs when tooltip is cleared
local function OnTooltipCleared(tooltip)
    wipe(addedIDs)
end

-- =====================================
-- INITIALIZATION
-- =====================================
function TID.Initialize()
    if isInitialized then return end
    if not TomoModDB or not TomoModDB.tooltipIDs then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Use TooltipDataProcessor for spell/item/unit (TWW standard)
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, OnTooltipSetSpell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
    end

    -- Hook aura-specific methods on GameTooltip
    HookAuraTooltip(GameTooltip)
    HookCurrencyTooltip(GameTooltip)
    HookAchievementTooltip(GameTooltip)

    -- Clear on hide
    GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)

    -- Quest hooks (pcall — may not exist in all contexts)
    pcall(HookQuestTooltip)
    pcall(HookMountTooltip)

    isInitialized = true
end

function TID.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end

    settings.enabled = enabled

    if enabled and not isInitialized then
        TID.Initialize()
    end

    if enabled then
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_tid_enabled"])
    else
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_tid_disabled"])
    end
end

function TID.Toggle()
    local settings = GetSettings()
    if not settings then return end
    TID.SetEnabled(not settings.enabled)
end

-- Export
_G.TomoMod_TooltipIDs = TID

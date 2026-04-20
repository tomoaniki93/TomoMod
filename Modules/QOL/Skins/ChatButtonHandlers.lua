-- =====================================
-- ChatButtonHandlers.lua
-- Button click handlers for the ChatFrameUI button bar.
-- Maps button labels to WoW API toggle functions.
-- Supports modifier-key switching (Ctrl/Shift/Alt).
--
-- Adapted from MayronUI ButtonHandlers.lua (Mayron, public domain).
-- =====================================

TomoMod_ChatButtonHandlers = TomoMod_ChatButtonHandlers or {}
local H = TomoMod_ChatButtonHandlers

local L = TomoMod_L or {}
local InCombatLockdown = InCombatLockdown
local UnitLevel        = UnitLevel
local UnitInBattleground = UnitInBattleground
local IsTrialAccount   = IsTrialAccount
local IsInGuild        = IsInGuild
local SHOW_TALENT_LEVEL = SHOW_TALENT_LEVEL or 10

-- =====================================
-- All available button names (used by the config dropdown)
-- =====================================

TomoMod_ChatButtonNames = {
    L["cfui_btn_character"] or "Character",
    L["cfui_btn_bags"] or "Bags",
    L["cfui_btn_friends"] or "Friends",
    L["cfui_btn_guild"] or "Guild",
    L["cfui_btn_help"] or "Help Menu",
    L["cfui_btn_pvp"] or "PVP",
    L["cfui_btn_spellbook"] or "Spell Book",
    L["cfui_btn_talents"] or "Talents",
    L["cfui_btn_achievements"] or "Achievements",
    L["cfui_btn_calendar"] or "Calendar",
    L["cfui_btn_lfd"] or "LFD",
    L["cfui_btn_raid"] or "Raid",
    L["cfui_btn_encounter"] or "Encounter Journal",
    L["cfui_btn_collections"] or "Collections Journal",
    L["cfui_btn_macros"] or "Macros",
    L["cfui_btn_worldmap"] or "World Map",
    L["cfui_btn_questlog"] or "Quest Log",
    L["cfui_btn_reputation"] or "Reputation",
    L["cfui_btn_pvpscore"] or "PVP Score",
    L["cfui_btn_currency"] or "Currency",
}

-- =====================================
-- Click handlers
-- =====================================

-- Character
H[L["cfui_btn_character"] or "Character"] = function()
    ToggleCharacter("PaperDollFrame")
end

-- Bags
H[L["cfui_btn_bags"] or "Bags"] = function()
    if ToggleAllBags then ToggleAllBags()
    elseif OpenAllBags then OpenAllBags()
    else ToggleBackpack() end
end

-- Friends
H[L["cfui_btn_friends"] or "Friends"] = function()
    ToggleFriendsFrame(FRIEND_TAB_FRIENDS)
end

-- Guild
H[L["cfui_btn_guild"] or "Guild"] = function()
    if IsTrialAccount() then return end
    if IsInGuild() then
        if ToggleGuildFrame then ToggleGuildFrame()
        elseif ToggleFriendsFrame then ToggleFriendsFrame(2) end
    end
end

-- Help Menu
H[L["cfui_btn_help"] or "Help Menu"] = function()
    ToggleHelpFrame()
end

-- PVP
H[L["cfui_btn_pvp"] or "PVP"] = function()
    if (UnitLevel("player") or 0) < 10 then return end
    if TogglePVPUI then TogglePVPUI() end
end

-- Spell Book
H[L["cfui_btn_spellbook"] or "Spell Book"] = function()
    if ToggleSpellBook then ToggleSpellBook(BOOKTYPE_SPELL)
    elseif SpellBookFrame then ToggleFrame(SpellBookFrame) end
end

-- Talents
H[L["cfui_btn_talents"] or "Talents"] = function()
    if (UnitLevel("player") or 0) < SHOW_TALENT_LEVEL then return end
    if ToggleTalentFrame then ToggleTalentFrame()
    elseif PlayerTalentFrame then ToggleFrame(PlayerTalentFrame) end
end

-- Achievements
H[L["cfui_btn_achievements"] or "Achievements"] = function()
    if ToggleAchievementFrame then ToggleAchievementFrame() end
end

-- Calendar
H[L["cfui_btn_calendar"] or "Calendar"] = function()
    if ToggleCalendar then ToggleCalendar() end
end

-- LFD
H[L["cfui_btn_lfd"] or "LFD"] = function()
    if ToggleLFDParentFrame then ToggleLFDParentFrame() end
end

-- Raid
H[L["cfui_btn_raid"] or "Raid"] = function()
    if ToggleRaidFrame then ToggleRaidFrame() end
end

-- Encounter Journal
H[L["cfui_btn_encounter"] or "Encounter Journal"] = function()
    if ToggleEncounterJournal then ToggleEncounterJournal() end
end

-- Collections Journal
H[L["cfui_btn_collections"] or "Collections Journal"] = function()
    if ToggleCollectionsJournal then ToggleCollectionsJournal() end
end

-- Macros
H[L["cfui_btn_macros"] or "Macros"] = function()
    if not MacroFrame then
        if C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_MacroUI")
        elseif LoadAddOn then LoadAddOn("Blizzard_MacroUI") end
    end
    if MacroFrame then ToggleFrame(MacroFrame) end
end

-- World Map
H[L["cfui_btn_worldmap"] or "World Map"] = function()
    if ToggleWorldMap then ToggleWorldMap() end
end

-- Quest Log
H[L["cfui_btn_questlog"] or "Quest Log"] = function()
    if ToggleQuestLog then ToggleQuestLog() end
end

-- Reputation
H[L["cfui_btn_reputation"] or "Reputation"] = function()
    ToggleCharacter("ReputationFrame")
end

-- PVP Score
H[L["cfui_btn_pvpscore"] or "PVP Score"] = function()
    if not UnitInBattleground("player") then return end
    if ToggleWorldStateScoreFrame then ToggleWorldStateScoreFrame() end
end

-- Currency
H[L["cfui_btn_currency"] or "Currency"] = function()
    ToggleCharacter("TokenFrame")
end

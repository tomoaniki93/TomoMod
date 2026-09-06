-- .luacheckrc — TomoMod static analysis config (Lua 5.1 / WoW Midnight)
--
-- Run locally:   luacheck .
-- CI runs the same on every push (see .github/workflows/ci.yml).
--
-- Design notes:
--  * std = "lua51" enforces the Lua 5.1 surface, so 5.2+ constructs the addon
--    must avoid (table.unpack, goto, bitwise operators, string.pack, ...) are
--    reported automatically.
--  * Warning 113 ("accessing an undefined global") is DISABLED: bundling a full
--    WoW API list is impractical, so read_globals below is a documented starting
--    point, not an exhaustive list.
--  * Warnings 111/112 ("setting/mutating an undefined global") are KEPT, so a
--    forgotten `local` -- which leaks a global and is a real taint hazard in WoW
--    -- is still caught. When you add a new TomoMod_* module global, add it to
--    the `globals` list below, otherwise luacheck will flag its assignment.
--  * "Redefining a local" (411) and the shadowing family (421/431/432) are off:
--    they are pervasive, intentional style across this codebase. Trailing-
--    whitespace cosmetics (611/612/614) are off too. unused_args is off because
--    WoW event handlers (self, event, unit, ...) routinely ignore trailing args.

std = "lua51"
codes = true
max_line_length = false

-- Third-party libraries are vendored and vetted upstream; do not lint them.
exclude_files = {
    "Libs/",
}

ignore = {
    "113",  -- accessing an undefined global (WoW API surface intentionally not enumerated)
    "411",  -- redefining a local (pervasive, intentional style here)
    "421",  -- shadowing a local
    "431",  -- shadowing an upvalue
    "432",  -- shadowing an upvalue argument
    "611",  -- line contains trailing whitespace
    "612",  -- line contains trailing whitespace in a comment
    "614",  -- trailing whitespace in a string
}

unused_args = false

-- Globals TomoMod reads/writes: its own module registry & public API (TomoMod_*),
-- SavedVariables, and config panels; plus a handful of Blizzard globals it
-- legitimately writes to or overrides (StaticPopupDialogs / ColorPickerFrame /
-- ClickCastFrames / ScriptErrorsFrame registries, SlashCmdList, FCF_* chat funcs).
-- Add a line here whenever you introduce a new TomoMod_* module global.
globals = {
    "ClickCastFrames", "ColorPickerFrame", "CompanionStatusDB", "FCF_FadeInChatFrame",
    "FCF_FadeInScrollbar", "FCF_FadeOutChatFrame", "FCF_FadeOutScrollbar", "FCF_StartDragging",
    "FCF_StopDragging", "GetMinimapShape", "SLASH_COMPANIONSTATUS1", "SLASH_TOMOCDMDEBUG1",
    "SLASH_TOMOCDMPROCGLOW1", "SLASH_TOMOCDMSCAN1", "SLASH_TOMODIAG1", "SLASH_TOMODIAG2",
    "SLASH_TOMOMOD1", "SLASH_TOMOMOD2", "SLASH_TOMOMODARTRACKER1", "SLASH_TOMOMOD_KB1",
    "SLASH_TOMOMOD_RL1", "SLASH_TOMOMYTHICTRACKER1", "SLASH_TOMOPRESET1", "ScriptErrorsFrame",
    "SlashCmdList", "StaticPopupDialogs", "TomoModConfigFrame", "TomoModDB",
    "TomoModItemScanTipTextLeft", "TomoModNPQuestScanTipTextLeft", "TomoMod_AFKDisplay", "TomoMod_ActionBarSkin",
    "TomoMod_ActionBars", "TomoMod_AddonDetect", "TomoMod_ArenaFrames", "TomoMod_AuctionRecipeTracker",
    "TomoMod_AuraTracker", "TomoMod_AuraTrackerDB", "TomoMod_Auras_player", "TomoMod_AutoAcceptInvite",
    "TomoMod_AutoFillDelete", "TomoMod_AutoQuest", "TomoMod_AutoSkipRole", "TomoMod_AutoSummon",
    "TomoMod_BagBank", "TomoMod_BagCategories", "TomoMod_BagMicroMenu", "TomoMod_BagSkin",
    "TomoMod_BlizzardAuraFrames", "TomoMod_BossFrames", "TomoMod_BuffSkin", "TomoMod_CDMKeybinds", "TomoMod_CDMLayout",
    "TomoMod_CDMProcGlow", "TomoMod_CDMScanner", "TomoMod_CVarOptimizer", "TomoMod_Castbar",
    "TomoMod_CastbarSpark", "TomoMod_CharacterSkin", "TomoMod_ChatButtonHandlers", "TomoMod_ChatButtonNames",
    "TomoMod_ChatFrameSkin", "TomoMod_ChatFrameSkinV2", "TomoMod_ChatFrameUI", "TomoMod_CinematicSkip",
    "TomoMod_ClassReminder", "TomoMod_CoTankTracker", "TomoMod_CombatText", "TomoMod_Compass",
    "TomoMod_Config", "TomoMod_ConfigPanel_Accueil", "TomoMod_ConfigPanel_ActionBars", "TomoMod_ConfigPanel_Castbars",
    "TomoMod_ConfigPanel_CooldownResource", "TomoMod_ConfigPanel_Diagnostics", "TomoMod_ConfigPanel_General", "TomoMod_ConfigPanel_Housing",
    "TomoMod_ConfigPanel_MythicPlus", "TomoMod_ConfigPanel_Nameplates", "TomoMod_ConfigPanel_PartyFrames", "TomoMod_ConfigPanel_Profiles",
    "TomoMod_ConfigPanel_QOL", "TomoMod_ConfigPanel_RaidFrames", "TomoMod_ConfigPanel_Skins", "TomoMod_ConfigPanel_Sound",
    "TomoMod_ConfigPanel_UnitFrames", "TomoMod_ConsumableBar", "TomoMod_CooldownManager", "TomoMod_CursorRing",
    "TomoMod_DamageMeterSkin", "TomoMod_DataKeys", "TomoMod_Defaults", "TomoMod_Diagnostics",
    "TomoMod_EnableModule", "TomoMod_FastLoot", "TomoMod_FrameAnchors", "TomoMod_GameMenuSkin",
    "TomoMod_GroupManagerSkin", "TomoMod_GroupPreview", "TomoMod_GroupStudio",
    "TomoMod_HideCastBar", "TomoMod_Housing", "TomoMod_InfoPanel", "TomoMod_InitDatabase",
    "TomoMod_Installer", "TomoMod_IsCompareOrMoneyTooltip", "TomoMod_ItemClasses", "TomoMod_L",
    "TomoMod_LevelingBar", "TomoMod_Loots", "TomoMod_LootsData", "TomoMod_LustSound",
    "TomoMod_MerchantTools", "TomoMod_MergeTables", "TomoMod_Minimap", "TomoMod_Modules",
    "TomoMod_Movers", "TomoMod_MythicHub", "TomoMod_MythicKeys", "TomoMod_MythicPartyKeys",
    "TomoMod_MythicTracker", "TomoMod_Nameplates", "TomoMod_ObjectiveTracker", "TomoMod_PartyCooldowns",
    "TomoMod_PartyFrames", "TomoMod_PartyHoTs", "TomoMod_Presets", "TomoMod_ProfessionHelper",
    "TomoMod_Profiles", "TomoMod_RFPreview", "TomoMod_RaidAuras", "TomoMod_RaidFrames",
    "TomoMod_RareAlert", "TomoMod_RegisterLocale", "TomoMod_RegisterModule", "TomoMod_ReputationBar",
    "TomoMod_ResetDatabase", "TomoMod_ResetModule", "TomoMod_ResourceBars", "TomoMod_ResurrectTracker",
    "TomoMod_SkyRide", "TomoMod_TomoScore", "TomoMod_TooltipIDs", "TomoMod_TooltipSkin",
    "TomoMod_UFPreview", "TomoMod_UF_target", "TomoMod_UnitFrames", "TomoMod_Utils",
    "TomoMod_Waypoint", "TomoMod_WhatsNew", "TomoMod_Widgets", "TomoMod_WorldQuestTab",
    "UF_Elements", "_",
}

-- Globals TomoMod only reads, provided by Blizzard or by embedded libraries.
-- Curated subset -- 113 is disabled, so this need not be complete.
read_globals = {
    -- libs / addon-provided + common WoW aliases + frequently used API
    "LibStub", "TomoMod_oUF", "format", "gsub",
    "gmatch", "gfind", "strsplit", "strjoin",
    "strtrim", "strmatch", "strfind", "strrep",
    "strupper", "strlower", "strsub", "strlen",
    "strconcat", "strrev", "wipe", "tinsert",
    "tremove", "tContains", "tIndexOf", "tDeleteItem",
    "tInvert", "max", "min", "abs",
    "floor", "ceil", "sqrt", "mod",
    "fmod", "bit", "random", "date",
    "time", "GetTime", "GetTimePreciseSec", "debugprofilestop",
    "debugstack", "geterrorhandler", "securecall", "issecure",
    "issecretvalue", "forceinsecure", "hooksecurefunc", "CopyTable",
    "Mixin", "CreateFromMixins", "CreateAndInitFromMixin", "CreateColor",
    "CreateFrame", "WrapTextInColorCode", "RGBToColorCode", "EnumUtil",
    "Enum", "Constants", "UIParent", "WorldFrame",
    "GameTooltip", "GameTooltip_SetDefaultAnchor", "GameTooltip_Hide", "InCombatLockdown",
    "UnitAffectingCombat", "IsInInstance", "IsInGroup", "IsInRaid",
    "GetNumGroupMembers", "GetNumSubgroupMembers", "UnitName", "UnitClass",
    "UnitClassBase", "UnitExists", "UnitGUID", "UnitIsUnit",
    "UnitIsPlayer", "UnitIsDead", "UnitIsDeadOrGhost", "UnitInParty",
    "UnitInRaid", "UnitIsConnected", "UnitIsVisible", "UnitCanAttack",
    "UnitReaction", "UnitLevel", "UnitHealth", "UnitHealthMax",
    "UnitGetTotalAbsorbs", "UnitPower", "UnitPowerMax", "UnitPowerType",
    "UnitHasIncomingResurrection", "GetSpellInfo", "GetSpellTexture", "GetSpellCooldown",
    "GetSpellCharges", "RegisterStateDriver", "UnregisterStateDriver", "RegisterAttributeDriver",
    "Settings", "BackdropTemplateMixin", "SecureHandlerSetFrameRef", "SecureHandlerWrapScript",
    "GetBindingKey", "SetBinding", "SaveBindings", "GetCurrentBindingSet",
    "SetOverrideBindingClick", "BINDING_HEADER", "NORMAL_FONT_COLOR", "HIGHLIGHT_FONT_COLOR",
    "GRAY_FONT_COLOR", "RAID_CLASS_COLORS", "CUSTOM_CLASS_COLORS", "PowerBarColor",
    "FACTION_BAR_COLORS", "GameFontNormal", "GameFontHighlight", "NumberFontNormal",
    "SystemFont_Shadow_Med1", "PlaySound", "PlaySoundFile", "SOUNDKIT",
    "StaticPopup_Show",
    -- C_* API namespaces actually referenced in the codebase
    "C_ActionBar", "C_AddOns", "C_AuctionHouse", "C_Bank",
    "C_BattleNet", "C_CVar", "C_CampaignInfo", "C_ChallengeMode",
    "C_ChatInfo", "C_ClassColor", "C_Club", "C_Container",
    "C_CooldownViewer", "C_CurrencyInfo", "C_Cursor", "C_CurveUtil",
    "C_DamageMeter", "C_DurationUtil", "C_EncounterStats", "C_EquipmentSet",
    "C_EventUtils", "C_FriendList", "C_Garrison", "C_GossipInfo",
    "C_GuildInfo", "C_HouseEditor", "C_Housing", "C_HousingBasicMode",
    "C_HousingCatalog", "C_HousingDecor", "C_HousingNeighborhood", "C_IncomingSummon",
    "C_Item", "C_LFGInfo", "C_Map", "C_MerchantFrame",
    "C_Minimap", "C_MountJournal", "C_MythicPlus", "C_NamePlate",
    "C_Navigation", "C_NewItems", "C_PetJournal", "C_PlayerInfo",
    "C_PvP", "C_QuestInfoSystem", "C_QuestLog", "C_RecentAllies",
    "C_Reputation", "C_Scenario", "C_ScenarioInfo", "C_Spell",
    "C_SpellBook", "C_SummonInfo", "C_SuperTrack", "C_TMT",
    "C_TaskQuest", "C_Texture", "C_Timer", "C_TooltipInfo",
    "C_ToyBox", "C_TradeSkillUI", "C_Transmog", "C_TransmogCollection",
    "C_TransmogSets", "C_UnitAuras", "C_VignetteInfo", "C_WeeklyRewards",
}

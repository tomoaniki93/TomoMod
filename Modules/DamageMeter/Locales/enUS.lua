local ADDON_NAME, TomoMod = ...

-- [MERGE] Standalone, `ns` was this addon's own private table. Embedded, the
-- vararg hands over TomoMod's, which every other file in the suite shares --
-- so 157 generic names (db, L, FONT, BG, ACCENT, Refresh, windows, inCombat)
-- would sit in the same table as everything TomoMod ever adds. Nothing
-- collides today, but the first core file that reaches for `ns.db` would
-- find this module's and neither would know.
--
-- One sub-table keeps the module's world to itself, and leaves every `ns.X`
-- below untouched.
local ns = TomoMod.DM

----------------------------------------------------------------------
-- Localization: English (default / fallback)
----------------------------------------------------------------------

local L = {}
ns.L = L

-- General
L["ADDON_NAME"] = "TomoDamageMeter"
L["ADDON_SHORT"] = "Tomo"
L["ADDON_PREFIX"] = "|cffe0115fTomo DM :|r "

-- Meter types
L["DPS"] = "DPS"
L["HPS"] = "HPS"
L["DAMAGE_TAKEN"] = "Damage Taken"
L["AVOIDABLE"] = "Avoidable"
L["ENEMY_DAMAGE"] = "Enemy Damage"
L["ABSORBS"] = "Absorbs"
L["INTERRUPTS"] = "Interrupts"
L["DISPELS"] = "Dispels"
L["DEATHS"] = "Deaths"

-- Categories
L["DAMAGE"] = "Damage"
L["HEALING"] = "Healing"
L["ACTIONS"] = "Actions"

-- Sessions
L["CURRENT"] = "Current"
L["OVERALL"] = "Overall"

-- Header / UI
L["RESET"] = "Reset"
L["LOCK"] = "Lock"
L["UNLOCK"] = "Unlock"
L["SETTINGS"] = "Settings"
L["REPORT"] = "Report"
L["CLOSE"] = "Close"

-- Format labels
L["FMT_COMPACT"] = "Compact"
L["FMT_1DEC"] = "1 Dec"
L["FMT_2DEC"] = "2 Dec"
L["FMT_3DEC"] = "3 Dec"
L["FMT_REGULAR"] = "Regular"
L["FMT_INT"] = "Int"
L["FMT_DEC"] = "Dec"

-- Report
L["REPORT_HEADER"] = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"] = "No whisper target. Select a player first."
L["REPORT_NO_DATA"] = "No data to report."
L["REPORT_CHANNEL_SAY"] = "Say"
L["REPORT_CHANNEL_PARTY"] = "Party"
L["REPORT_CHANNEL_RAID"] = "Raid"
L["REPORT_CHANNEL_GUILD"] = "Guild"
L["REPORT_CHANNEL_WHISPER"] = "Whisper"
L["REPORT_CHANNEL_AUTO"] = "Auto (group)"
L["REPORT_CHANNEL_INSTANCE"] = "Instance"
L["REPORT_CHANNEL_SELF"] = "Print to self"
L["REPORT_CHANNEL_RESTRICTED"] = "Say and Yell are restricted by the game: only one addon message gets through per click. Pick a group channel in the settings."

-- Settings
L["SETTINGS_TITLE"] = "TomoDamageMeter Settings"
L["SETTINGS_GENERAL"] = "General"
L["SETTINGS_APPEARANCE"] = "Appearance"
L["SETTINGS_SKIN"] = "Skin"
L["SETTINGS_BAR_TEXTURE"] = "Bar Texture"
L["SKIN_DARK"] = "Tomo Dark"
L["SKIN_NEON"] = "Tomo Neon"
L["SKIN_MINIMAL"] = "Minimal"
L["SKIN_GLOSSY"] = "Glossy"
L["SKIN_EMBER"] = "Ember"
L["SKIN_FROST"] = "Frost"
L["SKIN_TERMINAL"] = "Terminal"
L["SKIN_VOID"] = "Void"
L["SKIN_PARCHMENT"] = "Parchment"
L["SETTINGS_COLUMNS"] = "Columns"
L["SETTINGS_FONT_SIZE"] = "Font Size"
L["SETTINGS_FONT_FACE"] = "Font"
L["SETTINGS_BAR_HEIGHT"] = "Bar Height"
L["SETTINGS_BG_OPACITY"] = "Background Opacity"
L["SETTINGS_OOC_OPACITY"] = "Out of Combat Opacity"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Spell Breakdown Opacity"
L["SETTINGS_OPACITY"] = "Opacity"
L["SETTINGS_RECAPS"] = "Recaps"
L["SETTINGS_SHOW_SELF"] = "Always show my bar"
L["SETTINGS_BAR_TOOLTIPS"] = "Bar tooltips"
L["SETTINGS_TIMER_POS"] = "Timer position"
L["SETTINGS_TIMER_LEFT"] = "Left"
L["SETTINGS_TIMER_RIGHT"] = "Right"
L["SETTINGS_AUTO_RESET"] = "Reset on entering an instance"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Show death recap automatically"
L["DM_STANDALONE"] = "The standalone TomoDamageMeter addon is installed and owns the meter; its settings are in its own window. The bundled module stands down to avoid two competing windows."
L["DM_UNAVAILABLE"] = "Blizzard's damage meter is not available on this client, so the module is inactive."
L["DM_WINDOWS_HINT"] = "Columns, adding windows and category filtering are set in the meter's own window, next to the window they affect."
L["DM_OPEN_WINDOW_SETTINGS"] = "Window settings"
L["DM_TOGGLE_WINDOWS"] = "Show / hide"
L["SETTINGS_STRIP_REALM"] = "Strip Realm Names"
L["SETTINGS_ACCENT_COLOR"] = "Accent Color"
L["SETTINGS_USE_CLASS_COLOR"] = "Use Class Color"
L["SETTINGS_REPORT_CHANNEL"] = "Report Channel"
L["SETTINGS_REPORT_LINES"] = "Report Lines"
L["SETTINGS_WINDOWS"] = "Windows"
L["SETTINGS_ADD_WINDOW"] = "+ Add"
L["SETTINGS_REMOVE_WINDOW"] = "- Remove"
L["SETTINGS_WINDOW_COUNT"] = "Windows: %d / %d"
L["SETTINGS_COL_RATE"] = "Rate (DPS/HPS)"
L["SETTINGS_COL_TOTAL"] = "Total"
L["SETTINGS_COL_PCT"] = "Percent"
L["SETTINGS_FORMAT"] = "Format"
L["SETTINGS_TAB_GENERAL"] = "General"
L["SETTINGS_TAB_WINDOW"] = "Window %d"
L["SETTINGS_METER_TYPE"] = "Meter Type"
L["SETTINGS_SESSION_TYPE"] = "Session Type"
L["SETTINGS_LOCKED"] = "Lock Position"

-- Slash commands
L["CMD_RESET"] = "Data reset."
L["CMD_LOCKED"] = "Locked"
L["CMD_UNLOCKED"] = "Unlocked"
L["CMD_HELP_HEADER"] = "Commands:"
L["CMD_HELP_TOGGLE"] = "  /tdm — open settings"
L["CMD_HELP_TOGGLE_VIS"] = "  /tdm toggle — toggle window visibility"
L["CMD_HELP_RESET"] = "  /tdm reset — reset all combat data"
L["CMD_HELP_LOCK"] = "  /tdm lock — lock/unlock window position"
L["CMD_HELP_DIAG"] = "  /tdm diag — probe C_DamageMeter value readability"
L["RUN_RECAP"] = "Run Recap"
L["RUN_RECAP_NO_DATA"] = "No run recorded"
L["RECAP_COL_INT"] = "Int."
L["RECAP_COL_DEATHS"] = "Deaths"
L["RECAP_COL_AVOIDABLE"] = "Avoid."
L["SETTINGS_RUN_RECAP_AUTO"] = "Show run recap at the end of a dungeon"
L["SETTINGS_SNAP"] = "Snap windows to each other"
L["CMD_HELP_RECAP"] = "  /tdm recap — show the last run recap"
L["CMD_DIAG_ARMED"] = "Diagnostic armed — waiting for the next combat data update."
L["CMD_HELP_HELP"] = "  /tdm help — this message"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Auto-reset on instance entry"
L["SETTINGS_COMBAT_TIMER"] = "Combat Timer (DPS/HPS)"
L["SETTINGS_SELF_BAR"] = "Pin My Own Bar"
L["SETTINGS_BAR_TOOLTIPS"] = "Bar Tooltips (hover)"
L["SETTINGS_MODULES"] = "Modules"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Death recap popup on death"
L["SETTINGS_TIMER_POSITION"] = "Combat Timer Position"
L["TIMER_POS_RIGHT"] = "Right"
L["TIMER_POS_LEFT"] = "Left"
L["SETTINGS_CATEGORIES"] = "Categories"
L["SETTINGS_CATEGORIES_MIN"] = "At least one category must remain enabled."
L["AUTO_RESET_MSG"] = "Data auto-reset (instance entry)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Settings unavailable during combat."
L["WAITING_COMBAT_END"] = "Unavailable until after combat"

-- Detail
L["SPELL_BREAKDOWN"] = "Spell Breakdown"
L["NO_DATA"] = "No data available"
L["DEATH_RECAP"] = "Death Recap"
L["DEATH_RECAP_NO_DATA"] = "No death recorded"
L["RECAP_HEAL"] = "Heal"
L["RECAP_MELEE"] = "Melee"
L["RECAP_UNKNOWN"] = "Unknown"
L["BREAKDOWN_SPELLS_LABEL"] = "spells"
L["BREAKDOWN_CRITS_LABEL"] = "crits"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crit"
L["BREAKDOWN_COL_SPELL"] = "Spell"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segments"
L["SEGMENT"] = "Segment"
L["SEGMENT_COL_NAME"] = "Encounter"
L["TARGET_BREAKDOWN"] = "Target Breakdown"
L["TARGET_COL_NAME"] = "Target"

-- Tooltips
L["TIP_SETTINGS"] = "Open settings"
L["TIP_TARGET"] = "Target breakdown"
L["TIP_DETAILS"] = "Spell breakdown"
L["TIP_LOCK"] = "Lock/unlock position"
L["TIP_REPORT"] = "Report to chat"
L["TIP_RESET"] = "Reset all data"
L["TIP_CATEGORY"] = "Click to cycle category"
L["TIP_TYPE"] = "Click to cycle meter type"
L["TIP_SESSION"] = "Click to cycle session"

-- Hover tooltips
L["TIP_TOP_SPELLS"] = "Top spells"
L["TIP_TOTAL"] = "Total"
L["TIP_OVERKILL"] = "Overkill"
L["TIP_AVOIDABLE"] = "Avoidable damage"
L["TIP_KILLING_BLOW"] = "Killing blow"
L["TIP_CAST_BY"] = "Cast by %s"
L["TIP_CLICK_BREAKDOWN"] = "Click for spell breakdown"
L["TIP_LEFT_EXPAND"] = "Left-click: show spells inline"
L["TIP_RIGHT_WINDOW"] = "Right-click: open breakdown window"

-- Font names
L["FONT_FRIZ"] = "Fritz Quadrata"
L["FONT_ARIAL"] = "Arial Narrow"
L["FONT_2002"] = "2002"
L["FONT_MORPHEUS"] = "Morpheus"
L["FONT_SKURRI"] = "Skurri"
L["FILTER_PLAYERS"] = "Filter..."

L["CMD_HELP_RESETPOS"] = "  /tdm resetpos — move the death recap back to the centre"
L["CMD_POS_RESET"] = "Death recap position reset."

-- ============================================================
-- WhatsNew.lua — "What's New" popup after addon updates
-- Compares TomoModDB.lastSeenVersion with current version.
-- Shown once per version on PLAYER_LOGIN via C_Timer.After.
--
-- [fix] The dimmer used to be orphaned on close. It is a SEPARATE
-- full-screen mouse-blocking frame (the panel is its child), and only
-- WN.Hide() ever hid it -- but the panel was registered in
-- UISpecialFrames, so Escape made Blizzard call
-- TomoModWhatsNewFrame:Hide() directly, bypassing WN.Hide(). The panel
-- vanished, the dimmer stayed: dark screen, mouse dead, nothing to
-- click. MarkSeen() lived in the same bypassed function, so the popup
-- came back on the next login instead of staying closed.
--
-- Brand-new characters hit this every time: the popup is created while
-- the intro cinematic is playing (UIParent hidden, so it is invisible
-- but shown), and the first thing the player does is press Escape to
-- skip the cinematic -- closing a window they never saw.
--
-- Three changes make that state unreachable:
--   1. dimmer and panel are created HIDDEN and only shown once the
--      content is built, so a failure mid-construction leaves nothing
--      on screen (same pattern as Config/Installer.lua).
--   2. an OnHide script on the panel is now the single authority: it
--      hides the dimmer and calls MarkSeen(), so every close path
--      (X, "Compris !", Escape, any external Hide) behaves the same.
--   3. Escape is handled on the frame itself instead of through
--      UISpecialFrames -- which also drops the ToggleGameMenu ->
--      ClearTarget() taint path documented in Core/Forge/ForgeStudio.
--
-- The popup is additionally held back while a cinematic or movie is
-- playing, while in combat, and until a character's SECOND login.
-- ============================================================

TomoMod_WhatsNew = TomoMod_WhatsNew or {}
local WN = TomoMod_WhatsNew
local L  = TomoMod_L

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local LOGO_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Logo.tga"

-- Palette (matches Installer)
local A  = { TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3] }
local BG = { 0.07,  0.07,  0.09,  0.98 }
local BD = { 0.18,  0.18,  0.22,  1    }
local TX = { 0.88,  0.90,  0.89,  1    }
local DM = { 0.48,  0.48,  0.54,  1    }

local PANEL_W = 520
local PANEL_H = 480

-- ============================================================
-- CHANGELOG DATA
-- Each version entry: { title = "...", highlights = { "...", ... } }
-- Only keep the last few versions to avoid bloating memory.
-- ============================================================

-- Published for the Changelog config page. One table, two readers: the
-- popup that shows what is new after an update, and the page that lets you
-- read any past version. A second copy would drift the first time a release
-- was added to only one of them.
local CHANGELOG
CHANGELOG = {
    {
        version = "4.0.1",
        highlights = {
            L["wn_401_chat_v4"],
            L["wn_401_chat_options"],
            L["wn_401_chat_message_opacity"],
            L["wn_401_chat_messages"],
            L["wn_401_chat_urls"],
            L["wn_401_chat_sidebar_options"],
            L["wn_401_chat_wiring"],
            L["wn_401_chat_combatlog"],
            L["wn_401_chat_journal_controls"],
            L["wn_401_chat_phase21_polish"],
            L["wn_401_chat_tabs"],
            L["wn_401_chat_native_chrome"],
            L["wn_401_chat_sidebar"],
            L["wn_401_chat_sidebar_assets"],
            L["wn_401_chat_copy"],
            L["wn_401_chat_copy_clean"],
            L["wn_401_chat_safe"],
            L["wn_401_chat_links"],
            L["wn_401_chat_mover"],
            L["wn_401_chat_community"],
            L["wn_401_bags_v4"],
            L["wn_401_bags_search_sort"],
            L["wn_401_bags_sidebar"],
            L["wn_401_bags_slots"],
            L["wn_401_bags_native"],
            L["wn_401_bags_combat"],
            L["wn_401_bags_migration"],
            L["wn_401_bags_display_mode"],
            L["wn_401_bags_options"],
            L["wn_401_bags_render"],
            L["wn_401_bags_native_restore"],
            L["wn_401_bags_interactions"],
            L["wn_401_bags_button_visibility"],
            L["wn_401_bags_empty_quality"],
            L["wn_401_bags_text_polish"],
            L["wn_401_bags_surface_polish"],
            L["wn_401_bags_fit"],
            L["wn_401_bags_slot_identity"],
            L["wn_401_mplus_score_columns"],
            L["wn_401_actionbar_negative_spacing"],
            L["wn_401_castbar_lifecycle"],
            L["wn_401_castbar_identity"],
            L["wn_401_castbar_stale"],
            L["wn_401_castbar_preview"],
            L["wn_401_raid_position"],
            L["wn_401_class_reminder_position"],
            L["wn_401_objective_chrome"],
            L["wn_401_objective_position"],
            L["wn_401_tracker_anchor"] or "Changed - The Consumable Tracker button now stays firmly docked beside the information panel clock. It follows the clock itself instead of its time text, so opening the calendar or changing the time format cannot move the button over the clock.",
            L["wn_401_tracker_sizes"] or "New - You can now set the Consumable Tracker button size and icon size separately in Options. Both sizes update immediately and are saved with your profile.",
            L["wn_401_tracker_timers"] or "Changed - Tracker timers now scale with the icons. Larger or smaller tracker icons keep timer text and timer space proportioned and readable.",
            L["wn_401_layout_cogs"],
            L["wn_401_layout_chat_route"],
            L["wn_401_layout_scaled_positions"],
            L["wn_401_layout_minimap"],
            L["wn_401_layout_secondary_frames"],
            L["wn_401_layout_mythic_tracker"],
            L["wn_401_layout_v4_anchors"],
            L["wn_401_bags_position"],
            L["wn_401_layout_v4_routes"],
            L["wn_401_layout_pixel_perfect"],
            L["wn_401_layout_nudger"],
            L["wn_401_layout_mirror"],
            L["wn_401_layout_unitframes"],
            L["wn_401_layout_font_symbols"],
            L["wn_401_tomolayout_selection"],
            L["wn_401_tomolayout_config"],
            L["wn_401_tomolayout_highlight"],
            L["wn_401_azure_identity"],
            L["wn_401_azure_movers"],
            L["wn_401_azure_mover_labels"],
            L["wn_401_azure_mover_coverage"],
            L["wn_401_azure_guard"],
            L["wn_401_blizzard_auras"],
        },
    },
    {
        version = "4.0.0",
        highlights = {
            L["wn_400_interface_workspace"] or "New — Interface is now a focused workspace in the options sidebar. Its General, Action Bars, Skins and Sound pages sit directly underneath it, while Home, Roles, Profiles and Diagnostics remain one click away. The pages themselves, their nested tabs, search and deep links work exactly as before.",
            L["wn_400_units_workspace"] or "New — Units now has the same focused workspace navigation. UnitFrames, Nameplates, Party Frames and Raid Frames are listed directly beneath Units in the sidebar, so the pages you use together stay together. Their existing controls, previews and nested tabs are unchanged.",
            L["wn_400_combat_workspace"] or "New — Combat now has the same focused workspace navigation. Cast Bars, Resources, Cooldown Forge and Mythic+ are listed directly beneath Combat in the sidebar, keeping related configuration pages together. Their existing controls, previews, nested tabs, search and deep links are unchanged.",
            L["wn_400_comfort_workspace"] or "New — Comfort is now a grouped workspace with compact in-content navigation. Automation, Players, Classes, CVars, World Quest and Other sit in a first tab row; a second row shows only the pages of the selected group and remembers the last one you used. The sidebar stays compact, including a dedicated Consumables page for the readiness tracker, while your settings, previews, nested tabs, search and direct links are unchanged.",
            L["wn_400_context_profiles"] or "New — Your profiles can now follow the content you are in. Assign one to solo play, to dungeons, to Mythic+, to raids and to PvP, and TomoMod switches to it as you go: the raid profile the moment you zone in, the Mythic+ profile the moment the key starts. An assignment can be made for one specialisation or for all of them, the more precise one wins, and a context you never assign changes nothing at all — your spec profiles keep deciding exactly as they do today. The whole thing stays off until you switch it on with /tm context on, and /tm context shows you what it currently detects and everything you have assigned.",
            L["wn_400_context_tools"] or "New — A profile swap no longer closes the tools you had open. The diagnostics panel, the addon detector and the studios stay exactly as you left them across a content change: opening a studio in a raid and then stepping into a key does not shut it. Loading a profile yourself still replaces everything, because that is what you are asking for by clicking.",
            L["wn_400_context_combat"] or "New — A content change that lands mid-pull waits. Slotting a key puts you in combat straight away, so the swap is held until the fight is over and applied then, rather than rebuilding your frames on the pull. And the two profiles are compared before anything is applied: you are only asked to reload when the swap really does change which modules are switched on — a different size, colour or position is applied on the spot, without a word.",
            L["wn_400_ready_tracker"] or "New — A readiness tracker for group content. TomoMod now watches your flask, your food buff and the oil on your weapon together, and tells you at a glance whether all three are up. It sits next to the clock under the minimap and can be opened anywhere, but it only lights up where it matters: the glyph stays white while you are solo, and turns green or red as soon as you set foot in a dungeon, a raid, a scenario or a delve.",
            L["wn_400_ready_tracker_button"] or "New — The tracker sits as a small button next to the clock under the minimap: teal when everything is up, red as soon as something is missing. Hover it to read the three lines one by one, left click to open a panel showing each buff's icon and remaining time, and right click to move the button to the other side of the clock. Carrying a weapon in each hand asks for two oils and shows you how many are on; a shield or a held off-hand item is not counted, since neither of them can be oiled. The same two settings are in Options, under General, in the information panel section.",
            L["wn_400_live_toggles"] or "New — Most of TomoMod's modules can now be switched on and off without reloading the interface. 27 of the 62 modules take effect the moment you flip the switch, instead of setting a flag and asking you to reload before anything happens. The rest still need a reload, and now they only ask when there is a real reason for it.",
            L["wn_400_combat_defer"] or "New — A switch flipped in the middle of a fight is no longer refused, nor applied halfway. A change that would have to rebuild a protected frame is held until you leave combat and applied automatically then, and TomoMod tells you it is waiting. The changes that are safe in combat — fast loot, auto-repair, the alerts and the trackers — go through immediately, because making you leave a fight to turn off automatic looting would be theatre.",
            L["wn_400_dependencies"] or "New — Modules know what they depend on. Turning one off now also turns off the ones that cannot work without it, and names them; turning one on warns you when something it needs is still off. Nothing is left half-connected in silence any more.",
            L["wn_400_reload_honest"] or "Changed — The reload prompt is no longer TomoMod's answer to every single toggle. It appears for the 14 modules that genuinely cannot undo their work while the game is running — secure buttons that may not be respawned in combat, and hooks that cannot be removed once installed — and nowhere else.",
            L["wn_400_reload_batch"] or "New — When a change really does need a reload, TomoMod asks once instead of once per click. Ticking five boxes in a row raises a single question at the end, and choosing Later keeps your answer rather than dropping it: a small banner at the top of the screen then lists what is waiting, and reloads when you are ready. Undoing a change before you reload removes it from that list on its own — putting a setting back the way it was when you logged in is no longer something you have to reload to confirm.",
            L["wn_400_inventory"] or "New — /tm modules prints everything TomoMod contains, grouped the way the options are, with each module's state and whether it can be changed live or needs a reload. /tm modules <key> flips one straight from the chat box. Useful on its own, and the fastest way to find out which of your modules are live and which are not.",
            L["wn_400_resolution_presets"] or "New - Resolution presets adapt TomoMod to 1080p, 1440p and 4K displays. They set readable font sizes from the defaults and mark your current layout so it follows a later resolution change. Use /tm resolution to inspect the detected tier and /tm resolution <tier> to apply one.",
            L["wn_400_resolution_capture"] or "New - You can capture a layout you have tuned yourself for the current screen with /tm resolution capture. A captured layout and its font sizes take priority over the computed preset whenever that tier is applied.",
            L["wn_400_selective_import"] or "New - Profile imports no longer have to be all or nothing. TomoMod can inspect an import by module group, show which settings differ from yours and identify the entries it does not recognise. Use /tm import <string> to review an import before accepting it; the selectable import panel follows with the v4 options work.",
            L["wn_400_foundation_v2"] or "Note - Underneath all of the above, TomoMod now keeps one single description of its own contents: 68 entries covering every setting it saves, in nine groups, with 29 movable elements declared. It already powers content profiles and selective imports, while the layout engine reads the same inventory instead of maintaining another slightly different list.",
        },
    },
    {
        version = "3.6.5",
        highlights = {
            L["wn_365_mplus_stats_compare"] or "Fix — The Mythic+ Studio's Statistics page no longer throws an error once you have two or more recorded runs. The run comparison card formats each run's time, and the formatter it called was not yet in scope where that card is built, so the page stopped drawing halfway through and the comparison never appeared. A fresh profile looked fine, because the card is only built from the second recorded key onward.",
            L["wn_365_mplus_compare_columns"] or "Fix — The run comparison table on the Mythic+ Studio's Statistics page draws inside its card again. Its three value columns — run A, run B and the difference — were positioned past the right-hand edge of the panel, so the row labels appeared with no figures next to them. The columns, and the two run names above them, are now placed from the card's top-left corner and stay within it.",
            L["wn_365_mplus_compare_polish"] or "New — The comparison table reads as a table: a header band, a rule in front of each column, one row in two shaded, and the figures centred under their heading. The difference column is coloured now — green when the second run is the better one, red when it is worse, grey when there is nothing to compare — using the right direction for each line: a higher key level is an improvement, and so is a lower time, death count, enemy-forces time or boss split.",
            L["wn_365_teleport_launcher"] or "Changed — The Mythic+ teleport button on your character sheet is now a small, discreet icon placed just to the left of the sheet's close button, instead of the large icon that sat in the top-right corner. It opens exactly the same teleport panel, and behaves the same way — it simply no longer competes with the character sheet's own header for your attention.",
            L["wn_365_chat_secret_channel"] or "Fix — Channel notices no longer break the chat window. The game now hands the chat handler a protected value instead of a plain name for some channel notices, and comparing such a value with text is not allowed — so working out which channel a notice belonged to could fail before the notice was ever printed. TomoMod's chat skin now checks whether the value is protected before comparing it, and join, leave, invite and wrong-password notices are handled normally again.",
        },
    },
    {
        version = "3.6.4",
        highlights = {
            L["wn_364_studio"] or "New — Mythic+ Studio: a dedicated Mythic+ window with eleven pages — Dashboard, Tracker, TomoScore, Keys, Run History, Statistics, Weekly Planner, Score Planner, Level Analysis, Season Goals and Modules. It is a separate addon, loaded only the first time you open it or when a key starts, so it costs nothing until you use it.",
            L["wn_364_open"] or "New — Open the Studio with /tmplus, or with the new button on the Mythic+ options page. The old Mythic+ window now opens the new dashboard as well; its detailed dungeon and vault view is kept and is still reachable from inside the Studio. Asking for it in combat no longer does nothing: it opens as soon as combat ends, and tells you so.",
            L["wn_364_history"] or "New — Run History records every Mythic+ key you complete from now on: dungeon, level, time, whether it was timed, deaths, affixes, score gained and boss splits. It starts empty — the game's own past runs are shown for context but are never turned into local history — and it keeps your latest 100 keys.",
            L["wn_364_statistics"] or "New — A Statistics page builds season and per-dungeon figures from that history: runs, timed rate, average time and average deaths.",
            L["wn_364_compare"] or "New — Two recorded runs can be put side by side, with their boss splits and the gap between them. Comparing runs from different dungeons is allowed: the splits are then matched by position only, and the page says so.",
            L["wn_364_weekly"] or "New — A Weekly Planner shows your three weekly dungeon slots, your best key of the week and how many more completed runs are needed to fill the next one.",
            L["wn_364_score_planner"] or "New — A Score Planner suggests the next key level to run and what it would be worth. The figure is a planning estimate: the dungeon score recorded by the game stays the reference.",
            L["wn_364_analysis"] or "New — Level Analysis breaks your history down level by level — runs, timed, success rate, average time and deaths — and points out your comfort level: the highest level where you have at least three runs and finish in time seven times out of ten.",
            L["wn_364_goals"] or "New — Season Goals tracks your score, your highest key, timed keys at a level of your choice, your total recorded runs and clearing every season dungeon at a given level, each against a target you set.",
            L["wn_364_tracker_colors"] or "New — The Mythic+ tracker can use your own colours: accent, background, header, text, enemy forces and the three timer colours. The darker and lighter shades are derived from the accent, so a single pick keeps the whole tracker consistent. Leave the option off and the tracker looks exactly as before.",
            L["wn_364_tracker_position"] or "New — The Tracker page carries a live preview of the tracker and a positioning mode that puts the real one on screen with Done, Cancel and Reset, so you can place it without starting a key. During an active key, positioning is refused rather than moving the frame you are reading.",
            L["wn_364_keys"] or "Changed — Your party's keystones, the tracker and the end-of-key scoreboard now have a page each inside the Studio. They keep running in TomoMod itself, so they still work before the Studio has ever been opened.",
            L["wn_364_mplus_appearance"] or "New — The Mythic+ Studio has an Appearance page: text size, window scale, background opacity and an accent colour of your own, with a live preview and a reset button. It changes the Studio only — your tracker colours stay where they are, on the Dungeon Tracker page.",
            L["wn_364_mplus_reward_ilvl"] or "New — Every Great Vault slot, on the dashboard and in the Weekly Planner, now shows the item level its reward would come in at, under the key level. When the game will not answer for a level, a dash is drawn rather than a guess.",
            L["wn_364_mplus_tracker_preview"] or "Changed — The tracker's real preview is now a toggle: the same button opens it and puts it away, and it closes on its own when you leave the Tracker page or close the Studio. While a key is actually running it refuses to hide, so a preview you opened beforehand cannot take the real tracker off your screen mid-run.",
            L["wn_364_hot_size"] or "Fix — Changing your HoT icon size really resizes the icons on the party and raid frames again, whether you change it with the slider on the Party Frames and Raid Frames pages or in Healer Studio. Their placement was applied correctly all along, which made it look like a display glitch: only the size was being dropped, and an icon that appeared after the change still came back at its old size.",
            L["wn_364_hot_sliders"] or "Fix — The HoT icon size and max HoTs sliders on the Party Frames and Raid Frames pages take effect immediately. They were saved to your profile but never applied to the frames on screen, so the HoT row kept its previous look until the next reload.",
            L["wn_364_hot_duration"] or "New — The seconds shown on your HoT icons can be turned off. The icon keeps its sweeping cooldown animation, so you still see the time running out; you only lose the number printed over it, which on a small icon covers most of the artwork. The choice is yours and it is set separately for party frames, raid frames and Healer Studio, so you can keep the digits on one and only the sweep on the other. Leave it on and nothing changes.",
            L["wn_364_hot_max_size"] or "Changed — HoT icons can be made much bigger: up to 50 pixels in Healer Studio instead of 30, and the HoT icon size sliders on the Party Frames and Raid Frames pages reach 50 as well instead of stopping at 20 and 16. Nothing stops an icon from covering a whole cell, which is deliberate: one large icon can be easier to read mid-pull than a row of small ones.",
            L["wn_364_mythichub_keys"] or "Fix — The old Mythic+ window no longer takes over your keyboard. It used to close on Escape, and a window that listens for keys can swallow the ones the game needs — your movement keys, jump, your keybinds — for as long as it is open. It is mouse-only now, like TomoScore and the Mythic+ Studio: close it with its X button.",
            L["wn_364_teleport_menu"] or "New — Your character sheet gains a button that opens the Mythic+ dungeon teleports for the current season, all in one place. Click a dungeon to teleport there. Teleports you have not unlocked yet are still shown, greyed out, so you can see at a glance what is left to earn. The panel follows the season on its own, and it is unavailable in combat.",
        },
    },
    {
        version = "3.6.3",
        highlights = {
            L["wn_363_aura_display"] or "Fix — Aura icons are showing again on every frame that draws them through the game's own aura display: Healer Studio indicators, the party and raid heal-over-time rows, debuff and dispel indicators, nameplate auras and unit frame auras. The display behind them was given a unit but never switched on, so it had everything it needed and still showed nothing.",
            L["wn_363_aura_spacing"] or "Fix — The spacing you set between aura icons is applied again. It was being passed to the game under the old option names, which the current aura display ignores, so every row was drawn at the game's own default gap whatever you had chosen.",
            L["wn_363_aura_size"] or "Fix — Changing the size or the number of aura icons takes effect straight away again. The change used to be applied by rebuilding the icon group, which the game no longer allows, so the icons kept their previous size until the frames were rebuilt — in practice, until a reload. Icons already on screen are now resized on the spot, not only the ones that appear afterwards.",
            L["wn_363_aura_recycle"] or "Fix — A party or raid cell, or a nameplate, that is handed to a new unit no longer keeps showing the previous unit's auras. Releasing a frame now switches its aura display off, which clears its icons, instead of only detaching the unit and leaving it watching.",
            L["wn_363_healer_studio"] or "Fix — Healer Studio benefits from all of the above: its indicators appear as soon as a spell is selected, the size slider moves the icons that are already on screen, and turning a spell off clears its icon immediately instead of leaving it behind on a recycled cell.",
            L["wn_363_probe"] or "Fix — Cooldown Studio's buff tracking now shuts down completely when an icon stops tracking a buff, instead of leaving an unused watcher running for the rest of the session.",
            L["wn_363_revive_color"] or "Fix — A resurrected player no longer keeps the grey death colour on their party or raid frame. The frame was repainted while the game still reported the player as dead, and nothing repainted it afterwards, so the wrong colour stayed until a reload. It is now repainted when the player's state actually changes, which also covers someone who drops offline and comes back.",
            L["wn_363_tomoscore_keys"] or "Fix — The end-of-dungeon scoreboard no longer blocks your movement keys. It opens on its own when a key finishes, and it was set to react to the keyboard so Escape could close it, which could stop your movement keys from reaching the game. It is mouse-only again: close it with its button, and every binding keeps working while it is on screen.",
            L["wn_363_raid_event_gate"] or "Changed — Raid frames no longer listen for health, power and aura updates while you are not in a raid. The module was being woken by every unit in the game — party members, nameplates, bosses, your target — to look for a raid frame that could not exist. It now subscribes when you join a raid and stops when you leave, including in the middle of a fight.",
            L["wn_363_leveling_bar"] or "Fix — The leveling bar can be turned on again. Its frame was published under the same global name as the module that drives it, so building the bar once replaced the module: from then on the option, the width and height sliders, the mover and /tm sr all silently did nothing, and ticking the box left the setting switched on with no bar on screen.",
            L["wn_363_dk_runes"] or "Changed — Death Knight runes are drawn with a flat fill instead of the shared gradient bar texture. The gradient reads as a highlight on a tall health bar, but across six short rune segments it only muddied the colour.",
            L["wn_363_forge_drag"] or "Changed — In AstralForge, dropping an element now attaches it to the nearest corner, edge or centre of whatever it is sitting on, exactly as Healer Studio already did. The attachment point never used to change, so pushing a piece into a corner left it hanging from the middle of the frame by a long offset, and it slid out of place as soon as the frame was resized. Elements you had deliberately attached to another element rather than to the frame keep that link.",
        },
    },
    {
        version = "3.6.2",
        highlights = {
            L["wn_362_healer_studio"] or "New — Healer Studio: pick exactly which of your own heal-over-time effects, shields and healer buffs appear on the party and raid frames, and place each icon wherever you want on the cell. It replaces the fixed row of HoT icons with your own layout, and Party and Raid each keep their own. Available for Priest, Druid, Paladin, Shaman, Monk and Evoker.",
            L["wn_362_healer_editor"] or "New — The layout is built in a dedicated window, opened from Party Frames or Raid Frames under Features. Drag an icon onto the cell preview to place it, or set its size, its anchor and its exact offsets with the controls next to it — everything is saved as you go, with no Apply button and no reload. A starter preset switches on the first few spells of your class, and you can lay out any healer class, not only the one you are playing.",
            L["wn_362_healer_preview"] or "New — The preview in Healer Studio is your own cell, enlarged: it uses the width and height your party or raid frames are actually set to, so what you place is what you get in game. Dropping an icon snaps it to the nearest corner, edge or centre, which means it stays where you put it if you resize your frames later.",
            L["wn_362_healer_profile"] or "New — Healer Studio layouts are stored with the rest of your settings, so they follow a profile export and come back with an import instead of being dropped along the way.",
            L["wn_362_healer_spec"] or "New — By default the advanced layout only applies while you are in a healer specialization, so your Shadow or Feral spec keeps the normal HoT row without you having to switch anything. Leaving or entering a healer spec swaps the two over on its own, without a reload.",
            L["wn_362_healer_legacy"] or "Note — Nothing changes unless you turn Healer Studio on: it is off for both party and raid frames, and the classic HoT row keeps working exactly as before. You can also turn the classic row off entirely and keep only your own placed icons.",
            L["wn_362_vault_types"] or "Fix — The Great Vault preview in Mythic Hub now reads its Raids, Dungeons and Delves rows from Blizzard's official reward types instead of guessing them from whatever the weekly rewards API happened to return, so the Delves row no longer comes up empty or filled with another row's activities.",
            L["wn_362_vault_progress"] or "Fix — The Great Vault preview no longer forces a refresh of Blizzard's own Weekly Rewards window before reading your progress. That refresh resets activity progress to zero while a previous reward is still waiting to be claimed, which made completed dungeons, raid bosses and delves show up as 0.",
            L["wn_362_vault_slots"] or "Fix — Each Great Vault row now asks the game for its own activities and orders them by reward tier, so the extra entries the API returns alongside the real rows (bonus and catch-up rewards) can no longer take over a visible slot.",
            L["wn_362_ab_release"] or "Fix — Action buttons respond on the release of a click again. TomoMod's own buttons were missing the secure release attribute Blizzard installs on its action buttons, so with Cast on Key Press turned off nothing was cast at all, and press-and-hold spells such as Evoker empowered casts could be started but never released.",
            L["wn_362_ab_release_gse"] or "Fix — A button that was used for a GSE sequence now returns to the normal press and release behaviour of a regular action as soon as its action changes, instead of keeping the GSE contract until the next reload.",
            L["wn_362_ab_cooldown_push"] or "Fix — Action button cooldown swipes now follow the game exactly. TomoMod kept a short-lived copy of each button's cooldown state and reused it for up to a fraction of a second, which could hide a cooldown starting or ending — most noticeably on short cooldowns and during the brief window while the server confirms a cast. Cooldown state is now read fresh every time, while repeated lookups within one refresh pass are still shared.",
            L["wn_362_ab_counts"] or "Fix — Action bar charge and stack counters no longer trigger a full refresh of every button for each aura or charge event. On large Mythic+ pulls those events arrive in bursts; in combat the work is now grouped a few times per second instead, which keeps key presses responsive. Out of combat nothing is throttled.",
            L["wn_362_ab_glow"] or "Fix — The safety pass that clears leftover proc glows no longer rescans every visible action button for each glow event. The button that lost its glow is still updated instantly, and the full check now runs at most ten times per second, so proc-heavy fights no longer cost input latency.",
            L["wn_362_ab_assist_rotation"] or "Changed — Assisted Combat now locates its action buttons through the game's dedicated Assisted Combat slot API instead of searching every bar for the currently suggested spell, so a change of suggestion no longer touches unrelated buttons.",
            L["wn_362_ab_assist_load"] or "Fix — A change of Assisted Combat suggestion no longer refreshes every TomoMod action button, and TomoMod no longer hooks a Blizzard highlight function that can be called at rotation speed during combat. Together these were the largest source of extra work while the One Button rotation was active.",
            L["wn_362_ab_assist_highlight"] or "Fix — The Assisted Combat highlight is now cleared when the game stops suggesting a spell, and toggling Blizzard's assisted highlight option takes effect immediately instead of requiring a reload.",
            L["wn_362_rb_toggles"] or "New — Two new options under Animations & Power Bar: one turns off the glow that appears when a class resource reaches its maximum, the other turns off the supercharged combo point art for Rogues. Both are on by default, and switching either off immediately restores the normal look of the points already on screen.",
            L["wn_362_rb_glow_stop"] or "Fix — The maximum-resource glow no longer lingers when it should be gone. It is now stopped when the option is switched off and when the class resource display is rebuilt, instead of being left running on a frame that has already been discarded.",
        },
    },
    {
        version = "3.6.1",
        highlights = {
            L["wn_361_assist"] or "Fix — Blizzard's Assisted Combat rotation frame now shows and updates correctly on TomoMod action buttons instead of freezing on the button's unsynced Lua action field.",
            L["wn_361_keydown"] or "Fix — TomoMod's Cast on Key Press setting now stays in sync with Blizzard's own input CVar, fixing a first-press-after-login input that could be silently swallowed.",
            L["wn_361_safewindow"] or "Fix — Combat-deferred override bindings from a mid-combat /reload now reliably replay after combat instead of relying on a safety window that could itself allow blocked actions.",
            L["wn_361_strata"] or "Fix — Action Bar 1, Pet and Stance buttons no longer render above full-screen Blizzard panels such as the World Map.",
            L["wn_361_flyouts"] or "Fix — Spell flyouts such as Mage Portal/Teleport open and cast correctly again; TomoMod no longer resizes native flyout buttons in a way that could taint the secure flyout.",
            L["wn_361_flyouts_cast"] or "Fix — Native flyout popup buttons are no longer hooked or written to at all, since even cosmetic changes could taint Blizzard's protected CastSpellByID/CastSpellByName cast path.",
            L["wn_361_flyout_secure"] or "Fix — TomoMod action buttons now refresh their spell flyout through Blizzard's own UpdateFlyout inside a secure call, and TomoMod's replacement popup methods have been removed from owned buttons. The flyout arrow, the popup it opens and the cast that follows now stay entirely on Blizzard's protected path.",
            L["wn_361_bar6_quarantine"] or "Fix — Spell flyouts on Bar 6 no longer risk becoming forbidden to cast: that bar now uses TomoMod's own secure flyout instead of Blizzard's native one, since the native flyout could still pick up taint specifically when opened from Bar 6. Every other bar keeps using Blizzard's native flyout.",
            L["wn_361_flyout_keybind"] or "Fix — Pressing an assigned keybind to open or close a TomoMod flyout button now works correctly; only a mouse click was recognized before.",
            L["wn_361_flyout_discovery"] or "Fix — TomoMod now also scans the actual action slots on the quarantined bar to find its flyouts, instead of relying only on spellbook enumeration, so flyouts placed there always show the correct known/unknown slot icons.",
            L["wn_361_vehicle_mover"] or "New — Leave Vehicle now has its own mover in layout mode, so it can be placed anywhere on screen instead of being fixed above Action Bar 1. Its position is saved with your profile, and it still defaults to just above Bar 1 until you move it.",
            L["wn_361_vehicle_state"] or "Changed — The Leave Vehicle button is now shown whenever you can actually leave the vehicle, instead of whenever a vehicle UI is displayed, so it no longer appears for vehicles you cannot exit.",
            L["wn_361_vehicle_taxi"] or "Fix — Blizzard's own Leave Vehicle button is now hidden only while TomoMod's secure replacement is usable, so a working exit control remains available on taxi flights and in vehicles that do not allow an early exit.",
            L["wn_361_tracker"] or "Fix — Objective Tracker quest blocks skipped during combat now finish laying out automatically once combat ends, instead of staying overlapped until an unrelated quest update.",
            L["wn_361_buttonbag"] or "Fix — The minimap addon-button collector no longer forgets the buttons it has already gathered when it rescans, so addons that register their button later open a new row instead of stacking on top of the first one.",
            L["wn_361_trackdupe"] or "Fix — The Tracking panel no longer lists the same entry twice (Banker showed up on two rows). Tracking filters the game reports under the same name are merged into a single row that toggles them together.",
            L["wn_361_micromenu_native"] or "Fix — TomoMod no longer builds its own container, reparents buttons or touches layout for Blizzard's Micro Menu, and the old standalone Micro Bar module has been removed entirely.",
            L["wn_361_micromenu_gui"] or "Changed — The Bag & Micro Menu options panel now shows a compact Group Finder eye section instead of the old Micro Bar builder, with just an ON/OFF toggle and a size slider.",
            L["wn_361_lfgeye_fix"] or "Fix — The Group Finder eye no longer disappears when the Micro Menu fades out on mouseover; it now has its own visibility and scale handling, refreshed automatically when you enter the world, queue for something, or a dungeon/battleground pops.",
            L["wn_361_validation"] or "Tested — Assisted Combat, key-down casting, combat-reload bindings, Bar 1/Pet/Stance strata near the World Map, spell flyouts, Objective Tracker combat deferral, and the Group Finder eye across Micro Menu fade and LFG events were validated in game.",
        },
    },
    {
        version = "3.6.0",
        highlights = {
            L["wn_360_foundation"] or "Changed — ActionBars now use a zero-taint ownership model: TomoMod keeps addon-owned buttons out of Blizzard's native action-button broadcaster and leaves protected Blizzard bar state under Blizzard ownership.",
            L["wn_360_nativebars"] or "Fix — Blizzard standard action bars stay alive for secure paging but are visually suppressed, so only TomoMod bars are shown without freezing their runtime state.",
            L["wn_360_specialvisuals"] or "Fix — Blizzard Stance, Pet and Possess bars remain functional underneath while their duplicate textures, text, cooldown swipes, autocast overlays, checked borders and flash effects are masked.",
            L["wn_360_stance"] or "Fix — TomoMod Stance buttons now use independent secure spell actions and remain clickable for Druid forms, Paladin auras and Warrior stances.",
            L["wn_360_pet"] or "Fix — TomoMod Pet buttons now use independent secure pet actions; normal pet commands, abilities and right-click autocast toggles remain usable without relying on the visible Blizzard Pet Bar.",
            L["wn_360_possess"] or "Fix — Possession and vehicle states continue through Action Bar 1's secure paging instead of requiring TomoMod to manipulate Blizzard's PossessActionBar.",
            L["wn_360_paging"] or "Fix — Action Bar 1 reads its current secure action slot directly, keeping form, vehicle, override and possess paging live instead of freezing on a Lua-side snapshot.",
            L["wn_360_formsafe"] or "Fix — Druid Human/Cat/Bear changes now update Action Bar 1 correctly in and out of combat with no protected-action or secret cooldown errors observed in testing.",
            L["wn_360_extra"] or "Fix — Extra Action keeps Blizzard's secure gameplay behavior while TomoMod provides the visible button, its own GCD/charges and a click-safe presentation without the invisible native hitbox stealing input.",
            L["wn_360_zone"] or "Fix — Zone Ability keeps live state-dependent icons, GCD and charges, disappears when no longer active, and preserves native click behavior for quest abilities that require it.",
            L["wn_360_vehicle"] or "Fix — Leave Vehicle remains a secure TomoMod action with the shared ActionBar skin while Blizzard taxi behavior stays available when needed.",
            L["wn_360_gcd"] or "Fix — Native Stance/Aura/Posture GCD remnants are visually masked without touching Blizzard's cooldown values or protected button state.",
            L["wn_360_petvisuals"] or "Fix — The remaining Blizzard PetBar checked-state borders, flash effects and autocast overlays are now hidden while the underlying pet state stays fully functional.",
            L["wn_360_skin"] or "Changed — Extra Action, Zone Ability and Leave Vehicle now share the same regular TomoMod action-button skin pipeline as the rest of the bars.",
            L["wn_360_flyouts"] or "Fix — Spell flyouts open correctly again from TomoMod Action Bars, including Mage portals and Hunter traps.",
            L["wn_360_installer"] or "Fix — The first-run installer now loads reliably on fresh installs and waits until cinematics, movies and combat are over before appearing.",
            L["wn_360_rolesafe"] or "Fix — Party/Raid frames, Nameplates, TomoScore, Chat and Tooltips now handle Midnight's restricted group-role data safely instead of producing secret-value errors.",
            L["wn_360_mythiccombat"] or "Fix — MythicHub and TomoScore commands now wait until combat ends before opening or refreshing protected controls, then continue automatically.",
            L["wn_360_profiles"] or "Fix — Profile Import/Export popups now handle Escape safely in combat without causing blocked keyboard-input actions.",
            L["wn_360_validation"] or "Tested — Standard bars, Human/Cat/Bear paging, Stance, Pet, Possession, special buttons, mouse/keyboard input and combat were validated in game with no new ActionBar taint errors.",
        },
    },
    {
        version = "3.5.9",
        highlights = {
            L["wn_359_visibility"] or "New — Action bars now have a Secure Visibility Engine with combat-safe rules for combat state, group type, instances, mounts, targets, hidden mode and custom secure conditions.",
            L["wn_359_gcd"] or "Changed — GCD swipes stay visible where they belong, but pure GCDs no longer show noisy fractional countdown text; numeric text is reserved for the action's real cooldown.",
            L["wn_359_editmode"] or "Fix — Blizzard Edit Mode now opens without the protected TargetUnit/FocusUnit errors or Compact Party Frame secret-value failures that could previously be attributed to TomoMod.",
            L["wn_359_dormancy"] or "New — Securely hidden bars now go dormant and stop doing unnecessary visual work. Keybinds remain active, and the bar performs a full refresh the instant it becomes visible again.",
            L["wn_359_nativeglow"] or "New — TomoMod now uses its own native glow engine instead of LibCustomGlow, removing the obsolete AnimateTexCoords crash path and centralizing proc animation work.",
            L["wn_359_conditional"] or "Fix — Conditional abilities such as Monk Touch of Death now refresh usability and proc state from Blizzard's action notifications. Unusable abilities stay dimmed instead of being incorrectly overridden by red range coloring.",
            L["wn_359_specialbars"] or "Fix — Blizzard Pet, Stance and Possess bars stay fully Blizzard-owned for taint safety but are filtered with the 12.1 alwaysBlocked roleset, preventing duplicate native bars without bringing the Edit Mode errors back.",
            L["wn_359_paging"] or "New — Secure Paging for Action Bar 1 adds Alt/Shift/Ctrl pages, Friendly/Hostile Target pages, optional form paging and optional Skyriding paging, all configurable from TomoMod_Options.",
            L["wn_359_priority"] or "Changed — Paging priority now keeps Vehicle/Override/Possess authoritative while manual and modifier pages take precedence over automatic form or Skyriding pages when appropriate.",
            L["wn_359_formsafe"] or "Fix — Druid form changes in combat are now clean and reliable, without protected-action or secret cooldown errors when moving between Human, Cat and Bear.",
            L["wn_359_zoneability"] or "Fix — Zone Ability buttons now keep their icon, GCD and charge display in sync, update correctly when a quest changes state, and disappear when the ability is no longer available.",
            L["wn_359_extragcd"] or "Fix — Extra Action buttons now mirror their GCD and charge recovery on the TomoMod skin without reading or modifying Blizzard's native cooldown widget.",
            L["wn_359_specialbuttons"] or "Changed — Extra Action, Zone Ability and Leave Vehicle keep Blizzard's secure gameplay behavior while TomoMod provides the visible controls, preserving quest, vehicle and taxi behavior.",
            L["wn_359_specialskin"] or "Changed — Extra Action, Zone Ability and Leave Vehicle now use the same action-button skin pipeline as the rest of the bars; invisible Blizzard hitboxes no longer steal clicks or tooltips.",
            L["wn_359_validation"] or "Tested — Forms, special ability buttons, mouse clicks, GCD/charges, visibility, native glows, Edit Mode and secure paging were validated in game without new ActionBar taint errors.",
        },
    },
    {
        version = "3.5.8",
        highlights = {
            L["wn_358_input"] or "Fix — Action bar input is now consistently immediate: interrupts, instant abilities, GCD/off-GCD actions, rapid key spam and Shift/Ctrl binds no longer inherit the delayed keybind behavior seen before this update.",
            L["wn_358_state"] or "Fix — Moving, replacing or clearing an action, changing specialization or talents, paging, forms, vehicles and skyriding now refresh the affected buttons cleanly without stale icons, cooldowns, glows, grey states or charge counts.",
            L["wn_358_range"] or "Changed — Midnight 12.1 range coloring now uses Blizzard's native action-range notifications, while mana/usability updates are event-driven. The old periodic scan is kept only as a compatibility fallback.",
            L["wn_358_glowflyout"] or "Fix — Proc glows now follow transformed/base spell relationships more reliably, stale glows are cleaned up, and flyouts opened from mouseover-faded bars stay visible and return to normal fading when closed.",
            L["wn_358_taintstate"] or "Internal — Custom bookkeeping that used to live directly on Blizzard-owned frames has moved into external weak tables, reducing the amount of addon state attached to protected UI objects.",
            L["wn_358_registry"] or "Fix — TomoMod action buttons are isolated from Blizzard's native action-button registries and broadcasters where needed, preventing the game's controller from running retired native buttons through tainted update paths.",
            L["wn_358_secretcooldown"] or "Fix — Combat could flood the error log when Blizzard tried to apply unreadable secret cooldown values to retired native action buttons. Those broadcaster paths are now isolated and no longer generate the repeated cooldown errors.",
            L["wn_358_stancepossess"] or "Fix — StanceBar and PossessActionBar are now left fully under Blizzard's control. This removes the protected MainActionBar error that could be reproduced by summoning a temporary Monk companion during combat.",
            L["wn_358_blizzbars"] or "Fix — Blizzard's standard action bars are hidden again through the safe 12.1 visual-suppression path, leaving only TomoMod's bars visible without reintroducing the controller taint.",
            L["wn_358_validation"] or "Tested — The rebuilt action-bar path has been validated through intensive combat, reloads, talents/spec changes, forms, vehicles, skyriding, transforming spells, charges, flyouts, proc glows and the Monk companion transition with no ActionBar errors observed.",
        },
    },
    {
        version = "3.5.7",
        highlights = {
            L["wn_357_talkingheadfix"] or "Fix — Hide Talking Head could leave a talking head's voiceover playing underneath a hidden frame. Talking head frames manage their own visibility, so simply hiding the frame on show left the playing state and its finish timer running — and skipped every line after the first in a multi-line talking head, since the frame was already visible for those. TomoMod now hooks the actual play function and closes each talking head the same way Blizzard itself does, which reliably stops the timer and the voiceover together.",
            L["wn_357_talkingheadcleanup"] or "Internal — A stop-sound call issued in the very same moment a voiceover starts is occasionally ignored by the sound engine, so Hide Talking Head now follows up a fraction of a second later to make sure it actually stops.",
            L["wn_357_queueeyedb"] or "Fix — The queue status eye's position never actually saved. Its entry was missing from the settings defaults table, so the save handler silently skipped writing a new position every time you dragged it — the eye moved fine on screen, but forgot where you put it on the next login. The missing entry is back, and the save path now creates it on the fly if your saved settings are still missing it, so an out-of-date save costs nothing worse than one extra table.",
            L["wn_357_queueeyeposition"] or "Fix — The queue status eye's default position was a blind guess that landed in a different spot on every resolution — off-screen entirely on an ultrawide monitor, which is how this was caught. It now defaults to a spot beside the minimap, where the eye actually lives.",
            L["wn_357_lfgeyesurvive"] or "New — The Group Finder eye used to disappear entirely when you hid the Blizzard micro menu, since it lives inside that same menu's container. It now stays put — Group Finder queue status is always visible, wherever you've placed it, whether the native micro menu is hidden or not.",
            L["wn_357_lfgeyeoptions"] or "New — Two new Micro Bar options let you turn the Group Finder eye off entirely or resize it, next to the setting that hides the Blizzard micro menu.",
            L["wn_357_lfgeyescale"] or "Fix — The Group Finder eye's size slider did nothing unless Micro Bar was fully enabled with \"hide the Blizzard micro menu\" also turned on — the scale was silently reset back to normal on every refresh otherwise. It now applies regardless.",
            L["wn_357_roletaintguard"] or "Fix — A nameplate error could still slip through comparing a role you're not allowed to read directly, even with the existing guard in place. That comparison is now double-checked, so an unreadable role is treated as no role instead of raising an error.",
            L["wn_357_cooldowntaint"] or "Fix — Some action bar buttons could spam an error updating their cooldown swipe when the game wouldn't let the value be read directly, even on bars with skinning turned off. That update is now skipped safely on every affected button and every cooldown it carries, instead of raising an error.",
            L["wn_357_mainbartaint"] or "Fix — A rare error could appear trying to reshow the default action bar after mounting or entering a vehicle. It is now silenced the same way similar cases already are.",
            L["wn_357_mailiconcrash"] or "Fix — The minimap's mail icon could raise an error every time you got new mail. It no longer does, and the icon behaves exactly as before.",
            L["wn_357_buggrabber"] or "New — If you also run !BugGrabber, Diagnostics now backs itself up against it, catching errors it saw before TomoMod's own tracking started this session. Nothing changes if you don't have it installed.",
            L["wn_357_shieldenchant"] or "Fix — The character sheet's weapon enchant warning could flag a shield or an off-hand held item (tomes, frills, and the like) as missing an enchant, even though neither can actually take one — tanks with a shield and casters holding an off-hand item saw a red warning for something that was never enchantable to begin with. The warning now only shows on a slot holding a real, enchantable weapon.",
            L["wn_357_inspectiteminfo"] or "New — Inspecting another player now shows the same per-item breakdown as your own character sheet: item level, upgrade track, enchant text (or a missing-enchant warning) and gem sockets next to every equipped item, instead of just one averaged number at the top.",
            L["wn_357_inspectiteminfotoggle"] or "New — A new checkbox lets you turn the Inspect frame's item info/enchants/gems off independently of your character sheet's own settings.",
            L["wn_357_enemybuffgrid"] or "New — The Enemy Buffs tracker on your target and focus frames (the helpful auras cast on whatever you're targeting) now has its own Direction (left/right) and Next Row Goes (up/down) dropdowns, plus an Icons Per Row slider — it was previously fixed at 3 per row, growing upward, with no way to change either. The count slider's ceiling also went from 8 to 12, and any stack is capped at 3 rows, hiding the rest instead of growing forever.",
            L["wn_357_aurasgrid"] or "New — Regular Auras (buffs, debuffs, or both, on player/target/focus) now use the same icons-per-row grid as Enemy Buffs: an Icons Per Row slider (default 6) replaces the old pixel-width wrap, with the same 3-row cap.",
            L["wn_357_auradirectionfix"] or "Fix — Direction settings on both Auras and Enemy Buffs used to silently do nothing: the aura engine's live-refresh only re-applied grow direction when the icon size or count also changed in the same update, and even then a fixed anchor corner meant \"grow upward\" left the icon stack floating a few rows above the health bar instead of sitting flush against it. Both are fixed — direction and per-row changes apply immediately, and the stack now grows from right where it should, with nothing floating.",
            L["wn_357_aurasliverefresh"] or "Fix — Several Auras/Enemy Buffs options (count, direction, type) used to need a `/reload` to actually apply, even though they looked like they should update instantly. Most of them now do; the two that still genuinely need one — Enable and the buff/debuff/both Type dropdown — now say so directly in the panel.",
            L["wn_357_microbarcombatfade"] or "Fix — Hovering a Micro Bar button in combat could raise a blocked-action error instead of just fading the bar in. The hover fade now snaps straight to its target instead of animating while in combat, which avoids the blocked call entirely.",
        },
    },
    {
        version = "3.5.5",
        highlights = {
            L["wn_355_barhoverblocked"] or "Fix — Simply moving your mouse over an action bar button during a fight produced a blocked-action error, every single time. Blizzard's own button update runs on mouseover and ends by writing a press-and-hold setting directly — a write that isn't allowed in combat, and that gets blamed on TomoMod because the buttons are ours. One entry per hover is how a single session collected 127 of them. TomoMod now writes that setting from its own secure path, where it was already being written correctly, and skips Blizzard's redundant version.",
            L["wn_355_barpingblocked"] or "Fix — The same mouseover ran a second forbidden write two lines later, this one belonging to the ping system. Pings target Blizzard's own bars and never applied to TomoMod's buttons, so that call is now skipped as well. Neither of these ever broke anything on screen — but they buried real errors under noise and made the addon look responsible for whatever else went wrong in the same fight.",
            L["wn_355_escapekeyblocked"] or "Fix — With a TomoMod window open in combat, every key you pressed produced a blocked-action error — holding a movement key down was enough to fill the error log by itself. The combat check was already there, it just ran one line too late, after the protected call it was meant to prevent. It now runs first.",
            L["wn_355_microportrait"] or "Fix — On the custom micro menu, the character sheet button showed as a blank coloured square while every other button looked right. It is the only one whose art isn't a fixed icon — it's your character's portrait — and TomoMod was copying a texture reference that simply doesn't reproduce anywhere else. It now asks the game to draw your portrait onto the button directly, and borrows the same rounded mask and drop shadow Blizzard uses on its own character button — so it shows your character with the same shape and depth as the buttons beside it, instead of a flat square.",
            L["wn_355_perftooltip"] or "New — The memory tooltip on the custom micro menu now opens with a Performance block: your framerate, your home and world latency, and total addon CPU. The CPU line only means anything when the game is recording it, which is off by default and needs a reload to change — so rather than show you zeroes that look like a real measurement, it says \"profiling disabled\" until you turn it on.",
            L["wn_355_micronative"] or "Fix — On some clients, ticking \"hide the Blizzard micro menu\" did nothing whatsoever: the box stayed ticked, the bar stayed on screen. TomoMod looked for Blizzard's menu under a single name that has moved between patches, and gave up the moment it wasn't there — without even hiding the buttons, which was the part that would have worked. It now recognises every name Blizzard has used and always handles the buttons regardless. If nothing at all answers on your client, it now says so once in chat instead of failing silently — please report it with your client version if you see that message.",
            L["wn_355_queueanchor"] or "New — The queue status eye — the small icon that spins while you're waiting for a dungeon or battleground — can now be moved. Blizzard attaches it to the minimap and gives it no Edit Mode handle, which made it the one HUD element you simply could not place. It now appears among the movable anchors in `/tm sr`, and moving it during combat is applied the moment the fight ends rather than being refused.",
            L["wn_355_escapepropagate"] or "Internal — Keyboard propagation for those windows is now established once when the window is built, rather than re-set on every keypress. It never needed re-setting: it is a persistent property of the frame, and the only thing that ever turns it off is closing the window with Escape, which cannot happen in combat.",
        },
    },
    {
        version = "3.5.4",
        highlights = {
            L["wn_354_preyfix"] or "Fix — The Prey Tracker's progress bar was permanently stuck at 0%. `GetPreyWidgetInfo` kept only the boolean returned by `pcall`, not the actual widget data, so reading `.progressPercent` off it threw an error every second and aborted the update before it could ever fall back to the quest's own objective count. The call now keeps both return values, so a missing widget field is handled quietly and the real progress — read from the hunt's own objective count — comes through correctly.",
            L["wn_354_extranudge"] or "Change — The Extra Action Button and Zone Ability move overlays lose the four click-to-nudge arrows that surrounded them in `/tm layout`. Dragging the overlay with the mouse still repositions it exactly as before; only the extra buttons are gone.",
            L["wn_354_perflocale"] or "Internal — Loading a non-English locale used to build and instantly discard nearly 2900 translation table entries, five times over, on every `/reload` — the file compiled fully before the addon could decide it wasn't needed. Each non-active locale file now bails out before building its table, and the base-locale merge check (which was silently a no-op due to a metatable quirk) is fixed to only test what it's supposed to.",
            L["wn_354_perfrangeticker"] or "Change — The party and raid frame range-check ticker, a safety net for cases the game's own range event doesn't cover, was running twice a second per frame regardless of group size. It now runs every two seconds — still faster than any transition it needs to catch — cutting that cost by three-quarters.",
            L["wn_354_perfaura"] or "Internal — Scanning a unit's defensive auras opened a new protected call for every buff checked, up to forty times per aura update per tracked unit. It's now one protected call around the whole scan, with identical fallback behavior if something goes wrong partway through.",
            L["wn_354_perfpartylookup"] or "Internal — Party frames dropped a linear frame search in favor of a direct lookup table, and now fully unsubscribe from health/power/aura events while in a raid — where those frames are hidden and the raid frames handle updates instead — rather than quietly continuing to process events for nothing.",
            L["wn_354_perfcdf"] or "Internal — Cooldown Forge's update event could fire several times in the same frame during a burst of cooldown changes, each one repainting every bar and icon on its own. Those bursts are now collapsed into a single repaint per frame.",
            L["wn_354_perfmisc"] or "Internal — A handful of smaller hot-path cleanups: boss frame polling no longer builds new strings every tick, the Objective Tracker's deferred layout pass and recursive content scan no longer allocate throwaway tables on every node, and Skyriding's speed calculations no longer rebuild a closure on every tick.",
            L["wn_354_optionslod"] or "Change — The options panel — Config, 28 files and roughly 17,900 lines — now loads on demand instead of at login. It moved into its own TomoMod_Options add-on and only loads the first time you actually open it; every button and slash command that used to reach it directly now loads it transparently on first use.",
            L["wn_354_optionsfallback"] or "Internal — Mythic+ score colors, previously read once at login from a theme table that now lives in the on-demand options add-on (and so didn't exist yet), are read lazily instead — they resolve correctly the moment the options panel has been opened once, rather than being frozen at an empty fallback for the whole session.",
            L["wn_354_escapefix"] or "Fix — The Damage Meter's Death Recap, Run Recap, Spell Breakdown and Target Breakdown windows could leave Escape unable to close the game menu after being used, because closing them the old way routed through a function whose protected calls get refused once tainted. They now use the same safe close-on-Escape handler as every other TomoMod window.",
        },
    },
    {
        version = "3.5.3",
        highlights = {
            L["wn_353_brezvisual"] or "Enhancement — The Battle Rez Counter HUD received a visual refresh inspired by Tui's design patterns. The frame now features a professional multi-layer backdrop with inner shadow effects, improved spacing, and refined typography for better readability during combat.",
            L["wn_353_brezglow"] or "New — An optional glow effect now activates when battle resurrections are available, providing improved visual feedback and making the counter more noticeable at a glance.",
            L["wn_353_brezcolors"] or "Change — The Battle Rez Counter's color palette has been upgraded with Tui-inspired teal accent colors and better contrast between active (green) and cooldown (red) states for clearer status indication.",
            L["wn_353_brezlayers"] or "Internal — The Battle Rez Counter frame layout was refactored with proper layer ordering: background, inner shadow, icon texture, cooldown swipe, and text overlays. Better geometry and positioning across all UI elements.",
            L["wn_353_preytracker"] or "New — Prey Tracker: A movable progress bar displaying active Prey hunt progress (Midnight expansion feature only). Shows the hunt name, difficulty level, and real-time progress percentage with a smooth visual design matching the Battle Rez Counter.",
            L["wn_353_preyconfig"] or "New — The Prey Tracker is disabled by default (Midnight-only content) and can be enabled in Config → QOL → Combat → Prey Tracker. It automatically hides when no Prey hunt is active and shows a preview during placement mode.",
            L["wn_353_preylayout"] or "New — The Prey Tracker is fully integrated with TomoMod's unified layout mover system. Drag to position it alongside other HUD elements using `/tm layout`, with synchronized lock/unlock behavior and consistent placement mode previews.",
            L["wn_353_preyapi"] or "Internal — The Prey Tracker reads C_QuestLog and C_UIWidgetManager APIs to detect active Prey quests and track progress in real-time with a 1-second update rate, providing accurate status information during hunts.",
            L["wn_353_brezcrash"] or "Fix — The Battle Rez Counter could fail to load entirely on some client builds: a cooldown method that no longer exists, and a frame-level call made on a texture instead of a frame, both crashed module init. Both are fixed, along with a glow effect that crashed the moment it needed to reappear after being hidden once.",
            L["wn_353_preyevent"] or "Fix — The Prey Tracker registered an event that doesn't exist on this client, throwing during init. Fixed, and every event registration is now guarded so a missing event can no longer crash the module.",
            L["wn_353_preygui"] or "New — The Prey Tracker now has an actual settings section: Config → QOL → Automations, with an enable checkbox and width/font-size sliders. It previously had no in-game way to turn on.",
            L["wn_353_abmover"] or "Fix — The \"Action Bars\" entry in `/tm layout` did nothing at all. The ported action bar code runs in a sandboxed environment that never exposed itself to the rest of TomoMod, so move mode silently failed to activate. It now reaches the bars correctly.",
            L["wn_353_abflash"] or "Fix — Pressing an action button turned its icon fully white, and the first attempt at fixing it earlier in this same release did not work. The texture involved is not a cutout shape that needed a different blending mode, it is a solid white square — so blending it differently still painted it over the icon, and the change made three other textures that had been fine all along come out brighter than they should. The press effect now darkens the icon instead of covering it, which is what it was always meant to do.",
            L["wn_353_abpressopt"] or "New — You can choose what a button does while you hold it down. Config → Action Bars → General has a Press effect setting with three choices: Blizzard's own flash, which is now the default, TomoMod's darkening, or nothing at all. It takes effect the moment you pick it, with no reload.",
            L["wn_353_abposition"] or "Fix — A dragged action bar reset to its default position on every `/reload`. The saved position was never actually being written, and the restore path never read it back even when it was. Both are fixed — bar positions now persist correctly.",
            L["wn_353_abcolor"] or "Change — The move-mode overlay for action bars and the extra action/zone ability buttons now uses TomoMod's teal brand color instead of Tui's original blue, matching every other `/tm layout` overlay.",
            L["wn_353_abextramover"] or "Fix — The Extra Action Button and Zone Ability holders had their own separate move overlay that was never connected to `/tm layout` — always visible on screen but impossible to drag from the unified layout tool. Both now have a proper \"Extra Button\" entry in `/tm layout`.",
            L["wn_353_brezicon"] or "Fix — The Battle Rez Counter's icon rendered as a solid black square: the texture path used for it doesn't exist on this client. It now shows the correct Rebirth icon.",
            L["wn_353_nameplaterole"] or "Fix — Nameplates could spam taint errors when reading a unit's group role in restricted content, because the role can come back as a secret value that can't be compared directly. It's now guarded and treated as unknown rather than thrown.",
            L["wn_353_abmicrodefer"] or "Fix — The micro menu buttons could go missing for the rest of a session. When they need to be moved back into place and a fight is running, the move waits for combat to end — but the part meant to wake it up afterwards was never there, so it waited forever, silently, with nothing in the error log to say so. It now runs the moment you leave combat.",
            L["wn_353_abpaging"] or "Fix — When the bar changed under you — a vehicle, a possess bar, a stance, a skyriding page — the buttons kept the artwork of the page you had just left, or showed nothing at all, and only a full rebuild or a /reload put them right. The repaint meant to follow a page change was hanging off a Blizzard function that no longer exists on the current client, so it never ran once. The bars now repaint themselves when they change pages.",
            L["wn_353_aboverride"] or "Fix — The override bar was never listened to at all. That is the bar a vehicle, a skyriding mount or a druid's Flight Form puts you on, and because nothing told the bars it had happened, they carried on showing the actions of the page you were on before. It is now watched like any other page change: the slots are re-read and the buttons repainted.",
            L["wn_353_abemptyslot"] or "Fix — And with \"hide empty slots\" turned on, those same swaps left the bar blank rather than stale: the buttons were there but invisible, and unticking the option made the problem vanish, which is what gave it away. The repaint was running one frame too early, while the buttons still pointed at the slots of the page you had left, so every one of them was judged empty and faded out — with nothing running afterwards to think again. It now runs a second time on the next frame, once the buttons have caught up.",
            L["wn_353_totembar"] or "New — A totem bar. It shows the totems you have out, in your class's own priority order, each icon carrying the time it has left and a sweep running down it. Right-click one to dismiss that totem, and the bar takes itself off screen when nothing is out. Blizzard's own totem frame stands down while it is on and is handed back intact the moment you switch it off.",
            L["wn_353_totemconfig"] or "New — The totem bar is switched on in Config → Action Bars → General, under Totems, and takes effect straight away with no reload. It is off by default. Icon size, spacing, border, zoom, which way it grows, and the look of the duration text and the sweep are all yours to set.",
            L["wn_353_totemlayout"] or "New — Position it from `/tm layout` like every other HUD element. It stays visible and labelled there even when you have no totems out, so you can place it before ever casting one instead of having to drop a totem, run to the layout tool and hope it is still up.",
            L["wn_353_petstancelayout"] or "New — The pet bar and the stance bar can be laid out at last. They had the orientation, button count and column controls kept from them on the belief that the game owned their shape — it does not: they run through exactly the same layout code as the eight main bars, and always did, so the settings were live all along with nothing on screen to reach them. All three controls are now there for both, capped at ten slots rather than twelve. Setting the stance bar higher than the number of forms your class has is harmless; it is clamped for you.",
            L["wn_353_loots17"] or "New — The loot tables are up to date for Season 17. The dungeon rotation has turned over completely, so all eight of the new dungeons are there — Kings' Rest, Temple of Sethraliss, Ruby Life Pools, The Blinding Vale, Void Scar Arena, Nalorakk's Lair, Murder Row and Altar of the Fangs — along with the two new raids, Tidebound Grotto and Venomous Abyss, and the class restrictions for every item they drop. Last season's tables are retired rather than kept alongside: nothing in either rotation points at them any more.",
            L["wn_353_mplusteleports"] or "New — The Mythic+ tracker knows the teleports for the new rotation. The five rotation dungeons arrive with their teleport spells, and Kings' Rest and the Temple of Sethraliss have theirs filled in at last — both were sitting empty in a rotation they are part of, so the tracker had nothing to offer for either.",
            L["wn_353_keysync"] or "Fix — `/tmt keysync` now does something. The key-sync diagnostic had been written, and the note above it even named the command it was meant to answer to, but nothing in the handler ever routed there — so the one tool for telling a sync that is quietly failing apart from one that simply found nothing to match could not be reached from the game at all. It is now listed in `/tmt help` in all six languages.",
            L["wn_353_totemport"] or "Internal — The totem bar is a port rather than a rewrite, carried across from Tui as written with every changed line marked, so catching up with the original later is a replay of a handful of marks instead of a second reading of the whole file. Its cooldowns refuse secret values outright rather than guessing at them, which is how the rest of the ported code already treats restricted content, and every secure write waits for the end of a fight instead of being attempted mid-combat.",
        },
    },
    {
        version = "3.5.2",
        highlights = {
            L["wn_352_icons"] or "Fix — The action bar icons came back black. The check meant to spot an empty slot was looking for the icon to be given as a file path, which is how the game used to answer and has not for years — it now hands back a number instead. So every real icon failed a test written to catch the ones that were missing, was wiped, and left an empty square where your spell had been. Both the usual route and the fallback now accept either answer.",
            L["wn_352_tint"] or "Fix — Out of range, out of mana and unusable stopped showing after a reload or a bar change, and moving the mouse over the button would bring them back. TomoMod was tinting the icon in the very same place Blizzard tints it, so whichever of the two ran last decided what you saw. The tint is now a layer of TomoMod's own laid over the icon, which shades it exactly as before without the two of them writing over each other — and when there is nothing to signal, it simply is not there.",
            L["wn_352_scope"] or "Fix — With the action bars turned off, the skin kept skinning anyway. It falls back to finding buttons by name, and those names belong to Blizzard's buttons whether or not TomoMod has taken them over — so switching the bars off left the skin repainting frames it had no business touching. It now checks that the bars are actually running before it changes anything.",
            L["wn_352_move"] or "Internal — The action bars have moved house. They were filed away with the quality-of-life tweaks because that is where the skin began, and they stopped being a tweak the moment the last release turned them into a system of their own with an engine, five layers and their own buttons. They now sit with the unit, party and raid frames, where they belong, and are loaded the way those are. Nothing about them changed on the way over — the three fixes above came with them.",
            L["wn_352_tui"] or "Internal — Groundwork, and nothing you can see yet. Some of what is planned for the bars exists already in another addon, and rewriting it line by line to fit here would be slow and would introduce mistakes that are not in the original. So there is now a thin layer whose only job is to let one of those files run here untouched. Where TomoMod already has its own version of something — anchoring, move mode — the layer points at that instead of dragging a second copy along, which is why four functions stand in for sixteen hundred lines of it. Nothing calls any of this yet; it is deliberately being put in place on its own, before anything relies on it.",
            L["wn_352_port"] or "Internal — And then the thing that layer was built for. The action bar module from that other addon is now here in full: fourteen files, a little over eight thousand lines, brought across as they were written rather than retyped to fit. Every place a line had to change is marked, so that when the original moves on, catching up means replaying a handful of marks instead of reading the whole thing again and hoping to notice what moved. It is loaded, it is checked, and it is switched off on purpose — landing something this size and turning it on in the same release is how you end up unable to say which of the two broke your bars.",
            L["wn_352_portlayers"] or "Internal — What is inside it, for when the switch is thrown. Flyouts first: the last release shipped TomoMod's own buttons and had to say plainly that a mage portal or a hunter trap would not open on a bar using them, because the game refuses the ordinary route on a button an addon made and the way around it is a few hundred lines nobody writes twice. Those lines came with the port, along with a matching restyle of the game's own flyout for the buttons that are still Blizzard's. The extra action button and the zone ability get a place of their own to sit, one the game cannot quietly move them out of. Cooldowns, the glow and the greying-out of what you cannot cast each arrive as their own layer. None of it is on yet.",
            L["wn_352_switch"] or "Change — The switch is thrown: the action bars now run on the ported module, and the system that drove them before it has been removed rather than left sitting there switched off, because two of them each convinced they own the same buttons is not a state worth shipping in order to find out how it goes. The last three pieces came with it — the skinning, which strips the game's own artwork off a button and draws it from scratch, down to the macro name and the stack count; fading a bar out until you put the mouse on it, one bar at a time, with the bar held visible while your spellbook is open; and the overlays you see when you go to move a bar. Masque is supported now too, if you use it, and simply absent if you do not.",
            L["wn_352_bindings"] or "Change — Your keys carry over, and there are 106 fewer things to bind. The previous release shipped a binding for every button on every bar, so putting TomoMod's own buttons on a bar meant binding it a second time in the game's keybinding window, under a TomoMod heading, next to the binding you already had. The new buttons do not ask for that: they read whatever you have bound to the game's own action bar keys and take those over for themselves. A bar you had set up keeps working without you touching anything, and a key already spoken for by something else is left exactly where it is.",
            L["wn_352_settings"] or "Change — The Action Bars options page is back, and there is one thing to know before you update. When the bars were switched over earlier in this same release the page was reduced to a single message, because every control on it wrote to a system that no longer existed. It has now been rebuilt against what the bars actually read: five tabs — the buttons themselves, the text written on them, the indicators for out of range and out of power and what you cannot cast, fading a bar out until you point at it, and one tab per bar for how many buttons it carries and which way it grows. The thing to know: your old bar settings do not come across. The old way of storing them and the new one do not name anything the same, and the few names that look alike do not mean the same thing, so carrying them over would have meant guessing — and a wrong guess hands you a layout you never picked and cannot work back to. The old settings are cleared once, on your first login after the update, and the bars come up on clean defaults for you to set as you like.",
            L["wn_352_chatcopy"] or "New — Copying text out of the chat was rebuilt. The window you get now looks like the rest of the chat rather than a plain grey box: the text is already selected and scrolled to the last line the moment it opens, you can resize it, and it holds 500 lines where it used to stop at 128. There is a copy button on the chat window itself as well — always visible, only when you point at the chat, or not at all, whichever you prefer, under Skins, Chat Frame. And the little window that asks you to copy a link's address now matches everything else instead of being the game's own dialog.",
        },
    },
    {
        version = "3.5.1",
        highlights = {
            L["wn_351_engine"] or "Internal — The action bars used to be repainted five times a second, every button, whether or not anything had changed. That was the shape a skin ends up with when it grows into a feature set without ever being given somewhere to keep track of things. There is now one piece that owns the question — what state is this button in — and it is told by the game when something happens instead of checking on a timer, and it passes the news on only when a value has actually changed. Range is the one exception, because the game has no way of announcing it; that check still runs on a timer, and only while you have a target. It also never assumes the button underneath belongs to Blizzard, which is what made everything else in this release possible.",
            L["wn_351_render"] or "New — Icons and cooldowns became yours to set. The cooldown numbers and their size, the colour and opacity of the sweep, the edge and the shine, the charge and stack text and its size, the macro name, greying out an action you cannot use, and how much the icon is cropped — down to not cropped at all. There is also a choice of who draws the cooldown: Blizzard, which keeps its own sweep and simply restyles it, or TomoMod, which draws it. Blizzard is the default and stays the safer of the two for now; TomoMod's is what the new buttons further down need, and it is there so it can be proven before anything relies on it.",
            L["wn_351_glow"] or "New — Two glows on the bars, and they can both be lit at once. One is the classic proc highlight; the other follows the rotation suggestion the game itself makes. Each has its own style — Pixel, Autocast, Button, Proc or Blizzard — its own colour, and for the pixel one the number of lines, their thickness and the animation speed. They coexist rather than taking turns, because each keeps its own hold on the button. Matching is done on the spell, so a macro that ends up casting something glows exactly as the spell would on its own, and a talent that renames a spell is followed too. The rotation glow is off by default and needs the feature to exist on your character.",
            L["wn_351_hotkeys"] or "New — The keybind text on the buttons is now yours: show or hide it, its size, its colour, which corner it sits in, how far it is nudged, whether it is shortened, and whether it appears at all on an empty slot. It is worked out from the binding itself rather than copied off Blizzard's label, which matters because a button TomoMod makes has no such label to copy — Blizzard's is kept as a fallback so an unexpected change in a future patch means slightly worse text rather than none. There is also a binding mode: turn it on, hover a button, press a key. Right-click or Escape clears one. It will not open in combat.",
            L["wn_351_special"] or "New — Things the bars knew and never showed you. On a skinned bar you could not see which stance you were in, which weapon enchant was equipped, or which pet ability was set to cast itself: the skin removes Blizzard's markers and washes out its highlight. There is now a ring for the active action and for equipped items, each with its own colour and a shared thickness, on one ring with an order of precedence so two of them never pile up into a mess. Pet autocast gets its own shine that sits alongside the two glows above. The pet bar can hide itself when you have no pet. Stances have no equivalent — there is no way to ask the game whether a class has forms at all, and Blizzard's own stance buttons already vanish when there is nothing to show.",
            L["wn_351_ownbuttons"] or "New — TomoMod can now make its own action buttons instead of borrowing Blizzard's. It is off everywhere, switched on one bar at a time, and undone by unticking it and reloading. Everything above works on them unchanged. Please read the limits before turning it on, because they are real: flyouts do not open on a converted bar — mage portals, hunter traps, summoned flasks. Vehicle and override bars still follow the page change, but the special exit button and its artwork do not come with it. The game's rotation highlight is not drawn on them; use the rotation glow above instead. Pet and stance bars are left on Blizzard's buttons entirely. It is marked experimental because it is.",
            L["wn_351_bindings"] or "New — The new buttons come with 106 bindings already declared, so they show up in the game's own keybinding window under a TomoMod heading with a section per bar. They are bound through a dedicated click rather than a plain left click, which is what makes casting on key press behave correctly — this is a known corner, and Bartender4 moved the same way years ago for the same reason.",
            L["wn_351_keybound"] or "New — TomoMod's bars join the shared binding mode that Dominos, Bartender4 and Bagnon use, so one pass binds your bars and theirs together instead of every addon insisting on its own. The library that arbitrates this is now included, so the shared mode is there whether or not you run one of those addons. One detail worth recording for whoever updates it next: it must be taken from a packaged release, never from its GitHub mirror, which computes its own version from a marker that only ever gets filled in inside a source checkout — copied anywhere else it fails as soon as it loads.",
            L["wn_351_tabs"] or "Change — The Action Bars options page is five tabs now instead of two: Skin, Buttons, Glow, Hotkeys and Bars. Everything new used to land in one long column on the skin tab, and three of this release's five layers would have gone there too.",
        },
    },
    {
        version = "3.4.6",
        highlights = {
            L["wn_346_probe_secret"] or "Fix — The buff icons in the Cooldown Studio, which 3.4.5 had just taught to keep their countdown in combat, threw an error on the first icon that watched a buff. The invisible marker attached to each icon was asked whether it was on screen, on the understanding that this is a question about a piece of the interface rather than about the buff — and it is not. Whether an aura icon is on screen *is* whether the buff is up, which is precisely what the game is withholding, so the yes-or-no that came back was itself withheld, and asking it the question was what failed. Protecting the call could never have helped: the call worked fine, and the failure came a line later, from looking at the answer.",
            L["wn_346_probe_cooldown"] or "Change — So the question is put to something else. Each icon already has its own sweep, the one the game drives directly, and that piece belongs to TomoMod rather than to the game: the sweep appears while the buff is up and goes away when it ends, and nothing stops the addon from reading that. It gives the same answer from the side of the line where reading is still allowed. The game's own marker is kept behind it as a second opinion, now asked safely, and if neither will answer the icon simply contributes nothing that frame and carries on driving the sweep — which was always the larger half of what it is there for.",
        },
    },
    {
        version = "3.4.5",
        highlights = {
            L["wn_345_class_secret"] or "Fix — Health bars threw an error on every update for any player whose class the game now hides, 399 times in a single session in the report that led to this. Patch 12.1 widened what an addon is not allowed to read, and a hidden value is not simply missing: it is live, and it fails the instant anything is done with it — comparing it, looking something up with it, joining it to a piece of text, or even asking whether it is true. So the check has to come first; there is no catching it afterwards. Sixteen places in TomoMod each read a unit's class and looked the colour up the same way, and they now all go through one set of helpers that asks whether a value can be read before touching it. Each place decides for itself what an unknown class means, because the right answer is not the same everywhere: the class reminder assumes someone might need the buff rather than skipping them, the caster tint on hostile nameplates is left off rather than guessed, and the keystone list and TomoScore simply draw without a colour. The group leader crown is in the same family — whether someone leads the group can also be hidden now, and when it is the crown stays hidden, since showing one on a player who may not be the leader is worse than showing none.",
            L["wn_345_class_passthrough"] or "New — And then the class colours came back. Falling back to a faction colour when the class cannot be read is correct, but in a dungeon that is every single person in the group, so the frames would have been the wrong colour permanently rather than now and then. It turns out the game will still colour a unit for you even when it will not tell you the class: the class goes into one of the game's own functions and the colour comes straight back out of another, into the bar, without the addon ever reading either. Health bars on unit frames, nameplates, party frames and raid frames use that route first and keep their class colours. It only works where the colour goes straight onto something, though — anything that needs to darken or blend it has to read the numbers, and there the faction colour is still the answer.",
            L["wn_345_nameplate_auras"] or "Fix — Enemy nameplates disappeared when you turned the camera. Not the auras on them: the whole plate. Reading a unit's auras is another thing patch 12.1 can now refuse, and the refusal came from the middle of drawing the plate, so everything after it — the health bar, the name, the cast bar — simply never happened, and the plate looked deleted. Turning the camera set it off because that is what brings new plates into view. Every aura read on a nameplate is now guarded on its own, so a refusal costs that one aura its icon or its countdown and nothing else. Two of the guards written for this turned out to protect nothing at all, for a reason worth knowing if you write Lua: a guard placed around a call does not cover another call passed to it as an argument, because the argument runs first. One of the two sat around the exact call that was throwing.",
            L["wn_345_aura_probe"] or "Internal — Eleven different parts of TomoMod scan a unit's auras — the auras on your frames and on nameplates, the dispel highlight, the HoT row, the group buff icon, the defensive icons, CooldownForge's buff tracking. Each one used to walk up to forty aura slots one at a time, guarding every single step, and find out only at the end that the game was not going to answer at all. They now ask once, and the answer is remembered for the rest of that frame, so forty group frames cost one question instead of sixteen hundred guarded steps. The question is deliberately asked through the most permissive way of reading an aura, so an answer of no means every other route was already shut and nothing that could have been drawn is being skipped. One real bug came out of it: CooldownForge was emptying its own list of tracked buffs whenever a rescan was refused, and then tracking nothing at all until the game allowed a read again. Worth being plain about the limit — this makes things cheaper, not more complete. An icon whose scan cannot read anything still goes dark, exactly as it did before.",
            L["wn_345_aura_engine"] or "New — Auras were missing for most of a pull, and nothing said so: no error, nothing on the plate or the frame, just an empty space where the thing you wanted to see should have been. Everything else in this release makes a refused aura read harmless; none of it makes the aura come back, because the game will not hand it over while a fight is running. So TomoMod stops asking. It now describes what it wants — these auras, this many, laid out like this, styled like this — and the game does the looking and the sorting itself and hands back the finished icons. Nothing on TomoMod's side reads an aura any more, so there is nothing left to refuse. Every aura row in the addon works this way now: nameplate debuffs and buffs, the auras and target buffs on your frames, party heal-over-time icons, raid debuffs and raid heal-over-times. The heal-over-time rows needed one extra step, because they worked by recognising particular spells and the spell is exactly what is withheld — so the list of spells to watch is handed to the game up front, and it does the picking. The dispel cue took the longest to work out and changes shape as a result. It used to be a coloured border around a player's frame, lit by checking each harmful effect against what you can remove — and since neither of those can be looked at any more, it only ever lit up when you were out of combat, which is the opposite of when a healer needs it. It is now a small icon in the corner of the frame, and the game itself picks which effect to show: there is a way to ask it directly whether you can dispel something, and it answers without letting anyone read anything. Two things to know about it: bleeds never appear, because no class ability removes one, and crowd control is left out on purpose since it has its own display. Four bugs were caught along the way — an error every time a nameplate went away, icons created mid-fight that came out with no size and stayed invisible for good, switches for showing debuffs or heal-over-times that stopped taking effect until a reload, and a size slider that had quietly stopped controlling anything.",
            L["wn_345_aura_layout"] or "Fix — Aura rows stopped wrapping and always grew the same way, whatever the settings said. Handing the display over to the game meant telling it how big one icon is, and that turned out not to include which way the row should run or where it should wrap — those belong to the row itself, and were simply never passed on. Both directions work again, horizontal and vertical independently, along with the spacing between icons. Related: a row set to show eight auras could draw sixteen when it was showing both buffs and debuffs, since those are two separate lists and each was given the full allowance. The allowance is shared now. The flip side is that a row of eight can no longer be filled entirely by debuffs when there are no buffs to show — the two lists cannot lend each other room.",
            L["wn_345_cdf_probe"] or "New — Buff icons in the Cooldown Studio keep their countdown in combat. The studio is the one display that cannot be handed to the game wholesale: it puts cooldowns and buffs in the same row, which the game has no concept of, and what it really needs is narrower anyway — is this buff up, and how long is left — which is exactly what it is no longer allowed to look at. So it asks without letting the game draw: an invisible marker is attached to each icon, watching only that one buff, and the game drives the icon's own sweep directly. Whether the buff is up is answered by asking that marker whether it is on screen, which is a question about a piece of the interface rather than about the buff. One consequence worth knowing: only one thing is allowed to write the sweep at a time, because two of them taking turns is what made it flicker.",
            L["wn_345_dm_dropdowns"] or "Fix — On the Damage Meter options page, the theme and bar texture dropdowns opened with the right number of rows and nothing written on any of them. The meter labels its lists one way and TomoMod's dropdown expects another, and unlike the other controls that one has no fallback, so every row was drawn blank. The Damage Meter page also has its own icon in the menu now — it had been sharing the Diagnostics one, so two entries carried the same picture.",
        },
    },
    {
        version = "3.4.4",
        highlights = {
            L["wn_344_damagemeter"] or "New — TomoMod now has a damage meter. DPS and HPS, damage taken, avoidable damage, enemy damage, absorbs, interrupts, dispels and deaths, sorted into Damage, Healing and Actions that you cycle from the header, with a Current and an Overall session and a combat timer. Worth knowing how it works, because it explains what it can and cannot do: it reads Blizzard's own combat data rather than listening to the combat log and adding everything up itself. That means no wall of events to sift through, and numbers that match Blizzard's own meter because they are the same numbers. A client without that data says so plainly instead of showing you an empty window. It answers to /tdm, and can report to say, party, raid, guild, instance, a whisper, whichever channel fits your group, or just to yourself.",
            L["wn_344_dm_windows"] or "New — Up to five meter windows at once, each with its own type, session, columns and number format: watching damage and healing side by side is the ordinary case, and one window meant cycling back and forth all fight. Drag one against another and they dock edge to edge — from then on they move together and share the edge they meet on, so resizing one resizes the other, and pulling a window away unhooks it again. Nine looks come with it — Tomo Dark, Tomo Neon, Minimal, Glossy, Ember, Frost, Terminal, Void and Parchment — along with the bar texture, the font and its size, the bar height, the accent colour or class colours, how transparent the window is in and out of combat, and an option to keep your own bar pinned in view.",
            L["wn_344_dm_breakdowns"] or "New — A number on a bar does not tell you what produced it. Left-click any bar to open its spells inline, right-click to give them their own window: totals, hits, crits and crit rate per spell. A target breakdown answers the other half — not what you cast, but what you cast it into — and each pull can be read on its own as a segment rather than only as part of the running total. Clicking a player in the Deaths list opens a death recap of what killed them, which can also open by itself when you die; /tdm resetpos brings that window back to the middle if it has wandered somewhere unhelpful.",
            L["wn_344_dm_runrecap"] or "New — A run recap at the end of a dungeon: damage, healing, interrupts, deaths and avoidable damage taken for the whole group, opening on its own when the run ends, or brought back with /tdm recap. It builds itself up as you go rather than reading everything at the end, and that is not a preference — when a key actually finishes, the game will not let an addon read those values at all, so a recap written the obvious way could not even put the group in order. Instead a quiet snapshot is taken each time you drop out of combat, which is about fifteen times in a key and costs nothing you would notice. Anything unreadable at that moment is left alone rather than overwritten, so the last good figure for a player is never lost.",
            L["wn_344_dm_standalone"] or "Note — The meter is also published on its own as TomoDamageMeter. If you have that installed, the copy inside TomoMod stands aside as it loads and tells you so once at login, rather than two meters arguing over the same windows, settings and combat sessions. The bundled one always yields: installing the standalone is a deliberate choice, and the versions of it already out there have no way of knowing to step aside themselves.",
            L["wn_344_cds_window"] or "Fix — In the Cooldown Studio, the column of bar buttons down the left drew on top of the edit-mode button at the bottom of the window, and the labels spilled out of the buttons carrying them: 'Import : Buffs suivis' was simply wider than the box it sat in. The column had outgrown the room set aside for it when the import buttons were added, and nothing in this interface trims a piece that overflows — it just draws over whatever is beneath. The space is now worked out from what it has to hold, the buttons are wide enough for their own text, and the window is larger to pay for it. It also stops asking for more room than your screen has: it had only ever been told to stay on screen, which does nothing for a window that is bigger than the display, so on a smaller screen the whole left column could sit past the edge. It now fits itself to the space available, which is what makes making it bigger safe in the first place. AstralForge is built on the same window and gets the same treatment. On the dashboard, the Cooldown Studio card has also moved up next to the Tomo suite card, since both are ways out to something else.",
            L["wn_344_changelog_popup"] or "Fix — The What's New page could not lay out the notes it was showing: expanding a release wrote its paragraphs on top of one another. The reason is that a block of text has to be measured before the window has decided how wide it is, so a paragraph destined to wrap over six lines was measured as one, and everything below it was placed in the space that one line would have taken. Rather than teach the page to measure text, it now hands the release you picked to this very window, which has always been able to scroll. The page itself is now an index: every version as a button with the number of notes it holds, four to a row, newest first — fifty-nine of them in a single column made for a lot of scrolling to reach anything old. Two smaller things came with it. Reading an old release no longer counts as having read the current one, so looking up what changed in 3.2.1 out of curiosity will not swallow the notice for an update you have not seen yet. And this window's scrollbar had kept Blizzard's two brass arrows at either end of an otherwise green track; they are gone, and the bar uses the space they were holding.",
            L["wn_344_dm_config"] or "New — The meter's settings are now a proper Damage Meter page in TomoMod's options rather than a button that sent you to another window. The skin, the bar texture, the font and its size, the bar height and class-coloured accent; how transparent the window is, out of combat and on the detail panels; hiding realm names, keeping your own bar in view, bar tooltips, the combat timer and which side it sits on, resetting when you enter an instance, snapping the windows together; the automatic run and death recaps, and how many lines a report sends. Underneath, both this page and the meter's own window now go through one shared description of what has to be refreshed when a given setting changes — otherwise there would be two copies of that, and they would disagree the first time either one was edited. If a refresh does go wrong the setting is still saved, rather than showing you an error and quietly reverting what you just changed. Columns, adding windows and filtering by category deliberately stay in the meter's own window, since they act on one particular window rather than on everything; the page says so and takes you there. That window also used to open behind the options rather than in front of them, which is fixed.",
            L["wn_344_aura_secret"] or "Fix — Unit frame auras threw a stream of errors in patch 12.1 — 189 of them in a single session in the report that led to this. The game used to simply return nothing when an addon asked for a unit's auras in a state it did not approve of; it now refuses the request outright, and the refusal was not being caught, so it fired on every single aura event. It is caught now, and there is somewhere for it to go: the auras are read one at a time instead, which is slower but is the only route left open, and an aura that still appears beats one that produces an error. CooldownForge's buff watcher had the same problem from the other direction — the aura update the game sends can now arrive entirely unreadable, and merely testing whether it was a full update was enough to fail, another 38 times in one session. An unreadable update is now treated as a full one and everything is simply re-read, which is the only way to stay current when the details cannot be looked at.",
        },
    },
    {
        version = "3.4.3",
        highlights = {
            L["wn_343_changelog"] or "New — A What's New page in the options, holding every release TomoMod has ever shipped. Until now the release notes only ever appeared in the popup that follows an update, and that popup shows the version you have just moved to and nothing else — close it and the text is gone for good. The new page lists every version, newest first: click one to read its notes, click again to close it, or open and close them all at once. It reads the same notes the popup does, so there is no second list to fall out of date.",
            L["wn_343_cdf_resync"] or "New — Cooldown Studio: a bar you built from Blizzard's Cooldown Manager can now be brought back in line with it. Those bars were correct on the day you made them and had no way back afterwards, so a class rework left you comparing lists by hand. Resynchronise re-reads the category: abilities Blizzard has added since arrive, abilities it has dropped are removed. Everything you did to the bar survives — a spell that is still listed keeps its entry exactly as you tuned it, glow condition, spec visibility and per-entry effects included — and anything you added yourself is never touched and never removed, whatever Blizzard's list does. A spell you had added by hand that Blizzard later adds to the category stays yours rather than being claimed, so a later resync can never delete something you created.",
            L["wn_343_cds_icons"] or "Cooldown Studio: the list of what a bar tracks read 'Sort 384100' — correct, and no help at all. Each entry now shows its icon and its name, with the id kept in brackets after it. Until the game has cached a spell you still get the number on its own, which is the honest answer rather than a blank line.",
            L["wn_343_cds_scale"] or "New — Cooldown Studio: an icon scale slider, on both bar layouts. Making a bar bigger meant moving a width slider and then moving a height slider to exactly the same place; it is one control now. It is a view over the size you already had rather than a new setting, so there is still a single number underneath and nothing to keep in step. A button sets the icons back to square, keeping the size you were looking at rather than jumping back to the default. Once you deliberately set a width and a height apart the scale slider greys out — 'scale by 1.2' has no single answer at that point — and that button is what brings it back.",
            L["wn_343_iconsize_range"] or "Fix — Cooldown Studio: an icon size below 24 or above 64 looked accepted and was not. The bar rendered at the size you asked for and kept it, and then some later action — a resync, an import, a duplicate — quietly reverted it, with nothing to connect the change back to anything you had done. Meanwhile the separate width and height settings accepted 8 to 128 the whole time, so the same small icon was reachable through one control and refused by the other. There is one range now, 8 to 128, for all three. It is wider than before rather than narrower, so no bar you already have changes size.",
            L["wn_343_studio_shortcut"] or "New — A Cooldown Studio button on the dashboard, so opening the studio no longer means finding the CooldownForge panel first.",
        },
    },
    {
        version = "3.4.2",
        highlights = {
            L["wn_342_astralforge"] or "New — AstralForge, a full-screen designer for the pieces of a unit frame. Until now every part of a frame sat where TomoMod had decided it sat, and all you were given was a slider that pushed it a few pixels from there — so moving the name to the other side was not a setting, it was a number big enough to shove it across. You now drag each piece where you want it: which corner of the element attaches, and what it attaches to — the frame, the health bar, the resource bar, the info bar. It snaps to a small grid, lines up with the other elements as you pass them, and holding Shift drops it wherever you like. The sliders are still there for a two-pixel adjustment, and both write the same thing. It opens from the UnitFrames options, and like the Cooldown Studio it only loads when you ask for it. What you drag is a preview copy, never a real frame — the game protects those during combat, and editing one directly is what causes the interface problems TomoMod has spent two versions removing.",
            L["wn_342_af_nameplates"] or "New — Nameplates get the same designer, and for them it is entirely new ground: apart from the raid marker, nothing on a plate had a position setting at all. The name, the health value and percentage, the level, the classification icon and text, the cast bar with its icon, name, timer and shield, and the quest icon can each be placed where you want them. Your existing raid marker position is carried over unchanged, and everything else starts exactly where it already was. Two things are deliberately not draggable: auras, whose position is worked out from their place in the row rather than set, and the parts pinned to a bar's fill — a handle on those would claim to move something it cannot.",
            L["wn_342_af_props"] or "New — Opacity, scale and a text size override, per element. The size override starts at zero, meaning 'leave it as the module worked it out', so nothing changes until you say so. Only the settings a given piece can actually honour are shown: opacity means something on a piece of text, a scale does not, and a plain image takes neither of the two — you get the ones that apply to what you selected rather than a fixed row of sliders half of which do nothing.",
            L["wn_342_af_customtext"] or "New — Text you write yourself. Add up to six custom texts to a unit frame and four to a nameplate, write something like '[name] - [level]', and place it like any other element. The tokens are name, level, class, race and guild on a frame, and name, level, class, race and classification on a plate. Worth knowing why this is not simply the addon gluing words together: in Midnight the game hands out a unit's name and level as values an addon is forbidden to read, so anything as ordinary as joining a name to a dash would fail. Your template is turned into a pattern with the values passed through untouched and assembled by the game itself.",
            L["wn_342_af_presets"] or "New — Layout presets, and share strings. Save the whole layout of what you are editing under a name — every position, every opacity and scale, every custom text — apply it back later, or hand it to someone else as a string they paste in. Anything coming back in is checked the same way whether it is yours or a stranger's: values the addon does not recognise are dropped, an impossible anchor is refused before it reaches the game, and a layout that refers back to itself in a loop is broken apart. The worst a pasted string can describe is a layout.",
            L["wn_342_af_migration"] or "Your frames do not move. Every position you had set is converted into the new form together with the anchor the engine used to apply it against, so a converted profile and a brand-new one draw exactly the same frame. One old setting is dropped rather than converted — an aura offset the engine stopped reading back in 3.0.5. It has had no effect for several versions, and converting it now would move auras that are sitting precisely where you put them. Aura containers also stop keeping their position in a second place of their own: dragging one in game, placing it in the designer and setting it with the sliders now all write to the same setting, so they can no longer disagree.",
            L["wn_342_af_secret"] or "Fix — Opening AstralForge on a unit that was actually there could leave you with an empty window. The preview it builds was fed real data, and in the current game any piece of the interface whose content comes from protected information — a health value, for instance — also hides its own position and size from addons. Measuring those is the designer's entire job, so the very first measurement failed and took the preview down with it. The preview now runs on made-up data: an invented name, an invented health value, which nothing stops it from measuring and which look exactly like what you are laying out. Two safeguards come with it: anything that still cannot be measured is simply left without a handle instead of stopping everything around it, and if the preview cannot be built at all the window still opens with its element list, its inspector and its presets rather than opening empty.",
            L["wn_342_keysync_realm"] or "Mythic+: the party keystone list was empty for everyone on your own realm. Their key was received and stored the whole time — it just could never be found again. When someone's addon sends you their key, the game names them as 'Alice-Varimathras' whether or not that realm is yours, so every key is filed under a full name; but when TomoMod asks the game about the person standing next to you on your own realm, it gets back 'Alice' with no realm, and that matches nothing. This appeared with the new keystone sharing in 3.4.1, because the library it replaced hid that mismatch inside its own code. A name with no realm is now retried against yours, so a same-realm key is found again — and it is done once, in the place the keys are stored, rather than being something every screen that reads them has to remember.",
            L["wn_342_escape_keys"] or "Fix — While one of TomoMod's own windows was open, your keys did nothing: you could not move, and your abilities did not fire. Any window that closes with Escape has to ask the game for the keyboard, and a window holding the keyboard keeps every key to itself unless it deliberately passes the rest on — which it only did as a side effect of receiving a key it had no interest in, and never at all during a fight, which is exactly when losing your keys costs the most. Every key now goes straight through; the window keeps Escape alone, and only out of combat. With it comes the other half of the problem: a window now holds the keyboard only while it is actually on screen. One closed with Escape kept its grip afterwards, so the trouble outlived the window that caused it and the next window you opened inherited it. This covers every window in the addon that closes with Escape — the options, the installer, the loot window, the Mythic+ hub, TomoScore, the profession helper, the bag skin, the chat copy window and the Cooldown Studio.",
            L["wn_342_keysync_debug"] or "New — /tmt keysync. It prints which channel the sharing is using, whether you are in a guild, every key it currently holds, and then each member of your group with whether their key can actually be found. That last line is the whole point: a key that is stored but not found is a different problem from a key that never arrived, and from the party list the two look exactly the same — which is why the bug above took longer to identify than to fix. The command also asks your group for their keys as it finishes, so running it twice a second apart tells you whether anyone answered.",
            L["wn_342_cdf_viewer"] or "New — Cooldown Studio: build a bar from Blizzard's own Cooldown Manager in one click. Three buttons — Essentials, Utilities and Tracked Buffs — create a ready-made bar from the abilities Blizzard curates for the specialisation you are on, in its own order, and the tracked buffs come in as buffs rather than as cooldowns, so they appear while they are up and count down what is left of them. The list is read the moment you click and never stored: Blizzard keeps those three sets up to date through class reworks, so an imported bar follows the game instead of freezing a copy that would be right for one patch and quietly wrong from the next one on. Where a talent has replaced an ability with another, it is the replacement that lands on the bar, so the icon matches the one in your spellbook. It is a starting point, not something you are stuck with — what you get is an ordinary bar you can reorder, trim and restyle. And if your client has no Cooldown Manager, or Blizzard curates nothing for the specialisation you are on, the studio tells you so rather than handing you an empty bar.",
        },
    },
    {
        version = "3.4.1",
        highlights = {
            L["wn_341_style"] or "Mythic+ tracker: it was the last screen in TomoMod wearing colours of its own. Last version brought the end-of-run scoreboard in line and said the tracker you see during the key would not match until it got the same pass — this is that pass. It now uses the same green, the same text and the same borders as every other panel, on a near-black background with a mint cast. A font size setting comes with it, from 0.70 to 1.60, which grows the text without growing the panel.",
            L["wn_341_segments"] or "Mythic+ tracker: the timer is now three segments, one per chest, each counting down the time left before that chest is lost. Until now the panel showed the elapsed time and the gap to the full limit, and 'how long until +2 is gone' was arithmetic you did in your head between pulls. The segments are sized from the dungeon's real chest times, they read mint, yellow then red from left to right so the window being spent names itself by colour, and a spent one dims instead of disappearing so the bar still reads as a history of the run. If you would rather read the bar by shape than by colour, one setting paints all three in the same green.",
            L["wn_341_presets"] or "Mythic+ tracker: one fixed panel became three looks. Panel is what you already had. HUD drops the background and the header block and lists the objectives as plain text, slightly larger, on a condensed font. Minimal is three rows and nothing else — information, timer, forces — with the boss list gone and its tally moved up into the header, so you still know you are on 2 of 4 without spending four rows saying so. Everything a preset sets is also a switch of its own: background, header block, dungeon name, boss list, timer layout, segment colours, text size. Change one by hand and the preset says custom rather than pretending you are still on it.",
            L["wn_341_forces"] or "Mythic+ tracker: the forces bar could lie rather than admit it could not see. The game hides a growing number of values during a fight, and the bar was doing sums on them anyway — so a count it could not read came out as zero, and a bar that empties itself mid-pull does not look like missing data, it looks like the pull reset. It now holds the last figure it could actually read, and falls back in stages: exact counts, then the percentage alone, then frozen. It also shows what is left to kill rather than 730 / 1000, and states the time the count completed at.",
            L["wn_341_bossnames"] or "Mythic+ tracker: boss names came from a hand-written table that goes stale every season. Blizzard adds dungeons and reuses journal entries between them, so a list like that is wrong the day a patch ships and nothing warns you — the names simply degrade to 'Boss 1'. Names are now looked up live from the game, three ways in order: the map you are standing on, then the dungeon's own name matched against the journal, then the raw objective text if neither works. What it finds is remembered per dungeon, so it is learned rather than authored and cannot rot.",
            L["wn_341_splits"] or "Mythic+ tracker: you had nothing to compare a run against. Every finished key is now recorded per dungeon and per key level, and on the next attempt each boss shows how far ahead or behind your best you are. Forces get the same treatment: on each kill the tracker notes where your best run stood on trash at that point, and shows you the gap. A depleted run is recorded too — it may be the only reference you have for that dungeon, and a slow one beats none. Nothing is preloaded: an 'expected trash at boss 2' table shipped by an addon would be somebody else's route and would be wrong the day the dungeon is retuned. A button in the options clears what has been recorded.",
            L["wn_341_banner"] or "Mythic+ tracker: the end of a key passed without comment. There is now a banner — in time or depleted, the run time, the upgrades, and the margin in brackets. The margin is the number everyone says out loud when the key ends, and it was the one thing you had to work out yourself from a timer that had already stopped.",
            L["wn_341_options"] or "Mythic+ tracker: it had a second options window of its own, holding the same settings as the Mythic+ page in TomoMod's config — two places to change one value, and they drifted. It is gone: /tmt now opens the config on the Mythic+ page. Every other /tmt command is unchanged.",
            L["wn_341_legibility"] or "Mythic+ tracker: the text written on top of a filled bar was unreadable. Every label the tracker draws has a black outline behind it, and that text was almost black itself, so it dissolved into its own outline — the chest markers on the timer and the label on the trash bar were smudges while the white clock beside them stayed sharp. They are light now. Two smaller things went with it: a negative duration could print as a large positive one, so -3:40 appeared as 56:20, and the first boss no longer repeats its kill time twice on the same line.",
            L["wn_341_cds_taint"] or "Cooldown Studio: opening it could stop you logging out, by either of two routes. One line wrote to a table belonging to Blizzard — harmlessly, as far as the value went, but writing to it at all is enough for the game to distrust every window built from that table afterwards, the logout confirmation included. Separately, the 'copy the style from' popup handled Escape with its own copy of code that lives elsewhere in the addon, and that copy had drifted: it had lost its combat check and handed keypresses back to the game in a way that made the game menu refuse to open. Both are fixed, and the popup now shares the one implementation instead of keeping a private one. Neither ever affected a session in which you had not opened the Studio, which is why they took a while to pin down.",
            L["wn_341_keysync"] or "TomoMod was reporting itself as a source of interface problems dozens of times at every fight, without being one. The cause was a bundled library, LibOpenRaid, which works out whether the game is hiding a value by trying to read it and catching the error — the answer is right, but the game writes TomoMod's name into its log on every attempt, and that happens constantly. The library is no longer shipped. It was there for four keystone functions and nothing else, while also syncing cooldowns, gear, talents and durability, and it is the cooldown part that caused all of it. Keystone sharing is now TomoMod's own, in a file a fraction of the size: your key comes straight from the game, and the rest is shared with your group and guild directly, kept until the weekly reset. One thing that should now work for the first time: the party key list refreshes on its own when somebody's key changes — the old callback was wired in a way the library never actually called.",
            L["wn_341_buffskin"] or "The buff and debuff skin has been removed — the whole feature, along with its tab and its settings. It cannot be made to work on the current game: the buttons Blizzard uses for auras now hide their own size from addons, and putting a border on one raises an error inside Blizzard's code rather than in TomoMod's, where it could have been caught. On top of that those buttons are reshaped almost every patch, and this version alone spent five attempts chasing them. That is upkeep with no end, on the one part of the interface where Blizzard's own display is already fine. Your buff frame goes back to the default one, and the settings are cleared from your profiles since there is nowhere to carry them. If a skinned buff frame matters to you, a dedicated aura addon is the honest answer.",
            L["wn_341_auratracker"] or "The Aura Tracker has been removed. CooldownForge does the same job and does it better, and running two overlays that compete for the same corner of your screen was never going to end anywhere else. Its tab, its presets, its mover and its settings go with it, and a one-time cleanup drops the leftover settings from your profiles instead of carrying them around forever. If you had added spells to it by hand, they are not lost quietly: they cannot be converted automatically, so TomoMod lists them once at your next login, with their names, and you can recreate the ones you still care about in the Cooldown Studio.",
            L["wn_341_cds_reload"] or "Cooldown Studio: closing it can now reload your interface, and does by default. The Studio only loads when you ask for it, but the game cannot unload an addon again — a reload is the only thing that releases it, and it is also what clears anything the session may have picked up. The prompt waits for a sensible moment: never in combat, never during a key, never inside a dungeon or raid, and it comes back once you are out. You can turn it off in the CooldownForge options. Separately, leaving the Studio while the bars were unlocked used to strand them in edit mode with the resume button still floating on screen; both ways of closing the window now tidy up.",
        },
    },
    {
        version = "3.3.6",
        highlights = {
            L["wn_336_cdf_active"] or "CooldownForge: a buff that is up looked exactly like a spell that is recharging. Since an icon can track a buff instead of a cooldown, both states reached the screen as the same plain picture, and the only way to tell them apart was to read the number on them. Two new settings separate them: the cooldown sweep and the border can each take your class colour, or one you pick, while the tracked buff is active. Both are off everywhere by default, so nothing you have already built changes, and they only apply to entries that actually track a buff.",
            L["wn_336_cdf_threshold"] or "CooldownForge: the countdown can change colour when a spell is nearly back. Set a threshold in seconds, up to 60, and pick the colour it switches to underneath — reading a colour mid-fight is quicker than parsing a number. Zero turns it off and is the default. Where the game refuses to tell an addon how long is left, which is the case under restricted content, the timer keeps its normal colour instead of guessing: a countdown that guessed wrong would be worse than one that stayed plain.",
            L["wn_336_cdf_font"] or "CooldownForge: the text on your icons was locked to one font. The setting had existed in every bar since the feature shipped and nothing ever read it — the countdown, the stacks, the spell name and the mirrored timer were all hardcoded to TomoMod's own Poppins. You can now pick any font shared by your other addons, choose a thin, thick or absent outline, and give the countdown its own size independently of the stack and name text, so changing font no longer means abandoning your preset's sizing. Both size sliders run from 8 to 28 pixels now instead of 9 to 20. With no font-sharing addon installed the list holds Poppins alone and says so.",
            L["wn_336_cdf_glow_charges"] or "CooldownForge: glow can wait for every charge to come back. A two- or three-charge spell was ready or not as far as glow was concerned, so one charge out of three lit up exactly like three out of three. The new condition is answered from the recharge itself rather than by counting — the game hides the current count during a fight, and counting is precisely what cannot be done there. A spell with no charges falls back to plain readiness, so the condition is not silently useless on most of your entries.",
            L["wn_336_cdf_glow_stacks"] or "CooldownForge: glow can wait for a tracked buff to reach a number of stacks, set per bar and overridable per icon. The game does not publish a maximum for a buff, so the number is yours to give — 2 to 20 on a bar, up to 99 on a single entry. If the stack count cannot be read the glow stays off rather than firing on a guess, since a glow is something you act on.",
            L["wn_336_escape_taint"] or "Windows: pressing Escape could stop opening the game menu at all, leaving you unable to quit the game normally. Eight TomoMod windows closed on Escape by putting themselves on a list Blizzard walks through its game-menu code, and that code makes three calls the game refuses once anything in your session has upset it — so the menu never opened and Escape did nothing. Those windows now handle Escape themselves and never go near the game menu. Every other key still passes through. One thing to expect: on those eight windows Escape no longer closes them during a fight, because the call that makes this work is itself restricted in combat. Their close button still does.",
            L["wn_336_statusbar2"] or "New — Hide Blizzard Status Bar 2, in QOL, Automations. Edit Mode's second status bar sits beside the main one rather than inside it, so the option that hides Blizzard's status bars never reached it and nothing anywhere did. It is made invisible and click-through rather than deleted, which is what keeps it from causing errors: Blizzard still owns the bar, so it stays where it is in Edit Mode and you can still move it there. Unticking the option puts it back after a reload.",
            L["wn_336_ab_empty_refresh"] or "Action bars: with empty slots hidden, dragging a spell onto one left the button blank. The spell was really there and cast when clicked, but nothing was drawn on it until you reloaded — and dropping onto a bar blanked the neighbouring slots that had just been revealed for the drag. Hiding empty slots was changed last version to stop causing errors on Blizzard's buttons, and the new method left the bar unaware that a slot had been filled. It now notices, including when paging or a stance changes what a button points at.",
            L["wn_336_uf_aura_growth"] or "Unit frames: auras only ever grew downwards. The direction setting covered left and right, and the vertical half of the question had no setting at all — so a frame sitting low on your screen sent its second row of debuffs off the bottom edge with nothing anywhere to stop it. A vertical direction now sits beside the horizontal one on every unit's Auras tab, and the rows can stack upwards instead. Downwards stays the default and nothing you have already set up moves; the frame itself does not move either, the aura block simply grows the other way.",
            L["wn_336_ts_palette"] or "Mythic+: the end-of-run scoreboard was the one screen in TomoMod with colours of its own — a cyan accent where the rest of the addon is green, on a blue-tinted background where the rest is neutral. It came from before that board was part of TomoMod and had never been brought in line, so it read as somebody else's window. It now takes the same theme as everything else. Two colours stay as they were on purpose: the 'in time' bar and its text keep their own green, because on a panel that is already green everywhere an 'in time' marker in the same green stops telling you anything. The tracker you see during the key itself is untouched for now, so the two will not match until it gets the same pass.",
            L["wn_336_cdf_talent"] or "CooldownForge: an icon can be tied to a talent — shown only when it is taken, or only when it is not. The second half is as useful as the first, since a build that drops a talent usually gains something in its place, and both icons can now sit in the same bar with only the relevant one on screen. You give the spell the talent grants rather than a node number: nodes are renumbered at every talent rework, spells are not, so the condition survives a patch. It also follows your loadouts now — swapping talents announces itself differently from editing them, and only one of the two was being listened to, so a condition could keep answering with the previous build until something unrelated forced a refresh.",
        },
    },
    {
        version = "3.3.5",
        highlights = {
            L["wn_335_cdf_border"] or "CooldownForge: dragging the border thickness slider made the border disappear instead of thickening it. Each style setting was stored as one block, and the editor writes one field at a time — so setting the thickness threw away the border mode sitting next to it, and without a mode the icon was drawn with no border at all. Picking a colour did the same thing, and picking a mode quietly reset the thickness. Those settings now keep the fields you did not touch. No bar changes on its own; set the value again and you get what you asked for the first time.",
            L["wn_335_cdf_border_paint"] or "CooldownForge: even once it stopped disappearing, the border was barely visible and 1 pixel looked exactly like 4. The outline is drawn just inside the icon's edge, and the icon's picture covered the whole of it — so the border was painted and then hidden underneath, and making it thicker only buried more of it. The picture now stops short of the border and leaves it room. Two things to expect: a bordered icon shows its picture very slightly smaller, which is what a border costs, and a thickness you set while the slider appeared to do nothing will suddenly be visible — so a bar left on 4 will look much heavier until you set it to what you actually wanted. Icons with no border are unchanged.",
            L["wn_335_cdf_preset"] or "CooldownForge: touching any fine setting quietly turned your bar into a Tomo one. Picking a border colour on a Net or Verre bar switched its style to 'Custom', and Custom was not a real style — so the icon fell back to Tomo and the base you had chosen was gone. Which preset a bar uses and whether it has fine settings are now two separate things: changing the preset keeps your fine settings on top of the new one, and adjusting a fine setting leaves the preset alone. Bars already saved as Custom become Tomo with their settings kept, which is what they were already being drawn as, so nothing changes on screen.",
            L["wn_335_cdf_thickness"] or "CooldownForge: the border thickness slider goes up to 10 instead of 4. Four was a fair limit while the border was invisible; now that it is actually drawn it is not. Bear in mind the border takes its width out of the icon picture, so 10 on a small icon leaves very little of it.",
            L["wn_335_cdf_target"] or "CooldownForge: a bar can now depend on whether you have a target, alongside the existing combat, instance, group and raid conditions and with the same three choices — don't care, require it, require the opposite. For the bar you only want up while you are actually on something, or the utility bar that should get out of the way the moment you pick a target.",
            L["wn_335_cdf_dim"] or "CooldownForge: a bar whose visibility condition is not met can now fade instead of disappearing. Pick 'reduce opacity' instead of 'hide' and set how faint it should go, from 5% to 95%. The faded bar is still live — it keeps tracking cooldowns rather than freezing — so 'in combat = yes' with this option leaves you a readable, half-visible bar out of combat instead of one that comes back already out of date. Hiding stays the default and nothing changes for bars you have already set up.",
            L["wn_335_cdf_iconwh"] or "CooldownForge: icons no longer have to be square. Width and height are separate sliders now, 8 to 128 pixels each, instead of one size doing both — wide flat icons for a row across the top of the screen, tall narrow ones for a column beside your frames. Bars you have already built do not move: the new values start unset, and unset means 'keep the old square size'.",
            L["wn_335_cdf_aura"] or "CooldownForge: an icon can track a buff instead of a cooldown. Switch an entry to 'tracked buff' and it stays off screen while the buff is absent, then appears with its remaining time and stacks while it is up — so a proc can sit on the same bar as the cooldown that grants it. You can also name a different buff ID, for the procs that are granted by one spell and applied as another. Under Mythic+ the game hides most of what an addon can read about a buff; that is handled separately below.",
            L["wn_335_cdf_secret"] or "CooldownForge: a tracked buff disappeared the moment a fight started and came back the moment it ended. Every lookup went through the buff's spell ID, and in Midnight the game hides that number during combat — measured as fully readable out of combat against 6.5% in it, with every tracked buff going missing in the very frame the pull began. The game does hand out the ID once, at the moment the buff lands, together with a reference to that particular application; TomoMod now remembers the pair and asks about the application from then on, which the game keeps answering. The remaining time and the stack count are back in Mythic+ too, read the same way — the earlier note saying tracked buffs work there but without a timer is no longer accurate.",
            L["wn_335_cdf_aura_sources"] or "CooldownForge: tracked buffs are found through two paths now instead of four. Each had been added to cover a case the one before it missed, and nothing said which was actually doing the work — so they were measured over some 12 700 lookups each. Two carried the whole feature, and they cover opposite halves of it: one works during a fight, the other outside it. The two that produced almost nothing were removed, along with a sweep of all your buffs that ran every frame for every bar. One more gap is closed with them: a buff that only gains a stack is reported by the game as an update rather than as a new buff, so a proc first noticed that way mid-fight was never registered at all. What remains is a limit of the game, worth knowing rather than hunting for: during a fight it only names some auras. A buff already up when the fight starts is tracked normally; one applied in the middle of it may not be identifiable, and its icon stays hidden. There is no setting for that, and the tracked buff option now says so on the spot.",
            L["wn_335_cdf_viewer_source"] or "CooldownForge: a proc that lands in the middle of a fight is now tracked as well — the limit described just above is largely lifted. The game refuses to tell an addon which buff that is, but it has been drawing it on your screen the whole time: Blizzard's own Tracked Buffs display is not subject to the restrictions an addon is. TomoMod now reads that display — whether the icon is up, the time left on it, its stack count — instead of asking a question the game will not answer during a fight. Nothing is hardcoded and nothing protected is touched; it reads the same picture you are looking at. It only covers buffs Blizzard's Tracked Buffs display actually carries: for anything else the two previous methods answer exactly as before, so this adds cases and takes none away. Worth knowing if you use the new per-bar hiding: hiding a Cooldown Manager bar does not cost you this, because hiding works by transparency and the bar keeps running underneath. One visual detail to expect during a fight: where the game withholds the numbers but still draws the countdown, TomoMod mirrors that figure onto your icon — you get the time remaining as a number, without the sweep behind it, and it steps rather than ticks, because the bar refreshes on events instead of running a timer.",
            L["wn_335_cdf_aura_timer"] or "CooldownForge: a tracked buff could appear with no timer and no swipe even when the game had told us exactly how long it had left. There were two ways to put a countdown on the icon, and the wrong one was being preferred: the one that took a duration object, which the game hands back in a different shape from the one the cooldown display expects. It accepted it, drew nothing and reported no error — so the safety net meant to catch that failure never triggered, and the numeric path that would have worked was never reached. Readable numbers are now used first, and the object only when the game refuses to give the numbers. If you had tracked buffs showing as a bare icon, they get their timer and their stacks.",
            L["wn_335_cdf_glow_aura"] or "CooldownForge: the glow condition 'while a buff is active on you' went dark for the length of every fight, and nobody had connected it to the tracked buffs. It asked the game for your buff the same way tracked buffs originally did — the way that stops answering the moment combat starts — so the glow simply stopped, which reads as a glow that was never set up properly rather than as a bug. It now finds buffs exactly the way tracked buff icons do, so the two can no longer disagree about what you are carrying.",
            L["wn_335_microbar"] or "New — Micro Bar: Blizzard's little row of menu buttons becomes a bar of your own. Choose which buttons appear and in what order, horizontal or vertical, how many per line, their size, spacing, scale and opacity, and place it anywhere with the Movers panel. It can stay on screen, appear on hover, or appear on hover but stay up during combat. Icons can take your class colour, a colour you pick or the game's original look, with optional desaturation and a zoom under the cursor. Each button simply forwards your click to Blizzard's own, so everything keeps working in combat and nothing breaks when a new panel is added to the game. The originals also keep running underneath, so their alerts, their greyed-out states and their keybinds can be mirrored onto your buttons — with a choice of four alert glows, dimming for what is currently unavailable, and the keybind drawn on the icon.",
            L["wn_335_cdf_aura_gate"] or "CooldownForge: a tracked buff no longer has to be a spell you can cast. Before showing any icon the bar checks that the entry applies to you, and for a spell it checked your spellbook — which is right for a cooldown and wrong for a buff. Proc buffs are handed to you by a talent or applied by another spell, so your spellbook says you do not have them, and the entry was thrown out before anything looked at whether the buff was actually up. The icon never appeared — which is most of what tracked buffs are for. A tracked buff is now judged on the buff.",
            L["wn_335_cdf_aura_link"] or "CooldownForge: tracking a proc no longer means hunting down the buff's own spell ID. An ability and the buff it grants are almost never the same ID, so entering the ability — the obvious thing to do — watched a buff nobody ever has, and the icon simply stayed off screen. An entry now also tries whatever the game links to the ID you typed: Blizzard's Cooldown Manager already works this out for its own Tracked Buffs viewer, and TomoMod reads the same answer. Nothing is hardcoded, so it follows a patch that re-points a proc and a talent that swaps one, on its own. The optional buff ID field still works and still takes priority, for the cases the game does not link.",
            L["wn_335_cds_reorder"] or "Cooldown Studio: entries in a bar can be moved up and down. Reordering your icons meant removing an entry and adding it back at the end, then rebuilding everything after it. If the options panel is open on the entry you move, it follows that entry instead of staying on the slot — it used to end up editing whichever one had taken its place.",
            L["wn_335_mplus_teleport_override"] or "Mythic+: a dungeon teleport sitting in your spellbook could still be reported as not learned — the row greyed out, the tooltip saying it was unavailable, the click doing nothing. When a dungeon comes back in a later season, Blizzard re-issues its teleport as a different spell: Skyreach's is now cast as 'Voie des cieux', not the Warlords spell TomoMod's table lists. The check only ever asked about the listed one, so owning the current spell looked exactly like owning nothing. It now also asks the game which spell replaces the one it knows about, and accepts either — by spell number rather than by name, so it works whatever language your client runs in, and it follows a future season that re-points a teleport without needing an update.",
            L["wn_335_ab_taint"] or "Action Bars: the 'show empty button slots' option was the source of a burst of blocked-action errors on the bottom-left bar's buttons — errors the game blamed on whichever addon happened to be running at that moment, most recently making it look like Cooldown Studio was at fault. Showing the empty slots was done by writing into Blizzard's own button state and forcing the buttons shown, which the game then refuses to touch afterwards. It now uses the game's own 'always show action bars' setting, and bars that should not show their empties are made invisible and click-through instead. Blizzard keeps control of its buttons. Two things worth knowing: that setting is global, so it switches on as soon as one of your bars wants empty slots, and if you had turned it on yourself in Blizzard's options it will be turned back off once no TomoMod bar needs it. Dropping a spell onto an empty slot still works exactly as before.",
            L["wn_335_cdm_viewers"] or "Cooldowns: Blizzard's four Cooldown Manager bars can now be hidden one at a time, from the Cooldowns panel next to the Cooldown Studio button — Essential, Utility and the two Tracked Buffs displays each have their own tick. Ticking one takes that bar off the screen and out of TomoMod's placement mode and leaves the other three where they are. It replaces a single tick that did not hide anything: it only stopped TomoMod restyling those bars, so they stayed on screen in Blizzard's own look — a box labelled 'hide the Cooldown Manager bars' that made them more noticeable rather than less. A hidden bar is made invisible and click-through rather than deleted: it is still Blizzard's bar, still running underneath, and whether it exists at all is still decided in Blizzard's Edit Mode. Unticking puts it back exactly where you had placed it. The switch in CD & Resources is untouched and answers a different question — whether TomoMod dresses these bars at all, rather than which of them you want to see. The two also work together now: hiding a bar keeps working when the Cooldown Manager module itself is switched off, which had been the one combination where the tick was saved and never applied to anything — and which is exactly what someone who wants these bars gone is likely to try.",
            L["wn_335_cdf_entry_spec"] or "CooldownForge: an entry's specialisation could only be chosen at the moment you added it. After that nothing anywhere let you change it — an icon added on the wrong spec, or added before you decided it should only show on one, had to be deleted and re-added, which also meant losing its place in the bar. The dropdown now sits on the entry itself, both in Cooldown Studio and on the Cooldowns settings page.",
            L["wn_335_scrollbar_click"] or "Settings: the scrollbar in the settings window can be seen and used now. It was five pixels of dark grey on a dark panel — almost impossible to hit, and hard to notice at all, so the mouse wheel was in practice the only way down a long page. Clicking the track above or below the handle now jumps most of a screenful in that direction, and the handle can be grabbed without having to aim at it precisely. It also looks different, deliberately: a little wider, in a lighter grey, with a thin dark line down its inner edge so it stands out from the panel behind it. The text boxes that hold import and export strings have the same bar, and now match. This applies to every page in the settings, not just one.",
            L["wn_335_cds_tabjump"] or "Cooldown Studio: changing almost anything threw you onto a different tab. Editing an icon's style dropped you on Sharing, ticking a visibility condition dropped you on Layout. The editor rebuilds itself after nearly every change and reopened the tab it had remembered — but it only remembered a tab the very first time that tab was built, so it was stuck on whichever one you had opened last for the first time, and returning to a tab you had already visited never updated it. It now follows the tab you are actually on.",
        },
    },
    {
        version = "3.3.4",
        highlights = {
            L["wn_334_presets_roles"] or "Presets: the Tank, Healer and DPS presets wrote three or four settings each and took everything else from the shared base — three archetypes that were the same configuration under different names. Each one now writes a full role setup across party and raid frames, nameplates, target auras, resources, cooldowns and castbars: wide threat-coloured plates and numeric threat for tanks, much larger frames with HoTs, dispels and shields for healers, taller resource bars and only your own debuffs for damage.",
            L["wn_334_presets_reset"] or "Presets: switching from one to another kept the previous one's settings. A preset only ever wrote its own changes, so anything it did not mention stayed where the last one left it — going from Tank to Healer left you healing with tank-mode nameplates. The shared base now carries a value for every setting any preset can touch and is written first every time, so applying a preset gives the same result whatever you had before it.",
            L["wn_334_presets_cards"] or "Dashboard: the presets are cards now instead of four coloured buttons with nothing on them but a name. Each shows its role icon, its tagline and three points of what it actually changes, with the full description on hover — and the one you are currently running is marked Active, which nothing on that panel used to tell you.",
            L["wn_334_role_badges"] or "Settings: sections that matter to a particular role now carry a small tank, healer or damage icon in their header — heal-over-time and dispel displays, defensive cooldowns, tank mode, interrupt tracking, threat text and the rest. Hovering the icons names the roles.",
            L["wn_334_role_filter"] or "Settings: a role focus bar was added at the top of the sidebar — All, Tank, Healer, DPS. Picking one keeps the settings for that role at full brightness and dims the others. It dims rather than hides on purpose: an option you already know the location of is still exactly where you left it, whatever focus is active. Your choice is remembered between sessions.",
            L["wn_334_chat_history_settings"] or "Chat history: the only thing you could do with it was turn it on. It has a section of its own now — how long messages are kept (1 hour to 3 days, or no limit), how many lines are stored (10 to 500), and a session marker printed after the restored lines so everything below it is clearly from the current session. The stored limit was also off by one: it said 128 lines and kept 127.",
            L["wn_334_chat_history_delay"] or "Chat history: the restored lines used to print at exactly the moment addon load messages and Lua errors reach the chat, burying up to a full page of them under the replay. The history now waits a couple of seconds before appearing — adjustable, or zero for the old behaviour.",
            L["wn_334_chat_history_channels"] or "Chat history: which channels are kept — whispers, guild, officer, party, raid, instance, channels, say, yell, emotes — has been a setting since the feature shipped and had never appeared anywhere in the interface. It is on the panel now. An unchecked channel is not recorded at all rather than merely left out of the replay, so re-ticking one does not bring back what went by while it was off.",
            L["wn_334_chat_history_clear"] or "Chat history: there is now a button to delete everything stored, behind a confirmation, and turning the feature off clears what is already saved instead of leaving every line sitting in your saved variables. The panel says so before you untick it — along with the fact that history is stored account-wide and therefore shared by all your characters.",
            L["wn_334_roles_guides"] or "Roles: a new Roles category, with a guide page for tanking, healing and damage. Each one explains what actually matters for that role, and every point carries a button that opens the panel holding the setting and highlights it. The page also applies that role's preset and switches the sidebar's role focus in one click.",
            L["wn_334_search_nested_tabs"] or "Config search: a result inside a nested tab — raid frame HoTs, resource bar colours, anything a panel puts behind its own second row of tabs — opened the right category and then landed on its first tab, not the one holding what you searched for. The index only ever stored the innermost tab name, which the outer tab bar could never match. It records one name per level now, and each tab bar reads its own.",
            L["wn_334_search_index_all_tabs"] or "Config search: most of the settings were never in the index at all. Pages you have never opened are built once, out of sight, so that searching can find them — but a panel only builds its first tab, so everything sitting behind a second or third sub-tab, which is the bulk of the interface, could not be found by searching for it. Every tab is walked now. That is far more to build, so it happens in the background a few milliseconds at a time instead of freezing the game on your first search, and a list of results already on screen refreshes itself once it is done.",
            L["wn_334_search_index_duplicates"] or "Config search: panels that reuse one page across several tabs — every castbar unit, every unit frame — collapsed into a single result. The index only kept the innermost tab name, so the target castbar and the focus castbar wrote the same entry over the same section and every copy but the first disappeared. Entries now carry the full path, and each unit's sections are listed on their own.",
            L["wn_334_roles_deeplink"] or "Roles: the buttons on the guide pages opened the right category and then left you on whatever tab you had last used. They looked their setting up in the search index, and those settings — raid frame HoTs, party defensives, tank mode — were exactly the ones the index was missing. Each button now names its own route, tab by tab, so it lands on the right page and highlights the section, on a freshly started client and whatever you were looking at before.",
            L["wn_334_cr_detection"] or "Class reminder: it was reading the stance bar by position. Cat was slot 2, Bear slot 1, Moonkin slot 4 — but where a form sits on that bar depends on your talents, so on any build where it moved, the reminder was comparing your actual form against an unrelated slot: telling you a form was missing while you were standing in it, or staying quiet while you were out of it. Forms are matched by spell now. Warriors get their three stances, one per specialisation, instead of one entry covering three bar slots on every spec. And paladin auras were being looked for among shapeshift forms, where they were never going to be found — they are buffs, and are checked as buffs.",
            L["wn_334_cr_false"] or "Class reminder: some reminders could not be cleared at all. Evoker tracked a single Blessing of the Bronze buff, and that spell applies a different one to each class — so twelve classes out of thirteen were told they were missing a buff they were carrying, for as long as the module was on. Same for the talent versions of Mark of the Wild, Arcane Intellect, Moonkin Form and Shadowform: only the base version was known, so anyone running the variant was reminded about a buff they already had.",
            L["wn_334_cr_icons"] or "Class reminder: it was a pulsing line of text in the middle of the screen naming what was missing. It is a row of icons now, one per missing buff, form, stance or aura, and out of combat you can left-click one to cast it instead of reading its name and going to find it on a bar. Middle-click drops a reminder until your next loading screen, for the buff you have decided you are not taking today. Nothing is clickable in combat, on purpose — a row that stayed armed would be lying about what pressing it does.",
            L["wn_334_cr_options"] or "Class reminder: icon size, spacing, row scale, opacity, the label and its size, and a glow with its own colour. The two position sliders are gone — the row is placed with the mover like everything else that moves, and it has its own entry in the Movers panel. If you had moved it with the sliders, that position is carried over once.",
            L["wn_334_cr_panel"] or "Class reminder: the settings page opens on a live preview of the row, drawn by the module itself, so every slider moves the thing you are looking at. Clicking an icon takes you to its toggle, its label to the label options, the space around it to the sizing sliders. And the list of supported classes — a paragraph of text per class — is a grid now, one cell per tracked buff or form, coloured by class, each one a switch you can turn off for anything you would rather not be reminded about.",
            L["wn_334_cr_enchants"] or "Class reminder: weapon imbues were not tracked at all. Flametongue, Windfury, Earthliving, Tidecaller's Guard and Thunderstrike Ward each get their own reminder, and the two Lightsmith rites share one, since they are mutually exclusive and either satisfies it. Imbues are not auras, so the game never announced them the way it announces a buff — they now clear the moment you apply one instead of waiting for something unrelated to refresh the row.",
            L["wn_334_cr_poisons"] or "Class reminder: rogue poisons, one reminder per category rather than per poison — Lethal and Non-Lethal. What matters is whether the slots are filled, so it counts how many of that category are active against how many you can actually apply, one or two with Dragon-Tempered Blades. No list of builds to keep up to date, and nothing to reconfigure when you change talents.",
            L["wn_334_cr_shields"] or "Class reminder: shaman shields are tracked, and Elemental Orbit is taken into account rather than ignored. With the talent you carry Earth Shield on yourself and one of the other two, so both are checked; without it, any one shield is enough. The reminder names the category and its icon points at the right shield for your specialisation — Water for Restoration, Lightning otherwise.",
            L["wn_334_cr_context"] or "Class reminder: you can now choose where it shows up — everywhere, in dungeons and raids only, or in a group only. It is hidden in cities and inns by default, since that is where you are about to reapply everything anyway, and it stays quiet while you are dead, in a vehicle or flying on a mount: states where nothing on the row can be pressed.",
            L["wn_334_cr_group"] or "Class reminder: it can watch the group too. Turn on 'also remind when a group member is missing a buff' and a group buff you are carrying still raises its reminder while someone in range is without it — the case it always missed, since having the buff yourself says nothing about the rest of the party. Only members who actually want the stat count, and only out of combat: another player's auras cannot be read during a fight, and guessing would leave a reminder on screen for the whole pull. Off by default, because watching everyone's auras is not free.",
            L["wn_334_cr_perf"] or "Class reminder: it re-scanned your auras and your stance bar once a second, forever, whether or not anything had changed. The game already announces a buff gained, lost or expired, and the stance bar has its own events, so none of that polling was needed. It reacts to events now, and also notices a talent or spellbook change — which is when the set of forms you can be reminded about actually moves.",
            L["wn_334_uf_preview_engine"] or "Unit frames: the settings preview was a mock-up. It drew its own fake bars from the same numbers but with its own code, so it could disagree with what you actually got in game — and it did. It is built by the same functions that build your real frames now: bar texture, fonts, borders, the info bar, element offsets, the aura grid, enemy buffs and threat all come from the real engine, and the preview can no longer drift away from it.",
            L["wn_334_uf_preview_live"] or "Unit frames: the preview shows your actual units. When the unit exists — your target, your focus, your pet — the frames are fed real data and tagged LIVE; when it does not, they fall back to simulated values tagged SIM. There is also a Fit / 1:1 toggle, so you can check the frames at their true pixel size instead of the scaled-down strip.",
            L["wn_334_uf_texture_live"] or "Unit frames: changing the bar texture did nothing until you reloaded — it was only read when a frame was first built. Same for the duration numbers on auras. Both apply as you change them now, on your real frames and not only in the preview.",
            L["wn_334_tmkeys"] or "Mythic+: /tm keys opens the scoreboard on your actual group — everyone's name, class, M+ score and the keystone they are holding. Until now that board only appeared by itself at the end of a run, and the one command that opened it by hand showed sample data rather than anyone real. Deciding which key to run was exactly the moment you could not look at it. It works outside a dungeon, which is where you need it.",
            L["wn_334_score_roleicon"] or "Mythic+: every row on the scoreboard now shows a role icon beside the specialisation icon, in the same colours as the role presets and the settings badges. The spec tells you what someone brought, the role tells you what they are doing with it, and a keystone list you read before pulling wants both.",
            L["wn_334_score_spec"] or "Mythic+: your own specialisation was missing from your row on the scoreboard — the game does not report it through the same call it uses for everyone else. It is read directly now. Players sharing a role also came out in a different order every time the board was opened outside a run, since the damage figure that normally separates them is zero for everybody there; ties now fall back to keystone level, then score, then name.",
            L["wn_334_mplus_teleports"] or "Mythic+: dungeon teleports you had earned were shown as not learned. The panel and the scoreboard greyed the dungeon out, the tooltip said the teleport was not available, and clicking the row printed 'not learned' and cast nothing. The test it used only reports spells your class or your pet grants you, and dungeon teleports come from achievements — so it answered no for every single one of them, whatever was actually in your spellbook. Reported for Skyreach, and it applied to the whole list. The teleports work from the panel now.",
            L["wn_334_delete_confirm"] or "Delete confirmation: the feature that types the confirmation word for you was still reaching for a part of that window Blizzard removed in 11.2, and only worked through a fallback that guesses the window's internal name. It now asks the game for the text field the supported way, with the old routes kept behind it — so it keeps filling the box whatever Blizzard does to that popup next.",
            L["wn_334_friends_removed"] or "Contacts: the skin for the friends window has been removed, along with its tab in the settings. Blizzard is rebuilding that window in 12.1, and the skin worked by reaching for several dozen of its individual parts by name — parts the rebuild is free to move or rename. That does not age gently: it leaves a half-stripped window on patch day, for you rather than for us. The skin was off by default; if you had it on, the window simply goes back to Blizzard's own look. The Contacts button in the chat sidebar is unaffected.",
            L["wn_334_studio_reasons"] or "Cooldown Studio: the 'Open Cooldown Studio' button could do nothing at all. Every possible reason the editor failed to load was reported as the same message — 'not installed' — including the most common one by far, which is that it is installed and simply left unchecked in your addon list. Each reason now says what it is and what to do about it.",
            L["wn_334_studio_enable"] or "Cooldown Studio: if the only problem is that it is unchecked in the addon list, clicking the button now ticks it and opens the editor. Where the game insists on a reload first, it says so instead of sending you off to find the setting yourself.",
            L["wn_334_studio_preflight"] or "Cooldown Studio: the card in the Cooldowns tab tells you the editor cannot open before you click it, not after. The button stays clickable on purpose — for an unchecked addon, clicking it is the fix.",
            L["wn_334_studio_init"] or "Cooldown Studio: an editor that loaded but failed to start up swallowed your click without a word. It now says it loaded but could not initialise, and why.",
            L["wn_334_studio_toc"] or "Cooldown Studio: the sub-addon now shows the TomoMod icon, a category and the addon's real version number in your addon list. It was still declaring 1.0.0 with no icon, which made it look like somebody else's addon that happened to share the name.",
            L["wn_334_package_builder"] or "Packaging: the download is now built by a script that refuses to produce it if the Cooldown Studio ends up inside the TomoMod folder instead of beside it. WoW only looks at the top level of your AddOns folder, so a Studio packed one level down is a Studio nobody can see in their addon list — which is the situation half of the fixes above exist to diagnose.",
            L["wn_334_diag_export"] or "Diagnostics: the export window asked you to copy the report, then put the tracker's address in its title — an address you could only take by throwing away the report you had just copied. It now switches between the report and the link, tells you which one it just put in your clipboard, and shows the address on screen in plain text so you can simply read it.",
            L["wn_334_diag_reminder"] or "Diagnostics: the window now states that your report is saved and can be reopened at any time with /tmdiag tracker, so taking the link first costs you nothing. Closing it also prints the address in chat once per session, in case you closed it too fast.",
        },
    },
    {
        version = "3.3.3",
        highlights = {
            L["wn_333_summon_stuck"] or "Party & raid frames: the incoming summon icon stayed on the frame until you reloaded. Once you accept or decline, the game keeps reporting the summon's last state instead of clearing it, so the icon was describing something that had stopped existing minutes earlier. It now checks whether a summon is actually still open before showing anything.",
            L["wn_333_summon_roster"] or "Party & raid frames: when the group changed, a summon icon could stay on a frame that now belonged to a different player. The summon state is re-read on every roster change and after zoning, and it is refreshed with the rest of the frame instead of only when the game announces a change.",
            L["wn_333_defensives_party"] or "Party frames: defensive cooldowns active on each member are now shown, which previously only existed on raid frames — and there it was a single icon with no duration and no indication of what it was.",
            L["wn_333_defensives_categories"] or "Party & raid frames: defensives are split into externals (cast on this player — Ironbark, Life Cocoon, Pain Suppression), raid-wide (Rallying Cry, Darkness, Anti-Magic Zone) and personals (Divine Shield, Ice Block, Barkskin), each with its own toggle. Fifty spells, sorted so externals come first, with remaining time and a border colored by category.",
            L["wn_333_defensives_defaults"] or "Party & raid frames: only externals are shown by default. A raid-wide cooldown lights up every frame at once — exactly when you are least able to read them — and personals are constant. Both can be turned on.",
            L["wn_333_defensives_size"] or "Raid frames: the defensive icon size slider only took effect after a reload. It applies as you drag it now.",
            L["wn_333_hots_drift"] or "Party & raid frames: the two sets of frames disagreed about which heal-over-time effects to show. Blessing of Summer, Cloudburst Totem and Enveloping Breath appeared on party frames and not on raid frames — the same buff, on the same player, visible on one and not the other. There is one list now, covering all six healing classes.",
            L["wn_333_dispel_border"] or "Party & raid frames: the dispel highlight's border thickness is now a slider, 1 to 6. It grows outwards from the frame edge, so a thicker border never eats into the health bar, and the default looks exactly like before.",
            L["wn_333_stance_grid"] or "Action Bars: with 'show empty button slots' off, the stance bar could still put ten empty squares on screen, and they stayed there until you changed stance. The pass that reveals empty slots while you drag a spell was also running over the stance and pet bars, whose buttons are not action slots — so it judged every one of them empty and showed them, while the pass that hides them again deliberately skips those two bars, leaving nothing to put them back.",
            L["wn_333_diag_display"] or "Diagnostics: reports now include your resolution, display mode and UI scale — and flag the case where the scale has been set by something other than the game's own options. Above 1200 pixels tall the client will not scale the interface down far enough on its own, so high-resolution setups end up rescaled by hand or by another addon, and that was invisible in a report.",
            L["wn_333_diag_scalechange"] or "Diagnostics: a scale or resolution change during your session is logged with its before and after values, so a rescale shows up next to the errors it may have caused. That rescale is reapplied after every loading screen, which is when it tends to break things.",
            L["wn_333_diag_perf"] or "Diagnostics: reports now carry framerate (current, and the session's minimum, average and maximum) and latency, and every captured error records the framerate at the moment it fired. An error that only appears on a stuttering client is a timing problem rather than a broken feature, and nothing in a report used to tell them apart.",
            L["wn_333_diag_scale_expected"] or "Diagnostics: the report claimed your interface scale had been set by a macro or another addon on almost every setup. When the game's own UI scale option is off, the value it was comparing against is not the one the game is using, so a perfectly ordinary configuration was flagged. It now works out what the scale should be for your resolution and settings, prints it, and warns only when it genuinely differs.",
            L["wn_333_diag_settle"] or "Diagnostics: the scale the game applies for itself while you log in was recorded in every report as a mid-session rescale. The display capture now waits four seconds for the client to settle before taking a reading, so the only scale entry left in a report is one that actually needs explaining.",
            L["wn_333_diag_mode"] or "Diagnostics: when the report cannot work out your display mode it now prints the raw values the game gave it instead of a bare question mark — those setting names change between expansions, and a '?' on its own could not be diagnosed without asking you for more. Windowed-fullscreen and maximized windows are recognised in more cases, and addon versions no longer read 'vv1.2.3'.",
            L["wn_333_shared"] or "Internal: the party and raid frames kept two copies of the same 250 lines — the summon logic, the heal-over-time list, the defensive tracking. All three bugs above came from that: a fix applied to one copy and not the other. They share one implementation now.",
        },
    },
    {
        version = "3.3.2",
        highlights = {
            L["wn_332_companion_panel"] or "Pet Reminder: the module that warns you when your pet is missing or dead finally has a settings panel, under QOL. Enabling it, its size, its scale, whether it shows the icon, the text or both, and where it sits on screen were previously only reachable by editing a file by hand.",
            L["wn_332_companion_travel"] or "Pet Reminder: it could stay on screen, at four times its size, for an entire flight. It only ever checked whether you were flying at moments when you were still standing on the ground, and nothing could hide it afterwards. It is now hidden while flying, on a flight path and in a vehicle — and on a ground mount too, which you can turn back off.",
            L["wn_332_companion_locale"] or "Pet Reminder: 'Pet missing' and 'Pet dead' were English whatever your client's language was. Both are translated now, along with everything in the new panel.",
            L["wn_332_perf_auras"] or "Performance: the Aura Tracker and the Buff Skin now only listen to your own aura changes. They only ever acted on you, but they were being woken for every unit whose auras changed — twenty-plus raid members plus every visible nameplate, continuously — just to check the unit and drop it. The game filters those out before any of our code runs now.",
            L["wn_332_perf_castbar"] or "Performance: same for the castbar's latency tracking, which was being woken by every cast of every visible unit — an entire trash pull's worth of abilities — where only your own casts ever mattered.",
            L["wn_332_perf_gc"] or "Performance: the Aura Tracker was the biggest source of memory churn on the overlay. Its scan and layout ran several times a second in combat and threw away a pile of temporary tables on every pass; they now reuse the same working tables. Nothing on screen changed.",
            L["wn_332_aura_order"] or "Aura Tracker: two auras applied on the same cast with the same duration could visibly swap places between refreshes, because nothing decided their order. It is stable now.",
            L["wn_332_skyride_leak"] or "Skyriding: /tm skyride built a second copy of the bar every time it was used. The old one stayed on screen, no longer connected to anything and impossible to hide, because the game never reclaims a frame. The bar is built once now and the command just re-applies your settings to it.",
            L["wn_332_skyride_ticker"] or "Skyriding: the same command also left a permanent 4-per-second update running behind it each time, with no way left to stop it. They are no longer duplicated, and the update stops when the module is turned off instead of polling a hidden bar.",
            L["wn_332_tooltip_incombat"] or "Tooltip: item level and specialization disappeared from every tooltip the moment a fight started, and came back when it ended. The range test the inspect engine finished on is one the game refuses to answer for addons during combat, so every unit was judged out of range for the whole pull — while the taint log filled up with one blocked call per hover. It now uses a test that works in combat.",
            L["wn_332_tooltip_backoff"] or "Tooltip: the replacement range test is less precise (it sees much further than an inspect can actually reach), so a player too far away to answer is now remembered and left alone for twenty seconds instead of being asked again on every tooltip. Only one inspect can be in flight at a time, and one out-of-range player used to take that slot over and over. A tooltip that never got an answer also stopped being stuck on 'loading'.",
            L["wn_332_diag_nopath"] or "Diagnostics: charging across a gap, leaping onto a ledge or sending a pet somewhere it cannot walk was logged as an error in the report. 'No path available' is normal game feedback, and is now filtered out in all six languages.",
            L["wn_332_locale_castbar"] or "Config: the Castbars panel's main checkbox was labelled 'Enable consumable bar' in every language — two different options had been given the same translation key, and the consumable one won. Each has its own now.",
            L["wn_332_locale_translations"] or "Localization: 173 strings per language translated into German, Spanish, Italian and Portuguese — Cooldown Manager advanced/visibility settings, objective tracker quest categories, the chat frame UI, movers and cursor textures — plus the 49 chat frame UI strings in French. They were quietly falling back to English rather than showing an error, so nobody reported them.",
            L["wn_332_locale_search"] or "Config: the search box showed the raw text 'gs_no_results' instead of 'No matching option' when nothing matched. The message is defined in all six languages now.",
            L["wn_332_package"] or "Packaging: the download no longer includes the bundled libraries' test suites, examples, generated documentation and readme files. None of it was ever loaded by the addon.",
        },
    },
    {
        version = "3.3.1",
        highlights = {
            L["wn_331_tooltip_secret"] or "Tooltip: the whole unit information layer added in 3.3.0 never appeared in Midnight — no guild rank, target, Mythic+ score, mount, speed, location, item level, specialization or name-line icons. The layer reads the unit token back from the tooltip, the game now hands that token out as a protected value, and the guard rejected it, so nothing was ever written.",
            L["wn_331_tooltip_border"] or "Tooltip: the unit-colored border was off for the same reason — it read the token through its own guard and gave up, so every unit fell back to the configured border color, which looked exactly like the option doing nothing.",
            L["wn_331_tooltip_target"] or "Tooltip: the target line was dropped for any player whose name comes back protected, which is most of them. The name is no longer wrapped in a color escape — building that string counts as reading the name — and the color goes through the tooltip's own color arguments instead. Identical on screen, and it works now.",
            L["wn_331_tooltip_guards"] or "Tooltip: the safety guards could themselves raise an error. One compared the value to an empty string before checking whether it was protected, so it crashed on exactly the values it existed to catch, and around twenty true/false tests (does the unit exist, is it a player, can it be inspected…) were compared raw. All of them are checked in the right order now.",
            L["wn_331_inspect"] or "Tooltip: item level and specialization are back with the rest of it — the inspect engine ran the same unguarded comparisons on every eligibility test, and stood down on a protected value before ever sending a request.",
        },
    },
    {
        version = "3.3.0",
        highlights = {
            L["wn_330_tooltip_info"] or "Tooltip: unit tooltips now carry a real information layer — guild rank, the unit's current target, Mythic+ score, mount, movement speed and location, plus raid marker, role and class icons on the name line. Every line has its own toggle in Skins → Tooltip.",
            L["wn_330_tooltip_inspect"] or "Tooltip: hovering a player now shows their equipped item level and their specialization. Both require an inspect, so they appear when the player is in range; the item level is colored by the gap to your own rather than by season thresholds that go stale every patch.",
            L["wn_330_tooltip_border"] or "Tooltip: the border can take the unit's color — class color for a player, hostile / neutral / friendly for an NPC — and the level line is recolored by difficulty, red for a boss or a '??' unit.",
            L["wn_330_tooltip_bar"] or "Tooltip: the health bar is now hidden by default, since the information layer replaces it. Existing profiles are updated once; unticking the option puts the bar back and it sticks.",
            L["wn_330_pf_leader"] or "Party frames: the group leader is now marked with a crown above their frame, with its own toggle and size slider.",
            L["wn_330_stance_bar"] or "Action Bars: classes with no shapeshift forms got a stance bar with ten empty squares on it, and unchecking 'show empty button slots' made the whole stance bar vanish. The bar now only appears when you actually have forms, and shows exactly as many buttons as you have.",
            L["wn_330_leveling_panel"] or "Leveling bar: hovering it now opens a styled panel instead of a tooltip, showing level, XP, XP remaining, progress, rested, XP/h, time to level, XP gained since your last ding and the last quest's contribution. It flips below the bar when there is no room above.",
            L["wn_330_bags_click"] or "Bags: disenchanting, milling or prospecting from the bag skin took two attempts — the press consumed the targeting cursor and the release picked the item up instead. It works on the first try now, and dragging is unaffected.",
            L["wn_330_bags_layout"] or "Bags: the 'Categories' layout has been removed, leaving Combined Grid and Separate Bags. A profile still set to it is moved onto the combined grid once.",
            L["wn_330_chat_copy"] or "Chat: the per-message copy icon put a placeholder glyph in front of every line because its texture never resolved. The option is removed, and cleared once for anyone who had it on.",
            L["wn_330_tracker_delve"] or "Objective Tracker: inside a Delve the tracker showed nothing at all — no stage, no criteria, no progress. 'Hide when empty' only counted quest blocks, while a Delve tracks its progress in the scenario module, which that count deliberately leaves out, so the whole panel was hidden. Delves, scenarios and bonus objectives now count as content, and the panel sizes itself to them when they are alone on screen.",
            L["wn_330_tracker_delve_place"] or "Objective Tracker: with 'Hide when empty' turned off, the panel stayed but the delve block was never positioned inside it — the empty case returned before the pass that places it. Scenario and delve modules are now placed first, whatever else is tracked.",
            L["wn_330_cdf_unusable"] or "CooldownForge: an icon can now tint itself when the spell is off cooldown but cannot be cast right now — no rage, wrong form, missing reagent. Choose no effect (the default), grey out, or grey out plus a blue tint when the missing resource is the blocker, per bar and per spell.",
            L["wn_330_cdf_glow_usable"] or "CooldownForge: glow gained a 'when the spell is usable' condition — ready plus castability, so a resource-starved spell stops glowing while it waits instead of inviting a press that would fail.",
            L["wn_330_cdf_hide_unusable"] or "CooldownForge: a bar can also drop an icon entirely while you cannot afford it, next to the existing 'hide while on cooldown' filter. The two are independent and stack, and the remaining icons close the gap.",
            L["wn_330_cp_charged"] or "Resource Bars: supercharged combo points are now shown as such — the charged slot is marked whether it is filled or not, so you can see where the charge sits before spending it. The color is yours to pick in CD & Resource → Colors, red by default.",
            L["wn_330_colorpicker"] or "Config: the color picker kept opening behind the settings window and Cooldown Studio, which looked like the swatch did nothing. It now opens above them, right next to the swatch you clicked instead of at the centre of the screen.",
            L["wn_330_locale_escapes"] or "Localization: the Compass options printed raw escape codes where accents belonged — \"dxC3xA9filer\", \"xC3x89chelle\", \"Large (xC2xB190xC2xB0)\". Those strings used an escape syntax the game's Lua does not understand and printed literally; they are plain text again, in all six languages.",
            L["wn_330_diag_filters"] or "Diagnostics: being rooted in place and trying to mail a soulbound item were logged as errors in the report. Both are normal game feedback, and are now filtered out like the rest of it.",
        },
    },
    {
        version = "3.2.7",
        highlights = {
            L["wn_327_tracker_progressbars"] or "Objective Tracker: quest progress bars (kill counts, enemy forces, scenario and delve criteria) are back — a bar is no longer swept away as orphaned when its block is only reachable through an anchor, it survives collapsing and re-expanding its bucket, and the bars that stay are now themed like the rest of the tracker.",
            L["wn_327_tracker_position"] or "Objective Tracker: a tracker moved with Blizzard's own Edit Mode snapped back to its old spot on the next reload — that position was never written to the addon's database. It is saved when the Edit Mode session ends now, and a tracker scaled above or below 100% no longer creeps across the screen a little more on every reload.",
            L["wn_327_minimap_indicators"] or "Minimap: the instance difficulty flag stayed visible outside instances, because re-anchoring the native indicators also forced them visible and overrode Blizzard's own rule. They follow Blizzard's visibility again — and the expansion button no longer stays invisible for good once turned off and back on.",
            L["wn_327_resourcebar_frozen"] or "Resource Bars: the centered power bar stayed stuck on the value it was built with — 0 rage, 0 energy — for every spec whose only resource is the primary one (Warrior, Priest, Fire Mage, Mistweaver, Havoc...), while the unit frame showed the real amount. It refreshes like every other bar again.",
            L["wn_327_profile_rename"] or "Profiles: renaming or duplicating a profile did nothing at all — Blizzard's 11.2 popup rewrite removed the field the accept handler read the typed name from. Both work again, and Enter now confirms like the accept button.",
            L["wn_327_cds_rename"] or "Cooldown Studio: same fix for the Rename bar and '+ New' popups — the name you typed was ignored, so renaming did nothing and every new bar came out called 'Nouvelle barre'.",
            L["wn_327_popup_layer"] or "Popups: the reload prompt, the import / export dialogs and every profile confirmation used to render behind the config window and Cooldown Studio, looking like nothing had happened. They are now raised above whichever TomoMod window is open.",
            L["wn_327_profile_refresh"] or "Profiles: creating, deleting, renaming or duplicating a profile now refreshes the list on screen instead of leaving the previous one displayed from the panel cache.",
            L["wn_327_import_perf"] or "Profiles: importing is noticeably faster — the string decoded for the preview is reused on accept instead of being decoded a second time, which was most of the freeze when clicking Import.",
            L["wn_327_gui_split"] or "Config: Profiles and Diagnostics are separate sidebar categories again instead of being grouped under Tools, each with its own icon and description; old links to Tools still work.",
        },
    },
    {
        version = "3.2.6",
        highlights = {
            L["wn_326_whatsnew_stuck"] or "What's New: closing this popup with Escape used to leave the screen dimmed and the mouse dead, and the version unmarked so it came back next login. Every close path — X, button, Escape — now goes through one place that clears the dimmer and remembers the version.",
            L["wn_326_whatsnew_escape"] or "What's New: Escape is now captured by the window itself instead of Blizzard's UISpecialFrames, removing a taint path through the game menu; every other key still passes through.",
            L["wn_326_whatsnew_gates"] or "What's New: the popup now waits for a clear moment — never over a cinematic, a movie or a fight — and skips a character's very first login entirely, so it no longer greets you mid intro sequence.",
            L["wn_326_tracker_empty"] or "Objective Tracker: with nothing tracked, the tracker no longer leaves a dark panel covering most of the screen — it now collapses to its header, and 'Hide when empty' is on by default (existing profiles are updated once; turning it back off sticks).",
            L["wn_326_tracker_drag"] or "Objective Tracker: the panel can be dragged downwards again — screen clamping was applied to Blizzard's oversized tracker frame, whose bottom edge already sat off-screen, so every downward move was refused.",
            L["wn_326_repbar_drag"] or "Reputation bar: fixed the bar showing its unlock border in Layout mode but refusing to be grabbed — it never had mouse input enabled, so dragging could not start.",
            L["wn_326_suite_card"] or "Config: the dashboard gained a 'Tomo suite' card presenting TomoBoss (boss timers with spoken callouts) — a shortcut to its options if it is installed, a copyable address and a permanent 'Don't show again' otherwise.",
        },
    },
    {
        version = "3.2.5",
        highlights = {
            L["wn_325_friends_window"] or "Contacts: the friends window is now fully themed instead of being a half-done pass — flat dark body, accent border drawn above the list, restyled title and a plain accent close button.",
            L["wn_325_friends_tabs"] or "Contacts: the bottom tabs and the Friends / Recent Allies / Recruit A Friend sub-tabs lost their gold plates, and now show an accent underline and label on the selected one.",
            L["wn_325_friends_buttons"] or "Contacts: every button in the window (Add Friend, Send Message, the Who tab buttons, Convert to Raid, Raid Info, Join Queue) now shares one flat accent style that brightens on hover, and the two contact buttons split the bottom row evenly.",
            L["wn_325_friends_toggle"] or "Contacts: turning the skin off in the settings now restores Blizzard's look immediately instead of needing a reload.",
            L["wn_325_cdf_radial"] or "CooldownForge: cooldown bars can now arrange their icons on a circle instead of a line — set the radius, start angle, arc amplitude and direction from the new Layout mode.",
            L["wn_325_cdf_spacing"] or "CooldownForge: icon spacing is now two separate values — along the row and between wrapped rows — and the maximum was raised from 16 to 64 px.",
            L["wn_325_cdf_glow"] or "CooldownForge: glow can now trigger on a chosen condition — when the spell is ready, while a buff is active on you (with an optional buff ID for trinkets/talents), or always — set per bar or per spell.",
            L["wn_325_cdf_hidecd"] or "CooldownForge: a bar can now hide each icon while it is on cooldown, with the remaining icons closing the gap; it reflows only when the set of ready spells changes.",
        },
    },
    {
        version = "3.2.4",
        highlights = {
            L["wn_324_studio_real_icons"] or "Cooldown Studio: the Style tab preview now uses real icons — the bar's own spells first, then your class's spellbook and talents — instead of three hardcoded demo icons from unrelated classes.",
            L["wn_324_chat_contacts"] or "Chat: the chat sidebar gained a Contacts button that opens Blizzard's friends list in one click, restoring an entry point the skin's hidden native social button had removed.",
            L["wn_324_editbox_scrollbar"] or "Config: multi-line text boxes (import/export, notes...) no longer show Blizzard's gold arrow scrollbar — they now use the addon's own thin accent scrollbar and support the mouse wheel.",
        },
    },
    {
        version = "3.2.3",
        highlights = {
            L["wn_323_studio_preview"] or "Cooldown Studio: the Style tab now shows a live icon preview (same rendering as real bars) cycling through ready/on-cooldown states, so you can see style changes instantly.",
            L["wn_323_studio_copystyle"] or "Cooldown Studio: added a 'Copy style from...' button in the Style tab to copy just the visual style from another bar without touching spells, position or layout.",
            L["wn_323_studio_create"] or "Cooldown Studio: '+ New' now asks for the bar's name up front instead of creating a placeholder you then have to rename, and the rename/create popups now show reliably above the window with the name field auto-focused.",
            L["wn_323_slider_entry"] or "Config sliders: right-click a value to type an exact number, Ctrl+click to reset to default, with a tooltip reminder for both.",
            L["wn_323_petbar_editmode"] or "Action Bars: the Pet and Stance bars can now be selected and dragged in Edit Mode even when hidden at rest (no pet/no stances).",
        },
    },
    {
        version = "3.2.2",
        highlights = {
            L["wn_322_studio_intro"] or "New: Cooldown Studio — a dedicated full-screen editor for CooldownForge bars, with per-bar Layout/Style/Spells/Visibility/Sharing tabs, opened from the Cooldowns tab.",
            L["wn_322_studio_fix"] or "Cooldown Studio: fixed the window not always displaying above other frames, and its widgets not always inheriting the correct accent color.",
            L["wn_322_studio_visibility"] or "Cooldown Studio: added conditional bar visibility — show or hide a bar based on combat, instance, group or raid status, via simple Indifferent/Yes/No dropdowns in the Visibility tab.",
            L["wn_322_studio_finestyle"] or "Cooldown Studio: added fine-tuning style controls in the Style tab — opacity, border color/thickness, a custom timer color and a drop shadow toggle.",
            L["wn_322_forge_internal"] or "Internal: extracted the shared machinery behind CooldownForge and Cooldown Studio into a new internal Forge library, laying the groundwork for future deep-editing modules — no user-facing changes.",
            L["wn_322_studio_fixes2"] or "Cooldown Studio: fixed sidebar buttons (New/Duplicate/Rename/Delete/blueprints) sometimes not responding to clicks and overflowing their row, fixed Escape closing the window causing a taint error, and fixed the selected tab resetting instead of being remembered when switching bars.",
            L["wn_322_studio_talents"] or "Cooldown Studio: the spell library now also includes your active talents and hero talents, not just spellbook spells, so you can track them on cooldown bars too.",
            L["wn_322_talent_scan_fix"] or "Cooldown Studio: fixed the talent/hero-talent library scan finding nothing in-game — only actually-taken talents are now considered, using the correct API field to read your selected choice.",
            L["wn_322_diag_taintown"] or "Diagnostics: fixed phantom ADDON_ACTION_FORBIDDEN reports (UseToy, SetNote...) getting misattributed to random addons — Diagnostics now takes exclusive ownership of the taint events instead of letting Blizzard's own handling re-propagate them.",
            L["wn_322_actionbars_discover"] or "Action Bars: the Bar management info text now also mentions that expanding a bar reveals its button size and scale controls, making that option easier to find.",
            L["wn_322_tracker_editmode"] or "Objective Tracker: fixed the tracker freezing in place when dragging it while Blizzard's native Edit Mode was active.",
        },
    },
    {
        version = "3.2.1",
        highlights = {
            L["wn_321_cdf_intro"] or "New: CooldownForge — build custom cooldown bars per class, tracking spells, items, presets (potions, healthstone...), trinkets or your racial ability, from the new Cooldowns tab (Combat category).",
            L["wn_321_cdf_movers_io"] or "CooldownForge bars can now be dragged into place via the unified Movers manager, and shared between characters with a per-class Import/Export string.",
        },
    },
    {
        version = "3.2.0",
        highlights = {
            L["wn_320_gsearch"] or "Config window: the sidebar search is now global — it finds matching options across every category and tab, not just the visible page, and clicking a result jumps straight to it with a highlight flash.",
            L["wn_320_panelcache"] or "Config window: switching between category tabs is now instant after the first visit — panels are cached instead of being rebuilt every time.",
            L["wn_320_configlocale"] or "Config window: every remaining hardcoded French label across the settings panels is now fully translatable.",
        },
    },
    {
        version = "3.1.12",
        highlights = {
            L["wn_3112_score_taint"] or "Mythic+ Scoreboard: fixed a burst of taint errors that could block the end-of-dungeon scoreboard from displaying/positioning itself correctly if the player was still in combat right as the dungeon completed.",
            L["wn_3112_config_resize"] or "Config window: the /tm window can now be resized by dragging its bottom-right corner and scaled with a new 70-130% slider in General — default size increased to 1240x820, with a one-click button to reset both.",
        },
    },
    {
        version = "3.1.11",
        highlights = {
            L["wn_3111_castbar_deathstuck"] or "Castbars: fixed castbars for target, focus, boss and other non-player units getting stuck visible on screen if the unit died or disappeared without WoW ever firing a matching stop event.",
            L["wn_3111_castbar_targetreset"] or "Castbars: switching target or focus now fully resets the castbar instead of only clearing its fail-state timer, so a leftover cast from the previous unit can no longer stay shown on the newly selected one.",
            L["wn_3111_ot_lfgbutton"] or "Objective Tracker: collapsing a quest category now also hides its 'Find Group' button, not just the item button — both are correctly restored when the category is expanded again.",
        },
    },
    {
        version = "3.1.10",
        highlights = {
            L["wn_3110_actionbar_spelldrag"] or "Action Bars: the 3.1.9 empty-slot drag fix still didn't work for a spell, macro or mount already on a bar (with 'Show empty button slots' off) — moving one onto an empty slot now works during any pickup, without opening the Spellbook/Talents.",
            L["wn_3110_skyride_taint"] or "Skyriding: fixed a recurring taint error on the ground-speed display that could still fire hundreds of times per session despite an earlier fix — the speed calculation is now hardened with an extra safety net so it can no longer throw an error.",
            L["wn_3110_diag_exclusions"] or "Diagnostics: added two new exclusion keywords (merchant refusing to buy an item, looting blocked while Challenge Mode is active) so these normal gameplay messages are no longer logged as bugs.",
        },
    },
    {
        version = "3.1.9",
        highlights = {
            L["wn_319_actionbar_dragfix"] or "Action Bars: fixed spells being impossible to drag onto an empty slot (with 'Show empty button slots' off) unless the Spellbook/Talents window was open — empty slots now reveal themselves during any pickup.",
            L["wn_319_ot_mover_fix"] or "Objective Tracker: fixed the mover position sometimes resetting itself (Blizzard's Edit Mode could silently override it) — dragging it now sticks reliably.",
            L["wn_319_ot_quest_limit"] or "Objective Tracker: fixed the 'Max quests shown' slider having no effect at all in the default Categories layout.",
            L["wn_319_minimap_drift"] or "Minimap: fixed the minimap moving itself to a different spot after a /reload (a scale calculation bug was double-scaling the saved position).",
            L["wn_319_minimap_collector"] or "Minimap: fixed the button collector still hiding other addons' minimap buttons after a reload even when disabled.",
            L["wn_319_minimap_tracking"] or "Minimap: fixed the tracking button sometimes disappearing, and Blizzard's native tracking button staying unclickable after being revealed.",
            L["wn_319_repbar_hide"] or "Reputation Bar: fixed Blizzard's own reputation/honor bar still showing through in some cases when 'Hide Blizzard reputation bar' is enabled.",
            L["wn_319_tooltip_bg"] or "Tooltip: less transparent default background (92% -> 97% opacity) — still fully adjustable via the Background opacity slider.",
            L["wn_319_tooltip_anchor"] or "Tooltip: the 'Custom' position anchor no longer stays visible on screen outside of Layout mode, and a new 'Show/Hide anchor' button was added in Skins -> Tooltip.",
            L["wn_319_diag_copy"] or "Diagnostics: fixed the 'Copy Report' button appearing to do nothing — the export popup could open hidden behind the console window.",
        },
    },
    {
        version = "3.1.8",
        highlights = {
            L["wn_318_bagskin_itemclass_enum"] or "Bag Skin: category matching now uses Blizzard's Enum.ItemClass constants (with numeric fallbacks) instead of hardcoded item class numbers, keeping categorization accurate across clients.",
            L["wn_318_bagskin_cat_order"] or "Bag Skin: default category order updated — Quest Items is now grouped right after Equipment, ahead of Consumables and Trade Goods.",
            L["wn_318_bagskin_cat_foundation"] or "Bag Skin: added the internal groundwork for a future hide/reorder categories option — Miscellaneous and Free Slots always stay visible so no item can ever disappear.",
        },
    },
    {
        version = "3.1.7",
        highlights = {
            L["wn_317_libserialize_namespace"] or "Profiles: the embedded LibSerialize library now uses a private namespace ('TomoSerialize-1.0') instead of the shared 'LibSerialize' name, preventing export/import conflicts with other addons that also embed LibSerialize.",
            L["wn_317_drag_absolute_coords"] or "Movable frames: fixed saved positions drifting or flipping after a drag on Leveling Bar, Movers, AuctionRecipeTracker, Mythic+ Tracker, TomoScore, Frame Anchors, Bag Skin, Castbars, Party/Raid Frame anchors, Compass, Consumable Bar, Loot Browser, Minimap, Objective Tracker, Skyriding bar, Resource Bars and Unit Frames — positions are now saved as stable screen-absolute coordinates.",
            L["wn_317_ot_combat_taint"] or "Objective Tracker: fixed a possible taint error when Blizzard re-shows a collapsed quest bucket block during an in-combat quest update.",
            L["wn_317_deadcode_cleanup"] or "Internal cleanup: removed several unused/disabled modules to reduce addon size — no user-facing features were affected.",
            L["wn_317_raidmanager_fix"] or "Raid Frames: fixed the default Blizzard group leader panel (ready check, raid target markers, convert to raid, ping limit, leave group) being hidden along with the raid frames when 'Hide Blizzard raid frames' is enabled — only the member-frame container is suppressed now, the leader toolbar stays available.",
            L["wn_317_groupmanager_skin"] or "Raid Frames: the 'Skin the group leader panel' option now fully reskins the Blizzard toolbar in the TomoMod dark/mint theme — mode & ping dropdowns, role/group filters, toolbar icons (edit mode, settings, ready check, role poll, countdown), raid marker buttons with their Unit/Ground tabs, and red-styled Leave Group buttons — all while keeping every Blizzard icon intact and toggling live without a reload.",
            L["wn_317_groupmanager_collapsetab"] or "Raid Frames: fixed the group leader panel's collapsed toggle leaving a stray strip on the screen edge, and gave it a proper mint pull-tab look instead of a plain reskinned button.",
        },
    },
    {
        version = "3.1.6",
        highlights = {
            L["wn_316_party_combat"] or "Party frames: fixed visibility bugs when members join, leave, or the party converts to a raid mid-combat — frames now show/hide reliably in every situation.",
            L["wn_316_raid_combat"] or "Raid frames: fixed frames getting stuck visible or hidden when raid members join or leave during combat — visibility is now handled by a secure, combat-safe system.",
            L["wn_316_roster_repaint"] or "Party & Raid frames: fixed stale info (class color, absorbs, dispel highlight) briefly showing the wrong player after a roster shift, even mid-combat.",
            L["wn_317_cdm_holders"] or "Cooldown Manager: new 'Holders' system — freely move and lock each cooldown viewer (Essential, Utility, Buff Icons, Buff Bars) independently of Blizzard's Edit Mode grid, with live preview icons/bars while empty.",
            L["wn_317_resourcebars_health"] or "Resource Bars: new optional health bar — configurable height, format (%, value or both), class-colored fill, smooth animation and a low-health color threshold.",
            L["wn_317_config_cards"] or "Config UI: the Cooldown & Resource panel got a new Cards layout plus a dedicated Bars tab for all health bar settings.",
            L["wn_316_locale_cdm"] or "Fixed the CD & Resource panel showing raw keys instead of translated text for the Bars tab, placement/live preview cards and the health bar & animations section — translated in all 6 languages.",
            L["wn_316_taint_chat"] or "Fixed a taint error ('secret string value') in the chat frame skin when receiving channel messages.",
            L["wn_316_taint_skyride"] or "Fixed a taint error ('secret number value') in the Skyriding speed bar caused by the game's protected flight/gliding speed values.",
            L["wn_316_durability_pos"] or "Minimap: the gear durability text position is now configurable (corner + X/Y offset) in Interface → General → Info Panel — useful to avoid overlap with the new 12.0.7 expansion button.",
        },
    },
    {
        version = "3.1.5",
        highlights = {
            L["wn_315_ot_itembutton"] or "Objective Tracker: quest item buttons now correctly hide when their bucket is collapsed (the button is parented to the native tracker, not the block — previously it stayed visible above collapsed buckets).",
            L["wn_315_talkinghead"] or "QOL: the 'Hide Talking Head' toggle is back in the config GUI (QOL → Automations). It now applies instantly without /reload and is reversible — unchecking restores the scrolling dialogue frames.",
        },
    },
    {
        version = "3.1.4",
        highlights = {
            L["wn_314_tooltip_anchor"] or "Tooltip position: new 4-mode anchor — Default, Cursor (follows mouse), Corner (screen corner) and Custom (drag-to-place frame). Configure in Skins → Tooltip.",
            L["wn_314_locale_fix"]     or "Fixed missing tooltip color labels: background and border color pickers in Skins → Tooltip now display correctly in all languages.",
        },
    },
    {
        version = "3.1.3",
        highlights = {
            L["wn_313_nav"]        or "Config UI redesigned: 16 panels consolidated into 6 grouped categories (Interface, Units, Combat, Comfort, Tools), each with its own accent color and a page header.",
            L["wn_313_accent"]     or "Widgets now auto-adopt the accent color of their host panel — cards, headers, separators, checkboxes, buttons and tabs all react to the active category context.",
            L["wn_313_segmented"]  or "New SegmentedControl widget replaces short dropdowns (Bag Bar, Micro Menu, Chat Skin, Bag Layout, Sort, Audio Channel).",
            L["wn_313_dashboard"]  or "Accueil dashboard rewritten: hero banner with live diagnostics status, quick-action shortcuts (Installer, Profiles, Diagnostics, Reload) and redesigned module toggles.",
            L["wn_313_np_preview"] or "Nameplates: new live preview panel at the top of the config — shows ally, hostile and boss plates, updates in real-time as you adjust width, height, cast bar and font size.",
            L["wn_313_loot_filter"] or "Loot class filter fix: items missing from the IDB (e.g. new raid drops) now fall back to armor-type matching instead of being shown for all classes.",
            L["wn_313_sporefall"]   or "Loot data: Sporefall raid (ejEncounterID 2711) added with 15 items from KeystoneLoot build 12.0.7.",
            L["wn_313_diag"]       or "Diagnostics: 7 new UIError exclusion keywords + console now always appears above the config menu.",
        },
    },
    {
        version = "3.1.2",
        highlights = {
            L["wn_312_brand"]         or "Brand color updated from #0cd29f to #2e9dd8 (mint green) across the entire UI — title bar, panels, chat messages, popups and default color values.",
            L["wn_312_brand_api"]     or "New TomoMod_Utils.BRAND / BRAND_DARK / BRAND_HOVER constants centralise the accent color: Config panels and the Widget theme now read from a single source of truth.",
            L["wn_312_companion_fix"] or "CompanionStatus: fixed a global variable leak (UpdateIcon was declared without 'local').",
        },
    },
    {
        version = "3.1.1",
        highlights = {
            L["wn_311_icicles"]      or "Frost Mage: new Icicles tracker in the Resource Bar (5 segments + Glacial Spike glow when full). Custom color available in CD & Resource → Colors.",
            L["wn_311_taint_money"]  or "Fixed a Midnight taint error: hovering items in the Encounter Journal no longer throws a 'secret number' error on the gold value — TomoMod no longer taints item-comparison tooltips.",
            L["wn_311_art_qty"]      or "AuctionRecipeTracker: clicking a reagent searches the Auction House and shows the required quantity in the status bar (e.g. Searching: Awakened Fire × 14).",
        },
    },
    {
        version = "3.1.0",
        highlights = {
            L["wn_310_brez_counter"] or "New movable Battle Rez counter: shows how many combat resurrections are left and the time until the next charge (reads the shared pool, so it works on any class).",
            L["wn_310_resurrect"]    or "New resurrection indicator on party and raid frames: a rez icon appears on a member while a resurrection is being cast on them.",
            L["wn_310_raid_sizes"]   or "Raid frames can now use per-size layouts (10 / 25 / 40): frame width and height adapt automatically to the current group size.",
            L["wn_310_brez_fix"]     or "Fixed the party-frame battle rez cooldown: the icon now greys out and shows the recharge timer correctly whenever a brez is consumed.",
        },
    },
    {
        version = "3.0.7",
        highlights = {
            L["wn_307_objective_tracker"],
            L["wn_307_guardian_rage"],
            L["wn_307_resource_bars"],
        },
    },
    {
        version = "3.0.6",
        highlights = {
            L["wn_306_extra_button"],
            L["wn_306_extra_mover"],
            L["wn_306_extra_scale"],
            L["wn_306_compass"],
            L["wn_306_bagskin"],
        },
    },
    {
        version = "3.0.5",
        highlights = {
            L["wn_305_rare_alert"],
            L["wn_305_rare_alert_marker"],
            L["wn_305_tm_fix"],
        },
    },
    {
        version = "3.0.4",
        highlights = {
            L["wn_304_consumable_bar"],
            L["wn_304_cursor_textures"],
            L["wn_304_mythichub_tp"],
        },
    },
    {
        version = "3.0.3",
        highlights = {
            L["wn_303_tracking_panel"],
            L["wn_303_collector_panel"],
            L["wn_303_collector_autoclose"],
            L["wn_303_tooltip_fix"],
            L["wn_303_coords_pos"],
        },
    },
    {
        version = "3.0.2",
        highlights = {
            L["wn_302_collector_capture"],
            L["wn_302_collector_clean"],
            L["wn_302_collector_poll"],
            L["wn_302_native_choice"],
        },
    },
    {
        version = "3.0.1",
        highlights = {
            L["wn_301_locale_fix"],
            L["wn_301_combat_movers"],
            L["wn_301_procglow_taint"],
            L["wn_301_ground_speed"],
            L["wn_301_buttonbag_clock"],
        },
    },
    {
        version = "3.0.0",
        highlights = {
            L["wn_300_installer"],
            L["wn_300_presets"],
            L["wn_300_dashboard"],
            L["wn_300_search"],
            L["wn_300_minimap"],
            L["wn_300_buttonbag"],
        },
    },
    {
        version = "2.9.21",
        highlights = {
            L["wn_2921_aura_mover"],
            L["wn_2921_aura_gui"],
            L["wn_2921_reload_safety"],
            L["wn_2921_waypoint_arrow"],
        },
    },
    {
        version = "2.9.20",
        highlights = {
            L["wn_2920_waypoint_redirect"],
            L["wn_2920_waypoint_blob"],
            L["wn_2920_waypoint_label"],
        },
    },
    {
        version = "2.9.19",
        highlights = {
            L["wn_2919_antiflicker"],
            L["wn_2919_collapsed_persist"],
            L["wn_2919_header_detection"],
            L["wn_2919_recipe_height"],
            L["wn_2919_reward_preview"],
        },
    },
    {
        version = "2.9.18",
        highlights = {
            L["wn_2918_buckets"],
            L["wn_2918_bucket_toggle"],
            L["wn_2918_tracker_width"],
            L["wn_2918_layout_fix"],
        },
    },
    {
        version = "2.9.17",
        highlights = {
            L["wn_2917_ab_master_toggle"],
            L["wn_2917_installer_raid"],
            L["wn_2917_installer_coverage"],
            L["wn_2917_chat_skin_fix"],
            L["wn_2917_talking_head_fix"],
            L["wn_2917_minimal_style"],
        },
    },
    {
        version = "2.9.16",
        highlights = {
            L["wn_2916_layout_fix"],
            L["wn_2916_safe_init"],
            L["wn_2916_art_total"],
            L["wn_2916_avr_gui"],
        },
    },
    {
        version = "2.9.15",
        highlights = {
            L["wn_2915_art_module"],
            L["wn_2915_art_tooltip"],
            L["wn_2915_art_scrollbar"],
            L["wn_2915_art_anchor"],
            L["wn_2915_art_scan_fix"],
        },
    },
    {
        version = "2.9.13",
        highlights = {
            L["wn_2913_boss_names"],
            L["wn_2913_boss_checkmark"],
            L["wn_2913_ej_pcall"],
        },
    },
    {
        version = "2.9.12",
        highlights = {
            L["wn_2912_party_cd_fix"],
            L["wn_2912_healer_interrupt"],
            L["wn_2912_perf_cdm"],
            L["wn_2912_perf_aura"],
            L["wn_2912_perf_resbars"],
        },
    },
    {
        version = "2.9.11",
        highlights = {
            L["wn_2911_cdm_hooks"],
            L["wn_2911_procglow_fixes"],
            L["wn_2911_buffskin_fixes"],
        },
    },
    {
        version = "2.9.10",
        highlights = {
            L["wn_2910_ej_boss_names"],
            L["wn_2910_ej_fallback"],
        },
    },
    {
        version = "2.9.9",
        highlights = {
            L["wn_299_merchant_tools"],
            L["wn_299_already_known"],
            L["wn_299_extend_pages"],
            L["wn_299_locales"],
            L["wn_299_lustsound"],
        },
    },
    {
        version = "2.9.8",
        highlights = {
            L["wn_298_housing"],
            L["wn_298_housing_hover"],
            L["wn_298_housing_clock"],
            L["wn_298_housing_teleport"],
            L["wn_298_icons"],
            L["wn_298_locales"],
        },
    },
    {
        version = "2.9.7",
        highlights = {
            L["wn_297_rf_live_preview"],
            L["wn_297_rf_preview_layout"],
            L["wn_297_rf_preview_scaling"],
            L["wn_297_taint_blizzard"],
            L["wn_297_range_fix"],
            L["wn_297_actionbars_fix"],
            L["wn_297_mp_tracker"],
            L["wn_297_role_icon"],
            L["wn_297_castbar_fix"],
            L["wn_297_diag_exclusions"],
        },
    },
    {
        version = "2.9.6",
        highlights = {
            L["wn_296_raid_frames"],
            L["wn_296_raid_health"],
            L["wn_296_raid_auras"],
            L["wn_296_raid_utilities"],
            L["wn_296_raid_config"],
        },
    },
    {
        version = "2.9.5",
        highlights = {
            L["wn_295_taint_fix"],
            L["wn_295_diag_taint"],
            L["wn_295_tooltip_ids_moved"],
            L["wn_295_chat_text_offset"],
        },
    },
    {
        version = "2.9.4",
        highlights = {
            L["wn_294_installer"],
            L["wn_294_uf_pf"],
            L["wn_294_cb_res"],
            L["wn_294_skins_qol"],
            L["wn_294_bugfixes"],
            L["wn_294_locales"],
        },
    },
    {
        version = "2.9.3",
        highlights = {
            L["wn_293_partyframe"],
            L["wn_293_actionbar_fix"],
            L["wn_293_chat_taint"],
            L["wn_293_diagnostics"],
            L["wn_293_autofill"],
        },
    },
    {
        version = "2.9.2",
        highlights = {
            L["wn_292_actionbar"],
            L["wn_292_diagnostics"],
        },
    },
}

WN.CHANGELOG = CHANGELOG

-- Returns the release list, newest first. Nil-safe for callers that load
-- before WhatsNew has run.
function WN.GetChangelog()
    return CHANGELOG
end

-- ============================================================
-- VERSION COMPARISON
-- ============================================================

local function GetCurrentVersion()
    return C_AddOns.GetAddOnMetadata("TomoMod", "Version") or "0.0.0"
end

local function ShouldShow()
    if not TomoModDB then return false end
    local current = GetCurrentVersion()
    local seen    = TomoModDB.lastSeenVersion or ""
    return seen ~= current
end

local function MarkSeen()
    if TomoModDB then
        TomoModDB.lastSeenVersion = GetCurrentVersion()
    end
end

-- ============================================================
-- GATES
-- ============================================================

-- Per-character login counter. TomoModCharDB is declared as
-- SavedVariablesPerCharacter in the TOC, so it starts empty on every
-- freshly created character. A /reload counts as a login, which is
-- fine: past the first one, the player is out of the intro sequence.
local function BumpLoginCount()
    if type(_G.TomoModCharDB) ~= "table" then _G.TomoModCharDB = {} end
    local db = _G.TomoModCharDB
    db.loginCount = (tonumber(db.loginCount) or 0) + 1
    return db.loginCount
end

-- A brand-new character should not be greeted by a changelog while it
-- is still in the intro sequence, so the popup waits for login #2.
function WN.IsReturningCharacter()
    local db = _G.TomoModCharDB
    return (tonumber(db and db.loginCount) or 0) >= 2
end

-- Never put a full-screen modal in front of a cinematic or a fight.
local function IsBlocked()
    if _G.CinematicFrame and _G.CinematicFrame:IsShown() then return true end
    if _G.MovieFrame and _G.MovieFrame:IsShown() then return true end
    if type(_G.InCinematic) == "function" and InCinematic() then return true end
    if InCombatLockdown() or UnitAffectingCombat("player") then return true end
    return false
end

-- ============================================================
-- FIND ENTRY FOR CURRENT VERSION
-- ============================================================

local function GetCurrentEntry()
    local ver = GetCurrentVersion()
    for _, entry in ipairs(CHANGELOG) do
        if entry.version == ver then
            return entry
        end
    end
    return nil
end

-- ============================================================
-- UI
-- ============================================================

local frame

local function CreateFrame_WN()
    if frame then return frame end

    local backdrop = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    }

    -- Dimmer
    local dimmer = CreateFrame("Frame", nil, UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:SetFrameLevel(140)
    dimmer:SetAllPoints()
    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints()
    dimTex:SetColorTexture(0, 0, 0, 0.50)
    dimmer:EnableMouse(true)
    -- [fix] Created hidden, exactly like Config/Installer.lua's dimmer.
    -- CreateFrame() returns a SHOWN frame, so the old code put a
    -- full-screen mouse blocker on screen the instant this function ran;
    -- any error later in construction left it there with no way out.
    dimmer:Hide()

    -- Main panel
    frame = CreateFrame("Frame", "TomoModWhatsNewFrame", dimmer, "BackdropTemplate")
    frame:SetSize(PANEL_W, PANEL_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(141)
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(BG[1], BG[2], BG[3], BG[4])
    frame:SetBackdropBorderColor(A[1], A[2], A[3], 0.40)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame._dimmer = dimmer

    -- [fix] Single authority for closing. Whatever hides the panel --
    -- the X, the OK button, Escape, or any external Hide() -- lands
    -- here, so the dimmer can no longer outlive it and the version is
    -- always marked as seen.
    frame:SetScript("OnHide", function(self)
        -- An ancestor hiding us (UIParent during a cinematic) also fires
        -- OnHide, but leaves our own shown flag set. That is not a close:
        -- swallowing it would mark the version seen without the player
        -- ever having read it.
        if self:IsShown() then return end
        dimmer:Hide()
        -- Reading an old release from the Changelog page is browsing, not
        -- acknowledging this update: marking it seen here would swallow the
        -- notice for a version the player has not read yet.
        if self._browsing then
            self._browsing = nil
            return
        end
        MarkSeen()
    end)

    -- [fix] Escape handled here instead of via UISpecialFrames, which
    -- routes through ToggleGameMenu -> ClearTarget() (protected) and
    -- taints. Same pattern as Core/Forge/ForgeStudio.lua, including the
    -- combat guard: SetPropagateKeyboardInput is itself protected and
    -- throws ADDON_ACTION_BLOCKED on every keypress in combat.
    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if InCombatLockdown() then return end
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            WN.Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Header bar
    local header = CreateFrame("Frame", nil, frame)
    header:SetHeight(48)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    local hbg = header:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    hbg:SetColorTexture(0.05, 0.05, 0.07, 1)

    -- Logo
    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(24, 24)
    logo:SetPoint("LEFT", 14, 0)
    logo:SetTexture(LOGO_TEX)
    logo:SetVertexColor(A[1], A[2], A[3], 1)

    -- Title
    local title = header:CreateFontString(nil, "ARTWORK")
    title:SetFont(FONT_BOLD, 14)
    title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    title:SetTextColor(TX[1], TX[2], TX[3])
    frame._title = title

    -- Close button
    local close = CreateFrame("Button", nil, header)
    close:SetSize(28, 28)
    close:SetPoint("RIGHT", -10, 0)
    close:SetNormalFontObject(GameFontNormalLarge)
    local closeTxt = close:CreateFontString(nil, "ARTWORK")
    closeTxt:SetFont(FONT_BOLD, 18)
    closeTxt:SetPoint("CENTER")
    closeTxt:SetText("×")
    closeTxt:SetTextColor(DM[1], DM[2], DM[3])
    close:SetScript("OnEnter", function() closeTxt:SetTextColor(1, 0.3, 0.3) end)
    close:SetScript("OnLeave", function() closeTxt:SetTextColor(DM[1], DM[2], DM[3]) end)
    close:SetScript("OnClick", function() WN.Hide() end)

    -- Accent line under header
    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetHeight(1)
    accent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accent:SetColorTexture(A[1], A[2], A[3], 0.60)

    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 12, -12)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 52)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(PANEL_W - 44)
    scrollFrame:SetScrollChild(scrollChild)


    -- Style scrollbar (hidden if not needed, modern look if shown)
    local sb = scrollFrame.ScrollBar
    if sb then
        Mixin(sb, BackdropTemplateMixin)
        sb:SetWidth(7)
        sb:ClearAllPoints()
        sb:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 2, -2)
        sb:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 2, 2)
        sb:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        sb:SetBackdropColor(0.13, 0.13, 0.16, 0.18)
        sb:SetBackdropBorderColor(A[1], A[2], A[3], 0.18)
        local thumb = sb:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(A[1], A[2], A[3], 0.55)
            thumb:SetWidth(7)
            thumb:SetHeight(32)
            thumb:SetTexelSnappingBias(0)
            thumb:SetSnapToPixelGrid(false)
            -- Arrondi visuel (simulateur)
            if not sb._thumbBG then
                local bg = sb:CreateTexture(nil, "BACKGROUND")
                bg:SetColorTexture(0.13, 0.13, 0.16, 0.22)
                bg:SetPoint("TOPLEFT", sb, "TOPLEFT", 1, -1)
                bg:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", -1, 1)
                sb._thumbBG = bg
            end
        end
        -- UIPanelScrollFrameTemplate ships two gold arrow buttons. The bar
        -- itself was restyled but the arrows were left alone, so the panel
        -- ended up with Blizzard's brass at both ends of a mint track.
        for _, name in ipairs({ "ScrollUpButton", "ScrollDownButton", "Back", "Forward" }) do
            local btn = sb[name]
            if btn then
                btn:Hide()
                btn:SetAlpha(0)
                btn:EnableMouse(false)
                -- Blizzard's scroll code re-shows these on update, so a
                -- one-off Hide does not hold.
                btn:SetScript("OnShow", btn.Hide)
            end
        end
        -- Reclaim the space the arrows had reserved at both ends.
        sb:ClearAllPoints()
        sb:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 2, 0)
        sb:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 2, 0)

        sb:Hide() -- caché par défaut, affiché si besoin
    end

    frame._scrollChild = scrollChild
    frame._scrollFrame = scrollFrame

    -- OK button
    local okBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    okBtn:SetSize(140, 34)
    okBtn:SetPoint("BOTTOM", 0, 12)
    okBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    okBtn:SetBackdropColor(A[1], A[2], A[3], 0.15)
    okBtn:SetBackdropBorderColor(A[1], A[2], A[3], 0.40)
    local okTxt = okBtn:CreateFontString(nil, "ARTWORK")
    okTxt:SetFont(FONT_BOLD, 13)
    okTxt:SetPoint("CENTER")
    okTxt:SetText(L["wn_btn_ok"])
    okTxt:SetTextColor(A[1], A[2], A[3])
    okBtn:SetScript("OnEnter", function()
        okBtn:SetBackdropColor(A[1], A[2], A[3], 0.30)
    end)
    okBtn:SetScript("OnLeave", function()
        okBtn:SetBackdropColor(A[1], A[2], A[3], 0.15)
    end)
    okBtn:SetScript("OnClick", function() WN.Hide() end)

    return frame
end

-- ============================================================
-- POPULATE CONTENT
-- ============================================================


local function PopulateContent(entry)
    local f = CreateFrame_WN()
    local parent = f._scrollChild
    local scrollFrame = f._scrollFrame

    -- Clear old children
    for _, child in ipairs({ parent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({ parent:GetRegions() }) do
        region:Hide()
        region:SetParent(nil)
    end

    f._title:SetText("TomoMod — " .. L["wn_title"])

    local y = 0

    -- Version badge
    local verText = parent:CreateFontString(nil, "ARTWORK")
    verText:SetFont(FONT_BOLD, 18)
    verText:SetPoint("TOPLEFT", 0, y)
    verText:SetText(string.format(L["wn_version"], entry.version))
    verText:SetTextColor(A[1], A[2], A[3])
    y = y - 30

    -- Subtitle
    local sub = parent:CreateFontString(nil, "ARTWORK")
    sub:SetFont(FONT, 12)
    sub:SetPoint("TOPLEFT", 0, y)
    sub:SetText(L["wn_subtitle"])
    sub:SetTextColor(DM[1], DM[2], DM[3])
    y = y - 24

    -- Separator
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 0, y)
    sep:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    sep:SetColorTexture(A[1], A[2], A[3], 0.25)
    y = y - 16

    -- Highlights
    for _, text in ipairs(entry.highlights) do
        local bullet = parent:CreateFontString(nil, "ARTWORK")
        bullet:SetFont(FONT, 12.5)
        bullet:SetPoint("TOPLEFT", 4, y)
        bullet:SetWidth(PANEL_W - 64)
        bullet:SetJustifyH("LEFT")
        bullet:SetWordWrap(true)
        bullet:SetSpacing(3)
        bullet:SetText("|cff2e9dd8•|r  " .. text)
        bullet:SetTextColor(TX[1], TX[2], TX[3])
        local textH = bullet:GetStringHeight() or 16
        y = y - textH - 10
    end

    y = y - 8

    -- Reminder: /tm
    local remind = parent:CreateFontString(nil, "ARTWORK")
    remind:SetFont(FONT, 11)
    remind:SetPoint("TOPLEFT", 0, y)
    remind:SetWidth(PANEL_W - 64)
    remind:SetJustifyH("LEFT")
    remind:SetWordWrap(true)
    remind:SetText(L["wn_footer"])
    remind:SetTextColor(DM[1], DM[2], DM[3])
    y = y - (remind:GetStringHeight() or 14) - 8

    parent:SetHeight(math.abs(y) + 20)

    -- Hide scrollbar if not needed, show and style if needed
    if scrollFrame and scrollFrame.ScrollBar then
        local contentH = parent:GetHeight()
        local viewH = scrollFrame:GetHeight()
        if contentH <= viewH + 2 then
            scrollFrame.ScrollBar:Hide()
            scrollFrame:EnableMouseWheel(false)
        else
            scrollFrame.ScrollBar:Show()
            scrollFrame:EnableMouseWheel(true)
        end
    end
end

-- ============================================================
-- SHOW / HIDE
-- ============================================================

-- Bypasses every gate on purpose: this is the manual/debug entry point.
-- The automatic path is WN.TryShow().
function WN.Show()
    local entry = GetCurrentEntry()
    if not entry then
        MarkSeen()
        return
    end
    -- Content is built BEFORE anything becomes visible: both frames are
    -- created hidden, so an error in PopulateContent leaves a clean
    -- screen instead of a dimmer with no dialog behind it.
    PopulateContent(entry)
    frame._dimmer:Show()
    frame:Show()
end

-- Opens the popup on a given release, for the Changelog config page.
--
-- The page used to lay the notes out inline and they came out overlapping:
-- the info-text widget measures its height right after SetText, before the
-- frame has a width, so a wrapped paragraph measures as a single line. This
-- popup already solves that with a real scroll frame, so the page hands the
-- text to it rather than growing a second layout engine.
function WN.ShowVersion(version)
    if type(CHANGELOG) ~= "table" then return false end

    local entry
    for _, rel in ipairs(CHANGELOG) do
        if tostring(rel.version) == tostring(version) then entry = rel; break end
    end
    if not entry then return false end

    if not frame then CreateFrame_WN() end
    if not frame then return false end

    PopulateContent(entry)
    frame._browsing = true
    frame._dimmer:Show()
    frame:Show()
    return true
end

function WN.Hide()
    -- The OnHide script hides the dimmer and calls MarkSeen().
    if frame then
        frame:Hide()
    else
        MarkSeen()
    end
end

-- ============================================================
-- AUTO TRIGGER (called from Init.lua)
-- ============================================================

-- Retry cadence while a cinematic or a fight is in the way. The ceiling
-- is generous (~5 min) but finite: past it we give up WITHOUT marking
-- the version seen, so the changelog simply shows up next session.
local RETRY_DELAY  = 2
local MAX_ATTEMPTS = 150

function WN.TryShow(attempt)
    attempt = tonumber(attempt) or 1
    if not ShouldShow() then return end

    -- Skip if installer is about to show (first run)
    if TomoModDB and TomoModDB.installer and not TomoModDB.installer.completed then
        MarkSeen()
        return
    end

    -- [fix] A character's very first login is the intro sequence:
    -- cinematic, first steps, and a player who has not asked for a
    -- changelog yet. Deliberately no MarkSeen() here -- the popup is
    -- postponed, not consumed.
    if not WN.IsReturningCharacter() then return end

    if IsBlocked() then
        if attempt < MAX_ATTEMPTS then
            C_Timer.After(RETRY_DELAY, function() WN.TryShow(attempt + 1) end)
        end
        return
    end

    WN.Show()
end

-- ============================================================
-- PER-CHARACTER LOGIN COUNTER
-- ============================================================
-- PLAYER_LOGIN fires once per session and well before Init.lua's
-- 3-second TryShow timer, so the counter is always up to date by the
-- time the gate reads it.
local loginWatcher = CreateFrame("Frame")
loginWatcher:RegisterEvent("PLAYER_LOGIN")
loginWatcher:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    BumpLoginCount()
end)

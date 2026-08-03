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

local CHANGELOG = {
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
            L["wn_312_brand"]         or "Brand color updated from #0cd29f to #2ed884 (mint green) across the entire UI — title bar, panels, chat messages, popups and default color values.",
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
        bullet:SetText("|cff2ed884•|r  " .. text)
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

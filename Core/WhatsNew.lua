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

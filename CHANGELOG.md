## CHANGELOG 4.0.1

#### Chat V4

- **New** - The legacy chat skin has been replaced by Chat V4, a fresh presentation layer with a dark TomoMod shell, teal accents, dedicated message, tab, input and sidebar surfaces, and geometry that follows the main Blizzard chat window as it moves or resizes.
- **New** - Docked chat windows are mirrored into TomoMod-owned message surfaces while Blizzard remains responsible for receiving, formatting and securing every message. Existing history is backfilled on login, new messages preserve their native colours, and the visible renderer stays synchronised with Blizzard's scroll position.
- **Changed** - The Combat Log now uses the Chat V4 message surface when its tab is selected. Blizzard still owns every combat-log filter and formats each final line first; TomoMod only mirrors the resulting `ChatFrame2:AddMessage` output and does not replace or reimplement any combat-log API.
- **New** - Blizzard's Combat Log quick-filter bar is integrated at the top of the Chat V4 message area. The message surface reserves the bar's measured height, the bar is hidden on every other chat tab, and its original anchors, visibility, frame strata and level are captured and restored when Chat V4 is disabled. The controls are neither reparented nor reimplemented, so Blizzard's filtering behaviour remains intact.
- **New** - Skins > Chat Frame is now the live control centre for Chat V4. It can enable or disable the presentation, set the frame and message-area background opacity independently from 0-100%, choose a 9-20px chat font, configure message behaviour, customise the complete sidebar and set the Copy Chat limit; every control applies immediately without a reload.
- **New** - Frame opacity and message-area opacity are now independent controls. The message slider changes only the backdrop behind rendered chat text, including fully transparent at 0%, while tabs, sidebar and native input keep the frame opacity; existing profiles seed the new value from their previous background opacity once.
- **New** - Message presentation can add timestamps without replacing a timestamp Blizzard already supplied, abbreviate numbered and named channels using the client's own localized channel labels, turn familiar smileys into coloured symbols, and colour mentions of known players with their class colour. Sender classes are learned from Blizzard's chat events and GUID data rather than guessed from names.
- **New** - Plain `http://`, `https://` and `www.` addresses become teal clickable links while Blizzard hyperlinks remain untouched. Sentence-ending punctuation is kept outside the generated link, and clicking it opens a focused, preselected Ctrl+C popup instead of asking the game to open an external browser.
- **Changed** - The message fade option now controls the TomoMod renderer directly, using two minutes of visibility and a three-second fade. Changing any formatting option rebuilds the mirrored history from Blizzard's source messages, so existing and incoming lines use the same settings without a reload or duplicated transforms.
- **New** - Sidebar controls cover left/right placement, 26-48px width, 16-30px buttons, 0-8px spacing and individual visibility for Friends, Guild, Player Status, Voice/Channels, Mute, Deafen, Copy Chat, Loot Browser, TomoMod settings and Scroll to Bottom. Copy Chat can retain between 50 and 1,000 lines in steps of 50.
- **Changed** - Existing settings from the legacy `chatFrameSkin` database migrate once into Chat V4, including the enable state, background opacity, font size, fading, timestamps and their format, short channel names, URL detection, emoji and class-coloured mentions. Legacy values deliberately win over the new defaults during that one-time migration.
- **Changed** - `chatV4.enabled` is now the single public chat-module path used by the default database, module registry, dashboard, installer, role presets, content profiles, selective imports and resolution-based font scaling. The three former chat roots remain internal migration sources only and are no longer exposed as separate modules or toggles.
- **New** - All Chat V4 option labels are translated for English, French, German, Spanish, Italian and Brazilian Portuguese.
- **New** - Chat V4 now owns an interactive tab strip rather than placing passive visual mirrors over native tab positions. Every managed tab flows left-to-right inside the dedicated host, with widths kept between 62px and 130px and clipped to the available strip; even an independently undocked Combat Log remains a first-class tab beside General.
- **Changed** - Left and right clicks on a Chat V4 tab are forwarded to its invisible Blizzard tab, preserving native selection, temporary-window behaviour, context menus and Combat Log filter state. Chat V4 records the selected frame for its renderer and native input box, while the active underline and unread marker update immediately.
- **Fixed** - Tabs no longer inherit the screen coordinates or excessive height of Blizzard's native artwork. They stay completely inside the V4 tab host and cannot protrude through the panel's top border when a native frame, particularly the Combat Log, is undocked or moved elsewhere.
- **Changed** - The redesigned sidebar now uses fourteen dedicated, replaceable 64x64 transparent TGA assets instead of drawing its icons in Lua, including separate Online/AFK/DND, muted/unmuted and deafened/undeafened variants. Hover and pressed states, live status colouring, warnings and Friends/Guild online counts remain intact.
- **Fixed** - Every sidebar hover title and description now comes from the Chat V4 locale catalogue instead of hard-coded English. The Online/Away/Do Not Disturb status menu and Loot Browser label are also translated for all six supported languages.
- **Changed** - The Emotes shortcut has been removed from the sidebar and its options because it relied on Blizzard's chat menu as an external floating surface rather than a Chat V4-owned control. Existing profiles are sanitised on load: the old `buttons.emotes` flag and every `emotes` order entry are removed, while Copy Chat, Loot Browser, Settings and Scroll to Bottom are arranged into two option rows.
- **Fixed** - Sidebar buttons now initialise their visual state only after their accent region exists, preventing the sidebar from stopping on its first button. Friend and Guild count backplates also render behind their numbers instead of sharing the same overlay layer and obscuring them.
- **New** - Copy Chat is restored as a complete TomoMod window. It reads the selected Blizzard chat tab live when opened, keeps up to the latest 500 messages by default, follows the configured chat font size, and provides a movable, resizable 700x360 surface with translated Select All and Close controls.
- **New** - Copied messages are converted into readable text without losing useful context: native message colours are retained, raid-target icons become `{marker}` names, hyperlink labels remain visible, and resolvable Battle.net links show the player's readable name. Texture, atlas and hidden hyperlink control codes are removed from the copied result.
- **Changed** - Copy Chat automatically selects transcripts up to 8,000 characters, focuses longer transcripts without selecting them, and opens at the newest line. It uses Retail's scrolling edit-box and minimal scrollbar when available, with a legacy scroll-frame fallback instead of failing on a client without the modern template.
- **Internal** - Copy Chat no longer maintains a second stored message history. Blizzard's live chat frame is the source of truth every time the window opens; secret message, colour and count values are rejected before cleaning, concatenation or display and are never persisted.
- **Changed** - Mouse-wheel scrolling now supports three speeds through Blizzard's native chat frame: normal scrolling moves three lines, Control scrolls by page, and Shift jumps to the oldest or newest message.
- **Changed** - The native edit box still sends every message; Chat V4 only suppresses its old artwork and supplies the surrounding presentation. Disabling Chat V4 restores the captured native fonts, message regions, scroll controls, tabs, edit-box artwork and chat buttons.
- **Fixed** - Blizzard chat backgrounds, NineSlice borders, button-frame textures and resize handles no longer remain visible as a second translucent rectangle behind Chat V4. Their alpha remains locked at zero when Blizzard refreshes the native frame after selecting General or Combat Log, while every original value is still restored exactly when the V4 presentation is disabled.
- **Internal** - Chat V4 does not hook any `FCF_*` function, keeps Blizzard's specialised Combat Log filtering and formatting authoritative, rejects secret geometry and message values before reading or storing them, and limits its post-hooks to mirroring final output into TomoMod-owned presentation frames.

#### Bags V4

- **New** - The legacy bag skin has been replaced by Bags V4, a fresh seven-module implementation built from scratch. The window is entirely TomoMod-owned: a header carrying the title, the used/total slot count, a sort control and a close button, an optional search bar, a Pinned/Recent sidebar, a scrolling item grid and a footer showing your money. The legacy `Skins\BagSkin.lua` is kept on disk but is no longer loaded.
- **New** - Every slot is a real Blizzard `ContainerFrameItemButtonTemplate` item button parented to the TomoMod grid. Blizzard still owns clicking, dragging, right-click use, tooltips, stack counts and cooldown swipes; TomoMod only positions the button and draws its own quality border, item level, and pinned marker on top. No item action is reimplemented.
- **New** - Visual sorting cycles through Bag order, Quality, Name and Item level from a single header button. It changes the order items are drawn in and nothing else: no item is ever moved between slots or bags, so the sort cannot be interrupted mid-way or conflict with the server.
- **New** - Instant search filters the grid as you type, matching item names or item IDs. The field carries a placeholder, a clear button, Escape to empty then unfocus, and Enter to release focus; it can be hidden entirely, in which case the window reclaims its height.
- **New** - A sidebar keeps Pinned and Recent items in view as small icon tiles. Middle-clicking an item in the grid or the sidebar pins or unpins it, pins are stored per profile with their order preserved, and Recent is filled as a stack's total count grows. Left-clicking a sidebar tile searches for that item in the grid.
- **New** - Slots carry quality-coloured borders, the current item level on weapons and armour read back through `C_Item.GetCurrentItemLevel`, desaturation on locked items, and an accent dot on pinned ones. Quality borders, item level and empty slots can each be turned off. Reagent bags are included whenever the client exposes `Enum.BagIndex.ReagentBag`.
- **Changed** - Blizzard's container frames are suppressed by reparenting them to a hidden frame rather than by hiding them or unregistering their events. Each frame's original parent is recorded and handed back exactly when Bags V4 is disabled, and newly generated container frames are captured through `ContainerFrame_GenerateFrame`.
- **Changed** - Opening and closing follows the game rather than replacing it. `OpenAllBags`, `CloseAllBags`, `ToggleAllBags`, `ToggleBackpack` and `ToggleBag` are post-hooked, so bag keybinds, the micro menu, vendors, the mailbox and the bank all still drive the window, and closing the TomoMod frame closes Blizzard's bag state with it.
- **New** - Nothing is built or moved while you are in combat. Slot creation, layout and enable/disable are refused in lockdown, queued, and replayed on `PLAYER_REGEN_ENABLED`. Icons, stack counts, locks and cooldowns still refresh throughout a fight, because a button's bag and slot identity is fixed and only the layout is protected.
- **Changed** - Existing `bagSkin` settings migrate once into the new `bagsV4` database: the enable state, opacity, scale, slot size, spacing, a column count derived from the old window width, sort mode, quality borders, item level, empty slots, the search bar and the saved window position. The old sort modes that no longer exist fall back to Bag order.
- **New** - The frame is moved by dragging its header, is clamped to the screen, and saves its own anchor and offsets. A drag started in combat is refused rather than deferred.
- **New** - All twenty-four Bags V4 interface strings ship translated for English, French, German, Spanish, Italian and Brazilian Portuguese, registered by the module itself so no legacy bag locale file is required.
- **Internal** - Refreshes are coalesced through a single one-frame timer, so a burst of bag events produces one scan, one layout pass and one sidebar rebuild rather than one of each per event.
- **Internal** - Values returned by the container API are passed through `issecretvalue` guards before being read, stored or compared, and each module's `Initialize` runs inside its own error handler so one failing part cannot take the rest of the window down.
- **New** - Bags V4 now offers two display modes. Combined keeps everything in the single TomoMod window; Separate hands the bags back to Blizzard's individual windows, hides the V4 frame and returns every suppressed container frame to its original parent. The `combinedBags` CVar is set to match — an ordinary client setting, not a protected action — and a failure on a client that does not have it is harmless.
- **New** - Skins > Bags is now a live options page writing straight into the Bags V4 database. It covers the display mode, column count, slot size, slot spacing, scale, opacity, visual sorting, the search bar, quality borders, item level, empty slots, and how many pinned and recent tiles the sidebar keeps. Every control applies immediately, without a reload.
- **Fixed** - Bags V4 now joins TomoMod's main initialization chain and the Home dashboard controls `bagsV4.enabled` directly. Turning it off closes the custom frame and restores Blizzard's bags immediately outside combat; `bagSkin.enabled` remains synchronized for the installer and presets that still use the legacy path.
- **Fixed** - Bag slots now use a minimal renderer that is independent of Blizzard's private icon and count regions. The visible icon, stack count and cooldown are simple TomoMod-owned layers, while the native `ContainerFrameItemButtonTemplate` remains the sole owner of secure clicks and dragging. Valid Midnight slots can no longer appear empty because an internal Blizzard region changed name or state.
- **Fixed** - Blizzard's native secure left/right click and drag paths are left untouched. Tooltips are attached with `HookScript` rather than replacing the template's handlers, middle mouse is observed separately for pinning without changing the registered secure clicks, and every TomoMod visual overlay remains non-interactive.
- **New** - Tooltips are raised by the module rather than inherited from whatever container frame Blizzard happens to parent the button to: `SetBagItem` where it exists, the stored item link otherwise. The native button's own HIGHLIGHT texture is reused and reset to the complete slot.
- **Fixed** - Blizzard's native icon, count, border, new-item, Battle.net, flash and glow regions are kept transparent or stopped when each secure button is created, leaving one predictable TomoMod visual path without altering the button's protected behaviour.
- **Changed** - Empty slots now use a minimal dark fill and soft border without extra image assets. Quality borders stay strong above common quality and subdued below it, while locked-state desaturation is applied only to the visible TomoMod icon.
- **Changed** - Stack quantities and item levels scale through four font-size steps based on the configured slot size. Each label has a subtle dark contrast plate; quantities remain bottom-right and item levels top-left, so they stay readable without overlapping one another.
- **Fixed** - Item level went missing on slots whose data the location API had not caught up with, which happens on Midnight. The live `ItemLocation` value is still preferred because it accounts for upgrades, with `C_Item.GetDetailedItemLevelInfo` on the stored item link as the fallback; both results pass an `issecretvalue` guard before being used.
- **New** - The combined window now fits the actual number of displayed items. It keeps the configured column count when possible, adds columns before introducing a scrollbar when vertical space is tight, and enables scrolling only when no geometry within the current resolution and scale can contain the complete grid. The scrollbar is hidden and reset whenever the whole grid fits.
- **Fixed** - Every secure item button is explicitly shown when it is created, whenever it is rendered and immediately after it is placed in the grid. A hidden state retained by a pooled Blizzard button can no longer leave a visible TomoMod slot blank or unable to receive clicks.
- **Changed** - Physical buttons continue to refresh their fixed bag/slot contents during combat; only filtering and layout changes that would move protected descendants are deferred until combat ends.
- **Changed** - The main surface, header, search area, sidebar and footer use slightly brighter dark tones for clearer separation. Empty Pinned and Recent messages now receive the available sidebar width, wrap to at most two lines and reserve enough vertical space for all six translations.
- **Changed** - A display-mode change made in combat is queued instead of refused, and a Blizzard container frame generated during lockdown, which cannot be reparented safely, leaves the native bag visible for the rest of the fight rather than showing both bag systems at once.
- **Internal** - The installer and presets still write the legacy `bagSkin.enabled` flag during Phase 1. A persisted mirror and a half-second compatibility poll route those external writes into Bags V4, while the Home dashboard and dedicated Bags panel use the clean V4 database and runtime API directly.
- **Changed** - Bag slots now identify their purpose at a glance: ordinary bag space uses a mint/teal outline, while reagent-bag space uses an azure-white outline. Occupied slots still use item-quality colours when quality borders are enabled; with that option disabled, they retain their bag-type outline.

#### Mythic+ Studio — Score Planner

- **Fixed** - The Current Score, Target Score, Estimated Gain and Potential columns now share the available card width instead of relying on fixed horizontal positions. Potential no longer extends beyond the right edge at the default Studio size or when text scaling is increased.

#### Cast Bars

- **Fixed** - The cast bar no longer closes partway through a long cast. `UNIT_SPELLCAST_SUCCEEDED` was treated as the end of the bar's lifecycle, but an instant spell or a proc fired during a cast emits its own SUCCEEDED, and that event closed the bar belonging to the spell still being cast. `UNIT_SPELLCAST_STOP` is now the single closing signal.
- **Fixed** - Terminal events are matched against the cast that actually opened the bar. The cast GUID recorded at START is compared on STOP, FAILED and INTERRUPTED, falling back to the spell ID when no GUID is available, so an unrelated spell's stop or interrupt can no longer close or flash the bar of the cast in progress.
- **Changed** - Both identifiers are passed through `issecretvalue` before any comparison, and an event whose GUID and spell ID are both hidden by the client is accepted as before. Hiding an identifier can never leave the bar stuck, and a secret value is never compared.
- **New** - A one-second grace period past the announced end of a cast closes a bar that has stopped receiving events. Removing SUCCEEDED from the lifecycle left the player bar with a single closing path, and the OnUpdate's "the owner is gone" guard explicitly excludes `player`, so a STOP lost to a latency spike or a mid-cast reconnect would have left the bar frozen on screen with nothing to clear it. The window is deliberately generous: a pushed-back cast fires `UNIT_SPELLCAST_DELAYED` and a hastened channel fires `CHANNEL_UPDATE`, and both recompute the real end time. Empowered spells are excluded, since they hold past their announced end by design until release.
- **Changed** - `FadeOut` now resets the bar's state first, so no stale cast identity survives a close. Without that, the next cast's STOP would be filtered out as belonging to another cast and the bar would stay up.
- **Fixed** - Layout Mode and the options-panel preview are now independent. Moving the player cast bar from Layout Mode materialises it on demand without loading TomoMod_Options, and closing Layout Mode no longer cancels a preview started from the configuration window, nor the other way round. A settings change that triggers a full refresh keeps the Layout Mode preview alive instead of dropping it.
- **Fixed** - Entering combat closes every cast bar preview immediately, so a preview left open can never win over a real cast. Disabling the module clears both preview states rather than leaving them set for the next time it is switched on.

#### Objective Tracker

- **Fixed** - Blizzard's full-size `common-opacity-background` NineSlice no longer appears as a second translucent panel behind the TomoMod Objective Tracker after a native layout or objective refresh.
- **Fixed** - The native tracker header and animated module-header backgrounds remain locked at zero while the TomoMod skin is active, preventing Blizzard's header animations from bringing them back. Every captured alpha is released and restored when the TomoMod Objective Tracker is disabled; an in-combat disable safely completes after combat.

#### Consumable Tracker

- **Changed** - The readiness tracker button is now parented to and anchored from the centre of the information panel clock, rather than its changing time text. It stays in front of the clock when the calendar opens or the clock changes between local, server, 12-hour and 24-hour display modes, without shifting or overlapping the text.
- **New** - Button size and tracker icon size are independently configurable in the General page and the dedicated Consumables page. Both settings apply immediately, are saved per profile, and are kept within practical limits: 14-32px for the button and 24-56px for tracker icons.
- **Changed** - The tracker layout now scales with its icon size. Timer areas and timer text resize with the icons, so increasing or reducing the tracker no longer leaves fixed-size timers that look too small, too large or misaligned.
- **Changed** - The tracker returns safely to `UIParent` with an appropriate frame level when the information panel clock is unavailable, then reattaches to the clock when it returns.

#### Layout Mode

- **New** - Hovering a movable TomoMod element in Layout Mode now shows a cog button. Clicking it opens the relevant TomoMod options page directly, including the dedicated Comfort pages where applicable.
- **Fixed** - The cog button's hover colour is now defined where the button is created. Its previous reference pointed to an accent local declared later in the file and could stop the Layout Mode shortcut from being built.
- **Changed** - The configuration shortcut resolves its destination from the stable name of the hovered frame and its parents. It no longer scans the entire frame hierarchy when Layout Mode opens, making the routing deterministic and avoiding unnecessary work on busy interfaces.
- **Fixed** - The Layout Mode cog is available again on the chat window. Its two routes still pointed at the frames of the old chat skin, which Chat V4 replaced and which are no longer created; a single route now covers the Chat V4 message host, sidebar, tab strip and copy window, which all share the same name prefix.

#### Blizzard Aura Frames

- **New** - Interface > General can now manage Blizzard's default buff and debuff frames separately. You can keep either one visible, hide either one, or disable TomoMod's management entirely; every choice applies immediately without a reload.
- **Changed** - Blizzard aura visibility is controlled without reparenting frames or unregistering Blizzard events. TomoMod restores the frame's original alpha and mouse state when management is disabled, while preserving all TomoMod unit-frame aura displays independently.

## ####################################

## CHANGELOG 4.0.0 — TomoMod Now Knows What It Contains: One Declarative Inventory Of All 68 Database Keys, Sorted Into Nine Groups, Replacing The Several Hand-Rolled Module Lists That Every Feature Used To Re-Derive Slightly Differently + A Runtime Enable/Disable Engine That Switches 27 Of The 62 Public Modules On And Off Without A Reload, Driven By A Per-Module Declaration Of Which Global Implements It And Which Method Realises The Flag Rather Than By Guessing From A Method Name + Combat Deferral For The Ten Live Toggles That Respawn Protected Frames, Queued And Replayed On `PLAYER_REGEN_ENABLED`, While The Seventeen That Only Register Or Unregister Events Go Through Immediately + A Dependency Cascade That Switches Off What Cannot Work Without The Module You Just Disabled And Names It, Plus A Missing-Dependency Warning In The Other Direction + The Reload Prompt Cut From Every Module To The Fourteen That Genuinely Cannot Undo Their Work At Runtime, And Then Asked Once Per Burst Rather Than Once Per Click: Seven Direct `StaticPopup_Show` Call Sites In The Options Panels Replaced By A Queue The Engine Owns, A 0.35s Debounce, A Batch Mode For Whole-Profile Applies, A Later Button That Keeps The Queue Instead Of Dropping It, A Banner Listing What Is Waiting, And A Request That Cancels Itself When A Setting Is Put Back The Way It Was At Login + A `/tm modules` Readout Of The Whole Inventory, Grouped, With Each Module's State And Its Live-Or-Reload Capability + 29 Movable Anchors Declared With The Three Storage Shapes They Actually Use Today, Ready For The Layout Engine + 81 New Locale Keys Across All Six Languages + Three Out-Of-Game Test Benches That Fail On Any Drift Between The Inventory, `TomoMod_Defaults`, The Six Locales And The Real Module Sources + A Ready Tracker For Group Content, Rebuilt From The Consumable Bar That Had Shipped Disabled And Unloaded Since 3.x: Flask, Well Fed And Weapon Oil Watched Together And Reported By A Button Pinned To The Minimap Clock That Is Reachable In Every Kind Of Content But Only Colours Itself In Group Content — A White House Glyph While Solo, Teal Or Red In A Dungeon, Raid, Scenario Or Delve — Expanding On A Click Into A Three-Slot Icon Panel With A Per-Buff Timer, Reading Oils Back Through `GetWeaponEnchantInfo`'s Temporary Enchant Ids Rather Than Spell Ids, And Asking For A Second Oil Only When A Real Weapon Is Equipped In The Off Hand — Never For A Shield Or A Held Off-Hand Item, Neither Of Which Can Be Oiled, With Its Own Section In The Information Panel Card Of The General Options Page And Six More Locale Keys Behind It + Profiles That Follow The Content, The Fourth Piece Of The v4 Foundation: Five Contexts — Solo, Party, Mythic+, Raid And PvP — Read From The Instance Type And The Challenge-Mode API Rather Than From Dungeon Or Season Ids, Which Get Renumbered At Every Patch And Would Rot In A Table + Each Context Assignable To A Profile For One Specialisation Or For All Of Them, The More Precise Assignment Winning And An Unassigned Context Changing Nothing At All So A Player Who Never Uses The Feature Keeps Today's Behaviour To The Letter + The Content Profile Swapped Whole Rather Than Layered Over The Spec Profile, Reusing The Spec Switch's Own Path Instead Of Inventing A Parallel One + The Swap Deferred To `PLAYER_REGEN_ENABLED` Because Slotting A Key Puts You In Combat Immediately, Making Deferral The Normal Path Rather Than A Safety Net + The Nine Modules Lot 0 Marked `contextSwap = false` Held Back Across The Swap So A Studio Opened In A Raid Is Not Closed By Stepping Into A Key, While A Manual Profile Load Still Replaces Everything + Both Snapshots Compared Before Anything Is Applied So A Reload Is Only Requested When The Swap Genuinely Changes Which Modules Are Switched On, Instead Of Once Per Zone Change + A `/tm context` Readout Of The Detection And Every Assignment, With The Engine Off Until `/tm context on` + `R.IsEnabledIn()` Reading A Module's Enabled State Out Of An Arbitrary Snapshot Instead Of Only The Live Database + A Fourth Out-Of-Game Bench Of 54 Assertions Covering Detection, Resolution, The Swap Itself, Combat Deferral, Pinning And The Reload Prediction + Nine Context Locale Keys And Three What's New Entries In All Six Languages + Resolution Presets Built On What The Client Actually Does With Resolution Rather Than On The Number On The Box: UIParent Is Measured In Interface Units And `uiScale` Is The Conversion, The Client Refuses To Go Below 0.64, And So 1440p And 2160p Produce A Rigorously Identical 1200-Unit Canvas While 1080p Gets 1080 Units — Which Means A Preset Is A Recommended `uiScale`, A Font Multiplier And A Stamping Pass, And Positions Are None Of The Three + Legibility Scaled From Twenty-Two Hand-Declared Font Keys Read Out Of The Defaults Rather Than Out Of The Live Values, So Applying A Preset Twice Cannot Compound It And A 1080 -> 1440 -> 1080 Round Trip Lands Exactly Where It Started, With A Floor Of 8 Below Which Type Stops Being Readable At Any Resolution + The Font Multiplier Running The Way People Do Not Expect — 1.15 At 1080p And 1.00 Above It, Because One Unit Is One Physical Pixel At 1080p And 1.8 At 2160p, So The Small Screen Is The One That Needs Bigger Type + `Layout.StampReference()` Marking Every Declared Anchor With The Current Screen Size So Positions That Came Through The Lot 2 Migration Carrying No Reference, And Are Therefore Applied Verbatim, Start Following A Resolution Change From That Point On — Never Called By The Migration Itself, Only At A Moment When The Player Has Just Said This Layout Suits This Screen + A Capture Path That Snapshots A Real Tuned Layout Out Of A Live Client As That Tier's Preset, Positions Read Back Through The Registry's Anchor List So A Preset Covers Exactly What Lot 0 Declared, And Always Beating The Computed Values + The `uiScale` CVar Written Only When It Would Change Something, Since Above 1200 Physical Lines The Client Ignores The Request And Writing It Would Only Produce A Setting That Disagrees With Reality + `/tm resolution` Printing The Scale Facts Of All Three Tiers Before Anything Is Applied, And `/tm resolution capture` Recording The Current One + Selective Import, The Sixth Piece Of The v4 Foundation: A Profile String Broken Into The Registry's Nine Groups With A Row Per Module Carrying Whether It Differs From What You Already Have And Whether Accepting It Costs A Reload, Because A Full Profile Carries All Sixty-Two Modules And Without That Field Every Row Looks Equally Worth Ticking When Three Of Them Hold Anything New + Only The Ticked Modules Written And Everything Else Left Exactly As It Was — A Merge Rather Than The All-Or-Nothing Emptying `ApplySnapshot` Performs — Then `TomoMod_MergeTables` Filling Whatever A Payload Exported Two Versions Ago Has No Entry For + One Top-Level Key Replaceable On Its Own Precisely Because Lot 0's `Validate()` Proved No Module's Toggle Or Anchor Path Reaches Sideways Into Another's `dbKey` + Profile Storage, Migration Flags, Resolution Captures And The Aura-Tracker Rescue Refused Outright So Another Player's Bookkeeping Cannot Travel, And The Six Internal Manifests Neither Offered Nor Reported As Unknown + One Reload Decision For A Whole Import, Raised Only For Modules Whose Enabled State Actually Moves And Which Have No Live Path + The Decode Sequence That Had Been Recopied Into Import, PreviewImport And ImportAsProfile Extracted To A Single `P.DecodeImport` Before Lot 6 Made It A Fourth Copy + `/tm import <string>` Reading What A Payload Really Contains Before Any Of It Is Accepted + Thirteen New Locale Keys In All Six Languages And Two More Out-Of-Game Benches, Of 64 And 53 Assertions

#### Module Inventory — The Foundation

#### Options — Focused Workspaces

- **New** — The Interface category now opens as a focused workspace in the options sidebar. Its General, Action Bars, Skins and Sound pages sit directly below Interface, while Home, Roles, Profiles and Diagnostics remain available without leaving the workspace. The existing panel builders, nested tabs, search and deep links are preserved.
- **New** — Units now uses the same focused workspace navigation for UnitFrames, Nameplates, Party Frames and Raid Frames. Each page remains lazily built and cached as before, including its existing nested controls and previews.
- **New** — Combat now uses the focused workspace navigation for Cast Bars, Resources, Cooldown Forge and Mythic+. The sidebar keeps the combat configuration pages together while preserving their existing builders, nested tabs, search paths and live previews.
- **New** — Comfort is now a grouped workspace with compact in-content navigation. Automation, Players, Classes, CVars, World Quest and Other appear in a first tab row, while a second row shows only the pages of the selected group. The sidebar stays as compact as the other workspaces, the last page selected in each group is remembered, and the existing panel builders, nested settings, search paths and live behaviour remain unchanged. The Consumables readiness tracker has a dedicated page, and Housing remains under Other during this navigation migration.
- **Changed** — The sidebar search filters workspace pages as well as categories, and its active state follows the selected page. Choosing Home returns to the full category list; opening another category outside the workspace does the same.

- **New** — `Core/ModuleRegistry.lua` is the engine of a central module inventory. It stores no behaviour of its own: a manifest records where a module keeps its settings, which group it belongs to, what it can be toggled by, what it may move on screen, and whether it survives a content swap. Defining a manifest does not load, enable, disable or touch a module.
- **New** — `Core/ModuleManifest.lua` is the inventory itself: **68 entries, one per top-level key of `TomoMod_Defaults`** — 62 public modules and 6 internal bookkeeping entries (installer progress, cached keystones, CVar backups, the last seen version) that are never listed, never toggled and never offered at import time.
- **New** — Nine groups own the drill-down level for selective profile import and the spine of the v4 navigation: general (8), actionbars (2), skins (11), unitframes (3), groupframes (4), nameplates (1), cooldowns (3), mythicplus (3) and qol (27). They deliberately do not mirror `TomoMod_Config.CategoryTree`, which describes the *current* config UI and is due to be rewritten — binding the data layer to it would mean re-labelling every manifest the day the shell changes.
- **New** — 29 movable elements are declared as anchors, each carrying the shape it is actually stored in today: `point_relativePoint` (21), `anchor_relTo` (6) and `point_relPoint` (2). Three variants grew independently over the years and all three are still live, so the layout engine cannot assume one; declaring the shape per anchor turns the normalisation into a table walk instead of 26 special cases.
- **New** — `contextSwap` marks which modules must **not** follow a content-profile swap. Diagnostics, addon detection and the studios are tooling: a player who opens them in a raid should not find them closed after stepping into a key.
- **Internal** — `R.Validate(defaults)` refuses an inventory that does not hold together: an unknown group, a `dbKey` absent from the defaults, a `dbKey` claimed twice, an `enabledPath` or an anchor path that escapes its own `dbKey`, a duplicate anchor id, or a dependency cycle — which is named in the error rather than merely reported.
- **Note** — Nothing in this layer changes runtime behaviour on its own. That is deliberate: the registry has to be trustworthy before anything is allowed to act on it.

#### Enable And Disable Without A Reload

- **New** — `Core/ModuleLifecycle.lua` turns modules on and off while the game is running. The work it needed already existed and was never wired up: 28 modules already shipped a `SetEnabled()`, three an `Enable()`/`Disable()` pair, and six skins already read the flag inside their own hooks. Nothing centralised any of it, so the config UI fell back to the one thing that always works — a reload prompt.
- **New** — Four apply modes, declared per module and never inferred: `setter` calls `impl.<apply>(value)` (20 modules), `gate` calls `impl.<apply>()` and lets the module re-read the flag itself (4), `pair` calls `Enable()` / `Disable()` (3), and no mode at all means there is no live path and the caller is told a reload is needed (41).
- **Note** — A method is called only where a manifest names it, because the same name means different things in different files: `Toggle()` writes the flag in most modules but shows or hides a window in Loots, and `SetEnabled()` does the full job in AutoSummon while writing nothing but the flag in TooltipSkin. Guessing from a name would silently do the wrong thing in a handful of modules, with no way to see it from the outside.
- **Changed** — `requiresReload` is down from 22 modules to **14**. What is left is a statement about today's code, not a design goal: secure frames that may not be respawned in combat, and `hooksecurefunc` hooks, which cannot be removed once installed.
- **New** — Anything that respawns frames is deferred to `PLAYER_REGEN_ENABLED` rather than tainting the rest of the session, and the request is queued and replayed when combat ends. The 17 toggles that only register or unregister events are marked `combatSafe` and go through immediately — making a player leave combat to turn off fast loot would be theatre.
- **New** — Turning a module off cascades to its dependents and reports which ones went with it; turning one on reports the dependencies that are still off. The cascade only travels downward: switching a dependent off never touches the module it depends on.
- **New** — `LC.Summary()` and `LC.Report()` describe the inventory's live state — how many modules are switchable now, how many need a reload, how many have no toggle at all — one line per module, each carrying its capability and whether it is bound to a live implementation.
- **Internal** — Every call into a module goes through an `xpcall` wrapper that hands the error to `geterrorhandler()` and carries on. One module blowing up while a profile is applied must not take the other sixty with it — `Init.lua` already learned that lesson for `Initialize()`, and it applies with more force here, because this runs on a player action rather than once at login.
- **Internal** — Writing the same value twice is safe and still calls through to the module, so a profile apply that re-asserts the current state behaves identically to one that changes it.

#### The Reload Prompt — Asked Once, Deferrable, And Visible

- **Changed** — Seven call sites across the Nameplates, Party Frames and Raid Frames option panels no longer call `StaticPopup_Show("TOMOMOD_MODULE_RELOAD")` the instant a box is ticked. They call `TomoMod_Lifecycle.RequestReload(<key>)` instead, and the engine decides when — and whether — anything is shown. The old popup is left registered and untouched for whatever still calls it directly.
- **New** — Requests are batched. A 0.35s debounce absorbs a burst of clicks, so ticking five boxes in a row raises one dialog at the end rather than five in a stack, and the dialog names what is waiting rather than saying "a change" five times.
- **New** — `LC.BeginBatch()` / `LC.EndBatch()` suppress the prompt around a set of changes that should produce a single decision — a profile being applied, or a resolution preset written later in the series.
- **New** — What each module's flag read at login is recorded in `bootState`. `LC.NoteReloadNeeded(key)` compares against it and *cancels* a pending request when the setting has been put back where it started: unticking a box and reticking it before reloading leaves the session exactly as it was, and prompting then would be asking the player to pay for nothing.
- **New** — "Later" keeps the queue rather than dropping it. A banner at the top of the screen then lists the modules that are waiting, with a Reload now button and a close button that hides the banner without clearing the queue. A player who deferred is never left looking at a checkbox that quietly disagrees with what is actually running.
- **New** — The dialog is raised into `FULLSCREEN_DIALOG` and re-anchored on the next frame, so it cannot be lost behind the config window the player was just clicking in. `TOOLTIP` would be higher still, but a dialog drawn over tooltips reads as a rendering fault rather than as emphasis.
- **Changed** — A prompt that comes due in combat is not shown. It re-arms through the same watcher that replays deferred toggles, and appears once combat ends.
- **New** — `Core/ModuleReloadUI.lua` holds both surfaces and is loaded after `Core/ModuleLifecycle.lua`. The split is deliberate: the engine owns what is waiting, this file owns how it is shown, and the presentation is what the v4 GUI work rewrites — so that rewrite touches one file instead of picking presentation out of an engine.
- **Internal** — The engine carries no reference to a frame or a popup. The surface registers itself through `LC.SetPromptHandler(fn)`, and the banner tracks the queue through `LC.OnPendingChanged(fn)` rather than a timer, so the headless benches drive both with a plain function. A watcher that throws is swallowed: a broken banner must not block the engine.
- **New** — `LC.PendingReload()` (sorted, so the dialog and the banner list in a stable order rather than whatever `pairs()` yields), `LC.PendingReloadCount()`, `LC.IsPendingReload(key)`, `LC.CancelReload(key)` and `LC.ClearReload()` make the queue readable and editable from outside.
- **New** — Five locale keys — the prompt line, both buttons and the singular/plural pending counts — in all six languages.
- **Internal** — `Tools/test_module_lifecycle.lua` grows 140 lines covering the queue, the debounce, batch suppression, the boot-state cancellation, combat, and the fact that a duplicate request neither double-counts nor re-arms the dialog. The static bench gains 12 lines asserting the five new keys exist in all six languages.

#### Slash Command

- **New** — `/tm modules` prints the whole inventory, grouped, with each module's on/off state and whether it is live, deferred or reload-only. `/tm modules <key>` toggles one, reports the cascade and the missing dependencies, and — since the reload request is now queued by `SetEnabled` itself — prints how many modules are waiting rather than raising a dialog of its own.
- **Note** — The config UI grows its own view of this later in the v4 series. Until then the slash command is the only way to see what the lifecycle engine can actually do, which matters because live-versus-reload is per module and not guessable from the outside.

#### Ready Tracker — Flask, Well Fed And Weapon Oil

- **New** — `Modules/QOL/Consumables/ConsumableBar.lua` becomes a readiness tracker for group content, watching three slots at once: flask, well fed and weapon oil. The file was written for 3.x, shipped disabled, and was never loaded at all — its `Include` in `Modules/QOL/QOL.xml` and its `safeInit` in `Core/Init.lua` were both commented out. Both are live again, and the module is rebuilt around the tracker rather than around a standalone bar.
- **New** — A 20px status button pinned to the clock of the information panel under the minimap. Its glyph is teal when all three consumables are up and red as soon as one is missing, so the whole check is one glance with nothing opened.
- **New** — Left click expands and collapses the icon panel, right click moves the button to the other side of the clock, and both choices are saved (`expanded`, `buttonSide`). The tooltip lists the three lines with a Ready or Missing verdict each, both click hints, and which side the button is currently on.
- **New** — `ApplyButtonAnchor()` anchors against `clock.timeText` or `clock.timeLabel` when they exist, and falls back to the clock's own edges, then to the minimap, then to `UIParent`. The information panel builds its clock with a short delay, so `Initialize()` schedules a second refresh at 1.2s to re-anchor once that clock really exists.
- **New** — Weapon oil is read through `GetWeaponEnchantInfo()`, which returns a temporary enchant id and not a spell id. `OIL_SPELL_BY_ENCHANT` maps enchants 8051 and 8052 back to spells 1237008 and 1237006, so the slot can show the real icon and the real tooltip instead of a placeholder.
- **New** — Dual wielding asks for two oils. `OffHandNeedsOil()` reads the off-hand item, the slot shows `count/required` in red until both are applied, and the tooltip carries `(0/2)` when neither is. The panel counts down the shorter of the two remaining times, since that is the one that runs out first.
- **Fix** — Only a real weapon in the off hand raises the requirement to two oils. The item class test on its own let through anything the game reports with the weapon class; the equip location now comes back from the same `GetItemInfoInstant` call and is checked as well, so only `INVTYPE_WEAPON` and `INVTYPE_WEAPONOFFHAND` count. A shield or a held off-hand item — tome, focus, orb — takes no oil, and the tracker no longer asks for one that cannot be applied. Both the class and the location are tested with `issecretvalue` before they are read.
- **New** — Food is matched on duration rather than against a list of spell ids: a self-applied aura lasting between 50 and 62 minutes is taken as the Well Fed buff. A new food item is therefore recognised without a code change, where a spell list would have to be extended every patch. Flasks stay on an explicit list of the four Midnight spell ids.
- **New** — `IsEligibleContent()` — `party`, `raid` and `scenario` instances, with a `C_DelvesUI.HasActiveDelve(mapID)` fallback so a delve is still covered if its instance type changes in a patch — gates the **colour**, not the visibility. The button is reachable everywhere, including the open world and a city, which is where consumables are actually applied and where a tracker that hides itself would be useless. Outside group content the glyph stays white: present, clickable, silent. The one condition on visibility is the clock the button is anchored to, which the tracker follows rather than floating under an empty minimap.
- **New** — The state is carried by the icon rather than by a frame. `Assets/Textures/icons/icon_consumables.tga` is a flat white 64px glyph — a flask inside a gear ring, drawn in the house style of the config icons — tinted through `SetVertexColor`. It replaces the phoenix-oil spell icon, which could not be tinted, and with it the coloured border and the 5px status dot: one signal instead of three saying the same thing. `SetTexCoord` is deliberately absent, since the 0.08/0.92 trim that crops a Blizzard spell icon's border would have eaten the gear teeth.
- **New** — The tracker gets a section of its own in the options, inside the *Information panel* card of the General page rather than under QoL: the button lives against the clock that card configures, so its settings belong beside the clock's own, not three pages away. A checkbox enables the module and a dropdown chooses which side of the clock the button sits on — the same two settings the left and right clicks already toggle, for players who would rather not discover them by clicking. Both write straight to `TomoModDB.consumableBar` and call `TomoMod_ConsumableBar.ApplySettings()`, so the change is on screen before the panel closes.
- **New** — Six locale keys for that section — heading, help text, checkbox and the three dropdown labels — added to `Locales/Locale_300.lua` in all six languages, next to the Compass block that file already carried.
- **Changed** — The panel keeps everything the old bar had — icon size, gap, orientation, timer position and its own saved position through the Movers system — and shows preview timers on all three slots while unlocked, so it can be placed without holding a flask.
- **Changed** — A one-off `readyTrackerMigrated` flag enables the module the first time this build runs and sets the collapsed state, the button side and the missing-slot display. It runs once per profile; an explicit choice made afterwards is never overwritten.
- **Internal** — Every value coming out of the aura and item APIs passes `issecretvalue` before it is compared or used as a table index, and every API call is wrapped in `pcall`. Refreshes are driven by `UNIT_AURA`, `UNIT_INVENTORY_CHANGED`, `PLAYER_EQUIPMENT_CHANGED`, `PLAYER_ENTERING_WORLD` and the three `ZONE_CHANGED` events, plus a 1s ticker that only rescans while the content is eligible.
- **Note** — The options section is localised, but the tracker's own labels are not: the tooltip and the slot names are still built from a table inside the module, on a `GetLocale() == "frFR"` test, so a German, Spanish, Italian or Brazilian player reads them in English. Its manifest declares no apply mode either, which puts it among the modules whose toggle still asks for a reload. Both are follow-ups, not part of this release.

#### Content Profiles — Following The Content

- **New** — `Core/ContextProfiles.lua` swaps the active profile when the content changes. Five contexts — `solo`, `party`, `mythicplus`, `raid` and `pvp` — derived from the instance type, `IsInRaid`/`IsInGroup` and `C_ChallengeMode.IsChallengeModeActive()`. Never from dungeon or season ids: those are renumbered at patches, and a table of them would rot.
- **Note** — Arbitration A: a content profile is swapped **whole** rather than layered over the spec profile. The spec-based switch in `Core/Profiles.lua` already does exactly this shape of work — save the active profile, apply another snapshot, note what is now active — so contexts follow the same path instead of inventing a parallel one. What is new is the key, the detection, and the three things that only matter because a content change can happen at any moment rather than at a deliberate click.
- **New** — Assignments live in `TomoModDB._profiles.contextProfiles`, keyed `<specID>:<context>` with a `*:<context>` wildcard, and are resolved most-specific-first: this spec and this content, then any spec and this content, then nothing. A context with no assignment returns nothing and `Evaluate()` leaves the database untouched — the spec rules keep whatever they decided, exactly as they do today.
- **New** — The engine is off until it is asked for. `contextEnabled` defaults to false, `CTX.SetEnabled(true)` evaluates once on the spot, and a player who never switches it on sees no behavioural change whatsoever.
- **New** — An assignment pointing at a profile that has since been deleted is treated as no assignment: applying nothing silently is better than erroring, and the stale key is dropped so it stops being consulted on every zone change.
- **New** — `P.ApplyForContext(name)` in `Core/Profiles.lua` is `LoadNamedProfile` with one reservation: the modules the registry marks `contextSwap = false` do not follow the content. Their `dbKey` is copied out before the snapshot is applied and written back after. The pinning applies **only** there — a manual profile load must still replace everything, since that is what the player asked for by clicking.
- **New** — A swap that comes due in combat is queued and replayed on `PLAYER_REGEN_ENABLED`, through a watcher that also carries `PLAYER_ENTERING_WORLD`, `ZONE_CHANGED_NEW_AREA`, `GROUP_ROSTER_UPDATE` and the three `CHALLENGE_MODE_*` events. This is not an edge case: a Mythic+ dungeon only reports as such once the key is started, so the context change that matters most lands mid-pull by construction, and rewriting `TomoModDB` and respawning frames there is precisely the taint the addon spends its time avoiding.
- **New** — `CTX.PredictReloads(snap)` compares the live database with the snapshot **before** anything is applied, and returns only the modules whose *enabled* state differs and which lot 1 found to have no live path. A snapshot differing in a slider, a colour or a position is applied silently; only a difference in which modules are switched on can raise a prompt. Without that comparison the player would be asked to reload on every zone change.
- **Note** — A module absent from a snapshot is not read as off. `ApplySnapshot` merges the defaults in afterwards, so a missing path means "not carried", not "disabled" — reading it as false would predict a reload for every module a partial snapshot happens not to hold, which is the exact opposite of the point.
- **New** — The whole swap runs inside `LC.BeginBatch()` / `LC.EndBatch()` and hands its predicted reloads to `LC.RequestReload()`, so a content change raises one decision rather than one prompt per module, and reuses the queue, the banner and the Later button from the previous section rather than growing a dialog of its own.
- **New** — `R.IsEnabledIn(source, key)` reads a module's enabled state out of an arbitrary table instead of `TomoModDB`, for both toggle models. `R.IsEnabled(key)` is now that same function applied to the live database, so there is one reading rather than two that could drift.
- **New** — `/tm context` prints whether the engine is on, what the detection returns right now, and every assignment as `<context> <spec> -> <profile>`. `/tm context on|off` switches it. The GUI arrives later in the series; until then this is the only way to see what the detection actually returns, which matters because Mythic+ only registers once the key has been slotted.
- **Internal** — `CTX.Initialize()` seeds the current context at login without swapping anything. At connection the active profile is the one that was saved, and treating that as a change would swap the whole configuration on every `/reload`.
- **Internal** — `CTX.Evaluate()` returns immediately when the detected context has not changed, so it is safe to call on every event the watcher carries. `CTX.LastReport()` exposes what the last evaluation did — context, whether it swapped, whether it was deferred, which profile, which reloads — for the bench and for the panel that comes later.

#### Resolution Presets — One Canvas, Two Legibilities

- **New** — `Core/ResolutionPresets.lua` fits the interface to the screen it is drawn on. Three tiers — `2160p`, `1440p` and `1080p` — are matched on physical height from the tallest down, and a tier is a recommendation rather than a lock: `RES.Apply()` takes an explicit key, so a 1440p player who prefers the 1080p type sizes can simply say so.
- **Note** — The arithmetic is the whole design, so it is worth stating. `UIParent` is measured in interface units, not pixels, and `uiScale` is the conversion: `UIParent height = 768 / uiScale`. The pixel-perfect value is `768 / physicalHeight`, but the client refuses to go below 0.64. So 1080p keeps its ideal 0.711 and gets 1080 units; 1440p wants 0.533, is floored to 0.640 and gets 1200; 2160p wants 0.356, is floored to the same 0.640 and gets the same 1200.
- **Note** — 1440p and 2160p therefore produce a **rigorously identical** interface space. A 4K player is not laying out a bigger canvas, they are laying out the same 1200-unit canvas rendered onto more pixels — so three hand-positioned layouts would mean authoring the same one twice.
- **Note** — What genuinely differs is legibility, and it differs in the direction nobody expects. One unit is one physical pixel at 1080p, 1.2 at 1440p and 1.8 at 2160p, so a 12-unit font renders at 12, 14 and 22 physical pixels. The small screen is the one that needs bigger type, which is why the font multiplier is 1.15 at 1080p and 1.00 above it.
- **Note** — A preset is consequently three things — a recommended `uiScale`, a font multiplier and a stamping pass — and positions are none of them. Positions have been resolution-independent since lot 2; rewriting them here would fight that engine rather than use it.
- **New** — 22 legibility keys are written out by hand rather than discovered by walking the defaults for anything named `fontSize`. A walk would silently pick up every key a future module adds, including the ones where scaling is wrong, and nobody would notice until type went strange on someone's screen. The list is checked against the real defaults by the bench, so it cannot rot quietly either.
- **New** — Font values are computed from `TomoMod_Defaults`, never from whatever is currently stored. Multiplying the live value would compound every time a preset was applied twice, and a player going 1080p → 1440p → 1080p would land somewhere neither preset describes. A floor of 8 units applies underneath, below which type stops being readable at any resolution.
- **New** — `RES.FontPlan(tier)` returns the plan as `path -> value` instead of writing it, so a panel can preview a tier before committing to it.
- **New** — `Layout.StampReference(db)` marks every declared anchor with the current screen size. Positions that came through the lot 2 migration carry no reference size, so the layout engine applies them verbatim and they never follow a resolution change; stamping is what opts them in. It is deliberately never called by the migration itself — doing it there would rescale everyone's layout on upgrade, which is the one thing the v2 conversion exists to avoid. It belongs to a moment when the player has just said this layout suits this screen, which is exactly what applying a preset means.
- **New** — `RES.Capture(tier)` snapshots a real, tuned layout out of a live client and stores it as that tier's preset: every declared anchor plus the legibility keys. Positions are read back through the registry's anchor list, so a capture covers exactly what lot 0 declared and cannot drift from it. A capture always beats the computed values — computed values are a floor, not an ambition — and this is the path to shipping hand-authored presets without anyone having to guess coordinates from outside the game.
- **New** — `RES.Apply()` returns a report rather than printing one, on the same reasoning as the lifecycle engine: the installer, the config panel and the slash command each want to present the outcome differently. `opts.skipScale` and `opts.skipFonts` let a caller take part of a preset.
- **New** — The `uiScale` CVar is only touched when it would change something. Above 1200 physical lines the client ignores the request, so writing it would only produce a saved setting that disagrees with what is on screen; `useUiScale` is set alongside it, and both go through `pcall`.
- **New** — `/tm resolution` prints what was detected, the physical size, and the three tiers with their applied scale, whether the floor caught them, the resulting `UIParent` height and whether a capture exists for that tier. `/tm resolution <tier>` applies one and says whether it came from a capture or from the computed values; `/tm resolution capture` records the current layout under the detected tier.
- **Internal** — State lives in `TomoModDB._resolution` behind a `SCHEMA_VERSION`, holding the last applied tier and the captures. `RES._Reset()` is a test seam. `RES.Describe(height)` is pure arithmetic and takes a height rather than reading the client, which is what lets the bench check the floor behaviour with no game running.

#### Selective Import — Taking Part Of A Profile

- **New** — `Core/SelectiveImport.lua` ends all-or-nothing importing. `ApplySnapshot` empties `TomoModDB` and writes the payload over it, so someone who wanted another player's nameplate work had to accept their action bars, their chat skin and their minimap along with it.
- **Note** — Arbitration C: nine collapsible groups with a drill-down. The groups come from `Core/ModuleRegistry.lua`, so this file holds no list of its own and cannot fall out of step with the inventory.
- **Note** — Replacing one top-level key is a complete, self-consistent operation rather than a half-applied import, and that is not an assumption: lot 0's `Validate()` proves that every toggle path and every anchor path of a module sits inside that module's own `dbKey`, with nothing reaching sideways into another module's table. It is why that check was written back then rather than left as a nicety.
- **New** — `SI.Inspect(settings)` builds the checkbox tree. Each row carries its key, label and group, what the module's enabled state is now and in the payload, whether importing it would change anything at all, and whether accepting it costs a reload.
- **Note** — `differs` is the field that makes the table usable. A full profile carries all sixty-two modules, and without it every row looks equally worth ticking when three of them actually hold anything new.
- **New** — Top-level keys the payload carries that no manifest claims are reported separately as unknown rather than silently dropped or silently applied. The six internal manifests are claimed too, so they are neither offered nor reported: nobody wants another player's installer progress or keystone cache.
- **New** — `SI.Summarize()` gives the dialog its header figures — how much is on offer, how much of it changes anything, how much of that costs a reload — for the whole tree or for a selection. `SI.AllKeys(groups, onlyChanged)` and `SI.GroupKeys(groups, key)` back the select-all and the per-group header checkbox, read from the tree that is actually displayed so neither can drift from it.
- **New** — `SI.Apply()` writes **only** the selected modules and leaves everything else exactly as it was. That is the entire difference from the existing import, and the reason it does not go anywhere near `ApplySnapshot`. `TomoMod_MergeTables` then fills any key the payload predates, because a profile exported two versions ago has no entry for settings added since, and `TomoMod_NormalizeAllElements` runs afterwards.
- **New** — `_profiles`, `_migrations`, `_resolution` and `_auraTrackerRescue` are refused outright. Profile storage, migration flags and resolution captures tied to somebody else's screen must never travel between installations, whether they are asked for by name or arrive in the unknown bucket.
- **New** — A reload is requested only for a module whose *enabled* state actually moves and which lot 1 found to have no live path. A different colour, size or position is applied on the spot. The whole import runs inside `LC.BeginBatch()` / `LC.EndBatch()`, so it raises one decision rather than one prompt per module, and reuses the queue and the banner instead of growing a dialog of its own.
- **Changed** — `P.DecodeImport(str)` in `Core/Profiles.lua` holds the decode / decompress / deserialise / validate-header sequence that had been recopied into `Import`, `PreviewImport` and `ImportAsProfile`. Their error messages had already started to diverge, and lot 6 would have made it a fourth copy. It deliberately does not consume the preview cache, so a caller can inspect a payload and then apply it without paying for deserialisation twice.
- **New** — `/tm import <string>` prints what a payload really contains before any of it is accepted: the three header figures, then each group with its modules coloured by whether they differ from the current configuration, and the unrecognised entries at the end. The checkbox panel arrives with the v4 GUI work; until then this is the way to avoid importing blind.
- **Internal** — The deep comparison short-circuits on the first difference. A preview compares sixty-odd module tables and only ever needs a yes or no per module, so walking the whole of each one would be wasted work on every keystroke in the import box. A depth cap of 12 keeps pathological nesting from running away.
- **Internal** — `SI.InspectString()` and `SI.ApplyString()` decode and act in one call, for the panel that comes next.

#### Load Order And Binding

- **Changed** — `TomoMod.toc` loads `Core/ModuleRegistry.lua` then `Core/ModuleManifest.lua` between `Core/Database.lua` and `Core/Profiles.lua`. Both must come after the defaults, since the manifests are validated against them, and before Profiles, which reads the inventory for selective import.
- **Changed** — `TomoMod_RegisterModule()` now also hands the implementation to the manifest of the same name, so the registry can reach a live module without every caller having to register twice. Modules with no manifest, and manifests no module ever registers against, both stay legal: the bind returns false and nothing else changes.
- **New** — `LC.Resolve()` binds each manifest to the global that implements it, and runs last in the login sequence, after every module has had its chance to create its table. A module that failed its `Initialize()` still created its table, so it stays bound and reports its real state instead of vanishing from the inventory. A manifest whose global is missing is not an error either — the module may belong to a sub-addon that is not loaded.
- **Changed** — `TomoMod.toc` loads `Core/ContextProfiles.lua` immediately after `Core/Profiles.lua`. It reads the registry and drives the profile switch, so both have to exist before it is defined; nothing of it runs until `Core/Init.lua` calls `Initialize()`.
- **Changed** — `TomoMod.toc` loads `Core/ResolutionPresets.lua` immediately after `Core/LayoutEngine.lua`, whose `StampReference` it calls, and `Core/SelectiveImport.lua` after `Core/ContextProfiles.lua`, since it reads the registry, the lifecycle engine and `P.DecodeImport` alike. Neither runs anything of its own at load time.

#### Localisation

- **New** — `Locales/Locale_Modules.lua` carries the inventory's own vocabulary: **81 keys — 9 group labels and 72 module labels — in all six languages**, loaded after the existing locale files.
- **Internal** — The static bench fails on a key that any manifest cites and any one of the six languages lacks, and equally on a key no manifest cites. The localisation metatable returns the raw key when one is missing, so an untranslated label does not raise anything — it simply appears on screen as `mod_minimap`.
- **New** — Nine context keys — the feature's title, the word the slash command uses for what it detected, the empty-list line, the five context names and the label that dresses the `*` wildcard for the future panel — in all six languages, in `Locales/Locale_Modules.lua` beside the inventory's own vocabulary.
- **New** — Three What's New entries, for the content profiles, for the tools that survive a swap and for the combat deferral, in all six languages. The `wn_400_foundation` note is reworded in the six as well: the content profiles it announced as a future release now read from that inventory, so it no longer lists them among the things still to come.
- **New** — Thirteen keys for the two new engines — eight for the resolution presets (the feature's title, the three tier labels, the word the slash command uses for what it detected, the line explaining the 0.64 floor, and the two that say whether a capture or the computed values were used) and five for the selective import (its title, the summary line, the changed/identical legend and the unrecognised-entries heading) — in all six languages, in `Locales/Locale_Modules.lua`.
- **New** — Four What's New entries: two for the resolution presets, one for the capture and one for the selective import, in all six languages. `wn_400_foundation` is reworded again — importing part of a profile is no longer something the inventory *will* buy, it is the third feature reading from it.

#### Test Benches

- **New** — `Tools/test_module_registry.lua` exercises the engine's full contract on synthetic manifests, independent of the real inventory: pointed paths, the structural guards in `Define`, enable/disable including composite toggles and their memo, groups and the tree, context pinning, anchors, dependencies, `Validate`, the payload slicing that selective import will use, and the implementation binding.
- **New** — `Tools/test_module_manifest_static.lua` locks the real inventory down: a strict bijection between the manifests and `TomoMod_Defaults` in both directions, every declared path resolving for real with the shape it announces, and every cited locale key present in all six languages.
- **New** — `Tools/test_module_lifecycle.lua` covers the engine: apply modes, combat deferral and replay, the dependency cascade, error isolation, `Toggle`, the report and idempotence.
- **New** — The static bench additionally re-reads the module sources to prove that each declared global and each declared apply method is really defined somewhere. A manifest can name any global and any method, and nothing contradicts it until the game has run — at which point the error shows up as a switch that does not respond. All 47 declared globals and all 30 apply methods resolve.
- **Internal** — The benches are written for `luajit` from the addon root and are never loaded in game. The source scan shells out through `io.popen` to a POSIX `find`, so it needs a Unix-like shell: run from `cmd.exe`, `find` resolves to the Windows text-search tool of the same name, the scan sees no files at all, and section 6 reports every declared target as missing.
- **New** — `Tools/test_context_profiles.lua`, 54 assertions over a simulated world: the detection in all ten of its cases including a started key outranking everything else, resolution with and without the wildcard, a stale assignment being cleaned up, the swap itself and its idempotence, the login seed that must not swap, combat deferral and its replay, the nine pinned modules surviving, the reload prediction on both a cosmetic and a structural difference, and `IsEnabledIn` against a table that is not the live database.
- **Changed** — The static bench reads the context labels back out of `Core/ContextProfiles.lua` and `Core/Init.lua` rather than freezing a list of them, the same way it already does for the Forge domains, and asserts that each one exists in all six languages.
- **New** — `Tools/test_resolution_presets.lua`, 64 assertions. The scale facts of all three tiers are locked in hard, because the 0.64 floor making 1440p and 2160p identical is exactly the kind of counter-intuitive result a regression would slip past unnoticed. It also proves the two properties the font scaling depends on: applying a preset twice does not compound, and a 1080 → 1440 → 1080 round trip lands back on the starting value.
- **New** — The same bench checks that the hand-written legibility list has not rotted — every path still resolves against the real defaults and every one of them is a number — and covers detection, the readability floor, the CVar being left alone when the client would ignore it, the stamping handover to the layout engine, and captures winning over the computed values in both directions including their removal.
- **New** — `Tools/test_selective_import.lua`, 53 assertions: the deep comparison, the tree and its `differs` column, the summary and the three key-list helpers, and the one behaviour that matters most — what is not ticked does not move, including keys the registry knows nothing about. Then the refusals, the reload prediction on a cosmetic change versus a real toggle, and a payload from an older version whose missing keys are filled from the defaults.
- **Changed** — The static bench reads the `res_` and `imp_` keys back out of `Core/ResolutionPresets.lua` and `Core/Init.lua` rather than freezing a list, the same way it already does for the Forge domains and the context labels, and asserts each one exists in all six languages.

## ####################################

## CHANGELOG 3.6.5 — Hotfix: The Mythic+ Studio Statistics Page No Longer Errors Out On Its Run A/B Comparison Card Once Two Keys Have Been Recorded — `FormatMS` Is Forward-Declared So `RunLabel`, Written 177 Lines Above The Formatter, Captures The Local Upvalue Instead Of Calling A Global That Does Not Exist + The Run Comparison Table Rebuilt: Its Three Value Columns Anchored Inside The Card Instead Of Off Its Right-Hand Edge, Fixed-Width Centred Columns Behind A Header Band, Vertical Rules And Alternating Row Stripes, And Deltas Coloured Green Or Red According To Whether They Are An Improvement On That Particular Line + The Character Sheet's Mythic+ Teleport Launcher Halved To A 22px Button With An 18px Icon And Re-Anchored To The Left Of `CharacterFrame.CloseButton`, With A `TOPRIGHT -32, -16` Fallback When That Button Does Not Exist + The Chat Skin's Channel Branch Guarded Against Secret Values: `arg1` Tested Once With `issecretvalue` And The `INVITE`, `WRONG_PASSWORD` And `YOU_LEFT` Comparisons Short-Circuited Behind That Flag, With The `CHANNEL_NOTICE_USER` Test Reordered So `arg1` Is Only Read For The Notice Type That Actually Carries It

#### Mythic+ Studio — Statistics Page

- **Fix** — Opening the Statistics page with two or more recorded runs raised `attempt to call global 'FormatMS' (a nil value)` and left the page half-drawn: the run A/B comparison card, the boss splits and everything below them never appeared. `RunLabel()` formats each run's duration through `FormatMS`, but `FormatMS` was a `local function` declared 177 lines further down the file. A Lua local is only in scope for the code that follows its declaration, so the name inside `RunLabel` compiled as a global lookup — and there is no global `FormatMS`.
- **Fix** — `local FormatMS` is now forward-declared next to `SafeRunHistory` and `FindRunIndex`, above `RunLabel`, and the implementation lower down assigns to it (`FormatMS = function(ms)`) rather than declaring a second, unrelated local of the same name. `RunLabel`'s closure therefore captures the upvalue that the implementation fills in, whatever order the two are reached in.
- **Note** — The comparison card is only built when at least two runs are stored — `#runs < 2` draws the "no data" placeholder instead — which is why the page looked correct on a fresh profile and only broke from the second completed key onward. That is also what kept it out of sight on a new install.
- **Note** — The formatter's three other call sites — the dashboard's recent-runs list, the comparison table's Time row and the Run History table — are all written below the implementation and were never affected. Only `RunLabel` reads it from above.
- **Internal** — Nothing else moves: `FormatMS`'s body, its callers and the Statistics layout are untouched, and the change is confined to `TomoMod_MythicPlus/Studio.lua`. Verified by compiling both copies of the file under Lua 5.1.

#### Mythic+ Studio — Run Comparison Table

- **Fix** — The table's three value columns were drawn outside the card altogether. They were anchored `TOPRIGHT` with positive X offsets — `SetPoint("TOPRIGHT", 465, y)` pins the string's top-right corner 465px to the *right* of the card's own top-right corner, not 465px in from its left edge — so the run A, run B and delta figures landed off the panel while the row labels, anchored `TOPLEFT`, stayed where they belonged. Headers, values and deltas are now all anchored `TOPLEFT` from named column constants.
- **Fix** — The two run names above the table used a bare `LEFT` anchor with a vertical offset, which stacks -66 / -116 on top of the card's vertical centre instead of measuring down from its top. They are anchored `TOPLEFT` too, and widened from 395 to 410 now that they no longer share their source line with the `<` button.
- **Changed** — The columns sit at 245 / 330 / 415, each 70 wide, so the rightmost ends at 485 inside a 520-wide card and cannot spill onto the per-dungeon card beside it. Values and headers are centred in their column, and the label column is capped at 210 so a long boss name cannot run into the figures.
- **New** — The table now reads as a table: a header band behind the column titles, a vertical rule in front of each of the three value columns, and a background stripe on every other row.
- **New** — Deltas are coloured by whether they are an improvement instead of all being drawn in grey. `Row()` takes the raw delta and a `higherIsBetter` flag: a higher key level is better, while a lower time, death count, enemy-forces time and boss split are better. Green for better, red for worse, grey for a delta of zero — and for one that cannot be computed at all, such as a boss present in only one of the two runs, which still draws an em dash.
- **Internal** — Each row computes its delta once as a number and hands `Row()` both the formatted string and that number, rather than formatting it and throwing the value away. Which runs are compared, how they are picked and how the splits are matched are all untouched.

#### Character Sheet — Mythic+ Teleport Launcher

- **Changed** — The launcher no longer sits in the Character Sheet's top-right shortcut row at 44×44 with a 36×36 icon. It is 22×22 with an 18×18 icon, anchored `RIGHT` to `CharacterFrame.CloseButton`'s `LEFT` with a 4px gap, so it reads as a discreet utility shortcut instead of a second header icon competing with the sheet's own chrome.
- **Internal** — The anchor is guarded. When `CharacterFrame.CloseButton` does not exist — a Blizzard rename, or another addon replacing the header — the button falls back to `TOPRIGHT, -32, -16` on `CharacterFrame` rather than failing to place itself and landing at the frame's centre. Frame level, backdrop, hover tint, tooltip, click behaviour and the visibility rules are untouched, and the change is confined to `Modules/QOL/MythicPlus/TeleportMenu.lua`.

#### Chat Skin — Channel Notices And Secret Values

- **Fix** — `ChatFrame_MessageEventHandler`'s channel branch compared `arg1` against `"INVITE"`, `"WRONG_PASSWORD"` and `"YOU_LEFT"` without ever asking whether `arg1` was a secret value. A channel notice that arrives with a protected `arg1` therefore hit a comparison the client does not permit on secret values, and the notice was lost. `local arg1IsSecret = issecretvalue and issecretvalue(arg1)` is now computed once, next to `infoType`, and every one of those three comparisons is short-circuited behind `not arg1IsSecret`.
- **Changed** — The `elseif` that routes channel events is reordered from `((arg1 ~= "INVITE") or (chatType ~= "CHANNEL_NOTICE_USER"))` to `((chatType ~= "CHANNEL_NOTICE_USER") or (not arg1IsSecret and arg1 ~= "INVITE"))`. The two forms select the same events, but the new one tests the cheap, always-safe `chatType` first and only reads `arg1` for the single notice type that carries an invite — so no other channel event evaluates that comparison at all.
- **Internal** — The guard mirrors what the file already does elsewhere: `issecretvalue` is localised at the top, the monster-event path blanks a secret `arg4` / `arg9`, and the `BN_INLINE_TOAST_ALERT` branch returns early on a secret `arg1`. Only the channel branch was missing its equivalent. Which channel a notice is matched to, the zone-channel lookup and the `frame.channelList` / `frame.zoneChannelList` cleanup are otherwise untouched, and the change is confined to `Modules/QOL/Skins/ChatFrameSkin.lua`.

## ####################################

## CHANGELOG 3.6.4 — Mythic+ Studio: A Dedicated Load-On-Demand Control Centre With Eleven Pages — Dashboard, Tracker, TomoScore, Keys, Run History, Statistics, Weekly Planner, Score Planner, Level Analysis, Season Goals And Modules + Local Run History Recorded By TomoMod And Capped At 100 Completed Keys + Run A/B Comparison With Boss Splits + Custom Mythic+ Tracker Colours Read From The Saved Profile + Tracker Positioning Mode And Live HUD Preview Driven From The Studio + The Legacy MythicHub Window Redirected To The New Dashboard While Keystone, DataKeys, KeySync, The Tracker And TomoScore Stay Permanently Loaded In TomoMod + A New /tmplus Slash Command And An "Open Mythic+ Studio" Button On The Options Mythic+ Page + Party And Raid HoT Icon Size Applied Again, From The Options Sliders And From Healer Studio Alike + An Optional HoT Duration Readout — Keep The Seconds Or Keep Only The Sweep — And A HoT Size Ceiling Raised To 50px Everywhere + A Mythic+ Studio Appearance Page With Text Scale, Window Scale, Background Opacity And A Custom Accent, Plus Weekly Reward Item Levels On The Vault And The Weekly Planner + The Legacy Mythic+ Window Made Mouse-Only So Movement Keys Keep Reaching The Game + A Mythic+ Teleport Menu On The Character Sheet, Built From The Same Season Data As The Rest Of The Mythic+ Modules

#### Mythic+ Studio — New Load-On-Demand Addon

- **New** — `TomoMod_MythicPlus` is a separate `LoadOnDemand` addon (`Bootstrap.lua`, `RunHistory.lua`, `Studio.lua`) that depends on TomoMod and owns the dashboard, the history and the statistics. Nothing of it is in memory until the Studio is opened for the first time or a key starts, so a player who never opens it pays nothing for it.
- **New** — Eleven pages behind a left-hand nav: Dashboard, Tracker, TomoScore, Keys, Run History, Statistics, Weekly Planner, Score Planner, Level Analysis, Season Goals and Modules. The window position and the last page visited are remembered in `TomoModMythicPlusDB`.
- **New** — A Modules page switches Run History and Statistics off individually. A page whose module is disabled says so rather than drawing an empty shell.
- **Note** — The Studio is deliberately mouse-only: it never calls `EnableKeyboard`, so it cannot compete with WorldFrame for movement bindings when it opens around a dungeon event. This is the same rule TomoScore was put back under in 3.6.3.
- **Internal** — Every value read from the game's Mythic+ API goes through `IsSecret` / `Num` / `Bool` / `Str` guards, so a secret value returned mid-run is treated as missing instead of erroring.

#### Mythic+ Studio — Entry Points

- **New** — `Modules/QOL/MythicPlus/MythicPlusBridge.lua` is a small always-loaded bridge that owns every entry point: it loads the LoD addon on demand, prints a localised error when the load fails, and forwards `CHALLENGE_MODE_START` / `CHALLENGE_MODE_COMPLETED`.
- **New** — `/tmplus` (and `/tmmplus`) toggles the Studio.
- **Changed** — The old MythicHub window's `Show` and `Toggle` now open the new dashboard. The original implementation is kept and is still reachable from the Studio through `OpenLegacyHub()`, so the detailed dungeon/vault view is not lost.
- **Fix** — Opening the Studio during combat no longer fails silently: the request is queued, a localised message says it will open when combat ends, and `PLAYER_REGEN_ENABLED` opens the page that was asked for.
- **Note** — The bridge itself forwards the challenge-start event that caused the LoD addon to load. A frame created in response to an event cannot receive that event retroactively, so without this the very first key of a session would not have been recorded.

#### Run History — Local Recording

- **New** — Every Mythic+ key completed from this version onward is recorded locally: dungeon, level, time, timed or not, deaths, affixes, score gain and boss splits.
- **Note** — Blizzard's historical run list is read for dashboard context but is never rewritten as local history. The history therefore starts empty and fills up as you play; it is not back-filled from anything.
- **Changed** — The store keeps the latest 100 runs. The first draft kept 500; the cap is fixed rather than a slider, and existing databases are trimmed on load instead of only after the next completed key, so a profile copied between characters cannot carry an oversized store forward.

#### Statistics & Run Comparison

- **New** — A Statistics page builds season and per-dungeon figures — runs, timed rate, average time, average deaths — from the local history.
- **New** — Run A/B comparison puts two recorded runs side by side with their boss splits and the delta between them. Comparing two runs of different dungeons is allowed and says so: splits are then matched by position only.

#### Weekly Planner, Score Planner, Level Analysis & Season Goals

- **New** — Weekly Planner shows the three weekly dungeon slots, what is still missing for the next one and your best key of the week.
- **New** — Score Planner suggests the next key level to run and shows an indicative gain. The figure is a planning estimate — Blizzard's recorded dungeon score stays the authoritative value, and the page says so.
- **New** — Level Analysis breaks the local history down by key level and derives a "comfort level": the highest level with at least three tracked runs and a 70% timed rate.
- **New** — Season Goals tracks score, highest key, timed keys at a target level, total tracked runs and all season dungeons cleared at a given level, each with its own target. Run-count goals read the local history, so they start counting when Run History is enabled.

#### Mythic+ Tracker — Custom Colours

- **New** — `TMT:BuildPalette()` reads `TomoModDB.MythicTracker.colors` when `useCustomColors` is set, so the accent, background, header, text, enemy-forces and the three timer-bracket colours can be set per profile from the Studio's Tracker page.
- **Changed** — Only the accent is picked directly; its darker and hover variants are derived from it (×0.58, and ×1.18 + 0.08 clamped to 1) so a custom accent keeps a consistent set of shades instead of needing three separate pickers.
- **Note** — With `useCustomColors` off, the palette resolves exactly as before through `TomoMod_Utils.BRAND` and the shared widget theme. Each colour also falls back to its old value individually, so a partially filled colour table cannot blank part of the tracker.

#### Mythic+ Tracker — Positioning & Preview

- **New** — The Tracker page carries a live HUD preview of the tracker, so a scale, alpha or colour change can be judged without starting a key.
- **New** — A positioning mode drops the real tracker on screen with a Done / Cancel / Reset bar, so it can be placed against the rest of the interface rather than dragged blind.
- **Note** — Positioning mode refuses to start during an active Mythic+ run and says why, instead of moving the frame you are currently reading.

#### Options — Mythic+ Page

- **New** — The Mythic+ options page opens with a Mythic+ Studio card and an "Open Mythic+ Studio" button. The existing controls stay below it, so nothing moves for a profile that was already set up.
- **Note** — The card's strings come from the bridge, not from `TomoMod_L`: the Studio is reachable even when `TomoMod_Options` has never been loaded, so it carries its own six-locale vocabulary.

#### Mythic+ Studio — Appearance Page

- **New** — A twelfth page, Appearance, owns the Studio's own look: window text size (0.85–1.50), window scale (0.85–1.15), background opacity (0.72–1.00), an optional custom accent colour and a reset button, over a live mock of the header, a card and a stat value so a change can be judged without leaving the page.
- **New** — `MP:ApplyStudioAppearance()` pushes the accent, the background alpha and the window scale onto the live frame and re-runs the font sizing across the header, the subtitle, the version label and every nav button. Each font string records the size it was authored at (`_tmMPlusBaseSize` / `_tmMPlusBold`), so the scale multiplies that rather than flattening every string in the window to one size.
- **Changed** — `TomoModMythicPlusDB` gains a `ui` block — `textScale`, `windowScale`, `backgroundAlpha`, `useCustomAccent`, `accent` — normalised field by field on load, with the accent accepting either `{r,g,b}` or `{[1],[2],[3]}`. `MP.VERSION` moves 2 → 4.
- **Note** — The page states plainly that it governs the Studio only: tracker colours stay independent on the Dungeon Tracker page, and the two are stored apart. The strings ship in `Bootstrap.lua`'s own six-locale table, like the rest of the Studio's vocabulary.

#### Mythic+ Studio — Slider Widget

- **Changed** — Sliders are drawn in-house — a rail, an accent fill that tracks the value, a thumb — instead of `OptionsSliderTemplate`, whose Low/High/Text labels were being blanked one by one anyway. They take the mouse wheel, and the fill repaints on the rail's `OnSizeChanged`, so a slider built before its rail has a width still ends up drawn correctly.
- **Fix** — The value is seeded BEFORE `OnValueChanged` is wired. `SetValue()` raises that script, so in the other order every slider fired its caller's callback once while being constructed. On the Appearance page that callback rebuilds the page, which builds the slider, which fires again — the Studio died with a C stack overflow the moment the page was opened. Every other page was silently running its slider callbacks at build time too: opening the Tracker page fired a full `TrackerRefresh()` once per slider.
- **Fix** — `MP:RefreshStudioAppearance()` no longer nests. It calls `SelectPage()`, which rebuilds the page it was itself called from, and a rebuilt control can call straight back in. The guard is released through a `pcall` so a failure inside `SelectPage()` cannot latch it and silently disable every later refresh.

#### Mythic+ Studio — Weekly Reward Item Level

- **New** — Every Great Vault slot, on the dashboard and in the Weekly Planner, shows the item level its reward would come in at, under the key level. `C_MythicPlus.GetRewardLevelForDifficultyLevel` is tried first and `GetRewardLevelFromKeystoneLevel` second; both are `pcall`ed, both may return several values, and the highest positive one is kept. A level the client will not answer for draws an em dash rather than a wrong number.

#### Mythic+ Studio — Tracker Preview

- **Changed** — The tracker's real preview is a toggle: the same button opens the actual tracker and puts it away again, instead of only ever showing it and leaving the player to work out how to dismiss it. The label follows the state.
- **New** — The preview is torn down on every way out — leaving the Tracker page, resetting the tracker position, and closing the Studio, whose X now goes through `MP:Hide()` rather than a bare `Frame:Hide()`.
- **Note** — It refuses to put itself away while a key is actually running, so a preview opened before the pull cannot take the real tracker off screen mid-run.
- **Fix** — Four helpers (`WeeklyRewardItemLevel`, `RefreshOpenPage`, `MP:HideTrackerStandalonePreview`, `MP:ToggleTrackerStandalonePreview`) had landed inside the body of `SeasonBest()`, between its last loop and its `return`. That is valid Lua and loads without a word of complaint, which is what makes it dangerous: it scoped the two local helpers to `SeasonBest` — invisible to the dashboard and the weekly planner that call them — and left the two `MP:` methods unassigned until `SeasonBest` happened to run at least once, while `BeginPage()` calls one of them with no existence check. They now sit at file scope.

#### Mythic+ Studio — Tracker Page Layout

- **Fix** — The Tracker page's controls ran off the bottom of their own card. The card is 646 tall and the column reached −705 by the time the buttons were placed, so Reset position was drawn outside it entirely. The vertical rhythm is retightened along the whole column — every slider step, the checkbox groups and the three segmented controls — which brings the last row to −627 and leaves the card about 19px of slack.
- **Changed** — `Slider()` is 46 tall again rather than 54, with its rail at −20 and its thumb at +6. The extra height arrived with the in-house rail in the previous pass and is what pushed the page over; the reduction applies to every page that draws a slider, not only this one.
- **Changed** — Real preview, Edit mode and Reset position now sit on a single row of three 122px buttons 8px apart (right edge at 396 inside a 420 card) instead of a row of two and an orphan below. Three shorter labels ship with it in all six locales, and the unused `previewButton` local left behind by the previous pass is gone.
- **Note** — The three older strings the buttons used (`tracker_preview_show`, `tracker_preview_hide`, `tracker_reset`) are now unreferenced. They are left in place: they cost one table entry each, and `MP:T()` falls back to enUS and then to the key name, so nothing depends on pruning them.

#### Party & Raid Frames — HoT Icon Size

- **Fix** — Changing the HoT icon size did nothing on the party and raid cells, from either entry point: the `HoT icon size` sliders on the Party Frames and Raid Frames pages, and Healer Studio's per-spell size slider. Placement was applied correctly, which made it read as a display bug rather than a settings one — an indicator's anchor goes through a direct `SetPoint()` on its container, while its size has to travel through the aura engine, and only that half was lost.
- **Fix** — `AddGroups()` handed `MakeInitializer()` a COPY of the container's spec (`MakeInitializer({ size = spec.size, ... })`). The engine builds a button the first time an aura actually appears, which can be long after a size change, and it never re-runs the initializer on a recycled button — so a closure over a snapshot gave every later button the size the container was created with. Resizing a HoT while that HoT was not up therefore always came back at the old size. The initializer now closes over the live `spec` table, which is the one `AC.Relayout()` writes into. That is what the 3.6.3 note "newly pooled buttons inherit the new spec automatically" described and did not do.
- **Fix** — `AC.Relayout()` recognised its own buttons with `button:GetParent() == container`, which is a guess about where the engine parents the buttons it hands back, and a guess whose failure is silent: the icons simply keep their previous size. Every button now carries `d.container`, stamped by the initializer, and the sweep matches on that instead. Probe and dispel-alert buttons carry no container and are skipped, which is correct — they are one pixel by design.
- **Fix** — That sweep also ran AFTER the `SetAuraGroupLayout` / `SetAuraGroupMaxFrameCount` guard, so a missing or refused setter returned before it ever happened. `data.size` had already been stamped by then, and every later call exits on `not sizeChanged`, so a single refusal locked the icon size for the rest of the session. The sweep is extracted into `ResizeContainerButtons()` and now runs first and unconditionally.
- **Changed** — The icon's aspect crop (`2 / size`) is recomputed on a resize. It was calculated once from the size the button was built at, so a resized icon kept a crop cut for a size it no longer had.

#### Party & Raid Frames — Legacy HoT Row Settings

- **Fix** — The HoT size and count sliders on the Party Frames and Raid Frames pages saved to the profile and applied nothing: their callbacks were `function(v) db.hotSize = v end`, with no `ApplyPF()` / `ApplyRF()`. Both now apply, as the neighbouring sliders in the same card already did.
- **Fix** — `PF.ApplySettings()` and `RF.ApplySettings()` never touched `f.hotContainer`, so even a forced apply left the row alone and the two settings only reached cells built after a `/reload`. Both now resize the host frame from `hotSize` and `maxHoTs` and push the pair through `AC.Relayout()` on the engine group, alongside the CD tracker and defensive containers they already handled.
- **Note** — The raid `Debuff size` and `Max debuffs` sliders carry the same defect and are deliberately left for a separate pass rather than folded into a HoT fix.

#### Party & Raid Frames — HoT Duration Text & Size Ceiling

- **New** — The seconds printed over a HoT icon can be switched off, leaving the cooldown sweep. The swipe is a separate widget from the duration font string, so hiding the text costs nothing else: the icon still shows time running out, just without a number over art that may be only a few pixels wide. Blizzard's own swipe digits stay off as before, so this governs one readout and not two overlapping ones.
- **New** — Party Frames and Raid Frames each carry the toggle next to their HoT size and count sliders (`hotShowDuration`), and Healer Studio carries a per-mode one on its Party and Raid profiles. Neither imposes on the other: the legacy row and the advanced indicators keep their own setting, so a player can have digits on one and only the sweep on the other.
- **Changed** — `AC.Relayout()` accepts `showDuration`. It is deliberately written out rather than folded into the `and` / `or` chain its neighbours use: this one is a boolean, `false` is falsy, and that idiom would silently discard every request to turn the digits OFF. It is also applied before the size branch, which can still bail out on a missing engine setter.
- **Note** — An absent `showDuration` means on — in the defaults, in `Normalize()` and at every read site (`~= false`). A profile written before this version keeps the look it had instead of being silently restyled.
- **Changed** — The Healer Studio size ceiling goes from 30 to 50 px (`HI.MAX_SIZE`, which the studio's slider already read rather than copying). It is not clamped to the cell: a 50px indicator covers a raid cell outright, and one big icon on a small cell reads at a glance where a 20px one does not, so the bound only stops a value the engine cannot draw.
- **Changed** — The HoT icon size sliders on the Party Frames and Raid Frames pages follow, reaching 50 as well; they were capped at 20 and 16. "HoT size" now means the same range wherever it is set.
- **New** — The Healer Studio preview draws the duration text when it is on, at `9 * scale`. The runtime draws it at a fixed 9pt whatever the icon size, so the preview shows how small the number really is beside a 50px icon rather than scaling it into something the game will not draw.
- **Note** — That preview string is given its font at creation, before its first `SetText()`, not by the sizing call that runs later: `SetText()` on a FontString with no font assigned throws `Font not set`. It is the same ordering trap `AuraContainer.lua` documents at the top of its button builder, and the studio hit it because `EnsureIcon()` runs ahead of `PlaceIcon()`. The shared helper also falls back to `STANDARD_TEXT_FONT`, since `SetFont()` returns `false` rather than erroring when the client refuses a font file — a bare `SetFont()` is not proof that a font landed.
- **Changed** — `hotShowDuration` is carried by the party and raid defaults in `Core/Database.lua`, and by both the defaults map and the one preset that overrides HoT settings in `Presets.lua`, so applying a preset sets it explicitly instead of leaving whatever the profile happened to hold.

#### Mythic+ — Legacy MythicHub Window

- **Fix** — The legacy MythicHub window no longer routes Escape through `TomoMod_Utils.CloseOnEscape()`. Closing on Escape requires the frame to take keyboard input, and a keyboard-enabled frame with restricted propagation can consume the bindings the WorldFrame needs — ZQSD/WASD movement, jump, and every other keybind — for as long as the window is open.
- **Changed** — `MythicHub.lua` now states its intent instead: `F:EnableKeyboard(false)`. It is an informational, mouse-driven panel, its close button is the way to dismiss it, and the dungeon/vault view it carries is otherwise untouched.
- **Note** — `CloseOnEscape()` already avoided the `ToggleGameMenu` → `ClearTarget` taint path documented in 3.5.5; it paid for that with a keyboard-enabled frame. Not handling Escape at all avoids both, and puts the legacy hub under the same rule as TomoScore in 3.6.3 and the Mythic+ Studio in this release: a window that only displays information never asks for the keyboard.

#### Character Sheet — Mythic+ Teleport Menu

- **New** — `Modules/QOL/MythicPlus/TeleportMenu.lua` puts a launcher on the Character frame that opens a panel of the current season's dungeon teleports, eight cells in a 4x2 grid. Each cell carries the spell icon, the dungeon's short name and a tooltip with its full name.
- **New** — The season list, the dungeon names and short names, the teleport spell IDs and the known/unknown test all come from `TomoMod_DataKeys` (`GetCurrentSeasonIDs`, `GetDungeonName`, `GetShortName`, `GetTeleportSpellID`, `IsTeleportKnown`). There is no second season table to keep in step: the menu follows whatever DataKeys resolves for the live season.
- **Changed** — A teleport the character has not unlocked is still drawn, desaturated at 35% alpha with a neutral border and a tooltip that says so, rather than being omitted. A missing cell would otherwise read as a bug in the menu instead of as missing attunement.
- **Note** — The cells are `SecureActionButtonTemplate` buttons whose `type` / `spell` attributes are only set for a teleport that is actually known, so an unavailable cell has nothing to cast rather than casting and failing. Every write to those attributes is gated on `InCombatLockdown()`.
- **Note** — Opening or refreshing the menu in combat is refused, with a localised line through `UIErrorsFrame`. A refresh asked for during combat sets `_refreshPending` and is replayed on `PLAYER_REGEN_ENABLED`, which also closes the panel if the Character frame went away while it was locked down.
- **Changed** — The icon is looked up through `C_Spell.GetSpellTexture` first and `C_ChallengeMode.GetMapUIInfo` second, both `pcall`ed, with a generic icon as the last resort. Neither call is trusted to answer for a season the client has not finished loading.
- **New** — `Assets/Textures/TeleportMenu.tga`, a 64x64 32-bit icon for the launcher.
- **Note** — The launcher follows the Character frame skin toggle (`characterSkin.enabled` and `skinCharacter`): with the skin off, no button is added. The panel is mouse-only and never calls `EnableKeyboard(true)`, under the same rule as TomoScore and the Mythic+ Studio.
- **Changed** — `Modules/QOL/QOL.xml` loads the file after `MythicPlusBridge.lua` and well after `DataKeys.lua`, so the `TomoMod_DataKeys` upvalue it captures at file scope is already there.

#### Packaging

- **Changed** — `.pkgmeta` gained `TomoMod/TomoMod_MythicPlus: TomoMod_MythicPlus`, so the packager ships the new addon as a sibling folder like CDStudio, AstralForge, HealerStudio and Options.
- **Changed** — All eleven `.toc` files move to 3.6.4 together, the two new ones included.

## ####################################

## CHANGELOG 3.6.3 — Aura Containers on 12.1: Restored Icon Spacing, Containers Enabled When a Unit Is Bound, Live Size and Count Changes Without a Group Rebuild, Recycled Cells and Plates Unbound Cleanly & Aura Probes Disabled on Teardown — Fixing Healer Studio Indicators, Party and Raid HoT Rows, Debuff and Dispel Indicators, Nameplate Auras, Unit Frame Auras and Cooldown Forge Probes + Party and Raid Frames: Death Tint Cleared on Resurrection Through Unit-State Events + TomoScore: Mouse-Only Scoreboard So Movement Keys Keep Reaching the Game + Raid Frames: Unit Events Gated on Raid Membership Instead of Running Everywhere + Leveling Bar: Frame And Module No Longer Share A Global Name, So The Option, The Size Sliders, The Mover And /tm sr Work After The Bar Has Been Built Once + Resource Bars: Flat Fill For Death Knight Runes + AstralForge: Dropping An Element Now Picks The Nearest Anchor On Its Current Target, The Same Drag Model As Healer Studio, While Element-To-Element Anchoring Is Deliberately Preserved

#### Shared Aura Containers — Layout Keys

- **Fix** — `AddGroups()` built its group layout with `spacingX` / `spacingY`, which the 12.1 aura container engine does not read. The spacing option was therefore ignored everywhere a container is used and every icon row was drawn at the engine's own default gap. The keys are now `elementSpacing` (between icons on a line) and `lineSpacing` (between lines), which is what the engine actually consumes.
- **Note** — One layout table feeds every consumer, so the fix lands in the same pass on nameplate auras and buffs, party and raid HoT rows, debuff and dispel indicators, unit frame auras and Healer Studio indicators.

#### Shared Aura Containers — Enabling a Bound Container

- **Fix** — A container is inert until it is enabled. `AC.Create()`, `AC.CreateAuraProbe()`, `AC.CreateDispelIndicator()` and `AC.SetUnit()` assigned a unit and then asked for an update, but never called `SetEnabled`, so the engine had a unit and groups and still scanned nothing. Every path that binds a unit now enables the container immediately after, and only when the assignment itself succeeded.
- **Changed** — `AC.Create()` and `AC.CreateDispelIndicator()` no longer call `SetUnit` at all when `opts.unit` is nil. Passing nil into the engine's setter is not the same as never binding: a container created for a frame whose unit is not known yet is now left untouched until `AC.SetUnit()` gives it one.
- **Note** — `SetEnabled` is called through `pcall` and guarded on the method existing, so a client that does not publish it behaves exactly as before rather than erroring.

#### Shared Aura Containers — Live Size and Count Changes

- **Fix** — Changing an aura size or an icon count from the settings did nothing on 12.1. `AC.Relayout()` removed the container's aura groups and re-added them at the new size, but aura groups are add-only now: `RemoveAuraGroup` does not take the key back, so the re-add landed on a key that was still occupied and the container kept drawing at its previous size until the frame was rebuilt from scratch.
- **Changed** — The rebuild is replaced by the engine's live setters. `SetAuraGroupLayout` pushes the new geometry and `SetAuraGroupMaxFrameCount` the new budget, for the primary group and — when the container carries both polarities — for its `_helpful` twin, whose half of the budget is computed exactly as `AddGroups()` computes it. `AC.Relayout()` returns `false` when either setter is missing, rather than silently taking a path that cannot work.
- **Fix** — The engine lays out its own boxes but never sizes an aura button; that is done by our initializer, which only runs when a button is first pooled. Buttons already on screen therefore kept their old size through a `SetAuraGroupLayout`. `AC.Relayout()` now walks `buttonData`, and for every button parented to this container rewrites its wanted size, clears the `sizedTo` stamp and pushes it back through the existing `pending` / `AC.TrySize` retry. Buttons pooled later still inherit the new spec from the initializer, so both halves end up at the same size.
- **Note** — Clearing `sizedTo` matters as much as setting `wantSize`: `AC.TrySize()` treats a matching stamp as already applied, so a button that had landed at the old size would have skipped the resize entirely.
- **Removed** — The `RemoveAuraGroup` / `AddGroups` branch in `AC.Relayout()`. `AddGroups()` stays the single builder for `AC.Create()`.

#### Shared Aura Containers — Unbinding a Recycled Frame

- **Fix** — `AC.SetUnit(container, nil)` only forwarded the nil to the engine, which leaves the container enabled and still watching the unit it was last given. Party and raid cells, and nameplates, are recycled constantly, so a cell released from one unit went on displaying that unit's auras until it was handed another one. Unbinding now disables the container first, which is also what clears its engine-owned aura buttons, and then detaches the unit.
- **Changed** — `AC.SetUnit()` no longer refuses outright when the container has no `SetUnit` method: the unbind path only needs `SetEnabled`, and it still runs the pending-resize sweep and reports success. The bind path keeps its original contract and still returns whatever the assignment returned.

#### Aura Probes — Teardown

- **Fix** — `AC.DestroyAuraProbe()` detached the probe's unit but left its container enabled, so a discarded probe could keep being driven for the rest of the session. It is now disabled before the unit is detached, in the same order as a recycled cell.

#### Party & Raid Frames — Resurrection Colour

- **Fix** — A resurrected player could keep the grey death tint on their health bar until a `/reload`. `UNIT_HEALTH` can fire while `UnitIsDeadOrGhost()` still reports the pre-resurrection state, so the repaint it triggers reads the old state and stores the wrong colour — and nothing repaints afterwards, because health is no longer changing. `UNIT_FLAGS` and `UNIT_CONNECTION`, which carry the state transition itself, are now handled in `OnEvent` and repaint health and range on both party and raid frames.
- **Changed** — On both party and raid frames the two events sit in that module's `UNIT_EVENTS` table, so its gate registers and unregisters them along with the rest of the unit events. The raid side gained that gate in the same release, below.
- **Note** — `UNIT_CONNECTION` covers the same class of stale paint for a player dropping offline and coming back, which runs through the same colour path.

#### TomoScore — Keyboard Bindings

- **Fix** — The end-of-dungeon scoreboard could swallow movement keys. TomoScore is shown automatically at key completion and was made keyboard-enabled so that Escape would close it; when key propagation is unavailable or restricted at the instant the frame appears, the frame keeps the key press instead of passing it on and ZQSD/WASD stop reaching WorldFrame.
- **Changed** — The scoreboard is mouse-only again: `TomoMod_Utils.CloseOnEscape()` is no longer applied to it. The close button is unchanged, and every game binding keeps reaching WorldFrame while the scoreboard is on screen.
- **Note** — Escape no longer closes the scoreboard, and it is deliberately not routed through `UISpecialFrames` either — that path goes via `ToggleGameMenu`, whose protected `ClearTarget` / `SpellStopCasting` calls are refused once anything has tainted it. Other windows keep `CloseOnEscape`; only the frame that appears on its own, mid-keypress, gives it up.

#### Raid Frames — Unit Event Gating

- **Fix** — RaidFrame subscribed to its ten `UNIT_*` events from `RF.Initialize()` and never released them. Those events are global rather than per-frame, so outside a raid every party member, nameplate, boss and target token still woke `OnEvent` and paid for a `GetFrameForUnit()` lookup that could only fail. PartyFrame has had a gate of its own since its optimisation pass; the raid side never got one.
- **Changed** — The ten events move into a `UNIT_EVENTS` table behind `RF.SetUnitEventsEnabled()`, the mirror of `PF.SetUnitEventsEnabled()`, with the same `_unitEventsOn` short-circuit so a repeated call with an unchanged state costs nothing. `RF.Initialize()` now calls it with `IsInRaid()`, which leaves the block completely dormant when logging in outside a raid and subscribes immediately for a player who logs in already inside one.
- **Changed** — `RF.RefreshGroup()` re-evaluates the gate on every roster change, and does so *before* the `InCombatLockdown()` branch that returns early. Registering and unregistering events is not protected, so joining or leaving a raid mid-fight starts or stops the state updates at once instead of waiting for the pending refresh that runs on regen.
- **Note** — `GROUP_ROSTER_UPDATE` and the other non-unit events stay registered permanently — they are what drives the gate. Party and raid now carry the same shape, so the pair can no longer drift apart the way it just did.

#### Leveling Bar — Global Name Collision

- **Fix** — The leveling bar could not be switched on. `LevelingBar.lua` publishes its module table as the global `TomoMod_LevelingBar`, and `CreateBar()` then created the bar frame with that exact same name — `CreateFrame` writes a named frame straight into `_G`, so the first build of the bar replaced the module with the widget. Every public entry point vanished at that moment. The frame is now named `TomoMod_LevelingBarFrame`, and the module additionally publishes it as `LB.frame`.
- **Note** — Nothing announced the failure. The options panel writes `TomoModDB.levelingBar.enabled` *before* calling `TomoMod_LevelingBar.SetEnabled(v)`, so the setting flipped to enabled and the call that would have shown the bar died on a nil field. The first ever tick worked — no frame existed yet, so the table was still intact — which is why this only bit on the second toggle or after a `/reload` with the option already on.
- **Fix** — The same collision took down `ApplySettings()` (width and height sliders), `SetPosition()` (Reset position), `IsLocked()` / `ToggleLock()` (the `/tm sr` mover entry, whose `if ... .ToggleLock then` guard simply fell through) and the mover registration in `Movers.lua`.
- **Changed** — `ReputationBar.lua` anchored itself above the leveling bar by reading `_G["TomoMod_LevelingBar"]` and testing `GetObjectType() == "Frame"` — a guard written around the collision rather than against it. It now reads `TomoMod_LevelingBarFrame` and tests `IsShown()`, so it stops stacking itself above a bar that is enabled but hidden at max level.

#### Resource Bars — Death Knight Runes

- **Changed** — In bar mode the six rune segments used the shared unit frame texture (`TomoModDB.unitFrames.texture`, `tomoaniki` by default), which bakes a vertical gradient into the fill. That reads as a gloss highlight on a tall health bar and as muddied colour on a 12px rune. Runes now use a flat `WHITE8X8` fill through the new `TEXTURE_FLAT` constant, so `SetStatusBarColor` comes out exactly as configured.
- **Note** — Scoped to the runes. Every other resource bar keeps the shared texture, and icon mode is untouched — it draws from the `ClassPower` rune atlas and never went through this path.

#### AstralForge — Drag And Drop Anchoring

- **Changed** — Dropping an element in AstralForge now picks its anchor point for you, the same drag model Healer Studio already used. The anchor used to stay whatever it was set to while only the offsets moved, so dragging a piece into the top-left corner of a frame produced a `CENTER` anchor carrying a large negative offset — a layout that drifts the moment the frame is resized. The drop now chooses the nearest of the nine 3x3 anchors on the element's *current* target and writes it into both `point` and `relPoint`.
- **Changed** — `CanvasMT:_Measure()` takes a third `autoAnchor` argument, and `_DragUpdate()` and `_DragStop()` are the only callers that pass it — every other measurement keeps its previous behaviour. Because the update path re-anchors too, the element follows the cursor with the anchor it will actually be saved with, so what is on screen during the drag is what lands in the profile.
- **Note** — `relTo` is deliberately left alone. An element anchored to a sibling element rather than to the unit frame keeps that relationship instead of being flattened back onto the frame, which is what lets the element-to-element layouts introduced in 3.4.2 survive a nudge.
- **Note** — `PickAnchor()` compares screen pixels through `C.PointCoord`, not raw UI coordinates. The preview or one of its ancestors can be scaled, and comparing unscaled values under a scaled parent is the exact shape of the old minimap double-scale bug. A dead zone of a third of the frame on each axis keeps `CENTER` reachable, and any rect the game refuses to measure — a secret value on a live-data preview — falls back to `CENTER` rather than erroring.

## ####################################

## CHANGELOG 3.6.2 — Healer Studio: New Advanced HoT, Shield and Healer-Buff Indicators for Party and Raid Frames, Per-Spell Free Placement, Starter Presets & a LoadOnDemand Layout Editor + Mythic Hub: Great Vault Row Types from Blizzard's Official Enums, Delves Row Fix, Progress Reset Caused by a Forced Blizzard Refresh & Per-Row Activity Binding + Action Bars: Restored Secure Release Contract on Owned Buttons, Cooldown State Push-Through, Combat Input Latency, Coalesced Glow Reconciliation & Assisted Combat Event Load + Resource Bars: Full-Resource Glow and Supercharged Combo Point Toggles

#### Healer Studio — Advanced Healer Indicators (New)

- **New** — `Shared/HealerIndicators.lua` adds an opt-in replacement for the fixed HoT row on Party and Raid frames. Instead of one row of up to six generic HoT icons, a healer picks exactly which of their own auras to track and places each one freely on the unit cell, with its own anchor, offset and size. Party and Raid keep two independent profiles, so a dense raid grid can show three markers where the party cell shows six.
- **New** — Curated spell lists for the six healer classes — Priest, Druid, Paladin, Shaman, Monk and Evoker, 35 spells in total. Druid covers Rejuvenation, Regrowth, Lifebloom, Wild Growth, Germination, Spring Blossoms, Cultivation, Adaptive Swarm and Ironbark; Paladin covers both Beacons plus Bestow Faith, Glimmer of Light and Blessing of Summer; and so on for each class.
- **Note** — `AuraData.HEALER_HOTS` remains the source of truth. `GetSpellsForClass()` filters the presentation order against it and appends any spell ID present in `AuraData` but not yet listed here, so adding a spell in one place is enough.
- **Note** — `SPELL_CATEGORY` (`hot`, `shield`, `beacon`, `marker`, `external`) is a grouping for the studio list only and never gates behaviour. Spell names and icons come from the client, so nothing in the module duplicates a localised string that would rot at a patch.
- **Note** — Midnight-safe by construction: the module never reads aura data itself. Each selected spell owns one `CustomAuraContainerTemplate` group narrowed with `includeSpellIDs`, so the client decides whether the aura is present and drives the icon, the cooldown swipe and the stack count. `onlyMine` is set, so another healer's Rejuvenation never lights up your indicator.
- **New** — A **Only while in a healer specialization** switch, on by default. The advanced profile stays dormant on a Shadow Priest or a Feral Druid and the normal HoT row keeps running, so a single profile works across specs without being toggled by hand.

#### Healer Studio — The Editor

- **New** — `TomoMod_HealerStudio`, a LoadOnDemand sibling addon holding the editor. It is loaded on first use and costs nothing until then. Two buttons open it, one per profile, placed directly under the existing HoT settings: **Party Frames → Features → HoTs** and **Raid Frames → Features → HoTs**.
- **New** — The window shows the aura list for the selected class on one side and a live cell preview on the other. Icons are dragged straight onto the preview, and a size slider, an anchor dropdown and X/Y offset sliders cover the cases a drag cannot hit exactly. Every edit is written to the profile as it happens, with no Apply step and no reload.
- **New** — The preview is a magnified copy of the real cell, not a generic square: it reads the current Party or Raid `width` / `height` straight from the profile and scales it between 1.5x and 5x so small raid cells stay workable. Every offset is divided back by that scale before it is stored, so what the database holds is cell pixels and a layout does not shift when the preview scale changes.
- **New** — A dropped icon snaps to the nearest of the nine anchor points rather than keeping a free offset from wherever it landed. An icon dropped in a corner stays pinned to that corner when the cell is resized later, which a raw offset from `TOPLEFT` would not survive.
- **New** — **Starter preset** enables the first spells of the class at spread-out default anchors — four in Party, three in Raid — and **Reset this class** clears the whole class back to defaults. A per-spell **Reset position** returns a single icon to its default corner.
- **New** — Any of the six healer classes can be edited, not only the one being played, so a layout can be prepared before switching character.
- **Note** — Window chrome comes from `Forge.Studio`, every control from the shared widget kit and every string from `TomoMod_L`, so the studio inherits the look and the localisation of the rest of the configuration rather than carrying its own.
- **Note** — The drag surface is deliberately local rather than `Forge.Canvas`. The canvas is driven by ForgeRegistry element descriptors, and healer slots are per-spell rows in a saved table, not registry elements; folding them into the registry belongs to the AstralForge party/raid work.
- **Note** — Nothing in the studio reads an aura or touches a live cell. Edits land in `TomoModDB.healerStudio` and are pushed to the frames through `HI.Commit`, which is also why an edit can no longer reach the database without reaching the frames.
- **Note** — The editor refuses to open in combat rather than half-applying a layout, and enabling a profile that has no spell selected yet applies the starter preset automatically, so the switch never turns on an empty layout.

#### Party & Raid Frames — Legacy HoT Row Handover

- **Changed** — `PartyHoTs.UpdateUnit()` and `RaidAuras.UpdateHoTs()` now hand over to Healer Studio whenever its profile owns that cell, hiding the legacy container first. `HI.UpdateUnit()` returns `true` only when it took ownership, and hides its own indicators and returns `false` otherwise — so the handover is a single check per update rather than an `IsModeActive` test followed by a separate hide.
- **Fix** — Both handover branches deliberately run before the `f.hotContainer` guard. The legacy row is only built when `showHoTs` was on at frame creation, so a player who turned that row off entirely would have been unable to use the advanced indicators at all behind the previous early return.
- **Note** — Nothing changes for a profile that leaves Healer Studio off. Both `enabled` flags default to `false`, and the classic HoT row keeps its own size, count and options.

#### Healer Studio — Runtime

- **Changed** — The set of enabled spells for a mode is held in a revision-stamped active list: one record per mode holding parallel `ids` / `entries` / `set` arrays, rebuilt only when the revision or the player class changes and reused verbatim on every aura event in between. The arrays are `wipe`d rather than reallocated, and the `MODES` / `EMPTY` constants are hoisted, because the normalisation loop is reachable from the aura path on the first call after a profile swap — a table constructor there would generate garbage inside combat.
- **New** — `HI.Prewarm(f, mode)` builds every container a cell needs while out of combat, called from `RefreshAll()` whenever there is no combat lockdown. A first pull no longer pays for forty cells' worth of frame creation at once, and it avoids the engine refusing a `SetSize` while aura data is restricted.
- **New** — `HI.Commit(mode)` and `HI.Touch(mode)` split the two kinds of edit. A structural change (a spell enabled, a class reset) invalidates the cached list and refreshes; a geometry change only refreshes, since size, anchor and offset live in the very entry tables the cached list already holds by reference. The studio's sliders fire on every drag tick and use the cheap one.
- **Note** — Aura containers are created once per frame and spell, then reused. Deselecting a spell deactivates its container and unbinds its unit rather than destroying it, so toggling a checkbox during a fight does not churn frames.
- **Note** — A single watcher re-runs `RefreshAll()` on `PLAYER_REGEN_ENABLED`, `PLAYER_SPECIALIZATION_CHANGED`, `PLAYER_ENTERING_WORLD` and `GROUP_ROSTER_UPDATE` — no ticker and no polling. That covers a container creation refused while aura data was restricted, and re-evaluates the spec gate, so leaving a healer spec puts the classic row back without a reload.
- **Changed** — `HI.MIN_SIZE` and `HI.MAX_SIZE` (6 and 30 px) are published rather than private, so the studio's size slider cannot carry its own copy of the bounds the runtime clamps to. A profile with no size of its own inherits the frame type's existing HoT size, so a first run looks like what was already on screen.

#### Healer Studio — Settings Storage

- **New** — `healerStudio` is declared in `TomoMod_Defaults` (`Core/Database.lua`) with its `schemaVersion`, the `onlyHealerSpec` switch and the two mode tables, rather than being created only on demand. `Profiles.lua` sanitises an imported profile against the keys of `TomoMod_Defaults`, so a root key missing from that table is silently dropped on every import and export — the layouts would not have survived a profile round-trip.
- **Note** — Layouts are stored per class token and are empty by default, so declaring the key costs nothing for a player who never enables the feature, and an existing profile is untouched until the feature is switched on.

#### Forge Studio — Optional Open Argument

- **Changed** — `Forge.Studio.Launch()` accepts an optional `arg` in its options table and forwards it verbatim to the sub-addon's `Open()`. Studios that open on a single subject ignore it; Healer Studio uses it to pick which of its two profiles to edit. Loading the sibling addon on demand, self-healing a DISABLED one and reporting a locale-independent failure reason all stay in `Forge.Studio.Launch`, so `HI.OpenStudio()` is only the combat gate and the mode argument.

#### Healer Studio — Localisation

- **New** — 21 keys in all six locales (`btn_open_healerstudio`, `info_healerstudio` and the `hs_*` set) covering the options button, the studio window, its controls, its category labels and its combat refusal. Nothing in the feature carries a hard-coded user-facing string.

#### Packaging

- **New** — `.pkgmeta` moves `TomoMod/TomoMod_HealerStudio` out to a sibling `TomoMod_HealerStudio` folder at package time, the same arrangement as Cooldown Studio, Astral Forge and the options panel. The `.toc` declares `## LoadOnDemand: 1` and `## Dependencies: TomoMod`, and the studio degrades to a reported `loadError` if the widget kit or Forge is unavailable rather than erroring.

#### Mythic Hub — Great Vault Row Types

- **Fix** — The Great Vault preview no longer guesses which reward type belongs to which row. `DiscoverVaultTypes()` collected every `type` value returned by `C_WeeklyRewards.GetActivities()`, sorted them, and assumed the lowest was dungeons, the middle raids and the highest world content. Any week where one of the three did not appear — or where an auxiliary type showed up alongside them — shifted the whole mapping by one row. Row types are now taken straight from `Enum.WeeklyRewardChestThresholdType` (`Activities` / `MythicPlus`, `Raid`, `World`), with the previous 1 / 3 / 6 values kept only as fallbacks should the enum be unavailable.
- **Fix** — The **Delves** row, the one most often mis-detected by that heuristic, now binds to the correct reward type and shows its real progress instead of coming up empty or mirroring another row's activities.
- **Removed** — `DiscoverVaultTypes()` is gone. It ran on every vault refresh and could only ever re-derive what the client already publishes as an enum.

#### Mythic Hub — Great Vault Progress Values

- **Fix** — `RefreshVault()` no longer calls `WeeklyRewardsFrame:FullRefresh()` before reading the API. Blizzard's refresh path deliberately zeroes `activityInfo.progress` while a previous reward is still claimable, so forcing it made completed dungeons, raid bosses and delves display as `0`. MythicHub only ever reads from the `C_WeeklyRewards` API, so nothing in it required the Blizzard frame to be refreshed in the first place.

#### Mythic Hub — Great Vault Slot Binding

- **Changed** — Each row now queries `C_WeeklyRewards.GetActivities(rowDef.type)` for its own activities and sorts them by `index`, instead of bucketing one unfiltered `GetActivities()` call into a `byType[type][index]` table. The unfiltered call also returns auxiliary entries (`AlsoReceive`, `Concession`) that could land in a visible slot; the per-row query keeps the three displayed slots bound to Blizzard's actual row data.
- **Internal** — `hasGenerated` (`C_WeeklyRewards.HasGeneratedRewards()`) was read in `RefreshVault()` and never used afterwards. It has been removed along with the now-unused unfiltered activity list.

#### Resource Bars — Visual Toggles

- **New** — Two options under **Animations & Power Bar**: *Glow at maximum class resource* (`showFullResourceGlow`) and *Show supercharged combo points* (`showSuperchargedComboPoints`). Both default to `true`, so an existing profile looks exactly as it did.
- **Changed** — `UpdatePoints()` now keeps resource detection and the visual toggle apart. `isComboPointResource` still identifies a combo-point display on its own (`display == "points"` and `powerType == POWER_COMBO_POINTS`), while `chargeable` is that *and* the option. The texture branch stays gated on `isComboPointResource`, so switching the effect off actively repaints the normal art on point frames that already exist instead of leaving the last charged slot as it was.
- **Fix** — A running full-resource glow is now stopped rather than abandoned. The glow block gained an `elseif` that calls `PixelGlow_Stop` whenever the frame is glowing but should not be — the option turned off, or `glowOnMax` not set — and the class power frame stops its own glow before being hidden and rebuilt. Previously the glow could keep running on a frame that had already been discarded.
- **Internal** — `UpdatePoints()` reads `GetSettings()` once at the top of the call rather than re-deriving state further down.
- **Note** — The two labels are defined in all six locales.

#### Action Bars — Secure Release Contract on Owned Buttons

- **Fix** — Owned action buttons never carried `typerelease = "actionrelease"`, so the release half of every click was bound to nothing. With **Cast on key press** disabled the press is deliberately a no-op and the cast is supposed to happen on release, so those clicks did nothing at all; press/hold/release spells such as Evoker empowered casts could be started but never released. TomoMod builds its buttons from `ActionButtonTemplate,SecureActionButtonTemplate` and deliberately does not run `ActionBarActionButtonMixin:OnLoad()`, to keep addon-owned buttons out of Blizzard's native action-button registries — and that `OnLoad` is where Blizzard sets the attribute. `EnsureOwnedActionButton()` now sets it explicitly, right after `type = "action"`.
- **Fix** — `TUI_UpdateActionFlags`, the restricted snippet that runs on every action, form and page change, now restores `typerelease = "actionrelease"` whenever it is not already set. This also repairs a button coming back from the GSE forwarding path, which intentionally owns `typerelease` (`nil` or `"click"`) and previously left the normal action path with the GSE release contract until the next reload.
- **Unchanged** — `RegisterForClicks("AnyDown", "AnyUp")` stays as it is. TUI keybinds are routed through secure click bindings and need both phases, notably for press/hold/release spells.
- **Note** — The rewrite is conditional, so it costs a single attribute read per refresh and never re-writes an attribute that is already correct — the reason the previous code avoided touching it on every form/page swap.

#### Action Bars — Cooldown State Push-Through

- **Fix** — `GetActionCooldownState()` no longer memoizes an action's cooldown state across frames and events. During the server acknowledgement window, `ACTIONBAR_UPDATE_COOLDOWN` can arrive while the previously cached state no longer represents the action; reusing that state until an arbitrary TTL or `expiresAt` could hide a cooldown transition entirely, which is most noticeable on short cooldowns. Every call now reads the API.
- **Unchanged** — The same-batch caches inside `GetActionCooldownInfo()` and `GetActionCooldownDurationObject()` are kept, so duplicate queries for the same action within one `UpdateAllCooldowns()` pass are still coalesced. Event throttling is untouched.
- **Removed** — The cross-frame cache the fix makes dead: the five per-button weak tables (`_buttonCooldownAction`, `_buttonCooldownInfo`, `_buttonCooldownDurationObject`, `_buttonCooldownExpiresAt`, `_buttonCooldownInactiveAt`), the four TTL constants that drove them (`ACTIVE_COOLDOWN_CACHE_MAX_DURATION`, `ACTIVE_COOLDOWN_CACHE_LONG_REFRESH_TTL`, `ACTIVE_COOLDOWN_CACHE_FALLBACK_TTL`, `INACTIVE_COOLDOWN_CACHE_TTL`), `ResetButtonCooldownRuntimeCache()` with its call site and wipes, and `GetSafeCooldownTiming()`, whose only consumer was the cache expiry computation.
- **Removed** — Three debug counters that could only ever read `0` once the cache was gone: `AB_actionCooldownActiveHits`, `AB_actionCooldownInactiveSkips` and `AB_actionDurationActiveHits`. `AB_actionCooldownQueries`, `AB_actionCooldownHits`, `AB_actionDurationQueries` and `AB_actionDurationHits` remain, now reporting purely on the same-batch caches.

#### Action Bars — Combat Input Latency

- **Changed** — Button count refreshes (charges and aura stacks) are now coalesced during combat behind a new `AB_COUNT_UPDATE_INTERVAL_COMBAT` of 50 ms, tracked by `abUpdateFrame._lastCount`. `UNIT_AURA` and `SPELL_UPDATE_CHARGES` arrive in bursts on large Mythic+ pulls, and each one previously allowed a full active-button count pass on the next render frame. Counts are cosmetic, so the burst is collapsed instead. Out of combat the interval is `0` and the path stays completely unthrottled.
- **Fix** — A count pass deferred by that throttle no longer loses its work. When the window has not elapsed, `abUpdateFrame` re-arms itself with `_dirtyCounts` still set instead of consuming the flag, so the pending refresh runs on the next eligible frame rather than waiting for an unrelated event to schedule another one.

#### Action Bars — Overlay Glow Reconciliation

- **Changed** — The safety reconciliation that follows a spell-activation glow HIDE edge now runs through a dedicated `OnUpdate` frame with a 100 ms floor (`OVERLAY_GLOW_RECONCILE_INTERVAL`) instead of synchronously sweeping every visible action button for each event. Proc-heavy pulls can emit many HIDE edges close together, and that sweep is purely cosmetic cleanup.
- **Unchanged** — The P1 12.1 guarantee is preserved. The button belonging to the spell that emitted the edge is still updated immediately and synchronously, and a transformed button that has stopped mapping to that spell is still cleaned up by the reconciliation — now at most ten times per second instead of once per event.

#### Action Bars — Assisted Combat Event Load

- **Removed** — The `hooksecurefunc` on `AssistedCombatManager.UpdateAllAssistedHighlightFramesForSpell` is gone. Blizzard can call that method at rotation-evaluation cadence in combat, and every call scheduled a full owned-button visual pass. Its override-spell resolution and its `ns.Keybinds.UpdateAllRotationHelpers` call have moved into the `AssistedCombatManager.OnAssistedHighlightSpellChange` callback, which only fires when the highlighted spell actually changes.
- **Removed** — Both `ScheduleABVisualUpdate(false, true)` calls on the Assisted Combat path. A change of suggested spell is not a reason to invalidate every owned action button; rotation-frame and highlight work is now targeted, and unrelated buttons keep being updated by the normal action and cooldown events.
- **Changed** — `UpdateAllAssistedCombatRotation()` now prefers `C_ActionBar.FindAssistedCombatActionButtons()`, the authoritative Assisted Combat slot API. The previous route — `C_AssistedCombat.GetNextCastSpell()` followed by `C_ActionBar.FindSpellActionButtons()` — searched by the currently suggested spell, so it could touch unrelated normal spell buttons every time the suggestion changed. It is kept only as a fallback for clients that do not expose the slot API.
- **Fix** — `OnAssistedHighlightSpellChange` no longer returns early when the client reports no next spell. Losing the suggestion is itself a state change, and skipping it left the previous highlight on screen.
- **New** — A callback on `AssistedCombatManager.OnSetUseAssistedHighlight` refreshes the assisted highlights when the assisted-highlight CVar is toggled, so turning the feature off or back on now applies without a reload.
- **Changed** — The owned Assisted Combat rotation frame's `OnUpdate` treats its 0.2 s default as a floor rather than a starting point: `AssistedCombatManager:GetUpdateRate()` is adopted only when it is *slower*. That handler touches exactly one button and never runs faster than 5 Hz.

## ####################################

## CHANGELOG 3.6.1 — Action Bars: Assisted Combat Bridge, Input Latency Fix, Combat-Safe Paging, Flyout Taint Removal & Movable Leave Vehicle + Minimap Collector Row Wrapping

#### Action Bars — Assisted Combat Secure Slot Bridge

- **Fix** — Blizzard's Assisted Combat rotation frame no longer freezes or fails to appear on TomoMod-owned buttons. Its native `UpdateState()`/`OnUpdate()` logic dereferenced the button's Lua-side `action` field, which TomoMod intentionally leaves unsynced; every assisted-combat lookup is now bridged through the button's real secure action slot instead.

#### Action Bars — Input Latency

- **Fix** — TomoMod's "Cast on key press" setting is now kept in lockstep with Blizzard's `ActionButtonUseKeyDown` CVar before any owned button or override CLICK binding is built. Previously, a secure CLICK binding could follow Blizzard's account-wide press/release policy while the button attribute said otherwise, causing the first key press after login to be silently swallowed.

#### Action Bars — Combat-Safe Paging & Bindings

- **Removed** — The `inInitSafeWindow` escape hatch has been removed. It disabled every `InCombatLockdown()` guard in the ActionBars module for the whole `PLAYER_ENTERING_WORLD` handler, which meant the one case it was meant to help — a `/reload` taken mid-combat — was exactly the case where the lockdown was real and protected actions could still be blocked.
- **Changed** — Override bar bindings deferred by combat now replay reliably through the existing `pendingBindings` flag on `PLAYER_REGEN_ENABLED`, instead of relying on the removed safe window.

#### Action Bars — World Map Strata Fix

- **Fix** — Bar 1, Pet and Stance containers and buttons no longer render above full-screen Blizzard panels such as the World Map. They previously used `HIGH` frame strata to stay above alpha-suppressed native bars; they now stay on `MEDIUM` strata and rely on higher frame levels instead, which is enough to remain on top of the native surfaces without floating above other UI.

#### Action Bars — Spell Flyout Taint Removal

- **Fix** — Spell flyouts (e.g. Mage Portal/Teleport) no longer silently fail to cast after opening. Resizing native flyout buttons and calling the flyout's own `Layout()` from addon code tainted the protected `SpellFlyout` and its buttons; TomoMod no longer resizes or re-skins native flyout buttons, leaving Blizzard fully in control of their secure attributes.
- **Fix** — Native flyout popup buttons cast through Blizzard's own protected `CastSpellByID`/`CastSpellByName` calls, and even cosmetic writes to those buttons could contaminate that path into `ADDON_ACTION_FORBIDDEN`. TomoMod's flyout skinning no longer hooks or writes to native `SpellFlyout` buttons at all, trading the cosmetic skin for a guaranteed cast.
- **Fix** — Owned action buttons now refresh their flyout through the new `ActionBarsOwned.RefreshOwnedButtonFlyout()`, which runs Blizzard's own `BaseActionButtonMixin.UpdateFlyout` inside `securecallfunction`. An addon-originated `:UpdateFlyout()` call could otherwise carry TomoMod's taint into `BaseActionButtonMixin:SetPopup(SpellFlyout)`, and from there into the popup's protected cast path. The initial visual pass in `PrimeStandardOwnedButtonVisuals()` calls `ActionButton_Update` the same way, since it reaches `UpdateFlyout` too.
- **Removed** — The addon-owned `HasPopup`/`SetPopup`/`GetPopupDirection`/`SetPopupDirection`/`ClearPopup` replacements installed on every owned button have been removed. `ActionButtonTemplate` already inherits Blizzard's `FlyoutButtonTemplate`, and `SpellFlyout:Toggle()` calls the source button's popup API before it populates the native popup buttons — so replacing that API widened the taint path all the way to `CastSpellByID`. The bare `ActionButtonTemplate` + `SecureActionButtonTemplate` combination TomoMod uses is explicitly supported by `BaseActionButtonMixin.UpdateFlyout`.
- **Fix** — Spell flyouts on Bar 6 (MultiBar5, action slots 145-156) no longer risk becoming forbidden to cast. Blizzard's native `SpellFlyout:Toggle()` could still pick up TomoMod's taint specifically when opened from that bar, contaminating `SpellFlyoutPopupButton*.spellID`/`spellName` and turning the follow-up `CastSpellByID` into a protected-forbidden error. Bar 6 is now quarantined onto TomoMod's own secure flyout via `ShouldUseOwnedFlyoutForBar()`; every other bar keeps using Blizzard's native flyout untouched.
- **Fix** — TomoMod's owned flyout buttons now correctly respond to an assigned keybind press, not only a mouse click. The secure `OnClick` handler only checked for `button == "Keybind"`, which does not match the actual `button` value WoW passes on a keybind-triggered click.
- **Changed** — The owned flyout no longer refreshes slot icons/textures through `CallMethod()` calls from inside its restricted secure snippet; visuals are instead refreshed from the flyout's own insecure `OnShow`, keeping the secure click path minimal.
- **Fix** — TomoMod's owned flyout spell discovery now also inspects the actual action slots on the quarantined bar (via `GetActionInfo`) instead of relying solely on spellbook enumeration, so a flyout placed there — including ones not covered by the currently active spellbook branch for the player's class/spec — always gets correct known/unknown slot icons.

#### Action Bars — Leave Vehicle Mover & Visibility

- **New** — Leave Vehicle has its own holder and mover (`TUI_leaveVehicleHolder` / `TUI_leaveVehicleMover`), shown and hidden alongside the Extra Action and Zone Ability movers. It can be dragged anywhere on screen instead of being hard-anchored above Bar 1, and its position is persisted in `profile.frameAnchoring` like the other movers. Until it is dragged, it still falls back to its previous default position just above TomoMod Bar 1 — or to the screen bottom when Bar 1 does not exist.
- **Changed** — `CreateExtraButtonHolder()` no longer requires an `actionBars.bars` entry for Leave Vehicle, which has none; the anchor resolution for it is applied locally because the generic `TUI_ApplyFrameAnchor` resolver predates the new holder.
- **Changed** — The combat gate in `ApplyExtraButtonFrameAnchor()` now covers Leave Vehicle as well as Extra Action. Both host secure descendants, so neither holder is moved during lockdown; the move replays through the existing `pendingExtraButtonRefresh` flag on `PLAYER_REGEN_ENABLED`. Profile and layout changes reapply the saved position on the next Leave Vehicle refresh.
- **Changed** — The Leave Vehicle proxy's visibility state driver moved from `[vehicleui]` to `[canexitvehicle]`, so the button follows whether the vehicle can actually be left rather than whether a vehicle UI happens to be displayed.
- **Fix** — Blizzard's native Leave Vehicle button is now suppressed only when TomoMod's secure `leavevehicle` proxy is expected to be usable — `CanExitVehicle()` is true and the player is not on a taxi. Previously the native button could be hidden in states where the proxy would not work, leaving no way to exit; the native control is now kept as the fail-safe, including for early taxi landings.

#### Objective Tracker — Combat Deferral

- **Fix** — Quest blocks skipped during combat (because their secure objective buttons make `Hide`/`SetParent`/`SetPoint` protected) are no longer left half laid-out until an unrelated quest event happens to fire later. Skipped layout passes are now tracked and replayed automatically on `PLAYER_REGEN_ENABLED`, and frames pending correct placement are alpha-suppressed in the meantime instead of visibly overlapping.

#### Minimap — Tracking Panel

- **Fix** — The Tracking panel listed **Banker** twice. The panel builds its rows straight from `C_Minimap.GetTrackingInfo`, and the client returns more than one tracking filter under the same localised name, so two rows were rendered that nothing on screen could tell apart. Filters sharing a name are now merged into one row: it reads as enabled as soon as any of them is active, and a click sets all of them to the opposite state.

#### Minimap — Addon Button Collector

- **Fix** — The addon-button collector no longer drops the buttons it has already gathered every time it rescans. Captured buttons are reparented into the collector panel, so the rescan (which only walks `Minimap`, `MinimapBackdrop` and `MinimapCluster`) could never find them again — and since a rescan runs on every `ADDON_LOADED`, the layout restarted its numbering at 1 for buttons collected later. Those buttons were placed **on top of** the first row instead of opening a new one, and the panel resized itself around that last batch only. Already-collected buttons are now kept and new ones are appended, so the grid wraps onto as many rows as the column count requires. Buttons an addon has taken back are detected by their parent and become collectable again.
- **Changed** — Opening the collector always rescans now, instead of only when the internal list was empty, so buttons registered since the last scan are picked up on open.

#### Action Bars — TomoMod-Owned Spell Flyout on Every Standard Bar

4.0.0 quarantined bar 6 onto TomoMod's own secure flyout because Blizzard's native `SpellFlyout:Toggle()` could run in a TomoMod-attributed path there and taint `SpellFlyoutPopupButton*.spellID` / `.spellName`, which makes a later protected `CastSpellByID()` forbidden. In-game validation on Midnight 12.1 showed the quarantine had been drawn too narrowly: the same failure reproduces on the other TomoMod-owned bars, while Portal/Teleport opens and casts cleanly through the owned route on every one of them.

- **Changed** — `OWNED_FLYOUT_BAR_KEYS` now covers `bar1` through `bar8`, so all eight TomoMod standard action bars route their flyouts through `TUI_SpellFlyout` instead of Blizzard's native popup. Pet and stance bars are untouched and keep their native paths.
- **Changed** — `USE_OWNED_FLYOUT` deliberately stays `false`. It is the global override; the per-bar table is what does the routing, so a single bar can still be handed back to Blizzard without disturbing the other seven, and `ShouldUseOwnedFlyoutForBar()` remains the one place that answers the question.
- **Changed** — Flyout ID discovery in `CollectOwnedFlyoutIDs()` walks the same widened bar set. That matters for portal and trap actions which the enumerated spellbook branch does not represent on every class and spec state.
- **Fix** — A flyout button on bar 1 could open the previous page's flyout after a paging swap during combat. The secure `OnClick` snippet resolved the flyout from the cached `qui-flyout-id` attribute, which is written outside of lockdown and therefore still described the page the bar had left; it now reads the live flyout from `GetActionInfo(action)` on the slot the button is currently showing, and falls back to the cached attribute only when the slot does not report one.

#### Micro Bar Module — Blizzard Keeps Its Micro Menu Geometry

The replacement micro bar used to mute Blizzard's micro menu by fading its *containers* — `MicroMenu`, `MicroMenuContainer` and `MicroButtonAndBagsBar` — to alpha 0 and disabling their mouse. Those frames are Edit Mode systems on Midnight 12.1, and `MicroMenuMixin:GetEdgeButton()` compares the centers of its edge children while Edit Mode is recomputing layouts. A container TomoMod had altered could hand that comparison nil geometry, and the failure surfaced later, somewhere else in Blizzard's own pass. The rule is now absolute: TomoMod never changes the alpha, mouse state, parent, anchors or scale of those three frames.

- **Fix** — `MuteNative()` no longer walks a container list at all; the `NATIVE_CONTAINERS` table is gone. It mutes only the individual entries of `NATIVE_BUTTONS`, which are what the player actually sees and what the secure forwarders click. The native layout stays geometrically valid for Edit Mode whether the TomoMod bar is on or off.
- **Changed** — `QueueStatusButton` is no longer reparented to `UIParent`. The detach existed solely to save the Group Finder eye from the container fade; with the container untouched the eye survives on its own, so `lfgEyeOriginalParent` and the whole detach/reattach path are gone. `ApplyLFGEye()` now applies scale, alpha and mouse unconditionally, sets `lfgEyeManaged` from the same condition that decides custom placement, and hands positioning back to Blizzard through `QueueStatusButton:UpdatePosition()` when TomoMod is not managing it. `TomoMod_FrameAnchors` remains the only owner of the eye's placement.
- **Changed** — The Edit Mode stand-down is no longer a workaround for TomoMod's own container writes, because there are none left. While the Edit Mode window is open the native child buttons are simply unmuted so Blizzard's own preview of its micro menu is complete.
- **New** — The micro bar subscribes to `UNIT_PORTRAIT_UPDATE`, filtered to `player` through `RegisterUnitEvent` where the client exposes it, and re-reads the character button's art through `ApplyArt()`. The forwarder copies its icon from the native button at runtime, so a portrait that changed after the bar was built — a barber visit, a level-up, a zone-in that arrives before the portrait does — used to keep the old face until the next rebuild. The handler returns before the generic refresh path, so a portrait update never triggers a full bar rebuild.

#### Micro Bar — The Real Game Menu Button, a Live Character Portrait and a Reversible Click-Through

- **Fix** — The Game Menu button is on the micro bar again. Midnight added `HousingMicroButton` to the micro menu, which pushed `MainMenuMicroButton` past the end of a row sized for the previous icon count and silently dropped the one button that opens logout and settings. It is now ordered ahead of `StoreMicroButton` in `MICRO_BUTTON_NAMES`, so a truncated layout loses the shop rather than the game menu.
- **Fix** — The red "?" that appeared where the game menu should have been was `HelpMicroButton`, and it opened Blizzard's help browser. `LayoutNativeButtons()` used to anchor Help onto `StoreMicroButton` and swap their visibility, producing a button that looked like the one players were reaching for and did something else entirely. TomoMod no longer reparents, anchors, shows or hides `HelpMicroButton` at all — it stays under Blizzard ownership, and only the separate support-ticket indicator is still positioned, through `AnchorHelpTicketButton()`.
- **Fix** — The character portrait on `CharacterMicroButton` no longer stays blank or stale once TomoMod has reparented the micro buttons. `RefreshCharacterMicroPortrait()` runs the button's own `UpdateMicroButton` through `securecallfunction`, falling back to `pcall` on a client that does not expose it, then re-applies `SetPortraitTexture(..., "player")`. It runs when the bar is built and again on every reclaim pass.
- **Fix** — Turning the micro bar's **Click-through** option off restores mouse input to its buttons. The build path only ever called `EnableMouse(false)` when the option was on and had no path back, so a bar made click-through stayed inert until the next reload; both the build and the reclaim path now reconcile unconditionally with `EnableMouse(not clickthrough)`.
- **Changed** — The mouse-state reconcile and the portrait refresh moved out of the `needsReparent` branch of `ReclaimMicroButtons()` and now run on every pass. Blizzard can repaint or re-enable those buttons without moving them, so a pass that found nothing to reparent used to return with both left wrong.

#### Action Bars — Native Micro Menu Fade (No Container Ownership)

The ActionBars fade/build system used to treat `microbar` like any other owned bar: it created a TomoMod container for it, reparented it under that container's anchor key, and ran it through the same reclaim/layout hooks as Bar 1-8. On Midnight 12.1 that container ownership is unnecessary risk for a frame Edit Mode also lays out — the fix below removes it entirely and leaves the mouseover fade as the only thing TomoMod still does to it.

- **Changed** — `BuildBar("microbar")` now returns immediately: no container is created, `ActionBarsOwned.containers.microbar` and `ActionBarsOwned.nativeButtons.microbar` are cleared, and only `SetupBarMouseover()` runs. The legacy reparent/layout/hook branch further down `BuildBar()` is unreachable for this bar and is left in place only as dead code for the next cleanup pass.
- **Changed** — `GetContainerAnchorKey()` no longer maps `microbar` to `microMenu`, since no container is created for it to anchor.
- **Changed** — `SetBarAlpha("microbar", alpha)` now only calls `SetAlpha()` on the native `MicroMenuContainer` frame and updates the fade state's `currentAlpha`. It no longer walks or mutates individual buttons, textures, parents, anchors or scale — that responsibility stays with the separate Micro Bar module described above.
- **Changed** — `TUI_RefreshActionBarFade()` now branches on `microbar`: it refreshes the native fade state and calls `SetupBarMouseover()` directly instead of routing through the owned-bar fade helpers (`GetOwnedBarFadeState`, `CancelOwnedBarFadeTimers`, `SetupOwnedBarMouseover`), which assume an owned container that no longer exists for this bar.
- **Removed** — The `microMenu` entries in the Edit Mode hidden-handles map, the Edit Mode element list/DB key map, and the Edit Mode Blizzard-frame lookup table. Micro Menu visibility and positioning are Blizzard's Edit Mode concerns now that TomoMod does not own a container for it.
- **Changed** — The Fade options panel's bar list now labels this entry "Micro menu Blizzard (survol)" and adds an explanatory line above the bar checkboxes: the Micro Menu stays entirely Blizzard-owned, and TomoMod only changes its alpha to show it on mouseover — no move, resize, skin or reparent.

#### Micro Menu — Legacy Micro Bar Module Removed, Native Ownership Consolidated

The two Micro Menu code paths above still left two different systems touching `microbar`: the ActionBars fade helper faded the native `MicroMenuContainer`, and the standalone Micro Bar module (`Modules/QOL/MicroMenu/MicroBar.lua`) built its own forwarder bar next to it. Running both meant a profile with the Micro Bar enabled fought the ActionBars fade for the same frame's mouseover state, and the LFG eye (`QueueStatusButton`) still rode along with whichever container happened to be faded to 0, appearing and disappearing with either module's mouseover instead of staying under its own control.

- **Removed** — `Modules/QOL/MicroMenu/MicroBar.lua` is no longer included by `QOL.xml` and its `Initialize()` is no longer called from `Core/Init.lua`; the file itself is left in place but unloaded, since nothing else in the addon references `TomoMod_MicroBar` anymore.
- **Changed** — `Core/Init.lua` now force-disables `actionBars.bars.microbar.enabled`/`.fadeEnabled` on every existing profile at load, and `TomoMod_Defaults.actionBars.bars.microbar` defaults to `enabled = false, fadeEnabled = false` for new profiles, so upgrading does not leave the old ActionBars-owned fade fighting the module below for the same frame.
- **Removed** — The `microbar` entry is gone from the Fade tab's targeted-bar list in `ActionBars.lua`; there is nothing left for it to control once the ActionBars-owned fade path is disabled.
- **Changed** — `BagMicroMenu.lua` now targets the native `MicroMenu` frame directly (instead of `MicroMenu or MicroMenuContainer`) for its show/hover fade, and the `TomoMod_MicroBar.OwnsNativeMenu()` stand-down check it used to defer to is gone along with the module.
- **Fix** — The Group Finder eye (`QueueStatusButton`) no longer disappears when the Micro Menu fades out on mouse-leave. It previously lived inside whichever container got muted to alpha 0; a new `ApplyLFGEye()` in `BagMicroMenu.lua` sets its scale, alpha and mouse state independently of the Micro Menu's own fade, driven by a dedicated ON/OFF toggle and size slider.
- **New** — `BagMicroMenu` now refreshes on `PLAYER_ENTERING_WORLD`, `LFG_UPDATE`, `LFG_QUEUE_STATUS_UPDATE` and `UPDATE_BATTLEFIELD_STATUS`, in addition to the existing one-second startup delay, so the eye's state stays correct across zoning and queue pops instead of only being set once at login.
- **Changed** — The QOL options panel's Bag & Micro Menu tab no longer builds the full Micro Bar section (button ordering, orientation, per-line count, icon size, spacing, scale, alpha, fade mode, colors, glow states, keybind text and position controls). In its place is a single "Group Finder eye" section with the same ON/OFF toggle and size slider, now wired to `TomoMod_BagMicroMenu.SetLFGEyeEnabled`/`SetLFGEyeScale`.

#### Validation

- **Tested** — Assisted Combat rotation display, key-down/key-up casting, override bindings across a combat `/reload`, Bar 1/Pet/Stance visibility next to the World Map, Mage/Hunter spell flyouts, Objective Tracker layout during and after combat, and Micro Menu mouseover fade/geometry under Edit Mode were validated in game.
- **Tested** — Group Finder eye visibility while the Micro Menu fades on mouseover, and across `LFG_UPDATE`/`LFG_QUEUE_STATUS_UPDATE`/`UPDATE_BATTLEFIELD_STATUS` events (queue pops, dungeon/battleground finder updates), were validated in game.

## ####################################

## CHANGELOG 3.6.0 — Action Bars: Zero-Taint Native Separation, Secure Stance/Pet/Possession & Complete Blizzard Visual Cleanup

#### Action Bars — Zero-Taint Native Separation

- **Changed** — TomoMod's standard action buttons are now fully separated from Blizzard's native ActionBar broadcaster path. Addon-owned buttons no longer register as native Blizzard action buttons, preventing the controller from later executing protected native updates through TomoMod-owned state.
- **Fix** — Removed the remaining global ActionBar broadcaster mutations, native cooldown wrappers and protected-frame ownership tricks that could surface later as `ADDON_ACTION_BLOCKED`, `SetShownBase`, `SetScaleBase`, `SetAttribute` or secret-value cooldown errors.
- **Changed** — Blizzard keeps ownership of `MainActionBar`, `StanceBar`, `PetActionBar`, `PossessActionBar`, Override/Vehicle bars and their secure state machinery. TomoMod now limits itself to independent secure buttons, read-only state observation and narrowly scoped visual masking.

#### Action Bars — Blizzard Standard Bar Visual Suppression

- **Fix** — Blizzard's standard action bars can remain fully alive for paging and secure controller updates while their native presentation is visually suppressed, leaving only TomoMod's action bars on screen.
- **Fix** — The suppression path no longer snapshots or writes the current action slot back into TomoMod buttons. Action Bar 1 reads its secure `action` attribute directly, so form, vehicle, possess and override paging remain live in combat.
- **Fix** — Empty-slot presentation now refreshes from the current secure slot, restoring the **Hide Empty Buttons** option without freezing icons or paging.

#### Action Bars — Secure Stance, Pet & Possession

- **Fix** — TomoMod Stance buttons use independent `SecureActionButtonTemplate` spell actions and keep Blizzard's secure click handler intact. Druid forms, Paladin auras and Warrior stances remain clickable without depending on Blizzard's visible StanceBar.
- **Fix** — TomoMod Pet buttons now use independent secure pet actions instead of cloned `PetActionButtonTemplate` behavior. Left-click pet commands and abilities remain functional, while right-click autocast toggles continue to work where supported.
- **Fix** — Possession and vehicle states continue through Action Bar 1's secure paging instead of requiring TomoMod to manipulate Blizzard's PossessActionBar.
- **Fix** — Blizzard's Stance, Pet and Possess bars remain functionally active but their native textures, font strings, cooldown swipes, pet autocast overlays, checked borders and flash effects are masked. This removes duplicate Blizzard visuals without touching the secure parent bars or their gameplay state.

#### Action Bars — Druid Forms & Secure Paging

- **Fix** — Action Bar 1 now changes correctly between Human, Cat and Bear forms in and out of combat without stale icons, frozen action slots or protected-action errors.
- **Changed** — The current action slot is treated as secure runtime state and is read directly from the button attribute instead of being copied into a Lua-side `button.action` snapshot.
- **Fix** — Vehicle, Override and Possess states remain authoritative, while configured modifier, form and target paging continue to coexist with the secure state driver.

#### Action Bars — Extra Action, Zone Ability & Leave Vehicle

- **Fix** — Extra Action uses a TomoMod-owned secure presentation with its own GCD, cooldown and charge display while Blizzard's native button remains available as the gameplay authority. Its invisible native hitbox no longer steals mouse clicks or tooltips.
- **Fix** — Zone Ability keeps live quest/state icons, GCD and charge recovery, disappears when the ability is no longer active, and preserves Blizzard's native click semantics for abilities that require them.
- **Fix** — Leave Vehicle remains a secure `leavevehicle` action with the same TomoMod skin as the rest of the ActionBars, while Blizzard taxi behavior remains available when needed.
- **Changed** — Extra Action, Zone Ability and Leave Vehicle share the regular TomoMod `SkinButton()` pipeline instead of temporary diagnostic styling.

#### Action Bars — Cooldowns, GCD & Native Visual Cleanup

- **Fix** — TomoMod-owned special buttons use duration-object cooldown updates where required, avoiding reads of secret numeric cooldown values from Blizzard-owned cooldown widgets.
- **Fix** — Residual Blizzard GCD swipes on Stance/Aura/Posture buttons are now visually masked without calling `SetCooldown()` or modifying the protected buttons themselves.
- **Fix** — Residual PetBar visuals are fully cleaned up, including autocast overlays, checked-state borders and flash effects, while Blizzard's pet state remains intact underneath.

#### Action Bars — Native Spell Flyouts

- **Fix** — Spell flyouts now open correctly again from TomoMod action buttons, including Mage portal/teleport flyouts and Hunter trap flyouts. TomoMod keeps the visual styling while Blizzard handles the native secure flyout behavior.

#### First-Run Installer — LoadOnDemand & Safety Guards

- **Fix** — The first-run installer is now bootstrapped from the core addon instead of depending on the LoadOnDemand options addon already being open. Fresh installs and `/tm install` can therefore launch the installer reliably without first opening the configuration panel.
- **Fix** — The installer waits until cinematics, movies and combat are finished before loading and appearing. A new character can complete or skip the intro normally without an unseen installer intercepting input in the background. Manual installer requests made while blocked are deferred and resume automatically when it is safe.

#### Midnight Role Data — Shared Secret-Safe Handling

- **Fix** — Group-role reads now use one shared safe path across Party Frames, Raid Frames, UnitFrames threat coloring, Nameplates, TomoScore, Chat role icons and Tooltip role icons. When Midnight temporarily restricts role data, TomoMod now treats it as unavailable instead of allowing a secret value to reach comparisons, sorting or table lookups.

#### Mythic+ & Profiles — Combat Safety

- **Fix** — MythicHub no longer builds, refreshes, shows or hides its teleport controls during combat. Requests made in combat are remembered and replayed automatically after combat ends.
- **Fix** — `/tm score`, `/tm keys` and `/tm score last` now use TomoScore's combat-safe display path, preserving the requested data and opening the scoreboard automatically after combat when necessary.
- **Fix** — Profile Import and Export popups now use TomoMod's shared Escape-key handling, preventing protected keyboard-input changes from being attempted while in combat.

#### Validation

- **Tested** — Human/Cat/Bear form paging, Stance, Pet and Possession controls, standard action bars, Extra Action, Zone Ability, Leave Vehicle, GCD/charges, mouse clicks and keyboard activation were validated in game with no new ActionBar taint errors.
- **Tested** — The final native visual masking leaves Blizzard's secure bars operational while removing their duplicate presentation, including Pet checked/autocast states and Stance GCD remnants.
- **Tested** — Mage/Hunter spell flyouts, first-run installer launch after reload, MythicHub, `/tm score`, `/tm keys`, `/tm score last` and Profile Import/Export were validated in game after the 3.6.0 safety pass.
- **Internal** — 3.6.0 is the new clean ActionBars baseline. The validated zero-touch boundaries around Blizzard-owned secure frames are documented in code and should not be replaced by `Hide()`, `SetParent()`, event unregistering or protected attribute writes.

## ####################################

## CHANGELOG 3.5.9 — Action Bars: Secure Visibility, Special Buttons, Smarter Paging & Taint Safety

#### Action Bars — Secure Visibility Engine

- **New** — Every TomoMod action bar can now use a secure visibility rule that continues to work in combat. Available modes include Always, In Combat, Out of Combat, Solo, Party Only, Raid Only, Any Instance, Mounted, Has Target, Hostile Target, Hidden and a custom secure condition.
- **New** — Visibility controls live in TomoMod_Options while the secure runtime remains in the core ActionBars module, keeping configuration code separate from combat-critical execution.
- **Fix** — Hidden bars no longer rely on ordinary Lua `Show()` / `Hide()` calls during combat. Visibility changes are driven by secure state drivers and combat-time edits are safely deferred until combat ends.

#### Action Bars — Cooldowns & GCD Presentation

- **Changed** — The GCD swipe remains visible on every action actually affected by the global cooldown, but pure GCDs no longer display distracting fractional countdown text.
- **Changed** — Numeric cooldown text now tracks the action's real cooldown independently of the GCD, so long cooldowns and charge recovery remain readable without turning every GCD into a `0.x` timer.

#### Action Bars — Edit Mode & Blizzard Frame Safety

- **Fix** — Opening Blizzard Edit Mode no longer triggers protected `TargetUnit()` / `FocusUnit()` errors or secret-value failures while Blizzard refreshes Compact Party Frames.
- **Changed** — Player/Target/Focus/Pet suppression now follows the safer modern oUF roleset approach instead of reparenting Blizzard frames or forcing them hidden from secure callbacks.
- **Fix** — `StanceBar`, `PetActionBar` and `PossessActionBar` remain Blizzard-owned for taint safety while their native presentation is filtered with the Midnight `alwaysBlocked` roleset. TomoMod's own Pet/Stance bars stay visible without duplicate Blizzard bars.
- **Fix** — Blizzard Edit Mode no longer forces Pet/Stance/Possess preview bars back on when TomoMod owns their replacement UI.

#### Action Bars — Dormancy & Performance

- **New** — Bars hidden by the Secure Visibility Engine now enter a dormant visual state. Cooldown, range, usability, glow and Pet/Stance visual work is suspended while the bar is structurally hidden.
- **Changed** — Secure keybinds remain active while a bar is dormant. When the bar becomes visible again, TomoMod performs an immediate full visual refresh so icons, cooldowns, charges, range states and glows are current on the first frame.

#### Action Bars — Native Glow Engine

- **New** — TomoMod now ships its own native glow engine instead of LibCustomGlow-1.0. Pixel-style, action-button, auto-cast and proc effects are handled by TomoMod with a shared animation driver and Blizzard animation groups where appropriate.
- **Fix** — Removed the obsolete `AnimateTexCoords()` dependency that could crash proc animations on Midnight 12.1.
- **Fix** — Conditional procs such as Monk Touch of Death now refresh from Blizzard's action-usability notifications and target changes rather than depending only on traditional proc overlay events.
- **Fix** — Usability and mana state now take priority over range coloring. An unusable conditional ability stays dimmed instead of incorrectly turning red simply because its range state changed or no valid target existed.

#### Action Bars — Secure Paging

- **New** — Action Bar 1 can securely page from Alt, Shift or Ctrl modifiers and from Friendly or Hostile Target conditions, with selectable destinations from Action Bar 1 through Action Bar 8.
- **New** — Automatic form/stance paging and automatic Skyriding paging can each be disabled independently.
- **Changed** — Paging priority has been rebuilt so Vehicle/Override/Possess states remain authoritative, while manual page changes and configured modifier pages are no longer swallowed by form or Skyriding states.
- **Fix** — Paging configuration changed during combat is deferred and rebuilt safely after combat rather than attempting to replace secure drivers while protected.

#### Action Bars — Forms & Special Ability Buttons

- **Fix** — Druid form changes in combat are now clean and reliable. Switching between Human, Cat and Bear no longer triggers the protected-action or secret cooldown errors that could flood BugSack.
- **Fix** — Extra Action, Zone Ability and Leave Vehicle now keep Blizzard's secure gameplay behavior while TomoMod provides the visible controls, so quest abilities, vehicles and special encounters continue to work without compromising combat safety.
- **Fix** — Zone Ability buttons now update their icon, GCD and charge recovery live. Stateful quest abilities correctly change appearance after use, and expired abilities disappear after leaving their dungeon, quest area or scenario.
- **Fix** — Extra Action now mirrors its GCD and charge recovery on the TomoMod-owned skin using secret-safe duration objects, without reading or modifying Blizzard's native cooldown widget.
- **Fix** — Invisible Blizzard Extra Action buttons can no longer sit over a TomoMod Zone Ability and steal mouse clicks or tooltips.
- **Changed** — Extra Action, Zone Ability and Leave Vehicle now use the exact same `SkinButton()` pipeline as the regular TomoMod action buttons, including the current icon crop, backdrop, border, gloss and selected icon-skin preset. The temporary diagnostic styling is removed from all three special-button presentations.
- **Fix** — The TomoMod vehicle-leave button keeps normal vehicle exit behavior, while Blizzard's taxi button remains available when early landing is supported.

#### Validation

- **Tested** — Human/Cat/Bear form changes, spell use before and after shapeshifting, Extra Action, Zone Ability, quest-state icon swaps, GCD/charges, mouse clicks, keyboard activation and vehicle exit were validated in game without ActionBar taint errors.
- **Tested** — Secure Visibility, dormant bars, native glows, Touch of Death conditional usability, Blizzard Edit Mode, Pet/Stance/Possess handling and secure paging remain clean after the special-button rebuild.
- **Internal** — Removed obsolete ActionBar isolation scaffolding and retry helpers from the final 3.5.9 package while preserving the native-frame ownership rules validated in game.

## ####################################

## CHANGELOG 3.5.8 — Action Bars: Midnight 12.1 Reliability, Faster Input, Native Range Updates & Taint Hardening

#### Action Bars — Input & Combat Responsiveness

- **Fix** — Action bar keybinds now fire on key-down consistently, removing the delayed or "sticky" feeling that could make interrupts, instant abilities and modifier binds react late.
- **Fix** — The secure action path was tightened so interrupts, GCD abilities, off-GCD abilities, rapid key spam, Shift/Ctrl binds and stance/form changes stay responsive in combat.
- **Fix** — Invisible or retired Blizzard action-bar elements can no longer sit over TomoMod bars and steal mouse clicks.

#### Action Bars — State, Cooldowns & Transforming Spells

- **Fix** — Slot changes now refresh the affected TomoMod buttons immediately when a spell is moved, replaced, removed or restored.
- **Fix** — Specialization, talent/loadout, paging, stance/form, vehicle and skyriding transitions now invalidate stale button state instead of leaving an old icon, cooldown, glow, greyed state or charge count behind.
- **Fix** — Charge-based and transforming abilities now refresh their cooldown/charge state reliably after the action changes underneath the button.

#### Action Bars — Range & Usability

- **Changed** — On Midnight 12.1, range coloring now uses Blizzard's native action-range update path instead of continuously scanning every action button from Lua.
- **Changed** — Mana/usability coloring is now event-driven. A lightweight polling fallback remains only for clients where the native range API is unavailable.
- **Fix** — Range and usability updates are targeted to the affected buttons, reducing unnecessary work during combat without making range feedback less responsive.

#### Action Bars — Proc Glows, Flyouts & Mouseover

- **Fix** — Proc glows now follow base spells and transformed/override versions more reliably, and stale glows are cleaned up when a proc ends or an action changes.
- **Fix** — Opening a flyout from a mouseover-faded bar now reveals the source bar correctly instead of allowing an interactive flyout to inherit a fully transparent state.
- **Fix** — Closing the flyout correctly returns the bar to its normal mouseover/fade behavior.

#### Action Bars — Midnight 12.1 Taint Hardening

- **Fix** — Removed several custom state markers from Blizzard-owned frames and moved that bookkeeping into external weak tables, reducing the chance of contaminating protected UI objects.
- **Fix** — TomoMod's custom action buttons are detached from Blizzard's internal action-button registries where appropriate, preventing Blizzard's controller from treating addon-owned buttons as native ones.
- **Fix** — Blizzard action-button broadcasters are isolated from retired native buttons, eliminating repeated secret-value cooldown errors that could flood the error log in combat.
- **Fix** — `StanceBar` and `PossessActionBar` are now left under Blizzard's ownership. This resolves the protected `MainActionBar:SetAttribute()` error that could occur in combat when a Monk summoned a temporary companion/pet.
- **Fix** — Blizzard's standard action bars are hidden again using the safe visual-suppression path validated against the 12.1 controller, while TomoMod's own bars remain visible and functional.

#### Validation

- **Tested** — Reloads, specialization and talent changes, moving/replacing/clearing actions, charges, transforming spells, Druid forms, vehicles/skyriding, conditional macros, mana states, range changes, proc glows, flyouts, rapid key spam and modifier binds were tested without stale action states.
- **Tested** — Intensive combat testing, including the Monk companion/pet transition that previously reproduced the protected-action error, completed without ActionBar taint errors.

## ####################################

## CHANGELOG 3.5.7 — Hide Talking Head Only Half-Worked Because The Frame Manages Its Own Visibility: `TalkingHeadFrameMixin` Shows Itself Whenever `isPlaying` Is Still True, So An `OnShow` Hook That Merely Called `Hide()` Left `isPlaying` Set, The Finish Timer Running And The Voiceover Playing — And Skipped Every Line After The First In A Multi-Line Talking Head, Since `PlayCurrent()` Never Calls `Show()` Once The Frame Is Already Visible. TomoMod Now Hooks `PlayCurrent()` Directly, The One Entry Point Every Line Actually Runs Through, And Calls Blizzard's Own `CloseImmediately()` — Which Clears `isPlaying`, Cancels The Finish Timer, Tells The Game To Ignore The Current Talking Head, And Hides The Frame The Way Blizzard Itself Does — Then Sweeps The Voiceover Sound A Tick Later In Case `StopSound()` Was Ignored For Firing In The Same Frame As The `PlaySound()` That Started It; And The Queue Status Eye's Moved Position Was Silently Discarded On Every Login Because Its Defaults Table Entry Was Never Added When The Anchor Was Introduced, So `FrameAnchors`' Own Save Guard (`if db and db[def.key] then`) Skipped Writing The New Position Every Single Drag — With The Missing Entry Restored, The Save Path Now Creating It On The Fly For Anyone Still Missing It, And The Blind Corner Offset It Defaulted To, Which Landed Off-Screen Entirely On An Ultrawide Monitor, Replaced With A Spot Beside The Minimap Where The Eye Actually Lives; And, Because `QueueStatusButton` Is Itself A Child Of That Same Native Micro Menu Container, Hiding The Blizzard Micro Menu Took The Group Finder Eye Down With It — Leaving No Queue Status Visible At All While Queued For Anything — So It Is Now Reparented To `UIParent` The Moment TomoMod Owns The Micro Menu, Placed Through The Very Same `queueStatus` Anchor Rather Than A Second Competing `SetPoint`, And Given Its Own Enable Toggle And Size Slider; And, Reported Live From A Player On A Midnight PTR Build, `GetUnitRole`'s Existing `issecretvalue()` Guard Still Let A Secret Role String Reach A Direct Comparison On Nameplates — The Comparison Itself Is Now Also Wrapped In `pcall`, So An Undetected Secret Fails Closed Instead Of Throwing All The Way Up Through The Nameplate Update; And, From The Same Kind Of Report, Hundreds Of Blocked `SetCooldown` Calls Traced Back To Every Skinned Action Bar Button Carrying TomoMod's Taint The Same Way The Override Bar Already Did, So Blizzard's Own Cooldown Updates Started Rejecting Secret Values On Them Too — Now Skipped Outright Rather Than Attempted, Covering All Three Cooldown Widgets A Button Can Carry And Installed Unconditionally Rather Than Behind The Cosmetic Skin Toggle That Was Quietly Excluding Whole Bars From It, With A Sibling Fix Silencing The Rarer Case Of Blizzard's Own Controller Trying To Reshow A Retired Bar Mid-Transition; And The Square Minimap's Mail Icon Threw `attempt to call a nil value` On Every New-Mail Update Because Reparenting It Broke Its Own Blizzard Event Handler's Closing `self:GetParent():Layout()` Call — Now Absorbed By A Harmless No-Op Stub Since TomoMod Positions It Itself; And Diagnostics Now Optionally Backs Itself Up Against `!BugGrabber`, Backfilling And Then Staying Subscribed To Whatever It Catches, For Players Who Also Run It

#### Fix — Micro Bar Hover Fade Blocked In Combat

- **Fix** — Hovering a Micro Bar button in combat produced `ADDON_ACTION_BLOCKED` on `TomoMod_MicroBarFrame:Show()`. The buttons use `SecureActionButtonTemplate` (needed for their click actions), and script handlers attached to a secure button — here `OnEnter`/`OnLeave`, which drive the bar's hover fade — run in a protected calling context; `UIFrameFadeIn` calls `Show()` on the bar internally to animate the fade, and that `Show()` is what got blocked. The fade now snaps straight to its target alpha with `SetAlpha` instead of animating whenever `InCombatLockdown()` is true, avoiding the protected call entirely — only the smooth fade is skipped in combat, hover/tooltip behaviour is unaffected.

#### Fix — A Bad Database Migration Step Could Silently Break An Entire Session, And Diagnostics Wasn't Catching Any Of It

- **Fix** — `TomoMod_InitDatabase` ran the whole one-time migration list and the unit-frame/nameplate element normalization pass back to back with no error handling: an uncaught failure partway through the migration list skipped every migration after it AND the normalization pass entirely, since both used to be one unprotected call chain. On a profile with years of history behind it — unlike a freshly reset dev profile — that can leave `elements` entries genuinely missing, and everything downstream that reads them errors out again on every single update for the rest of the session (a Diagnostics report open to interpretation as "the addon just doesn't work," rather than one specific fixable failure). Both steps are now independently wrapped in `pcall`, so a failure in one can no longer take out the other, and it prints a clear, reportable message instead of silently repeating forever.
- **Fix** — Diagnostics itself defaulted to **off**: a purely opt-in feature a player experiencing real, repeated errors (their own BugGrabber, if installed, popping its own "too many errors, disable the addon" warning) would have no particular reason to go looking for, which is exactly how a report can come back with real problems happening and nothing captured. It now defaults **on** (popups stay suppressed by default regardless, so this is a quiet background capture, not a new popup) for new profiles, and a one-time migration switches existing profiles on as well — unticking it afterward still sticks.

#### Fix — Player Cast Bar Silently Did Nothing In EditMode If Disabled

- **Fix** — Clicking EditMode unlocks the Player Cast Bar through the exact same `enabled` flags that decide whether it gets built in the first place, so if it isn't built (its own toggle in Castbars settings is off), unlocking it silently did nothing — no error, no bar, nothing to grab, even though the same player would still see Blizzard's own untouched cast bar while actually casting and reasonably expect that to be the one moving. `TomoMod_Castbar.UnlockPlayerCastbar()` now prints a clear chat message pointing at the Castbars settings toggle instead of quietly no-oping when this happens.

#### Fix — Opening Blizzard's Own Edit Mode Could Blame TomoMod For A Blocked `TargetUnit()`

- **Fix** — A Diagnostics report showed `[ADDON_ACTION_FORBIDDEN] TomoMod: TargetUnit()`, from Blizzard's own `EditModeManager.lua` (`EnterEditMode -> OnEditModeEnter -> EditModeFrameSetup -> RefreshTargetAndFocus -> TargetUnit()`), fired the moment Blizzard's native Edit Mode opened. "Hide the Blizzard micro menu" mutes the native micro menu containers via ordinary `SetAlpha`/`EnableMouse` calls, re-applied every time Blizzard's own `UpdateMicroButtons` fires (bag changes, talent points, LFD eligibility...) — including, it turns out, during Edit Mode's own internal setup pass, which manages that same micro menu area as one of its systems. Repeatedly touching a frame Edit Mode is mid-refresh on from ordinary Lua is exactly the kind of taint that surfaces later as an unrelated blocked call deep in Blizzard's own code.
- **Fix** — The mute now stands down entirely for as long as `EditModeManagerFrame:IsEditModeActive()` is true (hooked via `EnterEditMode`/`ExitEditMode`), and reapplies itself the moment Edit Mode closes. The native micro menu is briefly visible again while Edit Mode is open, same as if "hide the Blizzard micro menu" were temporarily unticked.

#### New — Target/Focus Enemy Buffs Now Have A Direction Setting

- **New** — The "Enemy Buffs" tracker on the target and focus frames (the helpful auras cast on the unit you're targeting) now has its own **Direction** dropdown (right/left), an **Icons per row** slider, and a **Next row goes** (up/down) dropdown, next to the existing count and size sliders. Row growth was previously fixed at 3-per-row/upward, with the settings silently unused since the container never read them.
- **New** — Row count is capped at 3: if the icon count and per-row value would produce a 4th row, the extra icons are simply not drawn rather than growing the container unbounded.
- **New** — The count slider's ceiling went from 8 to **12**.
- **Fix** — The regular Auras' own direction/vertical dropdowns (player/target/focus, not just Enemy Buffs) had the same silent no-op: `AC.Relayout` only re-asserted grow direction and row width when icon size or count ALSO changed in the same call, so toggling direction alone did nothing until an icon size/count change (or a `/reload`) happened to trigger a full rebuild alongside it. `AC.Relayout` now diffs and re-applies direction/vertical/row-width independently of size/count.
- **Fix** — "Next row goes" (up/down) still looked broken even after the above: the engine's flow always starts AT its anchor corner and grows away from it, but both aura containers anchored their engine at a fixed TOPLEFT regardless of direction. With growVertical set to Up, row 1 landed at that top corner and every further row grew further upward past it — leaving the whole stack floating a few rows' worth of space above the health bar instead of sitting flush against it and growing upward from there. The anchor corner now tracks growDirection/growVertical (the corner content grows AWAY from), both on creation and on every live relayout.
- **Internal** — `UF.RefreshUnit`'s Enemy Buffs handling no longer hides and destroys the container on a settings change and hands off to a function that couldn't actually rebuild it (`UpdateEnemyBuffs` only ever updated an *existing* container) — a latent bug that would have quietly dropped the whole tracker after the first size/count edit. Both aura containers now relayout live through the same `UF_Elements.RelayoutAuras` / `RelayoutEnemyBuffs` path, and `UpdateEnemyBuffs` creates the container lazily if it's missing.

#### New — The Regular Auras Section Gets The Same Per-Row/3-Row Grid As Enemy Buffs

- **New** — Player/target/focus **Auras** (buffs, debuffs, or both, depending on the Type dropdown) now use the same icons-per-row grid as Enemy Buffs, instead of a pixel-based "Max width" wrap: an **Icons per row** slider (default 6) replaces it, and row count is capped at 3 the same way — extra icons beyond 3 rows are simply not drawn.
- **Fix** — The count, direction and vertical-direction controls in this section didn't call a refresh at all, so none of them updated the frame live — only the icon size and spacing sliders did. All of them now do.
- **New** — Both sections of the Auras tab now carry the same "Requires /reload to take effect" note used elsewhere in the addon: the Enable toggle and the buff/debuff/both Type dropdown still rebuild the container only when the frame is first built, so a reload is the one safety net that always catches those two.

#### Fix — Hide Talking Head Could Leave The Voiceover Playing

- **Fix** — `HideTalkingHead` used to hook `TalkingHeadFrame`'s `OnShow` and simply call `Hide()`. `TalkingHeadFrameMixin` owns its own visibility through `UpdateShownState()` (`SetShown(self.isInEditMode or self.isPlaying)`), so hiding the frame from `OnShow` left `isPlaying` set, left `finishTimer` running, and left the voiceover playing underneath — and `PlayCurrent()` skips the `Show()` path entirely when the frame is already visible, which a multi-line talking head does for every line after the first, so `OnShow` never fired again to catch it.
- **Fix** — The addon now hooks `PlayCurrent()` directly — the single entry point `TalkingHeadFrameMixin:OnEvent()` routes every `TALKINGHEAD_REQUESTED` through, once per line — and calls Blizzard's own `CloseImmediately()`: it clears `isPlaying`, cancels `finishTimer`, calls `C_TalkingHead.IgnoreCurrentTalkingHead()`, and hides the frame through `UpdateShownState()`, keeping the bottom-managed layout and `AlertFrame` anchors consistent with a real Blizzard close. Edit Mode is left alone, since the frame is shown there on purpose.
- **Fix** — A `StopSound()` issued in the same frame as the `PlaySound()` that started the voiceover is occasionally ignored by the sound engine, so the addon now sweeps the handle again 0.05s later to make sure it actually stops.
- **Internal** — `TalkingHeadFrame` is not a protected frame, so no combat guard was needed — combat is precisely when most talking heads fire (encounters, scenarios). The addon also stops listening for `ADDON_LOADED` the moment the hook is in place, instead of checking it on every subsequent addon load.

#### Fix — Queue Status Eye's Position Never Actually Saved

- **Fix** — `TomoMod_Defaults` never got a `queueStatus` entry when the queue eye was added to the movable-anchor list, so the save handler in `FrameAnchors.lua` (`if db and db[def.key] then ... end`) silently skipped every drag: the eye moved fine on screen, but the position was never written and reset on the next login. The missing default entry is back.
- **Fix** — The save path now also creates the entry on the fly (`if db and not db[def.key] then db[def.key] = {} end`) if a player's saved variables still carry an older defaults table without it, so a stale save costs a table instead of a silently discarded position.
- **Fix** — The anchor's default position was a blind corner offset (`TOPRIGHT, -220, -24`) that landed in a different spot on every resolution — off-screen entirely on an ultrawide monitor, which is how this was found. It now defaults to a spot beside the minimap, where the eye actually lives.

#### New — Group Finder Eye Survives Hiding The Blizzard Micro Menu

- **Fix** — `QueueStatusButton` (the Group Finder eye) is a child of the native micro menu container, so muting that container to hide Blizzard's micro menu took the eye down with it — leaving no visible queue status at all while queued for anything.
- **New** — While the Blizzard micro menu is hidden, TomoMod now reparents the eye to `UIParent` so it survives the mute, keeping Blizzard's own click handlers and right-click teleport menu intact, and places it through the same `queueStatus` anchor `FrameAnchors` already owns — position is set in exactly one place instead of two systems fighting over `SetPoint`. Turning the option off hands the button straight back to its original parent and lets Blizzard's own `UpdatePosition` put it back.
- **New** — Two new Micro Bar options, under the same tab as "hide the Blizzard micro menu": a toggle to enable or disable the eye entirely, and a size slider.
- **Internal** — Blizzard re-anchors the eye on its own layout pass (`UpdatePosition`), so the hook re-asserts TomoMod's placement a frame later rather than letting the two positions alternate. `LFG_UPDATE` and `LFG_QUEUE_STATUS_UPDATE`, which fire repeatedly while queued, are handled directly instead of falling through to a full bar rebuild every time.
- **Fix** — The eye's size slider silently did nothing unless Micro Bar was fully enabled with "hide the Blizzard micro menu" also turned on: `SetScale` only ran on the reparented path, and the other path unconditionally reset it back to `1` on every refresh. Scale now applies regardless of whether the eye has been detached from the native menu.

#### Fix — Nameplate Role Comparison Still Reachable On A Secret Value

- **Fix** — A player report still showed `attempt to compare local 'role' (a secret string value...)` from `Nameplates.lua`'s `GetUnitRole`, despite the 3.5.3 fix that guards the comparison with `issecretvalue()` first. The pre-check is only as good as the client's own reporting of secrecy; `role ~= "NONE"` is now also wrapped in `pcall`, so if `issecretvalue()` ever fails to flag a secret role, the comparison itself fails closed instead of throwing up through the nameplate update. The same net was added to the tank/threat coloring pass's `role == "TANK"` check.

#### Fix — Action Bar Cooldowns Blocked By Secret Values On Tainted Buttons

- **Fix** — A player report showed hundreds of `bad argument #1 to 'SetCooldown' (... Secret values are only allowed during untainted execution for this argument)` errors, entirely inside Blizzard's own `ActionButton_UpdateCooldown` chain, on both the override/extra action buttons and the reclaimed native buttons on every managed bar. `SkinButton` touches every button's cooldown frame directly (`ClearAllPoints`, `SetAllPoints`, `SetDrawEdge`), which taints it the same way the override bar's deferred attribute writers already did — so Blizzard's own later cooldown update on that frame rejects secret start/duration/modRate values because the button carries our taint. Two gaps let the first pass at this fix keep firing: the guard was installed behind the cosmetic skin toggle, so any bar with skinning disabled never got it at all, and it only wrapped the button's primary cooldown widget — `ActionButton_ApplyCooldown` actually drives three of them per button (normal, charge, loss-of-control), each with its own `SetCooldown` call. The guard now installs unconditionally the moment a button is reclaimed and covers all three widgets, skipping the call outright when `issecretvalue()` flags any argument, with `pcall` as a second net.
- **Fix** — A related, rarer blocked-action error, `MainActionBar:SetShownBase()`, came from Blizzard's own `ActionBarController` trying to re-show a bar TomoMod had already retired during a mount/vehicle transition. `UpdateVisibility` — the call `Show()` routes through before reaching the protected `SetShownBase` — is now silenced on retired bars the same way the existing `UpdateShownButtons`/`UpdateGridLayout` guards already are.

#### Fix — Minimap Mail Icon Threw An Error On Every Update

- **Fix** — Repositioning the mail, crafting-order and instance-difficulty indicators onto the square minimap reparents them onto `Minimap`. The mail icon's own Blizzard event handler ends every `UPDATE_PENDING_MAIL` with `self:GetParent():Layout()`, expecting `MinimapCluster.IndicatorFrame`'s real layout method — once reparented, that call hit nothing and threw `attempt to call a nil value`. The icon's own show/hide logic already ran by that point, so nothing looked broken on screen, but the error fired on every mail update. `Minimap` (and the hidden-indicator holder frame) now carry a harmless no-op `Layout()` stub, since TomoMod already positions these indicators itself and never needed Blizzard's own layout pass to run.

#### New — Diagnostics Now Backs Up Against `!BugGrabber`

- **New** — If the player also runs `!BugGrabber` (with or without BugSack), Diagnostics now hooks into it as a second, independent capture path: it backfills whatever `!BugGrabber` already caught this session before TomoMod's own error handler was installed, then stays subscribed to its capture event for anything caught afterward. Purely additive and fully optional — nothing happens if `!BugGrabber` isn't installed, and every imported entry still goes through the exact same filters (TomoMod-only unless "capture all" is on, Blizzard-only errors excluded) as everything Diagnostics already captures on its own.

#### Fix — Character Sheet Flagged Shields And Off-Hand Held Items As Missing An Enchant

- **Fix** — `CharacterSkin.lua`'s item info overlay treats `CharacterMainHandSlot` and `CharacterSecondaryHandSlot` as always enchantable, since a two-hand or one-hand/one-hand melee setup genuinely can enchant both. That assumption broke for healers/tanks with a shield and for casters holding an off-hand item (tomes, frills, etc.) in the second slot: neither can take a weapon enchant at all, yet the overlay still drew a red "Missing" warning on them.
- **Fix** — The overlay now reads the equipped item's actual `itemEquipLoc` for both weapon slots and skips the enchant check when it is `INVTYPE_SHIELD` or `INVTYPE_HOLDABLE`, instead of assuming every item in those two slots is a weapon. Real weapons in either hand are unaffected and still warn when unenchanted.

#### New — Inspect Frame Now Shows Per-Item iLvl, Enchants And Gems Like The Character Sheet

- **New** — Inspecting another player only ever showed a single averaged item level at the top of the frame. The Inspect frame now gets the exact same per-slot overlay the character sheet already has: item level, upgrade track, enchant text (or a red "Missing" warning on enchantable slots) and gem sockets drawn right next to each equipped item, reusing the same detection logic — including the shield/off-hand-holdable fix above, so inspecting a shield tank or an off-hand caster doesn't falsely flag a missing enchant either.
- **New** — A new "Show iLvl, Enchants & Gems on Inspect" checkbox was added next to the existing Inspect frame skin toggle, so this can be turned off independently of the character sheet's own item info/gem settings.
- **Internal** — The overlay system (item info + gem sockets) was generalized to take a unit instead of assuming `"player"`, and hooked into the Inspect frame's existing `INSPECT_READY`/`OnShow`/`OnHide` lifecycle plus Blizzard's own `InspectPaperDollItemSlotButton_Update`, so it refreshes the moment inspect data arrives or the inspected unit's gear changes.

## ####################################

## CHANGELOG 3.5.5 — Two Ways TomoMod Was Filling The Error Log With Blocked Actions In Combat, Both Of Them A Protected Call Made One Step Too Late: Every Mouseover Of An Action Bar Button While Fighting Ran Blizzard's Own Button Update Chain, Which Ends In A Plain-Lua `SetAttribute` And, Two Lines Later, A `ClearAttribute` — Both Protected On A Secure Frame, And Because These Buttons Are Created By The Addon Rather Than By The Game The Refusal Is Attributed To TomoMod, One Entry Per Hover, Which Is How A Single Session Collected A Hundred And Twenty-Seven Of Them Without A Single Thing Going Visibly Wrong On Screen; And Every Keypress With One Of The Shared Escape-Closable Windows Open In Combat Called `SetPropagateKeyboardInput` Before Checking Whether It Was Allowed To, So The Combat Guard That Was Already Sitting Right There Ran One Line Too Late To Prevent Anything — Holding A Movement Key Down Was Enough To Fill The Log On Its Own — With The Guard Now Moved Ahead Of The Call And The Propagation State It Was Setting Established Once When The Window Is Built Instead, Because Propagation Is A Persistent Property Of A Frame And Never Actually Needed Re-Establishing On Every Key — And One Cosmetic Fault With The Same Shape, A Value Read From Blizzard That Was Never Portable To Begin With: The Character Sheet Button On The Custom Micro Menu Drew As A Blank Coloured Square And No Other Button Did, Because Alone Among Them It Has Neither An Atlas Nor A Static Texture File — Its Art Is The Player Portrait, Pushed Into The Native Button By `SetPortraitTexture` — So Copying What `GetTexture` Returned Handed Over A Portrait Texture ID That Simply Does Not Reproduce On A Different Region, And The Fix Is To Stop Copying And Ask The Game To Paint The Portrait Onto TomoMod's Own Icon Directly — And Two More From The Same Micro Menu And The Frame Anchors Beside It, Both Of Them Failures That Announced Nothing At All: Ticking "Hide The Blizzard Micro Menu" Could Do Precisely Nothing On Some Clients, Because The Container Was Looked Up Under One Hardcoded Name And A Miss Returned Immediately — Skipping Even The Buttons, Which Answer To Their Own Names And Are What The Player Actually Sees — So The Lookup Now Sweeps Every Name Blizzard Has Used, Always Handles The Buttons Whether Or Not A Container Answered, And, When Genuinely Nothing Answers, Says So In Chat Once Per Session Instead Of Leaving A Ticked Box Sitting Above An Unchanged Bar With Nothing To Go On; And The Queue Status Eye, Parented To The Minimap Cluster And Given No Edit Mode Entry By Blizzard, Becomes The Newest Entry In `/tm sr` — The One HUD Element A Player Simply Could Not Place — With `ApplyAnchor` Learning To Defer Its `SetPoint` To The End Of Combat Rather Than Attempt A Move On A Frame Edit Mode Manages And Collect A Blocked Action For It — And Two Additions To The Same Micro Menu To Close The Release Out: The Repaired Character Portrait Now Takes Blizzard's Own Mask And Shadow Regions From The Native Button Instead Of Approximating Its Shape With Hand-Tuned Texture Coordinates, So It Carries The Same Silhouette And The Same Depth As Every Other Micro Button Rather Than Sitting Flat And Square Among Them, With Nothing Left To Retune The Next Time The Art Moves; And The Memory Tooltip Grows A Performance Block Above Its Per-Addon List — Framerate, Home And World Latency, And Total Addon CPU — Where The CPU Line Is Honest About The One Thing It Cannot Know, Reading *Profiling Disabled* In Grey Whenever The `scriptProfile` CVar Is Off, Which Is Its Default, Instead Of Printing A Column Of Zeroes That Would Look Exactly Like A Measurement Of An Addon Costing Nothing

#### Fix — Blocked Actions When Hovering Action Bar Buttons In Combat

- **Fix** — `InstallSecureActionFlagRefresh` now neutralises Blizzard's `UpdatePressAndHoldAction` on the buttons TomoMod creates. The standard bars keep Blizzard's `OnEnter` (the tooltip is added with `HookScript`, not `SetScript`), so every mouseover ran `OnEnter → UpdateAction → Update → UpdatePressAndHoldAction`, which ends in a plain-Lua `SetAttribute` on a secure frame — protected in combat, and attributed to TomoMod because the frame is addon-created: `[ADDON_ACTION_BLOCKED] TomoMod: TUI_Bar3Button9:SetAttribute()`, once per hover. Making it a no-op is safe because the attribute is already ours: the `TUI_UpdateActionFlags` restricted-environment snippet writes `pressAndHoldAction` itself, driven by the `OnAttributeChanged` wrap on `action` — exactly when the value needs to change. Blizzard's version was redundant, not helpful.
- **Fix** — Same chain, two lines further down `UpdateAction`: `PingableType`'s `UpdatePingAttributes` calls `ClearAttribute`, equally protected and equally blocked on a hover in combat (`TUI_Bar3Button12:ClearAttribute()`). Pings target Blizzard's own bars; these buttons are TomoMod's and are not a ping surface, so the call is dropped at no cost.
- **Note** — Neither of these ever broke anything visible. They were pure log noise — but enough of it to bury a real error, and enough to make the addon look like the cause of anything else that went wrong in the same fight.

#### Fix — Blocked Actions On Every Keypress With A TomoMod Window Open In Combat

- **Fix** — `TomoMod_Utils.CloseOnEscape`'s `OnKeyDown` handler called `SetPropagateKeyboardInput` *before* testing `InCombatLockdown()`. That function is itself protected, so the combat check — which was already written, one line below — ran too late to prevent anything: every single keypress with one of these windows open in combat produced an `ADDON_ACTION_BLOCKED`. Holding a movement key down filled the error log on its own. The guard now comes first.
- **Fix** — The `OnShow` hook carried the same unguarded call and is now guarded too. Returning early is safe because propagation is a persistent frame state, not something re-established per keypress: it is only ever flipped to false to swallow an Escape, which cannot happen in combat, so a frame in combat is already propagating and there is nothing to do.
- **Fix** — Propagation is now established once when the window is built, which is out of combat for every caller. Without it, a frame whose very first `Show` happened in combat would have swallowed every key, since both guarded paths above would correctly have declined to set it.

#### Fix — Micro Menu: The Character Sheet Button Was A Blank Square

- **Fix** — `MicroBar.lua`'s `ApplyArt` copies each native micro button's art onto TomoMod's own icon by reading an atlas name or a texture file off it. `CharacterMicroButton` has neither: its art is the player portrait, pushed into the native button by `SetPortraitTexture`. `GetTexture` on it therefore returned a portrait texture ID, which does not reproduce on another region and rendered as a flat coloured square — on that one button and no other, which is exactly what was reported. `ApplyArt` now takes the button's `key` and, for `"character"`, calls `SetPortraitTexture(icon, "player")` on TomoMod's icon directly instead of copying anything, resetting `SetTexCoord` first because portrait textures come uncropped. The call is wrapped in `pcall` and falls through to the normal atlas/texture path if it ever fails, so a client without the API behaves as before.
- **Change** — A portrait fills its texture edge to edge while the micro-button atlases carry their own padding, so simply painting it in left the character button reading noticeably bigger and squarer than its neighbours. It now borrows Blizzard's own two regions from the native button — the mask `UI-HUD-MicroMenu-Portrait-Mask` for the silhouette and `UI-HUD-MicroMenu-Portrait-Shadow` beneath it for depth — rather than approximating the shape with hand-tuned texture coordinates. Same look as Blizzard's button, and no magic numbers to retune when the art changes. Both are created once per button and guarded with `pcall`: a client missing either atlas falls back to the plain portrait instead of erroring.

#### New — Performance Readout In The Micro Menu's Memory Tooltip

- **New** — The memory tooltip on the custom micro menu gains a **Performance** block above the per-addon list: framerate, home/world latency, and total addon CPU. Framerate and latency are what a player actually reaches for when hovering that button, and both are free to read.
- **New** — Addon CPU is only recorded when the `scriptProfile` CVar is on, which is off by default and requires a reload to change. Rather than print a row of zeroes that look like a measurement, the line reads *profiling disabled* in grey until it is turned on.
- **Internal** — CPU totals are collected by `RefreshCPU` behind the same 5-second cache as the memory figures, so hovering repeatedly doesn't re-walk the addon list on every frame.

#### Fix — Micro Menu: "Hide The Blizzard Micro Menu" Could Do Nothing At All

- **Fix** — `MuteNative` looked the native container up as `_G.MicroMenu` and returned immediately when it was missing. Blizzard has moved that frame more than once, so on a client where the name no longer resolves the option was a complete no-op — the early return skipped the per-button loop too, even though those buttons answer to their own global names and are what the player actually sees. The lookup now sweeps `MicroMenu`, `MicroMenuContainer` and `MicroButtonAndBagsBar`, each guarded on the methods it uses, and the button loop runs unconditionally afterwards.
- **New** — When hiding was asked for and nothing at all answered to it, TomoMod now prints a single line in chat asking for a report with the client version, rather than failing silently. `MuteNative` returns whether it touched anything and `ApplyNative` warns once per session — once, because `UpdateMicroButtons` re-enters this path constantly.
- **Note** — The silent no-op is the whole reason this took a player report and a round trip to identify: a ticked box, an unchanged bar, and nothing anywhere to say why. That is the part the warning is meant to prevent from happening again.

#### New — The Queue Status Eye Is Now Movable

- **New** — The queue status eye joins the movable frame anchors in `/tm sr`. Blizzard parents it to the minimap cluster and gives it no Edit Mode entry, which made it the one HUD element a player had no way to place. It is already on the list of buttons the Minimap module must not collect, so nothing else in TomoMod claims it.
- **Fix** — `FA.ApplyAnchor` now defers to `PLAYER_REGEN_ENABLED` when called in combat instead of attempting the move. `SetPoint` on a protected frame is refused in combat; `AlertFrame` and `LootFrame` are not protected so this never mattered before, but the queue eye hangs off `MinimapCluster`, which Edit Mode manages — a refused move would have surfaced as an `ADDON_ACTION_BLOCKED` attributed to TomoMod. Pending anchors are keyed, so repeated calls during one fight collapse into a single re-apply when it ends.

## ####################################

## CHANGELOG 3.5.4 — The Prey Tracker's Progress Bar Was Stuck At Zero Percent Because Reading Its Own Widget Data Threw An Error Every Single Second, The Result Of Keeping Only Half Of What `pcall` Handed Back, The Extra Action Button's Move Overlay Loses The Four Click-To-Nudge Arrows Nobody Asked It To Grow, And A Pass Of Performance Fixes Across The Locale Loader, Party And Raid Frames, The Shared Aura Scanner, Cooldown Forge, Boss Frames, The Objective Tracker And Skyriding Removes A Handful Of Habits That Cost Nothing On Their Own And Add Up On Every Tick: A Non-Active Locale's Nearly Three Thousand Translation Entries Built And Thrown Away On Every `/reload`, A Range-Check Ticker Running Twice As Often As Any Transition It Needs To Catch, A Protected Call Opened Once Per Aura Instead Of Once Per Scan, Unit Events Left Subscribed In A Raid For Frames The Raid Module Had Already Taken Over, A Burst Of Cooldown Events Each Repainting Every Bar On Its Own, And Inline Closures Rebuilt On Every Tick Where A Named Function Would Do, The Options Panel — Twenty-Eight Files And Roughly Seventeen Thousand Nine Hundred Lines Most Sessions Never Open — Moves Into Its Own Load-On-Demand Sub-Addon That Loads Itself Transparently The Moment It's Actually Needed, And Four Damage Meter Windows Stop Routing Their Escape Key Through A Path That Could Quietly Leave The Game Menu Refusing To Close

#### Prey Tracker — Progress Was Stuck At 0%

- **Fix** — `GetPreyWidgetInfo` called `C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo` through `pcall` but kept only the first return value — the success boolean — into the variable read afterwards as the widget's data. `UpdatePreyProgress` then indexed that boolean for `.progressPercent`, which throws in Lua, and did so on every 1-second tick. The error aborted the update before it could ever fall through to the quest-objective fallback, so the bar rendered once at its initial value and never moved again — while Blizzard's own tracker, driven directly by the client, kept climbing right beside it.
- **Fix** — The call now keeps both values `pcall` returns (`ok, info`) and only reads the table when the call actually succeeded. The real Prey Hunt widget doesn't expose a percentage at all — it only reports a coarse Cold/Warm/Hot/Final state — so the bar now reads the objective's own `x/y` fulfillment count, exactly as the fallback path was already written to do.

#### Action Bars — Extra Action Button & Zone Ability Move Overlay

- **Change** — Removed the four click-to-nudge arrow buttons that surrounded the Extra Action Button and Zone Ability move overlays in `/tm layout`. Dragging the overlay with the mouse still repositions it exactly as before; only the extra buttons are gone.

#### Performance — Locale Loading

- **Fix** — `TomoMod_RegisterLocale`'s merge-in-base-locale check tested `TomoMod_L[k] == nil`, but `TomoMod_L` carries an `__index` metamethod that always returns something for any key — so the condition was always false and fired the metamethod on every one of the ~2900 enUS keys for nothing, on every load. It's `rawget`-only now.
- **Change** — `deDE.lua`, `esES.lua`, `frFR.lua`, `itIT.lua` and `ptBR.lua` each now bail out with `if GetLocale() ~= "<locale>" then return end` before their table constructor. Lua still builds the whole ~2900-entry table before `TomoMod_RegisterLocale` gets a chance to discard it, so a player on any other locale was allocating and immediately garbage-collecting five of those tables on every `/reload`. Only the active locale's file still builds its table.

#### Performance — Party & Raid Frame Range Checking

- **Change** — The range-check safety-net ticker on both Party and Raid frames dropped from 0.5s to 2.0s. `UNIT_IN_RANGE_UPDATE` already covers the normal case instantly; the ticker only exists to catch transitions that fire no event (phasing, disconnect, zone change), none of which needs sub-second resolution — it was running forty times a second in a 40-man for nothing.
- **Internal** — `PF.UpdateRange` / `RF.UpdateRange` now accept the settings table as an optional second argument so the ticker's loop doesn't re-read `TomoModDB` on every single frame.

#### Performance — Shared Aura Scanning

- **Change** — `AuraData.ScanDefensives` wrapped every `C_UnitAuras.GetAuraDataByIndex` call in its own `pcall` — up to 40 protected calls per `UNIT_AURA` per tracked unit, and a protected call frame is one of the more expensive things Lua can do. One `pcall` now wraps the whole scan loop instead; a mid-scan error still keeps whatever entries were already collected, so the degraded behavior is unchanged.

#### Performance — Party Frames: Unit Lookups & Raid Gating

- **Change** — `GetFrameForUnit` looked up a frame with a linear `pairs()` scan over every party slot, run from globally-registered `UNIT_*` events that fire for every unit token the client emits — nameplates, raid members, boss units, arena, pets — almost always to find nothing. It's now a direct `PF.byUnit[unit]` table lookup.
- **New** — `PF.SetUnitEventsEnabled()` unregisters the eight `UNIT_*` health/power/aura events entirely while in a raid, where the party frames are hidden and the raid module owns unit updates. Re-evaluated on `GROUP_ROSTER_UPDATE` and at login, so joining a raid drops the dead subscriptions instead of leaving them firing for nothing.

#### Performance — Cooldown Forge Update Batching

- **Change** — `CDF.FireUpdate` now coalesces bursts of `SPELL_UPDATE_COOLDOWN` / `SPELL_UPDATE_CHARGES` — which Blizzard can fire several times within the same frame — into a single pass on the next `OnUpdate`, keeping the strongest reason seen (a layout refresh subsumes a plain cooldown refresh). Previously every one of those events drove a full pass over every bar and icon on its own. `CDF.FireUpdateNow` remains for anything that genuinely can't wait a frame, though nothing currently needs it.
- **Internal** — Two inline closures wrapped in `pcall` for reading `GetChildren()`/`GetRegions()` — one running per icon per pass — replaced with named functions (`packChildren`, `packRegions`) so the closure isn't reallocated on every call.

#### Performance — Boss Frames, Objective Tracker & Skyriding

- **Change** — Boss frame polling built a fresh `"boss" .. i` string on its 0.15s ticker for all 8 possible slots; it now indexes a constant `BOSS_UNITS` table instead.
- **Change** — The Objective Tracker's deferred layout pump (`PumpUpdateSoon`) passed a fresh inline closure to `C_Timer.After` on every event burst; it now passes a single named function. Its recursive content-scan helpers (`ModuleHasVisibleContent`, `HasSpecialModuleContent`) replaced `{ frame:GetChildren() }` / `{ frame:GetRegions() }` table allocations — walked at every node of a tree that can reach a couple hundred frames in a delve or scenario — with `select("#", ...)` iteration that allocates nothing.
- **Change** — Skyriding's speed calculations wrapped an inline closure in `pcall` on a 0.25s ticker (needed because ground/forward speed can be a secret value in restricted content); both are now named functions (`PercentOfSeven`, `ScaleBySpeedMultiplier`) so the closure isn't rebuilt every tick.

#### New: Options Panel Now Loads On Demand

- **Change** — The entire Config UI — 28 files, ~17,900 lines that most sessions never open — has moved out of the main addon and into a new `TomoMod_Options` sub-addon, flagged `LoadOnDemand`. It loads the first time you actually open the options panel instead of on every login.
- **New** — `Core/OptionsLoader.lua` publishes stand-in functions for `Toggle`, `Show`, `Hide`, `SwitchCategory` and `InvalidatePanels` that load `TomoMod_Options` on first use and forward to the real implementation once it's in memory — every existing call site keeps working unchanged.
- **Fix** — If the sub-addon is disabled or missing, opening the options panel now prints a message telling you so instead of silently doing nothing.
- **Internal** — `TomoScoreCore.lua`'s theme colors were captured once at login from `TomoMod_Widgets.Theme`, which no longer exists at that point — it's part of the now-separate options addon. The lookup is now a lazy proxy that resolves on each access instead of freezing to an empty fallback forever.

#### Fix — Escape Could Stop Working After Certain Windows Were Used

- **Fix** — The Death Recap, Run Recap, Spell Breakdown and Target Breakdown windows (Damage Meter) closed on Escape by registering themselves in `UISpecialFrames`, which routes the key through `ToggleGameMenu` — and that function's protected `ClearTarget`/`SpellStopCasting` calls get refused once anything on that path has been tainted, silently breaking the ability to close the game menu with Escape afterwards. All four now use the shared `TomoMod_Utils.CloseOnEscape` handler instead, the same one already used by the Cooldown Studio, the What's New popup, and half a dozen other TomoMod windows.

## ####################################

## CHANGELOG 3.5.3 — Battle Rez Visual Refresh, Prey Tracker Integration & The Action Bars Finally Following A Page Change: Vehicles, Skyriding And Flight Form Swap The Bar Underneath You, And Until Now The Buttons Either Kept The Artwork Of The Page You Had Just Left Or, With Hide Empty Slots On, Faded Out Entirely And Stayed That Way Until A Reload — And Then A Totem Bar Arrives, Carried Across From Tui As Written Rather Than Retyped With Every Changed Line Marked So The Next Upstream Revision Is A Replay Of A Handful Of Marks, Showing The Totems You Have Out In Your Class's Own Priority Order With The Time Remaining Written Across Each Icon And A Sweep Running Down It, Right-Click To Dismiss, Blizzard's Own Totem Frame Stood Down While It Is On And Handed Back Intact The Moment It Is Switched Off, Positioned From The Same `/tm layout` As Everything Else And Deliberately Shipped Off By Default — Which Left It Reachable Only By Hand-Editing The Saved Variables Until The Options Page Caught Up A Moment Later With A Totems Section Of Its Own, Because A Feature With No Way To Turn It On Is A Feature Nobody Has — And Finally The Pet And Stance Bars Are Given Back The Orientation, Button Count And Column Controls That Had Been Withheld From Them On The Belief That Blizzard Owned Their Shape, Which It Does Not: They Run Through Exactly The Same Layout Path As The Eight Main Bars And Always Had, So The Three Controls Now Appear For Them Too, Capped At Ten Slots Instead Of Twelve — And Then The Season Turns Over Underneath All Of It: The Dungeon And Raid Loot Tables Are Regenerated For Season 17 Against Build 12.1.0 With Every Season 16 Key Retired Rather Than Kept Alongside, Because They Are Keyed By Challenge Mode And Encounter ID And Last Season's Simply Do Not Appear In Either Rotation Any More, Eight New Dungeons And Two New Raids Landing With An Item-Class Table Regenerated From The Same Run So That Every One Of The Three Hundred And Forty-Six Item IDs The New Tables Reference Has A Restriction Recorded Or Is Deliberately Unrestricted, And The Five Rotation Dungeons Reach The Mythic+ Tracker With Their Teleport Spells While Kings' Rest And The Temple Of Sethraliss Finally Have Theirs Filled In Instead Of Sitting At Nil In A Rotation They Are Both Part Of — With The Two Files That Now Carry Teleport IDs Checked Against Each Other Rather Than Trusted, And The One That Is Merely Generated Documented As The Cross-Check It Actually Is Instead Of Being Described As Feeding A Consumer That Never Read It — And Finally A Diagnostic That Had Been Written, Commented With The Very Slash Command It Was Meant To Serve, And Then Left Unreachable Because No Branch Of The Handler Ever Routed To It

#### Battle Rez Counter — Visual Improvements

- **Enhancement** — The Battle Rez Counter HUD now features a modern visual redesign inspired by Tui's design patterns. Multi-layer backdrop with inner shadow effect, improved spacing, and professional typography.
- **New** — Optional glow effect when battle resurrections are available, providing better visual feedback during combat.
- **Change** — Upgraded color palette with Tui-inspired teal accent, improved contrast between active (green) and cooldown (red) states.
- **Internal** — Frame layout refactored with proper layer ordering: background, inner shadow, icon, cooldown swipe, and overlays. Better geometry and positioning for all UI elements.
- **Note** — All existing configurations are preserved; the changes are purely visual and cosmetic.

#### New: Prey Tracker — Midnight Hunt Progress Display

- **New** — A movable progress bar displaying active Prey hunt progress (Midnight expansion feature). Shows hunt name, difficulty level, and real-time progress percentage.
- **New** — Disabled by default (Midnight-only content); enable in Config → QOL → Combat → Prey Tracker.
- **New** — Full editmode integration via `/tm layout` — drag to position, lock/unlock like other TomoMod HUD elements.
- **Internal** — Reads C_QuestLog and C_UIWidgetManager APIs to detect active Prey quests and track progress in real-time (1-second update rate).
- **Internal** — Same visual language as Battle Rez Counter: matching backdrop, colors, fonts, and mover registration pattern.
- **Note** — Automatically hides when no Prey hunt is active; shows preview during placement mode.

#### Mover System Enhancements

- **Enhancement** — Both Battle Rez Counter and Prey Tracker are now fully integrated with the unified mover system (`/tm layout`).
- **Internal** — Synchronized lock/unlock behavior, consistent drag labels, and placement mode previews across all HUD elements.

#### Battle Rez Counter — Crash Fixes

- **Fix** — The counter's cooldown swipe layer called `SetDrawEdge`, which does not exist on the `Cooldown` frame template in this client build, crashing module init the moment the HUD tried to build itself. The call is now guarded.
- **Fix** — That same swipe layer set its frame level from `ico:GetFrameLevel()` — but `ico` is a `Texture`, not a `Frame`, and textures have no frame level. This was the real crash behind the visible error, now reading `brezFrame:GetFrameLevel()` instead.
- **Fix** — The glow effect crashed the moment it needed to re-show itself: `CreateGlow()` returned nothing on any call after the first, so `UpdateGlow` tried to index a nil `glowFrame`. It now returns the already-created glow on repeat calls.

#### Prey Tracker — Stability & Missing GUI Option

- **Fix** — `UI_WIDGET_SET_UPDATE` is not a real client event; registering it threw during init. Replaced with `UPDATE_UI_WIDGET`, and every event registration is now wrapped in `pcall` so an event missing on a given client build can no longer crash the module.
- **New** — An actual GUI option: Config → QOL → Automations now has a Prey Tracker section with an enable checkbox, width and font-size sliders, and an info note — the module previously had no way to turn it on outside of editing the SavedVariables by hand.

#### Action Bars — Move Mode Was Silently Inert

- **Fix** — The "Action Bars" entry in `/tm layout` did nothing at all. The ported Tui action bar code runs inside a sandboxed chunk environment, and a bare `ActionBarsOwned = {...}` inside that sandbox writes only into the sandbox's private table, never into `_G` — so the mover's `ActionBarsOwned.SetEditModeEnabled(...)` call was always reading a nil global. Both the mover entry and `Helpers.IsEditModeShown()` now reach it through `TomoMod_TuiNS.ActionBarsOwned`, the one bridge that's actually a real global.
- **Fix** — With move mode reachable, the drag overlay itself then crashed with `bad argument #1 to 'SetColorTexture'`. The compat shim `ApplyPixelBackdrop` was written for a `(frame, r, g, b, a)` signature that no call site actually uses — both real callers pass Tui's real signature, `(frame, borderSize, filled, glow, borderColor, glowColor)`, with color tables in the later positions. The shim now matches that signature and draws the highlight through `SetBackdrop` on the `BackdropTemplate` frames both callers already create.
- **Fix** — A bar dragged into a new position in `/tm layout` reset to its default spot on every `/reload`. Two gaps stacked here: `Helpers.GetCore()` returned an empty table with no `.db.profile`, so every position save silently did nothing; and even after wiring that up, `RestoreContainerPosition` never actually read the saved position back — it only checked for a separate Tui frame-anchoring subsystem that was never ported, and fell straight through to the bar's native Blizzard position on every load. Both are now fixed: `core.db.profile` resolves to `TomoModDB`, and restore reads the saved anchor directly before falling back.

#### Action Bars — Move Mode Visuals & Extra Button

- **Change** — The move-mode overlay for action bars and the extra action/zone ability buttons used Tui's original blue accent. Both now use TomoMod's teal brand color, matching every other `/tm layout` overlay (Objective Tracker, Boss Frames, Party Frames), with the drag label text switched to white for consistency.
- **Fix** — The Extra Action Button and Zone Ability holders had their own separate, self-contained move overlay system that was never connected to `/tm layout` — the holder was always visible on screen but had no way to be dragged from the unified layout tool. Both are now registered as a "Extra Button" entry in `/tm layout`, with the same lock/unlock behavior as everything else.

#### Battle Rez Counter — Icon Fix

- **Fix** — The counter's icon rendered as a solid black square. The texture path used for it, `Interface\Icons\Spell_Nature_Rebirth`, does not exist — the actual Rebirth icon is `Spell_Nature_Reincarnation` (file ID 136080). The icon now shows correctly.

#### Nameplates — Secret-Value Taint on Group Roles

- **Fix** — `UnitGroupRolesAssigned` can hand back a secret string value in restricted content; comparing it directly (`role == "TANK"`, `role ~= "NONE"`) threw a taint error and spammed the error log. Both call sites — the per-nameplate role icon and the tank/threat coloring pass — now guard with `issecretvalue` and treat a secret role the same as no role, rather than propagating it into a comparison.

#### Action Bars — The Press Effect, Properly This Time

- **Fix** — Pressing an action button turned its icon fully white, and the fix attempted earlier in this same release was the wrong one. `Pushed.tga` is not a white cutout shape: it is an opaque white square, measured at alpha 253. Additive blending cannot rescue that — white through `ADD` saturates to white — so the button still went white on press. Worse, the blend override was applied in `ReplaceTexture`, which is shared by Highlight, Checked, Flash and Pushed, so it brightened the three textures that sat at alpha 22-86 and had been rendering correctly all along. `ReplaceTexture` no longer touches blend mode, and the custom pushed texture is drawn in `BLEND` tinted to black at 35% — darkening the icon on press instead of covering it, which is what the custom mode was meant to look like from the start.
- **Change** — The default press effect is now Blizzard's own pushed texture rather than TomoMod's. A custom press effect is worth having as a choice; it is not worth inheriting from a default that was painting a white square.
- **New** — A "Press effect" dropdown in Config → Action Bars → General, with three modes: Blizzard, TomoMod and None. It applies immediately, no reload.
- **Fix** — Switching press modes at runtime left the previous mode's tint behind: the custom mode darkens the texture through `SetVertexColor`, and nothing reset it, so picking Blizzard afterwards produced its standard flash stuck black at 35%. The tint is now reset before every mode is applied.

#### Action Bars — Micro Buttons Stayed Where Combat Left Them

- **Fix** — When the micro buttons need reparenting into their TomoMod container and that lands mid-combat, the work is deferred and replayed on `PLAYER_REGEN_ENABLED`. That replay was registered through `ns.Addon:RegisterEvent`, and `ns.Addon` was a bare table with no such method — so the call threw, `SafeCall` swallowed it, and the `_microDeferPending` flag set on the line before stayed `true` for the rest of the session. The micro bar never reclaimed its buttons after that first combat, and nothing reached the error log to say why. `ns.Addon` now carries a real `RegisterEvent`/`UnregisterEvent` pair backed by its own event frame.
- **Internal** — `ns.Addon` is assembled in one place, `Core/TuiCompat/Namespace.lua`, with both halves visible together — `db.profile` and the event API. `Helpers.GetCore()` is reduced to returning the object rather than building half of it lazily on first access.

#### Action Bars — A Page Change Left The Buttons Behind

- **Fix** — Paging swapped the actions but never repainted the buttons. The `ACTIONBAR_PAGE_CHANGED` / `UPDATE_BONUS_ACTIONBAR` / shapeshift branch refreshed cooldown, glow and empty-slot visibility and nothing else; the actual repaint was left to the `hooksecurefunc("ActionButton_Update", ...)` installed in `actionbars_public.lua`, which is guarded by `if ActionButton_Update then` — a global that no longer exists on modern retail, so the hook was never installed and the repaint never happened. The branch now runs the same trio `OwnedButton_PostDrag` uses after a drag — `SafeUpdate`, `SkinButton` with the cached size invalidated, `UpdateButtonText` — guarded on combat because `SkinButton` resizes and re-anchors regions.
- **Fix** — `UPDATE_OVERRIDE_ACTIONBAR` was never registered at all. That is the event for the bar a vehicle, a skyriding mount or a druid's Flight Form puts you on, so the module simply never learned the page had changed. It is now registered, and routed to the paging branch rather than to the `UPDATE_VEHICLE_ACTIONBAR` branch below it: that branch only schedules a visual rescan, while paging also rebuilds the slotMap, which is what an override swap actually needs — the buttons point at different slots.
- **Fix** — `UPDATE_VEHICLE_ACTIONBAR` had the same gap for the same reason and now re-enters the handler through the paging path, so a vehicle swap rebuilds the slotMap and repaints instead of leaving both stale behind a visual rescan.
- **Fix** — With "hide empty slots" on, those same swaps turned the buttons invisible rather than stale, and unticking the option made it go away entirely — which is what pointed at the cause. The secure snippet sets each button's action attribute during the swap, but the Lua-side `button.action` that `GetSafeActionSlot` reads is only synced afterwards, so a repaint in the same tick judges every button against the previous page's slots, finds them empty and has `UpdateEmptySlotVisibility` set alpha 0. Nothing re-evaluated afterwards, which is why only `TUI_RefreshActionBars` or a `/reload` brought them back. The repaint now runs immediately and again on the next frame, the same `C_Timer.After(0, ...)` idiom `OwnedButton_PostDrag` already uses after a drag, with the settings re-read rather than captured so a page swap that crosses a profile change does not repaint from the wrong table.

#### New: Totem Bar

- **New** — A totem bar. It shows the totems you currently have out, ordered by your class's own slot priorities, each icon carrying the time it has left and a cooldown sweep running down it. Right-click an icon to dismiss that totem. The bar hides itself entirely when nothing is out.
- **New** — Blizzard's own `TotemFrame` is stood down while the bar is enabled — its events unregistered, its alpha zeroed, its buttons made non-interactive — and handed back intact the moment the bar is switched off, rather than being permanently broken.
- **New** — Registered as a "Totem bar" entry in `/tm layout` like every other HUD element. The overlay keeps the frame visible and labelled while unlocked even with no totems out, so it can be placed before a single totem is ever cast; the container is given a minimum grab size for the same reason.
- **New** — Configurable icon size, spacing, border thickness, icon zoom, grow direction, and the duration text's font size, colour, anchor and offset, plus the cooldown swipe's colour and whether it draws at all. Defaults are lifted from Tui's own, in `Core/Database.lua` beside every other module's, so the profile engine and the reset paths see them like any other setting.
- **New** — An enable checkbox and info note in Config → Action Bars → General, under a Totems section. It applies immediately, no reload. The totem bar is a separate module with its own database table, so the control writes to `TomoModDB.totemBar` directly rather than through the tab's `G`/`SetG` accessors, which target `actionBars.global`.
- **Note** — Off by default. Enabling it is a deliberate choice, not something that appears under a shaman on first login after an update.
- **Internal** — Ported from Tui's `actionbars/totems.lua` as written rather than retyped, every deviation marked `TOMOMOD:` so the next upstream revision is a replay of a handful of marks instead of a second reading of the whole file. It lives in `Modules/Interface/ActionBars/tui/`; the mover registration is TomoMod glue and is deliberately kept out of that directory so re-importing upstream never touches it.
- **Internal** — Secret-value handling follows the policy the rest of the ported code already uses: `Helpers.ApplyCooldownFromStart` tries the duration-object sink first and refuses the numeric `SetCooldown` path outright when any argument is a secret value rather than coercing it into a guess, and the class token behind slot priorities collapses to nil rather than being compared.
- **Internal** — Every secure-attribute write is gated on `InCombatLockdown`, with the deferred work replayed on `PLAYER_REGEN_ENABLED` — the dismiss-slot attributes, the container's mouse-enabling, and the layout pass all take that route.
- **Internal** — `Helpers` gains `ApplyCooldownFromStart` and the `GetGeneralFont` / `GetGeneralFontOutline` / `GetGeneralFontSettings` trio the ported file reads.

#### Action Bars — Pet And Stance Bars Could Not Be Laid Out

- **New** — The pet bar and the stance bar now get the same orientation dropdown, button-count slider and column slider as the eight action bars. They had been withheld on the stated assumption that Blizzard owns their button count and the module only positions them — but both go through the very same `LayoutNativeButtons` path as everything else and read the very same layout keys, so the controls did nothing but hide settings that were already live.
- **Change** — The ceiling for both is ten slots rather than twelve, matching what those bars actually carry. The stance bar additionally clamps `iconCount` to the number of forms the class actually has, so setting it above that is harmless.

#### Loot Tables — Season 17

- **New** — The dungeon and raid loot tables are regenerated for Season 17 (WoW 12.1.0, build 69273) from the KeystoneLoot dataset of 2026-08-12. The dungeon rotation turns over completely: the Season 16 keys (161, 239, 402, 556-560) are gone and eight new ones take their place — Kings' Rest (249), Temple of Sethraliss (250), Ruby Life Pools (399), The Blinding Vale (584), Void Scar Arena (585), Nalorakk's Lair (586), Murder Row (587) and Altar of the Fangs (588).
- **New** — The raid tables follow the same turnover: the four previous instances are replaced by Tidebound Grotto (journalInstanceId 1317) and Venomous Abyss (1320), nine encounters between them, with the two final bosses carrying their extra mythic-only drops as before.
- **New** — `ItemClasses.lua` is regenerated from the same dataset run, 363 entries covering every one of the 346 distinct item IDs the new loot tables reference. An item with no entry is unrestricted, which is how cloaks, rings and universal trinkets have always been recorded.
- **New** — `TLD.dungeonTeleports`, the teleport spell IDs KeystoneLoot ships alongside the loot tables, carried over by the generator.
- **Note** — Season 16 loot is not kept alongside Season 17. The tables are keyed by MapChallengeModeID and ejEncounterID, and last season's keys no longer appear in either rotation, so retaining them would only grow the file.

#### Mythic+ — Teleports For The New Rotation

- **New** — The five Season 2 rotation dungeons are added to `DataKeys.lua` with names, short codes and teleport spell IDs: The Blinding Vale, Void Scar Arena, Nalorakk's Lair, Murder Row and Altar of the Fangs.
- **Fix** — Kings' Rest and Temple of Sethraliss had `nil` where their teleport spell should be, so the tracker had no teleport to offer for either even though both are in the rotation. Both are filled in.
- **Internal** — The teleport IDs are cross-checked between the two files that now carry them: all eight dungeons in the loot data resolve to a `DataKeys` row, every dungeon has a teleport and every teleport has loot data, and the spell IDs agree on both sides.
- **Internal** — `Data.lua`'s header no longer claims `Loots.lua` consumes `TLD.dungeonTeleports`; nothing reads that table. The teleports the addon actually uses come from `DataKeys.lua`, which is maintained by hand, and the generated copy is documented for what it is — an auto-refreshed cross-check where `DataKeys` is the stale side if the two ever disagree after a season update.
- **Internal** — The generator emitted its dungeon and raid comments in German, having been run against a German client. They are translated, with the English name kept in parentheses on the two raids so the journal instance is searchable either way.

#### Mythic+ — A Diagnostic Command Nothing Could Reach

- **Fix** — `/tmt keysync` now runs the key-sync diagnostic. `KeySync.Debug` existed, and the comment directly above it in `KeySync.lua` even documented the slash command it was meant to serve, but no branch of the `/tmt` handler ever routed to it — so the one tool for telling a silent transport apart from a lookup that simply never matched was unreachable from in game.
- **New** — `keysync` is listed in `/tmt help` in all six languages.
- **Fix** — While auditing that help text against the handler, two older gaps turned up and are closed with it. `reset` had never been listed in any language despite being a working command since the tracker shipped, and the French string was missing `key` and `kr` as well — so a French player reading `/tmt help` was told about four commands out of seven. All six languages now list all seven, in the order the handler tests them.

## ####################################

## CHANGELOG 3.5.2 — Three Faults That Shipped With The Action Bar Rebuild And Share One Cause Between Them, Which Is Writing Code Against What The API Used To Return Rather Than Against What It Returns Today: The Icon Texture Was Tested For Being A Path When Retail Has Handed Back A Numeric File ID For Years, So Every Real Icon Failed A Check Written To Catch Empty Ones And Was Cleared, Leaving A Row Of Black Squares Where The Bar Had Been; The Usability Tint Was Written Onto The Icon's Own Vertex Colour, Which Is A Slot Blizzard Also Writes On Its Own Schedule, So The Two Sides Overwrote Each Other In Whatever Order They Happened To Run And The Tint Froze After A Reload Until A Mouseover Shook It Loose, Fixed By Multiplying The Colour Through A Separate Texture That Belongs To TomoMod Instead Of Fighting For A Field That Does Not; And The Skin Kept Painting While The Bar System It Is A Layer On Top Of Was Switched Off, Reaching Through Its Own Name-Lookup Fallback Onto Blizzard's Untouched Buttons, Which Is Now Refused At The Door Because The System Was Finally Asked Whether It Was Running — And Then, With The Bars Working Again, The Ground Is Prepared For What Comes Next: The Nine Files Leave The QOL Pile They Had Never Belonged In And Take Their Place In Interface Beside The Unit And Raid Frames, Carrying Their Own Load List Rather Than A Block Of Lines In Somebody Else's, And Beside Them Lands A Compatibility Layer Whose Entire Purpose Is To Let A File Lifted Out Of Tui Run Here Untouched — One Namespace Table Handed To Ported Code Because TomoMod Never Adopted The Second-Vararg Convention Those Files Are Written Against, The Error, Debug And Registry Machinery Carried Over Verbatim So Upstream Changes Stay Diffable, And Everything With A TomoMod Equivalent Deliberately Not Carried Over But Bridged To What Is Already Here, Which Is Why Four Helper Functions Replace Sixteen Hundred Lines And Two Border Functions Replace Three Thousand: Nothing In This Release Calls Any Of It Yet, And That Is The Point Of Landing It On Its Own — And Then, With The Layer Standing, The Module It Was Built For Follows It Over In Two Lots, Fourteen Files And Eight Thousand Four Hundred Lines Carried Across Rather Than Retyped, Every Single Deviation Marked So That The Next Upstream Revision Is A Replay Of A Handful Of Marks Instead Of A Second Reading Of The Whole Thing, Held Behind One Switch That Nothing In This Release Flips, And Bringing With It The One Thing The Previous Release Had To Ship Without And Say So In Writing: Flyouts That Open On A Button TomoMod Made Itself — And Then The Switch Is Thrown: The Nine Files That Had Driven The Bars Since 3.5.1 Are Deleted Outright, Skinning And Mouseover Fade And The Edit-Mode Overlays Land As The Last Three Files Of The Set, Masque Is Supported For Anyone Who Wants It, The Hundred And Six Click Bindings Go Away Because The New Buttons Borrow The Keys You Have Already Bound To Blizzard's Own Commands Rather Than Asking You To Bind Anything A Second Time, And The Options Page Stands Down To A Single Notice Until Lot P5 Rebuilds It Against The Schema The Ported Module Actually Reads — Which Is The Honest Order To Do This In, Because Working Bars With Settings That Are On Their Way Back Beats A Full Options Page Wired To A System That No Longer Exists — And Then Lot P5 Closes The Sequence By Giving Them Back: The Ported Module's Own Defaults Are Lifted Into TomoMod's Database Rather Than Left Living Inside The Module, So The Profile Engine, The Reset Paths And The Options Page All See Them Like Any Other Setting, And The Page Returns As Five Tabs Written Against The Keys The Bars Genuinely Read Instead Of Forty-Five Widgets Writing Into A Schema Nothing Consults — With One Cost Stated Plainly Rather Than Buried, Which Is That The Old Bar Settings Are Dropped Instead Of Translated, Because The Two Schemas Share Neither Names Nor Nesting Nor Meaning For The Handful Of Keys That Merely Look Alike, And A Guessed Equivalence Would Hand The Player A Layout They Never Chose And Could Not Trace Back To Anything, Which Is Worse Than A Clean Default — And Then, Away From The Bars Entirely, The Chat Copy Window Stops Being A Scroll Frame Wrapped Around A Plain Edit Box And Becomes The Same Presentation Everything Else In The Chat Skin Already Uses, With A Real Scrolling Edit Box That Holds Five Hundred Lines Where The Old One Capped At A Hundred And Twenty-Eight, Select All And A Resize Grip And Text Already Highlighted And Scrolled To The Bottom The Moment It Opens, A Themed URL Prompt In Place Of Blizzard's Grey Dialog, And A Copy Button On The Chat Window Itself That You Can Have Always, On Mouseover, Or Not At All

#### Action Bars — The Icons Came Back Black

- **Fix** — `RenderIcon` cleared the texture on every button that had one. `GetActionTexture` returns a numeric file ID in retail, not a texture path, and the guard tested `type(texture) == "string"` — so a perfectly good icon failed the check written to reject empty ones, the texture was set to nil and the button was hidden, which draws as a black square. A new `IsUsableTexture` accepts a non-zero number as readily as a non-empty string, and both the engine's value and the direct fallback go through it.
- **Internal** — The direct `GetActionTexture(slot)` fallback is wrapped in `pcall` like every other game read in this module. It was the one call in the render path still made bare.

#### Action Bars — The Tint Stopped Fighting Blizzard For The Same Field

- **Fix** — Out of range, out of mana and unusable stopped updating after a reload or a bar swap, and a mouseover would put them right. `ApplyIconTint` wrote `SetVertexColor` on the icon, which is exactly where Blizzard's own `ActionButton_UpdateUsable` writes: whichever ran last won, so the tint was correct or frozen depending on execution order rather than on state.
- **Change** — The tint is now a separate texture of TomoMod's own, sitting over the icon in `MOD` blend mode. Multiplying the icon through it produces the same result a vertex colour would, on a widget Blizzard has no reason to touch, so there is nothing left to arbitrate. Normal is the overlay hidden rather than a colour written, which means the common case costs nothing.
- **Note** — The overlay resets the icon's vertex colour to white the first time it is created, so a button carrying a stale tint from before this release is cleaned up on its first repaint. No settings need clearing.

#### Action Bars — The Skin Stayed Inside Its Own Fence

- **Fix** — With the action bar system disabled, the skin carried on skinning. Its `_G[prefix .. i]` fallback finds Blizzard's buttons by name whether or not TomoMod has taken them over, so turning the bar system off left the skin repainting frames it had no business touching. `SkinButton` now refuses to run unless both the skin and the bar system are on.
- **Internal** — `ActionBars.lua` exports `IsEnabled` on `TomoMod_ActionBars` for this. The skin is a layer over the bar system rather than a feature beside it, and until now it had no way of asking whether the thing underneath it existed.

#### Action Bars Moved Into Interface

- **Internal** — The nine action bar files move from `Modules/QOL/ActionBars/` to `Modules/Interface/ActionBars/`. They were filed under QOL because that is where the skin started, and they have not been quality-of-life tweaks since 3.5.1 turned them into a subsystem with an engine, five layers and its own secure buttons. Interface is where the unit, party and raid frames live, and this belongs with them.
- **Internal** — The bars now carry their own `ActionBars.xml` rather than nine `<Include>` lines inside `QOL.xml`, which is how every other Interface module is loaded. Load order within the module is unchanged: `ActionBars.lua` first, then the button and engine layers, and the skin last.
- **Note** — No file content changed in the move, so the three fixes above travel with it. `Bindings.xml` sits at the addon root and is found by the client rather than by a path, so nothing there needed adjusting.

#### TUI Compatibility Layer — Groundwork, Lot P1

- **New** — `Core/TuiCompat/` is nine files that let a module lifted from Tui run inside TomoMod without being rewritten first. It is loaded ahead of every module in the `.toc`, because anything ported reaches for it at file scope.
- **Internal** — `Namespace.lua` is the reason the rest is possible. Tui's files expect a shared table arriving as the second vararg of an addon chunk — `local ADDON_NAME, ns = ...` — a convention TomoMod has never used. One table is built here and handed over explicitly, carrying the locale bridge, the no-op perf registry those files append to and never read, and the shared-media handle.
- **Internal** — `SafeCall.lua`, `DebugGate.lua` and `Registry.lua` are carried over verbatim apart from the namespace line and one chat prefix. Keeping them byte-similar is deliberate: it is what makes a future upstream change a readable diff instead of an archaeology exercise.
- **Internal** — Everything with a TomoMod counterpart is bridged rather than imported. `Helpers.lua` is four entry points written against TomoMod where upstream spends 1663 lines, `UIKitShim.lua` is the two border functions the ported bar code actually calls where upstream's `uikit.lua` is 3177 lines carrying a scale registry nothing here wants, and `Bridges.lua` routes anchoring and move mode straight to TomoMod's own `FrameAnchors` and `Movers`.
- **Internal** — The compat DB adopts Tui's `db.global` / `db.bars` shape. TomoMod's profile engine swaps module tables in place under `TomoModDB`, so the active profile at runtime *is* `TomoModDB` and a ported module finds its keys where it expects them. Migrating the existing TomoMod keys onto that shape is lot P5.
- **Note** — Nothing in TomoMod calls any of this yet, and that is what makes it safe to land on its own: the layer is built, verified to load, and left unwired until the ported modules arrive. `IconSkin` and `IconGlow` additionally expect the icon skin textures under `Assets/iconskin/`, which are not shipped here and must be copied across before lot P4 turns skinning on.

#### Ported Action Bars — The Core, Lot P2

- **Internal** — Eight files land in `Modules/Interface/ActionBars/tui/`, 4920 lines: the core, the helpers, the layout pass, the container builder, the per-bar builders, the event layer and the public surface, carried over from Tui's action bar module rather than rewritten against it. Every line that had to change carries a `TOMOMOD:` marker, and there are remarkably few of them, which is the whole point — a newer upstream revision is re-imported by replaying those marks rather than by reading eight thousand lines a second time and hoping to spot what moved.
- **Internal** — `actionbars_env.lua` is what makes *verbatim* affordable. Upstream declares most of its module at file scope, which in Lua means globals, and TomoMod's linter and its own conventions say otherwise. Rather than a rename pass across every file — which is exactly the kind of edit that introduces bugs the original does not have — the port installs a `setfenv` chunk environment shared by the whole module: a name declared inside it resolves inside it, anything else falls through to `_G` as before, and nothing leaks into the global table.
- **Internal** — Five helpers were added to the compat layer for this lot: a weak-keyed state table, the core handle, and the three secret-value probes the ported code calls. `Namespace.lua` gains `TUI_ACTIONBARS_READY`, the single switch the entire module hangs off, and the perf-probe toggle those files read and never write.
- **Note** — The bars on your screen are still the ones from the section above. The ported module is loaded, parsed and inert, and it stays that way until lot P4 flips the switch. Landing something this size and turning it on in the same release is how you end up unable to say which of the two broke the bars.

#### Ported Action Bars — The Layers That Draw, Lot P3

- **Internal** — Six more files, 3481 lines: cooldowns, usability, glow, pet and stance, the extra action and zone ability buttons, and flyouts. Same rules as P2, and `ActionBars.xml` now loads the module in the order Tui's own TOC declares rather than in the order that reads well — the per-bar builders load last and the event layer before the extra buttons, and both of those matter.
- **New (dormant)** — Flyouts. 3.5.1 shipped TomoMod's own secure buttons and had to name flyouts as the one thing they could not do: a mage portal or a hunter trap on a converted bar would simply not open, because the native path errors on an addon-made secure button and the alternative is several hundred lines of secure snippets that cannot be tested outside the game. Those lines are now here — a secure flyout of the module's own, built once and reused, its buttons skinned and their cooldowns driven, and Blizzard's own flyout restyled to match for the slots that still belong to it.
- **New (dormant)** — The extra action button and the zone ability get holders of their own, a saved position with a nudge control, and the hooks needed to stop Blizzard quietly putting them back where it would rather have them.
- **Internal** — Cooldowns arrive with the charge sweep and the loss-of-control sweep as widgets of their own, batched so that a bar-wide refresh writes once instead of per button, and fed through duration objects from end to end: no remaining time is ever read in order to decide anything. Usability paints its tint on an overlay texture it owns rather than on the icon's vertex colour — the same conclusion the fix at the top of this release arrived at independently, from the other direction.
- **Internal** — Four more compat helpers: `FrameMutationRestricted`, which fails closed by treating a frame it cannot prove unprotected as protected, two secret-value coercions, and the skin accent colour, which answers with the brand colour until lot P5 wires the real setting.
- **Note** — Editmode, skinning and mouseover are the three files still absent from the set, and they are lot P4 along with the switch itself. One thread does come alive before then: the hook that restyles Blizzard's spell flyout attaches when `Blizzard_ActionBar` loads, which is outside the gate.

#### Ported Action Bars — The Switch Is Thrown, Lot P4

- **Change** — `TUI_ACTIONBARS_READY` is on, and the ported module owns the action bars. The nine files that had driven them since 3.5.1 — `ActionBars.lua`, the engine, the five layers built on it and the skin — are deleted rather than left switched off, because two systems that both believe they own the same buttons is not a state worth shipping to find out about. The gate stays in the code as a kill switch.
- **New** — The last three files of the set land with it: skinning, which strips Blizzard's artwork and draws the button itself down to the macro, count and cooldown text; mouseover fade, per bar, with the spellbook kept visible while it is open; and the edit-mode overlays, which also carry the paging condition and the override bindings.
- **Change** — `Bindings.xml` and its 106 `CLICK TomoModAB_*` entries are gone, and nothing replaces them. The ported buttons read the keys you have already bound to Blizzard's own commands and override-bind those onto themselves — so a bar you had bound before this release keeps working with no action from you, and the keybinding window goes back to one entry per action rather than two. A key already claimed by something else is left alone rather than stolen.
- **New** — Optional Masque support, through a bridge that is a no-op when Masque is not installed. The group registers as `TomoMod`.
- **Change** — The Action Bars options page is a single notice for this release. Every control on it drove `TomoMod_ActionBars` and its layers, which no longer exist, so the page would have been forty-five widgets writing to a schema nothing reads. It says what is happening and offers the move-mode button; lot P5, below, rebuilds it against the schema the ported module actually uses.
- **Internal** — `Helpers.DeferredHideOnShow` is added for the skinning layer, combat queue included: `Hide()` on a protected frame is refused in combat, so the call is parked until `PLAYER_REGEN_ENABLED` rather than dropped on the floor. `Core/Init.lua` no longer initialises `ActionBarSkin`, which is the last reference to the old system anywhere in the addon.
- **Note** — What has not moved yet is the settings themselves. The bars come up on the ported module's own defaults, not on the values you had set in 3.5.1, because the two schemas are not the same shape and converting one into the other is lot P5. What that migration decided to do with the old keys is the section below.

#### Ported Action Bars — The Settings Come Back, Lot P5

- **New** — The Action Bars options page is rebuilt against the schema the ported module actually reads, and the notice from P4 is gone. Five tabs: General for the buttons themselves, Texts for what is written on them, Indicators for the states they show, Fade for mouseover fading, and Bars for the per-bar layout. It is written against `TomoModDB.actionBars.global`, `.bars[key]` and `.fade` rather than against anything of its own.
- **Internal** — The panel only exposes per bar what genuinely differs per bar. A per-bar key left nil means "inherit the global one", which is exactly how `GetEffectiveSettings` merges the two, so the Bars tab carries button count, growth direction, size and position and nothing else. Duplicating the global controls on every bar would have written explicit values that then stopped following the global setting, which is the opposite of what a per-bar override is for.
- **Internal** — Every control re-applies through `TUI_RefreshActionBars` — or `TUI_RefreshActionBarFade` for the fade tab — rather than reaching into the ported module. That single entry point is the module's public re-apply surface, and going through it is what keeps the panel diffable against upstream instead of coupled to its internals.
- **Internal** — The ported module's defaults are lifted out of Tui and into `TomoMod_Defaults.actionBars` in `Core/Database.lua`. They belong in the database, not inside the module: the profile engine, the per-module reset paths and the options page all read defaults from there, and a module that keeps its own is a module those three cannot see. Around three hundred lines of defaults, which is the size the settings surface of a five-layer bar system actually is.
- **Change** — The old `actionBars` table and `actionBarSkin` are dropped from every profile on first login after this update, and the bars come up on the new defaults. This is a deliberate loss of your bar settings, not an oversight. The two schemas share neither key names nor nesting, and the few keys that look alike do not mean the same thing — translating them would mean guessing at equivalences that mostly do not hold, and a wrong guess produces a layout you never chose and cannot trace back to anything. A clean default is the better failure.
- **Internal** — The migration replaces the table with a `CopyTable` of the new defaults rather than nilling it. Migrations run *after* `MergeTables`, so a nil would leave the table empty for the rest of the session and only fill in on the next login — the bars would have come up unstyled exactly once, for everyone, on the update that was supposed to fix them.
- **Internal** — `Helpers.CreateDBGetter` now seeds from the real defaults when a module table is missing instead of handing back an empty one, and guarantees `db.fade` alongside `db.global` and `db.bars`. An empty table is not a neutral starting point here: it means buttons with no size, no font and no colour, which reads on screen as a rendering bug rather than as a missing database.

#### Chat — The Copy Window Rebuilt On The TUI Presentation

- **New** — `Modules/QOL/Skins/ChatCopy.lua`, ported from Tui's `chat/copy.lua`, replaces the ScrollFrame-plus-EditBox window the chat skin had been carrying. Real `ScrollingEditBoxTemplate` with a `MinimalScrollBar`, brand-accented flat surface, Select All and Close, a resize grip, and the text already highlighted and scrolled to the end when it opens. The legacy widget path is kept as a fallback for clients that do not have the template.
- **New** — A copy button on the chat window itself, in three modes: always visible, on mouseover, or hidden. It defaults to mouseover, and existing profiles are seeded with that value by a migration rather than left to a nil fallback, so the dropdown in Skins → Chat Frame has something concrete to show.
- **Change** — The extraction cap goes from 128 lines to 500. Blizzard keeps up to a thousand per frame and the scrolling edit box handles far more text than the old one did; the cap stays bounded because concatenating an unbounded buffer on a click is a hitch you can see.
- **Change** — The URL prompt is themed to match rather than being Blizzard's `StaticPopup`. It is the same window you were already looking at, which is the point.
- **Internal** — Only the presentation and the message cleaner are ported. The line source stays TomoMod's — `GetMessageInfo()` on the live chat frame — because Tui reads its own `MessageStore`, which TomoMod does not have and did not need to grow in order to take the window. `ChatFrameSkin.lua` loses about a hundred and eighty lines and keeps only the entry points.

## ####################################

## CHANGELOG 3.5.1 — The Action Bars Were Skinned By A Module That Repainted Every Button Five Times A Second Whether Or Not Anything Had Changed, Which Is The Shape You End Up With When A Skin Grows Into A Feature Set Without Ever Being Given A Place To Keep State, So The Whole Row Is Rebuilt Around One Engine That Owns The Question "What State Is This Button In" And Answers It From Events Rather Than From A Ticker, Diffs Every Value Before Telling Anyone, And Reads The Game Through An Adapter So Nothing Downstream Knows Or Cares Whether The Frame Underneath Belongs To Blizzard Or To TomoMod — And Then Five Layers Are Built On Top Of It That Could Not Have Existed Before, Icons And Cooldowns With A Choice Of Who Draws The Sweep, Proc And Rotation Glows That Coexist On The Same Button Because Each Owns Its Own Key, Hotkey Text Resolved From The Binding Itself Instead Of Scraped Off Blizzard's Fontstring So It Still Works On A Button Blizzard Never Made, The Stance And Equipped And Autocast States The Engine Had Tracked Since The First Day And Nothing Had Ever Drawn, And Finally Real Secure Buttons Of TomoMod's Own Behind A Per-Bar Opt-In That Is Reversible With A Reload, With A Hundred And Six Click Bindings Shipped To Make Them Bindable And A Binding Mode To Assign Them On The Bars, Which Joins Any Other Addon's Shared Binding Mode When One Is Present Because The Library That Arbitrates It Is Now Embedded Rather Than Hoped For

#### Action Bars — One Engine Instead Of A Ticker

- **Internal** — `Modules/QOL/ActionBars/AB_Engine.lua` is new, and it is the single source of truth for what state an action button is in: registration, adapters, event wiring, diffing and dispatch. Everything else in this release is a consumer of it. Building it first is what made the rest of the release small.
- **Change** — The global 0.2s `OnUpdate` in `ActionBarSkin.lua` is gone. It pushed `SetVertexColor` onto every button five times a second regardless of whether anything had changed. State now arrives on events, and consumers are called only when a value actually differs from the one before it.
- **Note** — Range is the one thing that still needs a ticker, because no event exists for it. That ticker is gated on actually having a target, so it costs nothing while you are not fighting anything.
- **Internal** — The engine never assumes the frame underneath is a Blizzard button. An adapter turns a frame into raw state, which is why the TomoMod-owned buttons further down this release register through the *same* `action` adapter and inherit every layer built on top without a line of special-casing.
- **Note** — Every game read goes through `pcall` and every boolean is resolved inside the protected call, so a value the client withholds degrades to *unknown* rather than throwing. No arithmetic is ever performed on a value that came from the game. This is the same discipline 3.4.5 and 3.4.6 established elsewhere in the addon, applied here from the start rather than retrofitted.

#### Icons And Cooldowns — Choosing Who Draws The Sweep

- **New** — `AB_Render.lua` owns the *content* of a button: icon texture and crop, cooldown, charge and stack count, macro name. The chrome — background, border, insets — stays with the skin, and the state stays with the engine. It never reads state itself; it only reacts to what the engine hands it.
- **New** — A cooldown source setting. **Blizzard** adopts the Cooldown widget the button already has and merely restyles it, so Blizzard keeps feeding it and nothing can break. **TomoMod** draws it instead, through the same secret-safe duration-object path CooldownForge uses. Blizzard is the default and stays the safer answer while the bars still ride on Blizzard buttons; TomoMod's is what the owned buttons need, and it ships opt-in so it can be proven before anything depends on it.
- **New** — Cooldown numbers with their own font size, swipe colour and opacity, edge and bling toggles, charge and stack text with its own size, optional macro name, desaturation on unusable actions, and an icon crop slider that goes down to no crop at all.
- **Note** — Durations and charge counts are withheld values in Midnight. They are never compared and never used in arithmetic — they go straight into a C-side sink, `SetCooldownFromDurationObject` for spells and `SetText` for counts. Whether a cooldown is actually running is settled by feeding the object and then reading the widget's own `IsShown` back, which is the *detect-don't-test* pattern 3.4.6 arrived at.

#### Glow — Two Sources That Can Both Be On At Once

- **New** — `AB_Glow.lua`, with two independent glow sources: the classic proc highlight, and the Midnight rotation recommendation from `C_AssistedCombat.GetNextCastSpell`. Each has its own style, colour and LibCustomGlow key, which is what lets both sit on the same button without one clearing the other.
- **New** — Five styles for each — Pixel, Autocast, Button, Proc and Blizzard — with line count, thickness and animation speed for the pixel variant.
- **Change** — Matching runs on spell ID through the engine's cached content, so a macro that resolves to a spell glows exactly as the bare spell does, and a talent-morphed spell is matched through its override ID too.
- **Note** — The rotation glow is off by default and needs the Assisted Highlight to be available on your character. Blizzard draws that highlight on its own buttons; TomoMod-owned buttons do not get it for free, which is the reason this exists.
- **Internal** — The call conventions and the Blizzard-overlay suppression are deliberately identical to `CDMProcGlow.lua`. Two copies is the honest state today; they should collapse into one shared helper when ForgeLib lands, and writing them identically is what will make that a deletion rather than a merge.

#### Hotkeys — Resolved From The Binding, Not Scraped Off A Fontstring

- **New** — `AB_Hotkey.lua` owns the keybind text on every button: show or hide, font size, colour, one of seven anchor positions, offsets, abbreviation, and hiding the text on empty slots.
- **Change** — The binding is resolved through `GetBindingKey` on the canonical binding name rather than read off Blizzard's `HotKey` fontstring. A TomoMod-owned button has no such fontstring to read, so going to the source is what makes one code path serve both. Blizzard's fontstring is kept as a fallback, so an unexpected binding name in a future patch degrades instead of showing nothing.
- **New** — A binding mode: hover a button, press a key. Right-click or Escape clears the slot, and it refuses to open in combat.
- **Internal** — Bind-on-hover never touches the buttons' own scripts. It builds its own overlay frames on top and destroys them on exit, so no `OnEnter`/`OnLeave` handler is ever installed on a secure button.

#### Stances, Pet And States — Things The Engine Knew And Nothing Drew

- **New** — `AB_Special.lua`. The engine has tracked *active*, *equipped*, *autoCastAllowed* and *autoCastEnabled* since the first commit of this release, and nothing ever drew any of them: the skin kills Blizzard's equipped border and flattens the checked texture to a barely visible white wash. So on a skinned bar you could not see which stance you were in, which weapon-enchant item was equipped, or which pet ability was on autocast.
- **New** — An accent ring for the active action and for equipped items, each with its own colour and a shared thickness, on one ring with a priority so two states never stack into visual noise.
- **New** — An autocast shine on its own LibCustomGlow key, so it coexists with the proc and rotation glows rather than competing with them.
- **New** — Optional auto-hide for the pet bar when you have no pet. It extends the container's *existing* visibility driver condition rather than registering a second one, because two drivers calling Show and Hide on the same frame fight each other.
- **Note** — There is no stance auto-hide, and that is a limit rather than an omission. No macro conditional expresses *this class has no forms* — `[stance:0]` means "no form active", which a druid in caster form legitimately is. Blizzard's stance buttons already hide themselves when there is nothing to show, so the container is simply empty.

#### TomoMod's Own Buttons — Opt-In, Per Bar, And Reversible

- **New** — `AB_Button.lua` creates real `SecureActionButtonTemplate` buttons owned by TomoMod, as an alternative to reparenting Blizzard's. Opt-in per bar, off everywhere by default, and reversible: untick the option, `/reload`, and the bar goes back to Blizzard buttons.
- **Note** — Everything from the five layers above works on them unchanged, because they register with the engine through the same `action` adapter — it reads `frame.action` and falls back to `GetAttribute("action")`, and these buttons set only the attribute. That is what building the engine first bought.
- **Internal** — The secure plumbing is not reinvented. `ActionBars.lua` already owns a working paging setup, and these buttons receive the same attributes Blizzard's do. The action slot is taken from the Blizzard counterpart button rather than hardcoded, since slot ranges have moved between expansions; the hardcoded table is only a fallback for when the counterpart is missing.
- **New** — `Bindings.xml` ships 106 click bindings so the owned buttons are bindable from Blizzard's own keybinding UI, under a TomoMod category with a header per bar. They bind through a dedicated virtual mouse button rather than `LeftButton`, which is what makes cast-on-key-press behave — Bartender4 moved away from `LeftButton` for the same reason.
- **Fix** — Releasing a bar left a delegation in place. `delegated` and `pendingDelegation` were declared below `ReleaseBar`, so the reference inside it resolved to a global rather than to the real table, and the delegation was never undone. They are declared next to `owned` now, which is what binds that reference correctly.
- **Note** — Read this before enabling a bar. Flyouts do not open on a converted bar — mage portals, hunter traps, summon flasks. Vehicle, override and possess *paging* follows, but the specialised vehicle exit button and its artwork do not. The Assisted Highlight is not drawn; use the rotation glow above instead. Pet and stance bars stay on Blizzard buttons entirely.

#### Binding Mode — Shared With Whatever Else Is Installed

- **New** — `AB_KeyBound.lua` joins the shared binding mode that Dominos, Bartender4 and Bagnon use, so one pass binds TomoMod's bars and theirs together instead of each addon insisting on its own mode.
- **New** — LibKeyBound-1.0 is embedded, so the shared mode is available whether or not another addon provides it. The copy is taken from a packaged build rather than from the GitHub mirror, which is an SVN mirror whose revision number is computed from a keyword that is never substituted outside a checkout — it throws on an arithmetic operation the moment it is loaded from a plain copy.
- **Internal** — The proxy pattern is lifted from Dominos: rather than mixing six library methods into every action button, one hidden frame carries them and is reparented onto whichever button the mouse is over. The library only ever talks to that frame.
- **Fix** — `FreeKey` had to be provided rather than left to the library's default. Without it the library compares `GetBindingAction(key)` against `CLICK <name>:LeftButton`, which for TomoMod is neither the right button name — it would be the proxy's — nor the right virtual button, so every key would have been reported as stolen from somewhere else.
- **Internal** — `GetName` is forwarded to the real button for the same reason: the library prints the button's name when it confirms a binding, and the proxy's own name would have been meaningless there.
- **Note** — All binding reads and writes go through `AB_Hotkey.GetBindingName`, so this works identically on TomoMod-owned buttons, which bind through their own click command, and on reparented Blizzard ones, which bind through the `ACTIONBUTTON` and `MULTIACTIONBAR` names.

#### Options — The Page Grew Three Tabs

- **Change** — The Action Bars page is now five tabs rather than two: Skin, Buttons, Glow, Hotkeys and Bars. The skin tab had been accumulating every new control in one column, and three of the five layers in this release would have landed in it.
- **New** — 57 new strings across all six languages for the controls above.

## ####################################

## CHANGELOG 3.4.6 — The Invisible Marker That 3.4.5 Attached To Every Cooldown Studio Buff Icon Was Asked The One Question It Could Not Be Asked, Because Whether An Aura Button Is On Screen Is Not A Fact About The Interface At All But The Aura Presence The Client Is Withholding Wearing A Frame's Clothes, So The Boolean That Came Back Was Itself Hidden And Testing It Threw From Inside The Very Guard Written To Make The Studio Safe, On The First Icon Probed Rather Than Occasionally, Which Means The Feature Shipped In 3.4.5 Errored For Anyone Whose Bars Track A Buff, And The Answer Is Not A Better Guard Around A Value That Cannot Be Read But A Different Widget Entirely — The Studio's Own Cooldown, Which The Engine Already Drives And Which Belongs To TomoMod Rather Than To The Client, So Its Shown State Is Ordinary Data And Says Exactly The Same Thing The Refused Boolean Would Have Said, With The Engine's Button Kept Behind It As A Guarded Fallback And A Plain False When Neither Side Will Answer, Costing That Frame Its Presence Reading And Nothing Else Because Driving The Swipe Was Always The Larger Half Of The Probe's Job

#### Cooldown Studio — The Probe Asked A Frame Question And Got An Aura Answer

- **Fix** — Buff icons in the Cooldown Studio threw on the first icon probed. `AC.ProbeActive` decided whether a tracked buff was up by calling `IsShown` on the engine's aura button, on the reasoning — written into the comment above it — that this was a frame query rather than an aura read. It is not. Whether an aura button is displayed *is* the aura presence the client withholds, so the boolean handed back is itself hidden, and testing it as a condition is the operation that throws.
- **Note** — The `pcall` around the call was never the problem and never the fix. It caught nothing because nothing failed there: `IsShown` returned perfectly well, and the throw came one line later, from `(ok and shown)`. A hidden value has to be recognised *before* it is used, which is what `U.IsSecret` exists for.
- **Change** — The probe now asks its own Cooldown first. `AC.CreateAuraProbe` already receives the caller's Cooldown frame and hands it to the engine to drive; it is now kept on the probe as well. That widget belongs to TomoMod rather than to the client, the engine puts a swipe on it while the aura is up and takes it away when the aura ends, and its shown state is ordinary readable data — the same answer, from the side of the boundary where reading is still allowed.
- **Change** — The engine's button stays as a fallback rather than being removed, now behind the same guard. Both sides go through one small `readable` helper that returns nil for *unreadable*, which is a third answer distinct from false: a refusal is not a report that the aura is down.
- **Note** — When neither side answers the verdict is false, and that costs less than it sounds. The probe contributes no presence for that frame and goes on driving the swipe, which is its other and larger job — the icon keeps its countdown either way.

## ####################################

## CHANGELOG 3.4.5 — Patch 12.1 Hides A Unit's Class From Addons And Every Piece Of TomoMod That Painted Something Its Class Colour Went From Working To Erroring Four Hundred Times A Session, Sixteen Places That Each Read The Class And Looked It Up In Blizzard's Colour Table Are Replaced By Four Helpers That Ask Whether A Value Can Be Read Before Doing Anything With It, A Hidden Class Stops Taking The Frame Down And Falls Back To A Colour That Is Merely Less Specific, And Then The Fallback Turns Out Not To Be Necessary Most Of The Time Because The Class Token Can Be Handed Straight To A C Function And The Colour Handed Straight Out Of It Into A Setter Without Lua Ever Reading Either End, So Health Bars On Unit Frames And Nameplates And Party And Raid Frames Keep Their Class Colours On Exactly The Units A Dungeon Is Full Of, While Turning The Camera Stops Making Enemy Nameplates Disappear Because A Refused Aura Read Was Throwing From The Middle Of The Plate Update And Taking Everything After It Down, Two Guards That Looked Like They Covered That Call Turn Out To Have Covered Nothing Because An Argument Expression Runs Before The pcall Around It Does, And Eleven Aura Scanners Stop Each Discovering The Client's Refusal On Their Own Through Forty Protected Calls Apiece And Ask One Cached Question Per Frame Instead, Through An API Permissive Enough That A Refusal There Means Every Path Was Already Closed, While CooldownForge Stops Emptying Its Own Watch List On A Refused Rescan Because The Guard Sat Below The Two Lines That Clear It, And Nameplate Debuffs And Enemy Buffs Stop Being Absent For Most Of A Pull By Giving Up On Reading Auras Altogether And Letting The Client Do The Scanning And Sorting Itself Against A Container TomoMod Only Describes, Which Cannot Be Refused Because It Never Reads Anything, So The Whole Scan Path Is Deleted Rather Than Kept As A Fallback Nobody Would Ever Exercise, And Every Other Aura Row In The Addon Follows It Over — Unit Frame Auras And Target Buffs, Party HoTs, Raid Debuffs And Raid HoTs — With The Tracked Spell List Handed To The Client As A Candidate Filter Because Matching A Spell Id Is Exactly What Can No Longer Be Done, While The One Indicator That Looked Like It Could Not Move Turns Out To Move By Asking A Different Question Entirely — The Dispel Cue Stops Reading Each Debuff's Type To Decide Whether The Player Can Remove It, Which Only Ever Worked Out Of Combat, And Becomes An Icon The Client Itself Selects, So Not One Guarded Aura Scan Is Left On Any Frame Indicator, While The Cooldown Studio Gets What It Needs From The Engine Without Letting It Draw Anything — A Hidden Container Whose Single Invisible Button Drives The Studio's Own Cooldown, So The Swipe Is Right In Combat And Exactly One Thing Writes It — And The Damage Meter's Two Dropdowns Stop Opening With The Right Number Of Rows And No Text On Any Of Them

#### Auras And Classes — The Client Stopped Answering And Started Refusing

- **Note** — Patch 12.1 widened what the game will not let an addon read. A hidden value is not `nil`: it is live, and it throws the moment Lua compares it, indexes with it, concatenates it or tests it as a boolean. The guard has to run *before* the operation, which is why none of this could be fixed by wrapping things in `pcall` after the fact.
- **Fix** — Unit frame health bars threw on every update for any player whose class was hidden. `RAID_CLASS_COLORS[class]` refuses the lookup outright — *"attempted to index a table that cannot be indexed with secret keys"* — and it fired 399 times in a single session in the report that prompted this.
- **Internal** — Four helpers in `Core/Utils.lua` replace sixteen hand-written copies of the same three lines. `U.IsSecret` answers whether a value can be read at all; `U.SafeStr` returns a string or nil; `U.UnitClassToken` returns the class token or nil, preferring `UnitClassBase` because it hands back the token directly; `U.TryClassColor` returns the colour or nil.
- **Note** — `U.TryClassColor` returns nil rather than grey on purpose. Grey is a real colour a caller may legitimately want, and the callers disagree on what to do when the class is unknown — the health bar falls back to a faction colour, which is a far better answer than a grey bar.
- **Change** — Every site that used to read the class and index the colour table now goes through those helpers: unit frame and nameplate health, nameplate friendly names and role icons, castbars, party and raid and arena frames, the `class` text token on both frames and plates, the class reminder, the party keystone list, TomoScore's run data, and the tooltip skin.
- **Change** — Each site decides for itself what an unreadable class means, because the right answer differs. The class reminder treats unknown as *a beneficiary* — reminding someone who does not need a buff is a smaller failure than never reminding someone who does. The caster-NPC tint is skipped rather than guessed. The keystone list and TomoScore simply draw without a class colour. The tooltip keeps its default.
- **Fix** — The group leader crown. `UnitIsGroupLeader` can now return a hidden boolean, and testing one throws before the branch is even taken. Unknown hides the icon: a crown on a unit that may not be the leader is worse than no crown.

#### Class Colours — And Then It Turned Out The Fallback Was Rarely Needed

- **Note** — Falling back to a faction colour is correct and lossy. In a dungeon it is *every* group member, so the frames would have been permanently the wrong colour rather than occasionally.
- **New** — `C_ClassColor.GetClassColor` is C-side and accepts a hidden token. The colour object it returns has a C-side `GetRGB`, so the channels can go straight into another C-side setter — `SetStatusBarColor`, `SetTextColor`, `SetVertexColor` — without Lua ever reading either end. `U.ApplyClassColor` does exactly that and returns whether it worked, so the caller can fall back on `false` rather than guess.
- **Change** — Health bars on unit frames, nameplates, party frames and raid frames try that path first and only fall back to the old one when it refuses. The class colour survives a hidden class.
- **Note** — This works only where the colour goes directly into a setter. Anything that wants to darken, blend or compare has to read the numbers, and there the fallback is still the only answer. That is the technique's boundary, not an oversight.
- **Internal** — Each of those four call sites re-tests the same conditions the colour function it is short-circuiting would have tested, including the ones that take priority over the class branch — the nameplate path also checks focus, tap and enemy status, so a unit the fallback would never have class-coloured is not class-coloured here either.

#### Nameplates — Turning The Camera Made Enemy Nameplates Disappear

- **Fix** — Not the auras on the plate: the plate. Aura reads refuse once execution is tainted and *throw* rather than return nothing, and the throw came from the middle of the plate update, so everything after it — the health bar, the name, the cast bar — never ran. The plate looked like it had been deleted, and turning the camera was enough to trigger it because that is what brings new plates into view.
- **Change** — All eight aura reads across the nameplate module now go through three guards: one for the aura data, one for the duration object, one for writing the remaining time. A refusal costs that one aura its icon or its timer, and nothing else on the plate.
- **Fix** — `U.IsSecret` and `U.SafeStr` opened with `if v == nil`. Comparing a hidden value is one of the things that throws, so the guard failed on the single input it exists for — it worked on everything that did not need it. Both now use `type(v) == "nil"`, which is the only presence test safe on a hidden value.
- **Internal** — `pcall(f, g())` does not protect `g()`. Argument expressions are evaluated before `pcall` is ever entered, so a refusal from the inner call escapes the guard written around it. Two guards were written that way and covered nothing: the one around the aura-slot enumerator — the exact call that throws, and the exact cause of the vanishing plates — and the one around reading a remaining duration. Both now do the read inside the protected call.
- **Internal** — Those two are hoisted named functions rather than closures at the call site. A closure per plate is real allocation on the module whose own comments record hoisting a processor to avoid exactly that, and `U.ApplyClassColor` dropped its per-call closure in this release for the same reason.

#### Auras — Eleven Scanners Were Each Discovering The Refusal On Their Own

- **New** — An aura access probe in `Core/Utils.lua`. `U.AurasRestricted` spends one aura read — index 1 on the player, the cheapest there is — and caches the answer for the current frame, so forty frames asking the same question cost one read rather than forty rounds of protected calls that were all going to fail together.
- **Change** — Eleven scanners asked first instead of walking up to forty indices, protecting every call, to learn what one question answers. Eight of them then stopped scanning at all — they are on the aura engine further down this release — so what the probe still guards is the party group-buff check, the shared defensive scan and CooldownForge's rescan. It was worth building for those three alone, and it carried the other eight until they moved.
- **Note** — The probe is deliberately a *conservative* predictor, and that is what makes it safe to short-circuit on. It reads through `GetAuraDataByIndex`, which is the more permissive of the two aura APIs — the slot enumerator the nameplate and unit frame paths use refuses in cases the per-index reader does not. So a probe that comes back restricted means even the permissive reader is closed, and both paths would have returned nothing anyway. Nothing that would have drawn is suppressed.
- **Note** — The corollary is that when only the slot enumerator refuses, the probe reports readable and saves nothing. The per-call guards from earlier in this release stay exactly where they are; the probe is a cheaper first question, not a replacement for them.
- **Fix** — CooldownForge emptied its own watch list on a restricted rescan. The guard was placed after the two lines that clear `activeBySpell` and `spellByInstance`, so returning early left the list wiped rather than untouched, and nothing was tracked at all until the next readable update arrived. It now returns before the clearing.
- **Note** — What the probe buys is cost, not outcome. An indicator whose scan can read nothing still goes dark, exactly as it did before the probe existed — a dispel highlight, a HoT row, a defensive icon. Genuinely holding the previous frame's state through a refusal is a separate decision about visible behaviour, not a cleanup, and it is not made here: a dispel cue held over may be pointing at a debuff that has already gone.

#### Auras — Guarding The Reads Stopped The Errors And Not The Disappearing Auras

- **Note** — Everything above this point in the release makes a refused aura read survivable. None of it makes the aura appear. Auras are restricted for most of a dungeon pull, so the debuffs on nameplates were quietly absent exactly when they are worth looking at — no error, no clue, just nothing on the plate.
- **New** — `Modules/Interface/Shared/AuraContainer.lua`, aura displays driven by the client's own engine. It inverts the flow: TomoMod declares a container, a filter and how to build one button, and the client does the scanning, the sorting and the updating, handing back buttons to style. Nothing in that file ever reads an aura, so nothing in it can be refused. Every aura display in the addon runs on it: nameplate debuffs and enemy buffs, unit frame auras and target buffs, party HoTs, raid debuffs and raid HoTs.
- **Change** — The remaining time is written once, by one mechanism. Blizzard's countdown digits on the cooldown swipe are off everywhere; the engine's own duration text is the single source, and where it sits and what colour it is are the caller's to choose. Both were briefly on together, which drew the time twice — centred over the icon art and again in the corner. Nameplates keep the corner in yellow, the frames keep it centred in white, which is where their swipe digits used to be.
- **Fix** — Aura rows stopped wrapping and always grew the same way. Growth direction and the row-width limit belong to the *container*, and the conversion was sending the engine element sizes and nothing else — a group's layout only describes one button's box. Both axes are wired again, along with icon spacing, and both the horizontal and vertical growth settings drive their own axis rather than one being derived from the other.
- **Fix** — A container set to show eight auras could draw sixteen. "Both polarities" is two aura groups, and each honours its own frame count, so the budget is now split between them rather than handed to each in full. It also means a row of eight can no longer fill all eight from one polarity — two groups cannot lend each other slots, which is the cost of the arrangement rather than an oversight.
- **Change** — The scan-and-draw path on nameplates is gone rather than kept as a fallback: six guarded aura helpers, both frame-building loops, and the half-second ticker that rewrote every visible duration. The interface floor is 12.1, so the engine is always there, and a second implementation nobody exercises is a second implementation that quietly rots.
- **Fix** — Removing those tables left one read of them behind. `OnNamePlateRemoved` walked `plate.auras` unguarded, and the table is no longer built — so every plate removal, meaning every mob death and every plate leaving range, would have thrown. It hides the two containers instead.
- **Internal** — Availability is still probed by building a container and throwing it away, not by asking the API version. The frame type and the template both have to exist, and a version number does not say whether the template is registered.
- **Internal** — The button initializer creates and styles every region *before* registering any of them. Each `Set*` registration immediately runs the engine's update, which writes into our font strings, and a font string with no font assigned errors inside the engine rather than in our code — which is a long way from where the mistake would be.
- **Internal** — `AC.Filter` is the one place filter strings are built. The engine batches one scan per distinct filter compared byte for byte, so `HARMFUL|PLAYER` and `PLAYER|HARMFUL` describe the same auras and cost two scans; building every filter in one place with a fixed token order means callers asking for the same thing get the same string.
- **Internal** — Size and count changes go through `AC.Relayout`, which removes the aura group and adds it back. Button geometry belongs to the engine — it sizes and anchors from the group layout — and there is no setter for either value, so rebuilding the group is the sanctioned way to change them.
- **Fix** — Sizing a button is itself refused while auras are restricted, and an unsized button draws nothing at all. Since the engine runs the initializer once per pooled button and not again on reuse, a button first built mid-pull would have stayed invisible for good. The wanted size is now recorded separately from the size that actually landed, outstanding buttons sit in a weak-keyed set, and every container update retries them — a `next()` on an empty table when there is nothing owed.

#### Group And Raid Frames — The Last Scanners Move Over, Including The One That Looked Like It Could Not

- **Change** — Party HoTs, raid debuffs and raid HoTs are drawn by the engine. That is every remaining aura row in the addon; the hand-written icon loops that built them, and the scans that filled them, are gone.
- **Internal** — The HoT rows survive on a candidate filter. They worked by matching each aura's `spellId` against a table of tracked heal-over-time spells, and `spellId` is precisely what the client withholds — so the table is handed to the engine as the group's candidate list instead, and it does the narrowing on the side where the value can still be read.
- **Internal** — Raid debuff borders take their colour from the aura's dispel type, which used to mean reading `dispelName`. The engine paints that itself, on its own buttons, from data we are no longer allowed to see.
- **Change** — The dispel indicator moves too, and it changes shape doing so. It was a coloured border around the whole frame, lit by reading each debuff's dispel type and checking it against what the player can remove. Both halves of that are withheld now, so it only ever lit up *out* of combat — the inverse of when a healer needs it. It is a small icon in the corner of the frame instead, and the client picks the aura: `RAID_PLAYER_DISPELLABLE` asks exactly "can this player dispel this" and answers without a read.
- **Note** — Which means no guarded aura scan is left on any frame indicator. The route was not to find a way to ask about the unit, but to stop asking and let the engine select the aura — the same inversion as everything else here, arrived at one indicator later.
- **Note** — Two things about that filter are worth knowing rather than discovering. It covers class and spec dispels only, so a bleed never matches: nothing a class learns removes one, only the dwarf racial does. And crowd control is deliberately excluded, since it has its own display and would otherwise take the single slot.
- **Change** — The setting that was the border's thickness is now the icon's size, with a range to match. It kept writing a value nothing read otherwise.
- **Fix** — Turning "show debuffs" or "show HoTs" off left them on screen until a reload. The check had moved to frame creation only, and applying settings re-applies visuals to existing frames rather than rebuilding them — so the option worked in one direction and not the other. It is honoured on every update again.
- **Internal** — The raid updaters take the settings table as an argument now, read once by the caller and handed to both, rather than each looking it up.

#### Cooldown Studio — The One Display The Engine Cannot Draw

- **Note** — CooldownForge cannot use an aura container. It puts cooldowns and buffs in a single row, which the engine has no notion of, and what it actually needs is narrower: is this buff up, and how long is left. That is precisely what it may no longer read.
- **New** — So it asks the engine without letting it draw. A hidden container with one invisible button, restricted to the tracked spell's ids, is attached to the icon; the engine fills it and drives the icon's *own* cooldown widget. The swipe lands on the studio's icon with nothing having read an aura. Presence comes from asking the button whether it is shown, which is a question about a frame, not about an aura.
- **Fix** — One Cooldown, one owner. The engine writes that widget on its own schedule, so once a probe is driving it, nothing else touches it — the readable sources keep the mirror text and the visuals, which are the addon's alone. Two writers taking turns on one swipe is what makes it flicker.
- **Internal** — Ownership transfers the first time the probe is seen to work, not merely when one is attached. The engine side rests on API shapes that cannot be checked from Lua, and a probe that never fills would otherwise lock the readable sources out of a swipe it is not drawing either — no swipe at all, and nothing to say why. Once transferred it stays, because handing the widget back every time the buff drops is the same two-owner problem again.
- **Internal** — The probe button is sized through the same retry as every other aura button. Sizing is refused while auras are restricted, an unsized button is never laid out and so never shown, and "shown" is exactly what the probe reads — a probe that cannot be sized answers "not up" for the whole stretch it was built for.
- **Internal** — Replacing an icon's probe discards the old one. The studio reuses icons across rebuilds, so an icon can arrive carrying a probe for a different spell, and leaving it attached would put two containers on one icon, both driving the same cooldown.

#### Damage Meter — Two Dropdowns With The Right Number Of Blank Rows

- **Fix** — The skin and bar texture dropdowns on the Damage Meter options page opened with the correct number of rows and no text on any of them. The meter's list helpers return `{ value, label }`, which is what its own widget library reads; TomoMod's dropdown reads `text`, and unlike its segmented control it has no fallback, so every row was drawn with nil.
- **Note** — Converted at the call site rather than by changing the helpers, because the standalone options window reads the same two functions and expects the shape it already gets.
- **Change** — The Damage Meter category has an icon of its own. It had been drawing `icon_diagnostics.tga`, the same file as the Diagnostics category, so two entries in the menu carried the same glyph.

## ####################################

## CHANGELOG 3.4.4 — A Damage Meter Ships Inside TomoMod, Built On Blizzard's Own Combat Data Rather Than On A Combat Log It Would Have Had To Parse Itself, With Up To Five Windows That Dock Edge To Edge And Then Move And Resize As One Because Two Anchor Points Do What Size-Syncing Code Would Otherwise Have To, A Spell Breakdown And A Target Breakdown And Per-Encounter Segments Reachable From Any Bar, A Death Recap That Opens On The Player Who Died, An End-Of-Run Scoreboard That Accumulates Its Own Snapshots Because The Data Cannot Be Read At The Moment A Key Actually Ends, Nine Skins And A Font And A Bar Texture And A Column Set You Choose Per Window, And A Guard That Stands The Bundled Copy Down The Moment The Standalone Addon Is Installed So Two Meters Never Fight Over The Same Windows, While The What's New Page Stops Rendering Notes Whose Height It Cannot Measure And Hands Them Instead To The Popup That Already Knows How, Fifty-Nine Releases Become A Grid Rather Than A Column, Reading An Old Release Stops Counting As Having Read The New One, The Popup's Scrollbar Loses The Two Brass Arrows It Had Kept At Either End Of A Mint Track, And The Meter's Hundred And Fifty-Seven Names Move Out Of TomoMod's Shared Namespace Into One Of Their Own Before Anything Ever Collides With Them, While The Cooldown Studio's Sidebar Buttons Stop Drawing On Top Of The Footer They Had Quietly Grown Into And Get Boxes Wide Enough To Hold Their Own Labels, And A Studio Window Stops Being Able To Ask For More Screen Than The Screen Actually Has, While The Meter's Settings Leave The Doorway They Were Shipped Behind And Become A Page In TomoMod's Own Options That Writes Through The Same Single Description Of What To Refresh As The Standalone Window Does So Neither Can Drift From The Other, And Reading A Unit's Auras Stops Erroring On Every Aura Event Once Something Has Tainted Execution Because Patch 12.1 Refuses The Fast Enumerator Outright Rather Than Returning Nothing And There Is A Slower Reader It Will Still Answer

#### Damage Meter — TomoMod Had No Meter, And Adding One Usually Means Parsing The Combat Log

- **New** — A damage meter, bundled with TomoMod. DPS, HPS, damage taken, avoidable damage taken, enemy damage taken, absorbs, interrupts, dispels and deaths, grouped into Damage, Healing and Actions categories you cycle from the header. Current and Overall sessions, a combat timer, and a bar for each player.
- **Note** — It reads Blizzard's own `C_DamageMeter` data rather than parsing the combat log. That is the whole architectural decision: no `COMBAT_LOG_EVENT_UNFILTERED` subscription, no event flood to filter, and the numbers agree with Blizzard's own meter because they *are* Blizzard's numbers. It needs a client that has the API, and says so plainly when there is not one.
- **New** — `/tdm`, with `toggle`, `reset`, `lock`, `recap`, `resetpos`, `diag` and `help`. `/tomodm` is the long form. None of them collide with TomoMod's existing commands.
- **New** — Report to chat, with the channel chosen in the settings: say, party, raid, guild, instance, whisper, automatic by group type, or printed to yourself.
- **Note** — Say and Yell are deliberately called out in the interface as restricted: the game lets only one addon message through per click on those, so a multi-line report silently loses everything after the first line. Naming the limit beats letting it look like a bug.

#### Damage Meter — Five Windows That Behave Like One

- **New** — Up to five meter windows at once, each with its own meter type, session, column set and format. Watching DPS and healing side by side is the ordinary case, and one window forced you to keep cycling.
- **New** — Edge-to-edge docking. Drag a window against another and it hooks on; the chain then moves together, and pulling a window away detaches it.
- **Internal** — There is no size-synchronisation code, and that is the point. A docked window is anchored by *two* points on the shared edge rather than one, so its width is the host's width by construction — permanently, including through a resize — and dragging the head moves the chain because the engine already resolves the anchors. A docked window also hides its resize grip, since the constrained axis now belongs to the window it is docked to.
- **New** — Nine skins — Tomo Dark, Tomo Neon, Minimal, Glossy, Ember, Frost, Terminal, Void, Parchment — plus a bar texture, a font, a font size, a bar height, an accent colour or class colours, background and out-of-combat opacity, and an option to pin your own bar.

#### Damage Meter — A Number On A Bar Does Not Tell You What Produced It

- **New** — A spell breakdown from any bar: left-click expands the spells inline, right-click opens them in their own window. Totals, hit counts, crit counts and crit rate per spell.
- **New** — A target breakdown, answering the other half of the question — not what you cast, but what you cast it into.
- **New** — Per-encounter segments, so a pull can be read on its own rather than only as part of the running total.
- **New** — A death recap, opened by clicking a player in the Deaths category, or automatically on your own death if you turn that on. It shows the events leading to the death, and `/tdm resetpos` brings the window back to the centre if it has been dragged somewhere unhelpful.
- **Internal** — The per-spell data carries fields that were previously dropped: the pet or guardian that cast a spell, the overkill portion, whether the damage was avoidable, and whether the blow was the killing one. Every one of those reads is guarded, because any field can come back as a secret value mid-combat.

#### Damage Meter — The End Of A Run Is Exactly When The Data Cannot Be Read

- **New** — A run recap: an end-of-run group scoreboard, with damage, healing, interrupts, deaths and avoidable damage taken per player. It can open by itself when a dungeon ends, and `/tdm recap` brings the last one back.
- **Internal** — It accumulates rather than queries, and it has to. The obvious version reads the meter when the dungeon ends, and that does not work: `CHALLENGE_MODE_COMPLETED`, `LFG_COMPLETION_REWARD` and zone changes are not `DAMAGE_METER_*` events, and outside those handlers the API returns secret values — no sorting, no comparison, no `string.format`. A recap built that way could not even rank the group.
- **Internal** — So nothing is read at the end. A snapshot is taken at every `PLAYER_REGEN_ENABLED`, inside an event handler, where the values are readable and names have resolved. The Overall session is cumulative, so the last snapshot of a run *is* the run total and there is nothing to add up — roughly fifteen snapshots per key, at no measurable cost. A value that comes back secret is skipped rather than written, so a player's last readable figure survives.

#### Damage Meter — Two Copies Of The Same Meter Is Worse Than Either One

- **New** — The meter also ships as a standalone addon, TomoDamageMeter. When that one is installed, the copy bundled in TomoMod stands down at load and says so once at login, rather than two meters fighting over the same windows, settings and combat sessions.
- **Note** — The bundled copy is the one that yields, deliberately. Someone who installed the standalone chose it on purpose, and standalone versions already in the wild carry no guard of their own, so they cannot be asked to stand down. Deferring here is the only rule that works without shipping a matching update first.
- **Internal** — The guard loads before every other file in the module, so the flag is set before anything registers an event, and every entry point checks it rather than relying on load order alone.

#### Damage Meter — The Settings Move Into TomoMod's Options Without Becoming A Second Copy Of Themselves

- **New** — The meter's settings are now a real *Damage Meter* page in TomoMod's options, not a doorway to somewhere else. Skin, bar texture, font and font size, bar height, class-coloured accent; background, out-of-combat and breakdown opacity; realm stripping, your own pinned bar, bar tooltips, the combat timer and which side it sits on, reset on entering an instance, window snapping; automatic run recap and death recap, and the number of lines a report sends. Five cards, laid out like every other page in the addon.
- **Internal** — `Meter/Settings.lua` is new, and it is the reason the page could be built at all. It holds one declarative table of every setting: a database key and the recipe for making the change visible — clear the character-width cache and refresh the fonts, re-skin every window, tell the breakdown panels separately because they are not in `ns.windows`. `ns.ApplySetting` writes the value and runs the recipe; `ns.GetSetting` reads it back.
- **Internal** — Both the standalone options window and the new page write through `ns.ApplySetting`. Those recipes used to be inline in the standalone window's callbacks, so folding the settings into TomoMod would otherwise have meant two copies of "what to refresh when the bar texture changes", and the two would have drifted the first time one of them was edited. Eight callbacks in the standalone window were replaced by the shared call, and a setting now behaves identically wherever it is changed.
- **Internal** — A failing refresh no longer takes the value with it. The recipe runs under `pcall` *after* the write, so a broken refresh prints and the setting still saves — the alternative is a player changing a setting, seeing an error, and finding it reverted.
- **Internal** — The config page cannot reach `TomoMod.DM`, and handing it the namespace would have let it touch internals that are none of its business. It goes through the bridge instead: `Get`, `Set`, `GetSkinList`, `GetTextureList`, `GetFontList`, `L` and `IsAvailable`, and nothing else.
- **Note** — The labels come from the module's own locale table, which already carries these strings in nine languages. Re-adding them to TomoMod's six locales would have been duplication, and a downgrade for Chinese and Russian players. Fourteen new keys were added to those nine locale files instead.
- **Note** — Columns, adding windows and category filtering stay in the meter's own window on purpose: they act on one specific window rather than on a global setting, and they read better next to the window they edit. The page says so and offers the two buttons that get you there.
- **Fix** — The meter's settings window opened *behind* TomoMod's config when launched from it. It sat on the `DIALOG` strata while TomoMod's config sits on `FULLSCREEN_DIALOG`; it now matches, claims top level, and comes to the front wherever it is opened from.
- **Note** — The page still says what is actually going on in the two cases where there is nothing to configure: the standalone addon has taken over, or the client has no damage meter API. Neither is an error, and neither shows a dead control.

#### Auras — Patch 12.1 Stopped Answering The Question And Started Refusing It

- **Fix** — Unit frame auras threw errors continuously once anything had tainted execution. `C_UnitAuras.GetAuraSlots` no longer returns nothing in that state — it refuses outright, with *"Auras cannot be accessed when secret while tainted"* — and the call was unguarded, so it fired on every aura event: 189 errors in a single session in the report that prompted this.
- **Change** — The call is guarded, and the refusal now has somewhere to go. When the slot enumerator is closed to us, the auras are read one at a time through `GetAuraDataByIndex`, which is not subject to the same refusal. Slower, and the only path left — an aura row that still draws beats one that errors. Both the main aura path and the enemy-buff collector take the same route.
- **Fix** — CooldownForge's aura watcher had the mirror-image problem on the `UNIT_AURA` payload, which can now arrive secret in its entirety: `isFullUpdate` as a secret boolean, `addedAuras` and the instance-id lists as secret tables. Testing a secret boolean throws before anything else in the handler runs — 38 errors in one session — and `ipairs` over a secret table throws the same way.
- **Change** — The flag is checked with `issecretvalue` first, and an unreadable one is treated as a full update: the incremental lists are just as unreadable, so rescanning is the only way to stay current. Each list walk is guarded, and a failed walk falls back to a rescan rather than silently dropping the update. The removal walk is the exception — a stale entry is cleared by the next full update anyway, and rescanning on every removal event would cost far more than the bug.

#### What's New — The Page Was Growing A Second Layout Engine To Solve A Problem The Popup Had Already Solved

- **Fix** — Expanding a release on the What's New page overlapped its own paragraphs. The info-text widget measures its height immediately after `SetText`, before the frame has been given a width, so a paragraph that will wrap over six lines is measured as one and everything below it gets laid out on top of it.
- **Change** — The page no longer renders the notes at all. Clicking a version hands it to the same popup that appears after an update, which already owns a scroll frame sized to its content. The alternative was teaching the page to measure wrapped text, which is a layout engine, and there was already one a function call away.
- **Change** — The releases are a grid of version buttons with their note counts, four to a row, newest first. Fifty-nine of them in a single column is a very long page for what is essentially an index.
- **Fix** — Reading an old release no longer marks the current version as seen. The popup marks on close, so browsing 3.2.1 out of curiosity would have swallowed the notice for an update you had not read yet. Browsing is now distinguished from acknowledging.
- **Fix** — The popup's scrollbar carried Blizzard's two brass arrow buttons at either end of a mint track: the bar itself had been restyled and the arrows left as they came. They are hidden, and stay hidden — Blizzard's scroll code re-shows them on update, so a one-off `Hide` does not hold — and the space they had reserved is given back to the bar.
- **Internal** — Five locale strings retire with the accordion: the per-version open and close labels, the empty-release line, and the expand-all and collapse-all buttons. They are gone from all six locales rather than left behind as keys nothing reads.

#### Damage Meter — Bundled Code Was Living In The Shared Namespace

- **Internal** — The meter now keeps its names in `TomoMod.DM` rather than in TomoMod's addon-wide private table. Standalone, the addon vararg handed it a table of its own; embedded, that same vararg hands over the one every file in the suite shares — so roughly 157 names, `db`, `L`, `FONT`, `BG`, `ACCENT`, `Refresh`, `windows` and `inCombat` among them, were sitting exactly where anything else in TomoMod might reach.
- **Note** — Nothing had collided. The rest of TomoMod uses precisely one key in that table, `ns.oUF`. This is the fix made before something did collide, because the failure it prevents is the quiet kind: the first core file to want `ns.db` would have found the meter's, written to it, and neither side would have known.
- **Internal** — The sub-table is created in `Guard.lua`, which the module's XML already loads first, so the other twenty-three files take it rather than each testing for it. One line changed per file; every `ns.X` in the bodies stayed exactly as written.

#### Cooldown Studio — The Sidebar Buttons Had Outgrown The Space Reserved For Them

- **Fix** — The bar actions down the left drew on top of the edit-mode button in the footer. The block reserves a fixed height, and the two import rows that arrived with the Cooldown Manager import pushed the last row thirty-two pixels past it. Nothing clips a frame's children in this interface, so the overflow did not vanish or scroll — it simply drew over whatever was underneath. The reserve is now derived from the rows it holds rather than set by hand, with the arithmetic written down so a sixth row is an obvious adjustment instead of another guess.
- **Fix** — The labels were wider than the buttons carrying them. *Import : Buffs suivis* in a 104-pixel box drew roughly twenty pixels past each edge, which is why the column looked like it was bleeding into the bar list on one side and the window border on the other: the label is a centred font string with no width, and nothing trims it. The buttons are 143 wide now, sized from the longest label rather than from what happened to fit, and the sidebar is 330 to hold two of them side by side.
- **Change** — The window asks for 1400x880 where it asked for 1280x840, and the footer's edit-mode button is wider to match its own text.
- **Fix** — And it no longer asks for more screen than there is. `SetClampedToScreen` keeps a frame *inside* the display but cannot shrink one that is larger than it, so a studio sized for a wide monitor lost its left edge on a smaller one — the sidebar, and with it every button described above. The shell now fits the requested size to the usable area, less a margin so the border is never flush with the screen edge. The requested size became a target rather than a promise, which is what makes enlarging it safe at all.
- **Note** — AstralForge is built on the same shell and inherits the fit for free. That is the second time this release that the shared chrome has paid for itself, and the reason the fix went there rather than into the Cooldown Studio alone.

#### Dashboard — Card Order

- **Change** — The Cooldown Studio card sits directly above the Tomo suite card, rather than below the quick configuration two cards further down. The two are the dashboard's ways out to something else, so they read better together.

## ####################################

## CHANGELOG 3.4.3 — Every Release Note TomoMod Has Ever Shipped Becomes A Page You Can Open Instead Of A Popup You Dismissed Once And Lost, A Bar Imported From Blizzard's Cooldown Manager Stops Being A Snapshot That Rots At The Next Class Rework And Learns To Be Brought Back In Line Without Losing A Single Thing You Tuned On It, The Cooldown Studio's Entry List Stops Reading As A Column Of Spell Ids And Shows The Icon And The Name Of What It Is Actually Tracking, Icon Size Becomes A Scale You Set Once Rather Than Two Numbers You Keep In Step By Hand, The Scale Control Dims Itself Rather Than Guessing Once A Width And A Height Have Been Set Apart, The Dashboard Gets A Way Into The Studio That Does Not Require Finding The CooldownForge Panel First, And An Icon Size Outside Twenty-Four To Sixty-Four Stops Looking Accepted Right Up Until The Next Resync Or Import Or Duplicate Silently Snapped It Back

#### What's New — The Notes Were Shown Once And Then They Were Gone

- **New** — A *What's New* page in the options, listing every release TomoMod has shipped, newest first. Each version is a row you open to read its notes and close again, with two buttons that open or close them all at once. Until now the only place release notes ever appeared was the popup after an update, which shows the version you have just moved to and nothing else — dismiss it and the text is gone.
- **Internal** — The page and the popup read one table. `Core/WhatsNew.lua` publishes it as `WN.GetChangelog()` rather than the page carrying a copy, which would have drifted the first time a release was added to only one of them.
- **Note** — A release whose locale strings are missing falls through to its English text exactly as the popup does, and a highlight that resolves to nothing but its own key is skipped rather than printed. `wn_342_astralforge` on a line of its own would be worse than one line fewer.
- **Change** — The page rebuilds on every toggle instead of being served from the panel cache, so expanding or collapsing a version cannot show a stale copy. It joins the dashboard, the profiles page and the diagnostics page on that list.

#### Cooldown Studio — An Imported Bar Was A Snapshot, And Snapshots Rot

- **New** — *Resynchroniser* on any bar built from a Blizzard Cooldown Manager category. It re-reads the category and brings the bar back in line: abilities Blizzard has added since the import arrive, abilities it has dropped are removed. Class reworks are the whole reason it exists — an imported bar was correct on the day you made it and had no way back afterwards.
- **Change** — Deliberately a reconcile, not a rebuild. A spell that is still listed keeps its existing entry untouched: its glow condition, its spec visibility, its per-entry effects, all of it. Ten minutes of tuning surviving a single button press is the only thing that makes the button worth pressing.
- **Note** — Anything you added by hand is never touched and never removed, whatever Blizzard's list does, and it keeps its relative order after the imported block. A spell you had added yourself that Blizzard later adds to the category stays yours rather than being adopted — adopting it would mean a later resync could delete an entry you created.
- **Internal** — Imported entries carry a `fromViewer` flag and the bar remembers the category it came from in `viewerSource`. The flag is what makes removal safe, since a resync only ever deletes entries carrying it, and it had to be added to the entry schema explicitly: that table is a whitelist, and a field missing from it is dropped on the way in.
- **Note** — Both failure cases report rather than doing nothing visible: a client with no Cooldown Manager API says so, and a specialisation Blizzard curates nothing for says that instead. The per-entry editor is also deselected on a resync, because it is keyed by index and the list has just moved underneath it.

#### Cooldown Studio — The Entry List Was A Column Of Numbers

- **New** — Every entry in a bar's spell list now shows its icon and its name. It read `Sort 384100` before — accurate, and useless: working out what a bar actually contained meant looking ids up somewhere else.
- **Note** — The id stays, in brackets after the name, and is still what you get on its own while the client has not cached the spell yet. A blank row would be worse than a bare number.
- **Internal** — The icon is a texture escape inside the existing text widget rather than a texture region per row. The list is rebuilt on any click, so a real widget per entry would mean laying them out and recycling them by hand for no visible gain. The escape trims the icon to 5..59 of 64, cropping Blizzard's built-in border, which otherwise reads as a grey box at 16 pixels.

#### Cooldown Studio — Icon Size Was Two Numbers You Kept In Step By Hand

- **New** — An *icon scale* slider, on both the line and the radial layouts. It is the control you want whenever the answer is "same bar, bigger", which until now meant moving a width slider and then moving a height slider to exactly the same place.
- **Change** — Scale is a view over the existing size rather than a new stored setting. Two numbers describing one thing drift the first time a preset or an import writes only one of them, so there is still one number underneath.
- **New** — *Revenir a des icones carrees*, which clears the width and height overrides and hands control back to the single size — keeping the size you were looking at rather than snapping back to the default.
- **Change** — The scale slider dims once width and height have been set apart, because "scale by 1.2" has no single answer at that point. It dims rather than disappearing: a control that vanishes leaves you wondering what happened, one that greys out says "not right now". The button above is what brings it back, so the greying-out is not a one-way door.
- **Internal** — `W.CreateSlider` gains `SetEnabled`. It greys the label, the value badge and the track fill, drops the frame's alpha, stops the slider and the badge taking mouse input, and hides a tooltip the badge may still own — a disabled control keeping a tooltip alive from before is its own small lie.

#### CooldownForge — A Size Outside The Range Looked Accepted Until It Was Not

- **Fix** — An icon size below 24 or above 64 was silently snapped back, but never at the moment you set it. Nothing sanitises on every change, so the bar rendered at the size you asked for and kept it — until a resync, an import or a duplicate ran the sanitiser and reverted it with no explanation and no obvious connection to what you had just done.
- **Change** — One range now, 8 to 128, for the size and for both overrides. They disagreed until now: the width and height overrides accepted 8 to 128 the whole time, so the same 8-pixel icon was reachable through one control and refused by another.
- **Internal** — The bounds are published as `CDF.ICON_MIN`, `CDF.ICON_MAX` and `CDF.ICON_BASE`, and the Studio's sliders read them rather than repeating the numbers. A slider that offers a value the sanitiser will later clamp away is worse than a narrower slider, because it looks like it worked.
- **Note** — This widens the accepted range rather than narrowing it, so no bar you already have changes size.

#### Dashboard — The Studio Was Behind A Panel You Had To Know About

- **New** — A Cooldown Studio card on the dashboard, offering the same button as the CooldownForge panel.
- **Internal** — It delegates to that panel's own opener through `TomoMod_OpenCooldownStudio` rather than keeping a second copy. The Studio is a LoadOnDemand sibling addon, so opening it means handling not-in-memory, disabled, and missing from the folder entirely; two copies of that dance would have drifted apart on the first change to either.

## ####################################

## CHANGELOG 3.4.2 — AstralForge Arrives And Every Piece Of A Unit Frame Or A Nameplate Stops Being Something You Nudge By Two Pixels At A Time And Becomes Something You Drag Where You Want It, Anchor Points And Anchor Hosts Become Yours To Choose Instead Of Being Hard-Coded In The Engine, The Position Of A Thing Stops Living In Four Different Shapes Depending On Which Thing It Is, An Element Can Be Anchored To Another Element With A Cycle Guard That Makes That Safe, Opacity And Scale And A Font Size Override Arrive Per Element, Custom Text Elements Can Be Added With Tokens Compiled Rather Than Concatenated Because The Game Now Hands Out Names And Levels As Values Lua Is Not Allowed To Touch, A Whole Layout Can Be Saved Under A Name And Handed To Somebody Else As A String, Every Existing Profile Is Carried Over To Render Pixel-For-Pixel As It Did Before, The Designer Never Once Edits A Live Frame, The Party Keystone List Comes Back Empty For Everybody On Your Own Realm Because The Sender Of An Addon Message Always Carries A Realm And The Unit You Look It Up By Does Not, A Slash Command Is Added That Tells A Silent Transport Apart From A Name That Never Matched, Opening The Designer On A Unit That Actually Exists Stops Failing On A Rectangle The Game Has Made Secret Because A Preview Fed Real Data Cannot Be Measured At All, A Cooldown Bar Can Be Built From Blizzard's Own Cooldown Manager In One Click With Its Spell List Read Live At The Moment You Click Instead Of Shipped As A Table That Rots A Patch Later, And Every Window In The Addon That Closes With Escape Stops Keeping The Whole Keyboard To Itself For As Long As It Is Open And For Some Time After It Is Closed

#### AstralForge — Everything Was A Slider, And A Slider Only Ever Nudged

- **New** — AstralForge, a dedicated full-screen designer for the pieces of a unit frame. Pick a subject, drag any element onto the frame, and drop it where you want it. It opens from the UnitFrames panel and from the Nameplates panel, and like the Cooldown Studio it is a LoadOnDemand sibling addon: it costs nothing until you ask for it.
- **Change** — An element's *anchor point* and its *anchor host* are now yours to choose. Until now the engine decided both — the name was pinned to the top-left of the health bar, the level to its top-right, and so on — and the only thing exposed to you was an X/Y offset from wherever the engine had decided. Moving the name to the other side of the frame was not a setting, it was a number large enough to push it there. Each element now stores a full anchor record: its own point, the host it hangs from, the host's point, and the offset.
- **New** — Snapping to a 2-pixel grid, with magnetic alignment guides that light up when an element lines up with another. Hold Shift while dropping for free placement.
- **New** — *Reset element positions*, per domain, for when an experiment has gone far enough that starting over beats undoing it.
- **Change** — The sliders stay. A drag is the right tool for "over there" and a slider is the right tool for "two pixels left", so both write the same record and neither overrides the other.
- **Note** — The designer never touches a live frame. Its subject is a detached preview clone built by the same factories the real frames and the config preview use, so what you edit is what you get without any of it being a protected frame. This is not caution for its own sake: unit frames are protected in Midnight, dragging one would taint it, and the taint would outlive the session.

#### AstralForge — Nameplates Had No Position Settings At All

- **New** — The nameplate is a second domain in the same designer, with the same drag, the same anchors and the same properties. Name, health value, health percentage, level, classification icon and text, cast bar, cast icon, cast name, cast timer, cast shield, quest icon and raid marker are each positionable.
- **Change** — Only the raid marker ever had a usable position setting; everything else was hard-coded in the plate factory. The old raid marker anchor is carried into the new record with the anchor pair the engine used to apply, and every other element starts from a default that reproduces exactly what the factory did.
- **Note** — Auras and enemy buffs are deliberately *not* draggable on a plate. Their position is computed from their index in a fan-out, so a handle over one would claim to move something it cannot; the layout rule is the thing to edit, and that is a later job. The same goes for anything pinned to a status bar's fill rather than to its geometry — absorb, spark, stage markers — and for the 9-slice borders and glows derived from the health bar's own rectangle.

#### AstralForge — An Element Could Only Hang From A Frame Part

- **New** — An element can be anchored to another element, not just to a structural host. That is what makes "put the level directly under the name, whatever the name does" expressible at all.
- **Internal** — Which needs a cycle guard, so it ships with one: the anchor graph is walked before anything is applied, an edge that would close a loop is refused, and the elements are placed in topological order so a host is always positioned before whatever hangs from it. Without that, two elements anchored to each other is not a strange layout, it is a frame that never finishes laying out.
- **Internal** — A dropped position is never read back with `GetPoint`. It is measured as the delta between the element's anchor point and the host's, both converted to screen pixels through their own effective scale and divided back by the element's, so a `SetScale` anywhere up the chain does not shift the result. That is the exact failure that used to bite the minimap mover.

#### AstralForge — Opacity, Scale And Text Size, Per Element

- **New** — Visual properties on any element: opacity, scale, and a font size override for text. The override starts at 0, which means "keep the size the module computed", so nothing you have set up changes until you say otherwise.
- **Change** — Only the properties a widget can actually honour are offered. Opacity on a font string is meaningful, a scale on one is not, and a texture takes neither a scale nor a font size — so the panel shows what applies to the thing you selected rather than a fixed set of sliders, two of which would do nothing.

#### AstralForge — Text You Write Yourself

- **New** — Custom text elements. Add up to six on a unit frame and four on a nameplate, write a template such as `[name] - [level]`, and place it like any other element. Available tokens are name, level, class, race and guild on a unit frame; name, level, class, race and classification on a nameplate.
- **Internal** — A template is compiled into a format string plus an ordered argument list and handed to `SetFormattedText`, never concatenated. In Midnight `UnitName` returns a secret string and `UnitEffectiveLevel` a secret number: `"a" .. UnitName(u)` raises, and so does comparing or measuring one. The values are resolved C-side and Lua never reads what it fetched. Percent signs in your own text are escaped on the way in, or `SetFormattedText` would read them as conversions and shift every argument after them.
- **Internal** — The compiler is shared between the two domains, which differ only in their token table and their resolver. The risky half is written once.

#### AstralForge — A Layout Was Something You Rebuilt By Hand

- **New** — Layout presets. Save the complete layout of the current subject under a name — every anchor, every visual property, every custom element — apply it back, or delete it.
- **New** — Share strings. A preset exports to a string you can paste to somebody else, and imports the same way.
- **Internal** — Everything coming back in, whether from your own preset or from a stranger's string, goes through the same sanitiser as a fresh record: fields the registry does not recognise are dropped, invalid anchor points are refused before they reach `SetPoint`, and anchor cycles are broken. The worst a hostile payload can describe is a layout.

#### AstralForge — Underneath, One Registry Instead Of Four Conventions

- **Internal** — Each domain declares its anchorable hosts and its positionable elements once, with a default anchor and a resolver that finds the widget on a built frame. The studio, the config panels, the migration and the preset engine all read that declaration, so adding an element is a descriptor rather than an edit in four files.
- **Change** — The aura containers used to keep their position under `auras.position`, written by the in-game drag — the last place in the unit frame domain with a second source of truth for where something sits. The drag now writes an element record like everything else, so the studio, the drag and the sliders all agree.
- **Change** — Existing profiles are converted, and the conversion is written to render identically. Every legacy offset is carried over together with the anchor pair the engine used to apply against it, then the dead key is dropped. A fresh profile and a migrated one produce the same frame.
- **Note** — One legacy key is dropped without conversion: `elementOffsets.auras`. The engine stopped reading it in 3.0.5, so it holds a value that has had no effect for several versions, and converting it would *move* auras that are currently sitting exactly where you put them.
- **Internal** — Nine headless test suites ship alongside, run outside the game. Beyond the usual unit tests they include a static pass over the sources, which is the only way to prove a negative: that no `SetPoint` on a managed element has reappeared somewhere in the engine, that no legacy key is read outside the migration, that the studio never edits a live frame, and that every element's label exists in all six locales.

#### AstralForge — A Preview Fed Real Data Is A Preview That Cannot Be Measured

- **Fix** — Opening AstralForge on a unit that exists raised `attempt to perform arithmetic on a secret number value` inside the canvas and left the window without its subject. The preview clone was built on live data, and in Midnight a widget's rect becomes *secret* as soon as its content derives from protected data — a font string fed by `UnitHealth` is the textbook case. `GetLeft()` then returns a secret number and the `r - l` that measures the handle raises.
- **Change** — `UFP.CreateStandalone` runs on simulated data by default. That is structural, not cosmetic: a simulated frame has no secret rect, so it can be measured, and measuring is the entire job of a designer. A caller that only displays and never measures can ask for live data back with `opts.live`.
- **Internal** — `ForgeCanvas` gains `Plain()`, which every coordinate entering the file now passes through. The cardinal rule is one of *order*: `issecretvalue()` is checked before any arithmetic **and** before any comparison, since `s > 0` on a secret number raises exactly as `r - l` does. A secret coordinate degrades to nil, which the callers already read as "not measurable yet" — the handle hides and the rest of the canvas keeps working, instead of one element taking down the whole rebuild.
- **Fix** — `S.Open()` builds the subject under `pcall`. The element list, the inspector and the presets stay usable when the preview cannot be built, rather than the window opening empty with no indication of why.
- **Internal** — A tenth headless suite ships with it, `Tools/test_forge_secret_values.lua`. It replays the reported trace with sentinel values that raise on any arithmetic, comparison or concatenation, so a passing test is a proof rather than a promise. The static pass gains the matching check that no bare rect getter has reappeared in the canvas — an ordering rule cannot be observed at runtime once it has already been broken.

#### Mythic+ — Keystones Of Your Own Realm Were Received And Then Never Found Again

- **Fix** — A group member on your own realm had no keystone in the party list. The entry was received, stored and kept correctly the whole time; it simply could not be found afterwards. Addon messages identify their sender as `Alice-Varimathras` whether or not that realm is yours, so every entry is filed under a fully qualified name — but `UnitName("party1")` returns an empty realm for someone on your realm, so the natural lookup is `Alice`, which matches nothing. The keystone sharing rewritten in 3.4.1 is where this appeared: the library it replaced hid the asymmetry inside its own accessors.
- **Change** — `KS.Data` resolves the fallback itself. A bare name that carries no realm is retried against the player's own realm through an `__index` on the table, so a consumer that looks up `Alice` gets the entry filed as `Alice-Varimathras` without knowing anything about how the transport names people. The alternative — storing every entry twice, once qualified and once bare — would have doubled the saved variables and made `pairs()` list every same-realm player in the group twice.
- **Internal** — Writes go through `rawset` and the weekly purge walks the keys rather than calling `wipe`, because both have to reach the table itself rather than the fallback. `pairs()` is unaffected by the metatable, so the debug dump, the weekly purge and the saved-variables write still see one row per player.
- **Note** — A character name containing a hyphen is treated as already qualified and does not take the fallback. That is the same behaviour as before this fix, so nothing regresses; it is written down here because the rule is now in one place instead of at each call site.

#### Mythic+ — There Was No Way To Tell Silence Apart From A Failed Lookup

- **New** — `/tmt keysync`. It prints the prefix, the channel currently in use and whether you are in a guild, then every stored entry, then each group member resolved exactly the way the key viewer resolves them — `resolved` or `no data`. A row that is stored but not resolved is a lookup problem; a member missing from both lists is a transport problem. Those two failures look identical from the party list, and this release exists because telling them apart took longer than fixing the bug.
- **Change** — The command finishes by requesting keystones from the group, so a second run a moment later shows whether anything answered.

#### Cooldown Studio — A Bar Of Your Class's Own Cooldowns Was Something You Filled In By Hand

- **New** — Import a Blizzard Cooldown Manager category as a ready-made bar. Three buttons in the studio's bar panel — *Import : Essentiels*, *Import : Utilitaires*, *Import : Buffs suivis* — create a bar populated with the abilities Blizzard curates for the specialisation you are on, in Blizzard's own order. It is a starting point rather than a lock: what you get is an ordinary bar you can reorder, trim and restyle like any other.
- **Change** — Tracked buffs arrive as aura entries rather than cooldown ones, because that is what the category is: an icon that appears while the buff is up and counts its remaining time, not a swipe over a recharge. The other two categories import as plain cooldowns.
- **Note** — The spell list is read live from `C_CooldownViewer` at the moment you click, never shipped as a table. Blizzard keeps those three sets current across class reworks, so an imported bar follows the game; a hardcoded copy would be right for one patch and quietly wrong from the next one on. That is the same rule the item and racial presets already follow, and the reason no spell ids were added to the catalogue for this.
- **Internal** — Categories are resolved by `Enum.CooldownViewerCategory` key, not by number. Enum members are renumbered between builds, so a hardcoded `1` is a different category after a rebuild rather than an error anyone would notice. A key the running client does not expose is skipped instead of assumed.
- **Internal** — `overrideSpellID` wins over `spellID` where a talent has replaced the base ability, so the icon on the bar matches the one in the spellbook, and ids are de-duplicated — a category can list the same spell through two entries.
- **Note** — Both failure cases are reported rather than producing an empty bar in silence: a client with no Cooldown Manager API says so, and a specialisation Blizzard does not curate — or a category set the client has not sent yet — says that instead.

#### Windows — A Window That Listened For Escape Kept Every Other Key As Well

- **Fix** — While one of the addon's windows was open, movement and ability keys did nothing. `U.CloseOnEscape` calls `EnableKeyboard(true)`, and a frame taking keyboard input swallows every key unless it explicitly propagates — propagation defaults to false. The old handler only propagated as a *side effect* of receiving a key it did not handle, and returned early in combat without propagating at all, which is precisely when losing your keys costs the most.
- **Change** — `SetPropagateKeyboardInput(true)` is now the first statement of the handler, unconditionally, on every keypress. Escape is the only key the helper consumes, and only outside combat where hiding the frame is safe. The order is the fix: propagate first, decide afterwards.
- **Fix** — The keyboard is claimed only while the window is visible, bracketed by `OnShow`/`OnHide`, with the initial state following `IsShown()`. A hidden frame still holding keyboard input is how a closed window goes on eating keys — so the symptom outlived the window that caused it, and a second window opened afterwards inherited a propagation flag left switched off.
- **Note** — Propagation is re-armed on show rather than on hide, and that asymmetry is deliberate. `OnHide` runs synchronously inside the very Escape keypress that closed the window, so re-arming there would hand that same Escape straight on to `ToggleGameMenu` — closing your window and opening Blizzard's in a single press.
- **Note** — Nine windows share this helper and inherit the fix without a line of their own: the options, the installer, the loot window, the Mythic+ hub, TomoScore, the profession helper, the bag skin, the chat copy window and the Cooldown Studio. That is the return on 3.3.6 having replaced eight hand-written copies of the handler with one shared implementation, and on 3.4.1 bringing the last private copy in behind it — a keyboard bug of this kind would otherwise have been nine separate fixes, found one window at a time.

## ####################################

## CHANGELOG 3.4.1 — The Mythic+ Tracker Stops Being The One Screen In The Addon With A Colour Scheme Of Its Own, The Timer Becomes Three Segments That Each Count Down The Chest They Own, One Fixed Panel Becomes Three Looks With A Three-Row Minimal HUD Among Them, The Forces Count Learns To Say It Does Not Know Instead Of Reading Zero, Boss Names Stop Coming From A Hand-Written Table That Rots Every Season, A Run Can Finally Be Compared Against Your Own Best One Boss At A Time And One Checkpoint At A Time, The End Of A Key Gets A Banner That States The Margin, The Tracker's Private Options Window Is Gone, Text Written On Top Of A Filled Bar Stops Dissolving Into Its Own Outline, A Negative Time Stops Being Printed As A Large Positive One, Opening The Cooldown Studio Stops Being Able To Block Your Own Logout By Either Of The Two Routes It Had, LibOpenRaid Is Dropped Along With The Flood Of False Taint Reports It Produced, The Buff Frame Skin Is Withdrawn Because Blizzard's Aura Buttons Cannot Currently Carry A Border Without Erroring, And The Aura Tracker Is Retired In Favour Of CooldownForge

#### Mythic+ Tracker — It Was The One Screen With Colours Of Its Own

- **Change** — The tracker takes its colours from the TomoMod brand tokens. Surfaces are near-black with a mint cast, the accent is the same green as every other panel, and text, border, red and yellow come from the shared theme. 3.3.6 gave the end-of-run scoreboard this treatment and said in as many words that the in-run tracker still carried its own cyan set and the two would not match until it got the same pass. This is that pass.
- **New** — A font size multiplier, 0.70 to 1.60, on top of whatever the preset sizes things at. It is the setting that makes the tracker usable at a scale that is not yours: the frame scale slider grows the panel, this grows only the text inside it.
- **Internal** — The palette is built lazily in `TMT:BuildPalette` rather than at parse time. `Config/Widgets.lua` does load before this module today, but a parse-time dependency on TOC ordering is a trap for whoever reorders it next. The fallbacks run brand tokens, then the literal mint, so the tracker renders even when everything above it is missing.
- **Internal** — Every FontString the module creates is registered with the size and flags it was built at, so a scale change is re-applied in place instead of tearing the frame down and rebuilding it. The registry is also what makes a shared-media font a one-line change later rather than a sweep through every `CreateFontString` call.

#### Mythic+ Tracker — Text Written On Top Of A Filled Bar Was Unreadable

- **Fix** — The colour used for text sitting on a filled bar was near-black, and every font string the tracker builds carries an `OUTLINE` flag and a black shadow. Near-black text on a black outline dissolves into it: the palier markers on the timer and the label on the forces bar were smudges in game while the white elapsed time beside them stayed crisp. That colour is now near-white, which is what it should have been from the start — an outline is only useful when the fill and the outline differ.
- **Fix** — `FormatTime` printed a negative duration as a large positive one. The seconds were fed straight into modulo arithmetic, so a value of −220 came out as "56:20" rather than as anything recognisable. It now takes the magnitude and leaves the sign to `FormatDelta`, which is the function that owns it.
- **Fix** — In the preview the first two bosses had their kill times the wrong way round. The client's field counts seconds *since* the kill, so the boss killed first carries the larger number; reversed, the preview showed boss 2 dying before boss 1 and a negative leg time under it.
- **Change** — The first boss row no longer repeats its kill time in the split column. It was the same number twice on one line, since with nothing before it there is no leg to measure.

#### Mythic+ Tracker — One Timer Bar, Three Countdowns

- **New** — The timer is a segmented bar: one segment per chest threshold, each sized from that dungeon's real chest times rather than from a fixed ratio, each showing the time left before *that* threshold is lost. The number that drives decisions in a key is "how long until +2 is gone", and until now the only thing on screen was the total elapsed time and a delta against the full limit — the rest was arithmetic you did in your head between pulls.
- **New** — Segment colours, *per palier* or *brand*. Per palier reads mint, yellow, red from left to right, so the window being spent tells you which one it is by colour alone; brand paints all three in the same mint ramp for anyone who would rather read the bar by shape than by hue.
- **Change** — A spent segment keeps its own colour and drops to 42% alpha rather than being blanked. The bar still reads left to right as a history of the run, but the eye lands on the window actually being spent.
- **New** — A *timer layout* choice. *Two lines* keeps the elapsed time, the limit and the delta on their own row above the bar. *One line* folds the elapsed time onto the bar itself and drops the other two, because the last segment's countdown already is the time left before depletion and both would be restating it.
- **Internal** — The gradient is written onto the status bar texture, and `SetStatusBarColor` writes the same vertex colours — the two cannot both drive one bar. Hence a fallback path rather than a belt-and-braces call to both: where `SetGradient` is unavailable the ramp's bright stop is used, so the palier stays readable and only the shading is lost.
- **Internal** — In the one-line layout the elapsed time sits at the left edge of a segment that is bare track early in a key and filled later. Its colour follows what is actually behind it rather than being fixed, because dark text on the filled state is unreadable and so is light text on the empty one.

#### Mythic+ Tracker — One Fixed Panel Became Three Looks

- **New** — Three presets. *Panel* is the tracker as it was: background, header block, boss rows with pastilles. *HUD* strips the chrome and the row striping and lists the objectives as plain text at 1.15× size, on the bundled condensed face. *Minimal* is three rows and nothing else — information, timer, forces — with the boss list gone entirely and its tally moved into the header, so you still know you are on 2/4 without giving up four rows of screen to say so.
- **New** — Each thing a preset sets is also a control of its own: panel background, header block, dungeon name, boss list style, timer layout, segment colours, font size. A preset is nothing but a named set of values for those.
- **Change** — Touching any of those by hand moves the preset to *custom*, exactly like the UnitFrames preset engine, and neither preset button highlights. A named preset that silently drifts away from what it says stops being worth naming.
- **Internal** — `ApplyPreset` ignores unknown names, so a profile carrying `custom` — or a preset removed in some later version — never wipes the settings it was pointed at. `ResolvePreset` answers the reverse question after every hand edit and is what the config panel reads back.
- **Internal** — Layout walks a running offset from the top of the frame and no element is anchored to another. A hidden row therefore costs one skipped branch in one function rather than a re-anchoring chain at every call site — which is the only reason "hide the boss list" is a checkbox and not a rewrite.

#### Mythic+ Tracker — The Forces Count Could Lie Rather Than Say It Did Not Know

- **Fix** — Scenario criteria fields are not guaranteed readable in combat under 12.x, and the forces bar was comparing, matching and doing arithmetic on them regardless. Every field now passes a guard before it is touched, and the bar degrades in stages instead of guessing: exact counts, then percentage only, then frozen at the last value it could read.
- **Change** — With nothing readable this frame the bar holds its last known fill rather than dropping to zero. A forces bar that empties itself mid-pull does not read as "I cannot see the number", it reads as "the pull reset", which is the one thing it must never say by accident.
- **Fix** — The weighted-progress criterion is matched on presence, not on magnitude: asking whether `totalQuantity` is greater than zero is exactly the comparison that is banned on an opaque value. The absolute count is read from `quantityString`, which carries a stray percent sign despite being an absolute number, with the numeric field as the fallback.
- **Change** — The bar shows what is left to kill rather than "730 / 1000". Mid-pull the useful number is the remainder, and it is one glance instead of a subtraction.
- **Fix** — A boss row is only listed when the criterion is *explicitly* not weighted progress. If the flag is unreadable there is no way to tell a boss apart from the forces counter, and listing the forces counter as a boss is the worse of the two failures.
- **New** — When the count completes, the tracker states the time it completed at, and — if it has a recorded run to compare against — how that time compares.

#### Mythic+ Tracker — Boss Names Came From A Table That Rots Every Season

- **Change** — The module used to carry a hand-written challenge-map to journal-instance table copied from another addon. Blizzard adds challenge maps every season and reuses journal instances across them, so a table like that is wrong the day a patch ships and nobody notices, because the failure is silent: boss names quietly degrade to "Boss 1".
- **New** — Resolution is live and in three tiers. Walk the player's map hierarchy calling `EJ_GetInstanceForMap`, since multi-floor dungeons often have no mapping on the floor you are standing on but the parent map does. Failing that, match the challenge map's own name against the Encounter Journal's dungeon list, newest expansion first, exact match preferred and containment accepted. Failing that, give up and fall back to the raw criteria text, so the tracker degrades instead of breaking.
- **Internal** — Names are normalised to letters and digits before matching, so punctuation and article differences between the challenge-mode name and the journal name do not defeat it.
- **Internal** — A successful resolution is cached in the database keyed by challenge map. That cache is learned at runtime and never authored, so unlike the table it replaces it cannot be stale: a wrong entry could only ever come from the client itself. The tier scan restores whichever expansion tier the journal was on, so opening it after a key does not land you somewhere you did not leave it.

#### Mythic+ Tracker — There Was Nothing To Compare A Run Against

- **New** — *Compare to best run*. Each finished key is recorded per dungeon and per key level, and on the next attempt every boss row carries the delta against that record. An exact key-level match wins; failing that the nearest level below, then the nearest above — a slower reference is still a reference.
- **Change** — A depleted run is recorded too. It may be the only data you have for that dungeon, and a slow reference beats no reference. Only a faster run replaces what is on record.
- **New** — *Forces checkpoints*. On each boss kill the forces percentage is snapshotted, and on later runs the bar shows where your best run stood at the boss you have just killed, with an arrow and the gap. The reference holds between kills instead of jittering every tick, which is what makes it readable mid-pull.
- **Change** — With no record yet, a boss row falls back to the leg time from the previous kill rather than showing an empty column.
- **Note** — Nothing here is authored. A curated "expected forces at boss 2" table would be the same rotting data as the boss-name table just removed — wrong the day a dungeon is retuned — and it would also be somebody else's route rather than yours.
- **New** — *Clear recorded times*, in the panel, for when a dungeon is retuned or a route changes enough that the old reference is worse than none.

#### Mythic+ Tracker — The End Of A Key Passed Without Comment

- **New** — A completion banner: in time or depleted, the run time, the number of upgrades, and the margin in parentheses. The margin is the number people actually say out loud after a key — how much room was left, or by how much it was missed — and it was the one thing you had to work out yourself from a timer that had already stopped.
- **Internal** — The completion payload arrives on an event that can fire while combat is still up, so the time is guarded before it is compared or divided. A completion time that cannot be read hides the banner rather than rendering a run of nonsense.

#### Mythic+ Tracker — A Second Options Window Nobody Asked For

- **Change** — The tracker carried its own self-contained options window duplicating every setting already present in the Mythic+ config panel — two places to change the same value, with all the drift that implies. It is gone. `/tmt` opens the main config on the Mythic+ category, and the panel drives the tracker directly.
- **Note** — Every other `/tmt` subcommand is unchanged: `unlock`, `lock`, `reset`, `preview`, `key`, `kr`, `help`.

#### Cooldown Studio — Opening It Could Block Your Own Logout

- **Fix** — One line, `StaticPopupDialogs = StaticPopupDialogs or {}`, near the dialog definitions. Blizzard has already created that table long before this file loads, so the `or {}` never did anything except reassign the table to itself — but an assignment to a Blizzard global taints it whatever the value, and `StaticPopup_Show` reads that global. The taint then rode into every dialog sharing the pool, the logout confirmation among them, and the answer was blocked until the interface was reloaded. Indexing the table, which is what every other line in the file already did, carries no such cost.
- **Note** — This only ever happened in a session where the Studio had been opened. It cost nothing on a session that never touched it, which is exactly why it took a while to attribute.

#### Cooldown Studio — A Second Route To The Same Blocked Escape

- **Fix** — The "copy the style from…" popup carried its own hand-rolled copy of the Escape handling, and that copy had drifted from the original: it had lost the combat guard and called `SetPropagateKeyboardInput` unconditionally. Propagating a key out of an addon's `OnKeyDown` makes the resulting binding run with that addon's taint, which is how `TOGGLEGAMEMENU` ended up refused on `ClearTarget` — the same symptom as the dialog-table fix above, reached by a completely different road. It uses the shared `U.CloseOnEscape` now, guarded in one place.
- **Fix** — Closing that popup released the keyboard before hiding. An orphaned frame still claiming keyboard input is precisely the thing the change exists to prevent.
- **Fix** — It also stopped calling `SetParent(nil)` on the dimmer, which left a live frame with its scripts attached and nothing owning it.
- **Note** — Two hand-rolled copies of the same handler remain in the Profiles panel, both missing the combat guard. They are untouched here and worth the same treatment.

#### Cooldown Studio — Closing The Window Left The Bars In Edit Mode

- **Fix** — Leaving the Studio while the bars were unlocked stranded the movers in edit mode with the floating resume button still on screen. Both close paths — the shell's X and Escape — call `Hide` on the frame directly and never reach the Studio's own close function, so the cleanup lived somewhere neither of them went. It now hangs off the frame's `OnHide`, which is the one place both paths pass through.
- **Internal** — Entering edit mode also hides the window, and that must not be read as the player leaving. A flag set across that single `Hide` call separates the two, so entering edit mode no longer re-locks the movers it just unlocked.

#### Cooldown Studio — Releasing It From Memory

- **New** — *Reload interface after closing the Studio*, on by default, in the CooldownForge panel. The Studio is load-on-demand, and the game has no way to unload an addon once it is in memory: only a reload releases it. Reloading on close is also what guarantees that anything the session picked up dies with it.
- **Change** — The prompt waits for a safe moment rather than being dropped. It never appears in combat, during a Mythic+ key, or inside a party or raid instance — a reload mid-pull is its own disaster — and comes back when you leave combat, change zone or enter the world.
- **Note** — The switch exists because taint cannot be proven absent, only unobserved. The line above was one confirmed source and it is fixed; the reload is what covers the ones nobody has found yet. Turn it off if you would rather not be asked.

#### Libraries — LibOpenRaid Is Gone, And With It A Flood Of False Taint Reports

- **Fix** — The library named TomoMod as a taint source dozens of times at every combat start. It decides whether a value is secret by performing the forbidden comparison inside a `pcall` — the answer comes back correct, but the client logs each attempt against the addon that made it, and the aura loop makes that attempt constantly. Any genuine taint report was buried under the noise.
- **Change** — The library is no longer shipped. It was carried for four keystone functions and nothing else, while also synchronising cooldowns, gear, talents and durability — and the cooldown path, through `AuraUtil.ForEachAura`, was the source of the flood. Four functions are not worth 780 KB and a taint log nobody can read.
- **New** — `KeySync.lua` replaces those four functions and only those. Your own keystone needs no library at all, `C_MythicPlus` hands it over directly; the rest is transport — one addon-message prefix, one line format, and a table that survives a logout and empties itself at the weekly reset. Nothing about it is authored: every entry is learned from the players you group with.
- **Internal** — The public shape is deliberately the one the call sites already expected, so swapping the library out was one line per consumer. Both consumers, the party key viewer and the scoreboard, are otherwise untouched.
- **Internal** — Keystone getters are read on events that can land mid-combat, so every numeric field passes an `issecretvalue()` guard before it is compared or stored. The wire format is pipe-free so realm names with punctuation survive it, and an unknown protocol version is ignored rather than guessed at.
- **Fix** — The keystone update callback never fired. The library's `RegisterCallback` expects the *name* of a member function as its third argument, and the call site passed an anonymous function — so the party key viewer never refreshed on its own. The replacement takes a function, which is what was being handed to it all along.

#### Buffs & Debuffs — The Buff Frame Skin Is Gone

- **Change** — The buff and debuff skin has been removed: the module, its tab, its presets and its settings. It could not be made to work on the current client, and shipping something that throws errors is worse than shipping nothing.
- **Note** — The reason is not cosmetic. Blizzard's aura buttons report secret dimensions, so any backdrop attached to one raises an error inside Blizzard's own `Backdrop.lua` — not in TomoMod's code, where it could be guarded, but downstream of it. A border on those buttons is not a thing an addon can currently draw, however it is attached.
- **Note** — The other half of the problem is that those frames are reshaped nearly every patch. This version alone went through the border taking the brand colour, then carrying the remaining time, then a tile for the timer, then square icons, then a fix for the tile appearing under permanent auras — each one chasing a container that had moved again. That is maintenance with no end, spent on the one surface where Blizzard's own aura display is already adequate.
- **Change** — A migration drops the stored settings rather than leaving them orphaned in every profile. Nothing can be carried anywhere: there is no other feature with an equivalent schema to move them to.
- **Note** — Blizzard's own buff frame takes over, unmodified. If you want a skinned one, a dedicated aura addon is the honest answer — it is a whole feature, not a corner of a suite.

#### QOL — The Aura Tracker Is Gone

- **Change** — The aura tracker has been removed: CooldownForge covers the same ground, and having two overlays competing for the same screen space was the whole reason it kept feeling redundant. Its module, its config tab, its presets, its mover and its settings are all gone with it.
- **Change** — A migration drops the stored settings rather than leaving them orphaned in every profile. Nothing reads that table now, and the profile system would otherwise go on copying it around forever.
- **New** — Spells you had added to it by hand are not lost silently. They have no equivalent in CooldownForge's schema so they cannot be converted, but the IDs are kept aside and listed once at login, with their names, so you can recreate the ones you still want. Blacklist entries are not kept: they were removals from a default list that no longer exists.
- **Internal** — The notice prints from the login path, not from the migration. Migrations run before the chat frame is ready, so a message printed there would go nowhere. The rescue key is excluded from profile export for the same reason the migration flags are: it is bookkeeping, not configuration.

## ####################################

## CHANGELOG 3.3.6 — A Buff That Is Up Stops Looking Exactly Like A Spell That Is Recharging, The Countdown Changes Colour Before The Spell Comes Back, The Icon Text Stops Being Locked To One Font, One Outline And One Size, Glow Learns To Wait For Every Charge Or For A Stack Count You Name, An Entry Can Belong To A Talent Instead Of To A Class, Unit Frame Auras Can Grow Upwards Instead Of Only Downwards, The Mythic+ Scoreboard Stops Being The One Screen In The Addon With A Colour Scheme Of Its Own, Escape Stops Being Able To Lock You Out Of The Game Menu, Edit Mode's Second Status Bar Finally Gets A Switch, And A Spell Dropped Onto A Bar Actually Appears On It

#### CooldownForge — A Buff That Is Up Looked Exactly Like A Spell That Is Recharging

- **New** — Two style axes, *swipe while the buff is active* and *border while the buff is active*, each set to no effect, your class colour, or a colour you pick. Since 3.3.5 an entry can track a buff instead of a cooldown, and both states arrived on screen as the same plain icon: a proc that is up and the cooldown that grants it recharging were told apart only by reading the number on them. These two axes are what separates them at a glance.
- **Change** — Both are *off* on every preset, so no bar you have already built changes appearance. They only fire on an entry that actually tracks a buff; a plain cooldown icon never reaches them.
- **Internal** — Both are declared in `CDF.SKIN_TABLE_AXES`, so an override on the mode does not discard the colour beside it — the field-by-field merge added in 3.3.5 for `border`, `swipe` and `timer` covers them from the start rather than being retrofitted after the same defect shows up again.
- **Internal** — When the buff drops, the border is handed back to `styleIcon` rather than being repainted from a guessed resting colour. The style pass already knows what the border should be for that bar, preset or override, and asking it is the only way that cannot drift from the answer every other icon gets.

#### CooldownForge — The Countdown Changes Colour Before The Spell Comes Back

- **New** — A per-bar threshold, 0 to 60 seconds, with its own colour. Under it the running countdown switches to that colour, which is the cheapest way to read "this is about to come up" without stopping to parse a number mid-fight. Zero disables it and is the default, so nothing changes on a bar you have already set up.
- **Internal** — The remaining time is only ever computed from values that came back readable. Under restricted content a cooldown's start and duration are protected values, and comparing one against the threshold is exactly the operation that raises an error — so `CDF.RemainingSeconds` returns *nil* rather than a number it could not verify, and nil means the threshold simply does not fire. It never means zero: a spell whose remaining time cannot be read must not be drawn as though it were ready.
- **Internal** — Spells only expose a duration object, so the probe frame is loaded with it and the times are read back through `GetCooldownTimes`; items and trinkets still hand back plain numbers and take the direct path. Both go through the same readability guard, and a tracked buff supplies its own remaining time from the aura state, which was already known at that point in the render pass.
- **Note** — Where the client refuses to give the remaining time, the countdown keeps its normal colour instead of guessing. The Studio says so next to the slider.

#### CooldownForge — The Icon Text Was Locked To One Font

- **Fix** — `bar.text.font` has been in the bar schema since CooldownForge shipped and was read by nothing. Every font string on every icon — the countdown, the stack count, the spell name, the mirrored timer — was hardcoded to the bundled Poppins, so the field was saved, exported, imported and ignored.
- **New** — The font is now chosen from LibSharedMedia, alongside the bundled Poppins, matching what the castbars already offer. With no library present the dropdown holds Poppins alone and says why.
- **New** — The text outline is a choice rather than a constant: thin, thick, or none. A light font on a busy background needs one; a heavy font with one on looks muddy.
- **New** — The timer has its own size, independent of the stack and name text. It defaults to *follow the preset*, which is what it has always done, so changing the font no longer forces you off the preset's sizing to get the countdown you want. The range on both sliders is 8 to 28 px, up from 9 to 20.
- **Internal** — `LibStub` registers a library table before the file defining it has finished, so a library that errored mid-load leaves a truthy but empty table behind and a bare `if LSM then` passes right up to the first call. The guard checks for `Fetch` rather than for the table, the same pattern `Castbar.lua` uses. Every fetch is wrapped, and an unknown font name falls back to Poppins instead of leaving an icon with no font set — which the game treats as an error, not as a default.

#### CooldownForge — Glow Waits For Every Charge, Or For The Stack Count You Name

- **New** — *When every charge is back* joins the glow conditions. A two- or three-charge spell was either ready or not as far as glow was concerned, so a spell sitting on one charge of three glowed exactly like one sitting on three.
- **New** — *When the buff reaches N stacks*, with the count set per bar and overridable per entry. The client does not publish a maximum for an aura, so the number is yours to give; the slider covers 2 to 20 per bar and up to 99 on an entry.
- **Internal** — "Every charge is back" is answered from the charge cooldown, not by comparing counts. `chargeInfo.currentCharges` is a protected value under Midnight, and `current == max` is precisely the comparison that fails on it; the charge cooldown runs while a charge is missing and stops once they are all back, which is the same question with nothing secret in it. A spell with no charge system falls through to the plain ready test, so the condition is meaningful on every entry rather than silently doing nothing on most of them.
- **Internal** — The stack condition reads only the display-safe application count that tracked buffs already resolve. Where it is unreadable the glow stays off rather than firing on a guess — a glow that lights up on missing data is worse than one that stays dark, because it is the one you act on.
- **Internal** — `UNIT_AURA` is registered only when something on screen needs aura state. The stack condition needs it as much as the existing buff condition does, so the test that decides was widened to cover it — and, while there, to read the bar-level condition and not only the per-entry override, which it had been missing.

#### CooldownForge — An Entry Can Belong To A Talent

- **New** — An entry can be shown only when a talent is taken, or only when it is *not*. The second half matters as much as the first: a build that drops a talent usually gains a replacement, and both icons can now live in the same bar with only the relevant one on screen.
- **Change** — The condition is expressed as the spell the talent grants, not as a trait node. Node ids are renumbered at every talent rework and a hardcoded table of them is exactly the kind of data that goes stale between patches; a talent-granted spell is in your spellbook precisely while the talent is picked, which is the same signal with none of the maintenance.
- **Internal** — `C_SpellBook.IsSpellKnownOrInSpellBook` is the current test, with the legacy globals kept behind it and `FindSpellOverrideByID` in front — so a talent that replaces the spell with another still answers yes. Every call is wrapped, and a client that answers none of them reports "not taken" rather than failing.
- **Internal** — The check runs in `CDF.IsEntryVisible`, beside the specialisation filter and before the kind-specific tests. A talent condition is about whether the entry belongs in this build at all, not about what it points to, so it belongs at the same level as the spec gate.
- **Fix** — Swapping loadouts fires `ACTIVE_TALENT_GROUP_CHANGED`, not `TRAIT_CONFIG_UPDATED`, and only the latter was registered. Without the first, a talent condition — and the aura link map rebuilt on the same signal since 3.3.5 — would keep answering with the previous build until something unrelated forced a layout. Both it and `TRAIT_CONFIG_LIST_UPDATED` now invalidate and refresh.
- **Note** — Entries with no talent condition are untouched, which is all of them until you set one. The condition is stored per entry and travels with a bar's import/export string.

#### Unit Frames — Auras Only Ever Grew Downwards

- **New** — A *vertical direction* setting sits beside the existing growth direction on every unit's Auras tab: rows fall downwards, as they always have, or stack upwards. The horizontal choice already covered left and right; the vertical one was a constant, so a frame sitting low on the screen had a second row of debuffs walking off the bottom of it with no setting anywhere to stop that.
- **Change** — Downwards stays the default, and it is stored as nothing at all rather than as an explicit value. Every profile you already have therefore keeps its exact layout without a migration pass, and a profile that never touches the setting stays as small as it was.
- **Internal** — Growing up anchors the icons from the container's bottom edge instead of its top and walks the rows the other way. The container's own anchor is not touched, so the frame it belongs to does not move — the aura block grows away from the frame in the direction you asked for rather than dragging anything with it.
- **Internal** — The anchor point is composed from the two axes rather than enumerated. `TOP`/`BOTTOM` comes from the new setting and `LEFT`/`RIGHT` from the old one, so the four combinations exist because the pair exists, not because four branches were written out — and adding a third axis later does not double the branch count again.

#### Mythic+ — The Scoreboard Was The One Screen With Colours Of Its Own

- **Change** — The end-of-run scoreboard takes its colours from the shared TomoMod theme. It was carrying a standalone palette from before it was folded into the addon: a cyan accent where the rest of the suite is green, and a blue-tinted background where the rest is neutral. It was the only surface in TomoMod that did not match the others, so it read as a different product wearing the same name.
- **Change** — Three palette entries were named after the colour they used to be — `BORDER_TEAL`, `BAR_TEAL`, `TEXT_TEAL`. They are `BORDER_ACCENT`, `BAR_ACCENT` and `TEXT_ACCENT` now. A name that describes a specific colour is a name that starts lying the first time the colour is changed, which is exactly what happened here.
- **Internal** — The theme is read from `TomoMod_Widgets.Theme`, which the TOC loads at line 49 against the scoreboard's line 79, so it is always present. The old literals are kept as per-entry fallbacks rather than as a second palette: they answer only if the theme table is missing entirely, and they hold the theme's values, not the previous cyan ones — a fallback that renders something different from the real thing is a fallback that hides the fault it exists to survive.
- **Note** — Two colours are deliberately not derived from the accent. The "in time" bar and its text stay their own green: on a panel whose borders, headers and highlights are all brand green, an "in time" indicator painted the same green stops being an indicator.
- **Note** — The Mythic+ run tracker, the panel on screen during a key, still carries its own cyan set and is unchanged by this. The two are visible in the same run, so they will not match until it gets the same treatment.

#### Windows — Escape Could Stop Opening The Game Menu Entirely

- **Fix** — Eight windows closed on Escape by registering themselves in Blizzard's `UISpecialFrames`. That list is walked by `ToggleGameMenu`, which then calls the protected `SpellStopCasting()`, `SpellStopTargeting()` and `ClearTarget()`. Once anything in the session has tainted that execution path, all three are refused with `ADDON_ACTION_FORBIDDEN` and the game menu never opens — so Escape stops working and the player cannot quit without alt-F4. The windows now capture Escape themselves and never touch `ToggleGameMenu`.
- **Change** — The affected windows are the settings panel, the installer, the loot window, the Mythic+ hub, the end-of-run scoreboard, the profession helper, the bag skin and the chat copy window.
- **Internal** — This was already solved once, in Cooldown Studio in 3.2.2, and again in the What's New popup in 3.2.6, each with its own copy of the handler. The logic is now `TomoMod_Utils.CloseOnEscape(frame, onEscape)` and the eight windows share it. Escape is consumed, every other key propagates so game shortcuts keep working.
- **Note** — `SetPropagateKeyboardInput` is itself a protected call, so the handler stands down in combat: on these eight windows Escape no longer closes them mid-fight, and every key propagates normally instead. That is the deliberate trade — a keypress that throws `ADDON_ACTION_BLOCKED` on every press is worse than a window you close with its own button.
- **Note** — Four hand-written copies of the same handler remain, in Cooldown Studio, the What's New popup and the two profile dialogs. They work; they simply have not been moved onto the shared helper yet.

#### Status Bars — Edit Mode's Second Status Bar Could Not Be Hidden

- **New** — *Hide Blizzard Status Bar 2*, in QOL → Automations. Edit Mode's second status bar is a sibling of the main container rather than a child of it, so the existing suppression — which walks the main container's tree — never reached it and there was no setting anywhere that did.
- **Change** — The suppression machinery no longer names its targets in the code. A single function returns the list of containers to blank from the settings that govern them, and both the reputation bar and the new option feed it, so the second bar reuses the taint-safe path rather than getting its own copy of it.
- **Fix** — The `StatusTrackingBarManager.UpdateBarsShown` hook was installed on every call to the suppression pass rather than once. It is now guarded by a flag, and it re-reads the target list on each run so a setting can take effect without a reload.
- **Internal** — Blanking is done with `SetAlpha(0)` and `EnableMouse(false)`, never `Hide()`. The container is touched by Blizzard's secure code, and forcing its shown state is what propagates taint — the frame stays logically shown and simply cannot be seen or clicked.
- **Note** — Blizzard still owns the bar, so it remains visible and movable in Edit Mode. Unticking the option does not bring it back until a reload.

#### Action Bars — A Spell Dragged Onto A Bar Stayed Invisible

- **Fix** — With *show empty button slots* off, dropping a spell into an empty slot left the button blank. The spell was there and cast when clicked, but nothing was drawn on it until a reload. Dropping onto a bar also blanked the slots that had just been revealed for the drag, so the rest of the row went invisible on the way out.
- **Internal** — The cause is the ownership handover made when empty slots stopped being `Hide()`n and started being blanked with alpha, in the taint fix of 3.3.5. Blizzard's own `SetShown()` used to undo our `Hide()` the moment an action appeared, so nothing in this module ever had to notice a slot changing. Alpha is ours, Blizzard does not reset it, and the duty that came with taking it was not picked up.
- **Change** — The empty pass is re-run on `ACTIONBAR_SLOT_CHANGED`, on `ACTIONBAR_PAGE_CHANGED` and `UPDATE_BONUS_ACTIONBAR` — paging and stance bars change what a button points at without any slot changing — on `PLAYER_ENTERING_WORLD`, and once more after a drag ends.
- **Internal** — Costs nothing in combat: the pass already queues itself behind `PLAYER_REGEN_ENABLED` when locked down, and the queue is keyed per bar, so a burst of slot changes mid-fight collapses to one refresh per bar when the fight ends.

## ####################################

## CHANGELOG 3.3.5 — The Border Slider Stops Erasing The Border It Was Meant To Thicken, The Border It Does Draw Stops Being Painted Over By The Icon It Surrounds, Cooldown Bars Learn Whether You Have A Target And Can Fade Instead Of Vanishing, Icons Stop Being Forced Square, An Icon Can Track A Proc Instead Of A Cooldown, The Studio Lets You Reorder Entries Instead Of Deleting And Re-Adding Them, An Entry's Specialisation Can Be Changed After It Has Been Added Instead Of Never, Fine-Tuning A Style Stops Silently Rebasing The Bar Onto Tomo, The Border Slider Goes Past 4, A Tracked Buff Resolves From The Ability That Grants It Instead Of Requiring You To Hunt Down The Buff's Own ID, The Studio Stops Throwing You Onto Another Tab After Every Single Edit, The Aura Lookup Is Measured Down To The Two Sources That Actually Answer, Glow-On-Buff Stops Going Dark On The Pull, A Tracked Buff Gets The Timer It Was Already Reading, The Empty-Slot Option Stops Tainting Blizzard's Own Action Buttons And Blaming It On Whichever Addon Was Nearby, A Tracked Buff Stops Vanishing The Instant A Fight Starts And Gets Its Timer And Stacks Back Under Restricted Content, Blizzard's Four Cooldown Manager Bars Can Be Hidden One By One Instead Of All Together And Ticking The Box Actually Hides Them, A Proc Applied In The Middle Of A Fight Is Found By Reading The Display The Client Was Drawing All Along Instead Of Asking For A Name It Will Not Give, A Dungeon Teleport Re-Issued Under A New Spell Stops Being Reported As One You Never Learned, The Settings Scrollbar Becomes Something You Can Actually Click, And The Micro Menu Becomes A Bar You Can Size, Order And Place

#### CooldownForge — Changing One Style Field Wiped The Others

- **Fix** — Dragging the border thickness slider made the border disappear. The style resolver overlaid the bar's overrides onto the preset one axis at a time, replacing whole values — but `border` is a table of independent fields, and the studio writes one field at a time. Moving the slider left `border = { thickness = 3 }` with no `mode`, the renderer's `if bd and bd.mode` test then failed, and it called `SetBackdrop(nil)`: the outline was removed instead of thickened.
- **Fix** — Same defect on the two neighbouring axes. Picking a border colour dropped the mode and the thickness with it; picking a mode silently reset the thickness to 1. `swipe` and `timer` are tables too and were losing fields the same way.
- **Change** — Those three axes are now merged field by field: the preset supplies every field, the bar's own values land on top, and untouched fields keep the preset's answer. `CDF.SKIN_TABLE_AXES` names them, so the merge stays opt-in rather than being applied to axes that really are single values.
- **Note** — No bar changes appearance from this on its own. A bar whose border looks wrong today was configured through the defect, and setting the field again now produces what was asked for the first time.

#### CooldownForge — Touching Any Fine Setting Silently Rebased The Bar Onto Tomo

- **Fix** — Picking a border colour on a Net or Verre bar quietly turned the whole icon into a Tomo one. The style carried a single field naming the preset, and every fine control overwrote it with the sentinel `"custom"` the moment it was touched. There is no `"custom"` entry in the preset table, so the resolver fell through to its Tomo fallback — and the base the fine settings were supposed to sit on top of was gone. The preset dropdown then had nothing valid to show either.
- **Change** — Which preset a bar uses and whether it has fine settings are two different questions, and they are now two different fields: `preset` always names a real base, `customized` is a flag. Changing the preset keeps your fine settings and re-bases them; touching a fine setting no longer moves the base.
- **Change** — The Studio's Style tab says so. The line under the fine settings read "editing a fine setting switches the style to Custom", which described the defect; it now states that fine settings layer over the preset without replacing it. A bar carrying fine settings says so under its preset dropdown, so switching preset is not a blind move.
- **Note** — Bars saved as `"custom"` are migrated to `preset = "tomo"` with the flag set, which is exactly what they were already being drawn as. Nothing changes appearance. The migration runs from the bar sanitizer, so it happens once, on load, for every bar.

#### CooldownForge — The Border Slider Stopped At 4

- **Change** — The border thickness range is now 1 to 10, up from 1 to 4. Four was a reasonable ceiling while the border was invisible; now that it is actually drawn, it is not.
- **Internal** — The bounds live on `CDF.BORDER_THICKNESS_MIN` / `MAX` rather than being written into the slider call, and the engine clamps the stored value to the same pair when it normalises a style — so a hand-edited profile or an import cannot hold a thickness the interface would refuse to offer.
- **Note** — Worth knowing alongside the inset fix below: the icon art now stops short of the border, so thickness comes out of the picture. At 10 px on a small icon there is not much picture left. The range is wider because the setting works, not because the top of it is advisable.

#### CooldownForge — The Border That Did Survive Was Painted Over By The Icon

- **Fix** — With the defect above worked around, the border was still barely there, and 1 px looked the same as 4 px. The outline is a backdrop edge, which the game draws *on* the frame's border — inside its bounds. The icon art was anchored to the whole frame, in the ARTWORK layer, which sits above a backdrop. So the outline was drawn and then covered by the icon on every side, and widening it only moved the covered part further in.
- **Change** — The art is now inset by the edge width, leaving the border the room it needs to be seen. Two things follow from that and are worth knowing before you look at your bars: an icon with a border on now shows its picture slightly smaller — by the border thickness on each side, which is what a border costs — and a thickness slider that appeared to do nothing now visibly does something, so a bar left on 4 px while it looked like 1 px will read as considerably heavier until the value is set to what was actually wanted.
- **Internal** — The rounded-corner mask and the cooldown swipe are anchored to the art rather than to the frame, so both follow the inset without being touched. The art's `SetTexCoord` crop is unchanged: the icon is re-anchored, not re-cropped, so the same part of the picture is shown, just in a smaller box.
- **Note** — A bar with no border is anchored exactly as before. Only the bordered case moves.

#### CooldownForge — A Bar Can Depend On Whether You Have A Target

- **New** — *A target selected* joins combat, instance, group and raid in the visibility conditions, on the same tri-state as the rest: don't care, require, or require NOT. It covers the bar you only want up while you are actually on something, and the out-of-combat utility bar that should get out of the way the moment you pick a target.
- **Internal** — Evaluated with `UnitExists("target")`, which is a plain boolean and stays readable in restricted content; nothing here inspects the target itself, so the condition keeps working where reading the unit would not. `PLAYER_TARGET_CHANGED` drives the refresh, so it stays event-driven like every other condition — no polling was added.

#### CooldownForge — An Unmet Condition Can Dim The Bar Instead Of Hiding It

- **New** — Each bar now chooses what an unmet visibility condition does: hide it, which is what it always did and remains the default, or keep it on screen at reduced opacity. The opacity is a slider, 5% to 95%, and only appears once dimming is selected.
- **Change** — A dimmed bar is not a frozen one. It stays laid out and keeps being polled, so its cooldowns run and are readable while it is faded — "in combat = yes" with dimming leaves a working, half-visible bar out of combat rather than one that reappears already out of date.
- **Internal** — `CDF.IsBarVisible` becomes a thin wrapper over a new three-state `CDF.GetBarVisibility` returning `show`, `dim` or `hide`. The boolean contract every existing caller relies on is unchanged, and `dim` counts as visible — which is what keeps the polling loop, whose own comment says filtered bars must keep being updated while hidden, doing the right thing without being touched.
- **Internal** — The alpha is applied to the bar container rather than to each icon, so it multiplies with the per-icon style opacity instead of overwriting it. The stored value is clamped on the way into the database as well as on the way out, so a hand-edited profile cannot produce an invisible bar with no way back.
- **Note** — The visibility table is now kept when dimming has been chosen but no condition has been set yet. It used to be discarded as empty, which would have thrown that choice away for anyone who picked the mode before picking a condition.

#### CooldownForge — Icons Are No Longer Forced Square

- **New** — Width and height are separate sliders, 8 to 128 px each, replacing the single 24-to-64 square size. Wide, short icons for a row of procs along the top of the screen; tall, narrow ones for a column beside the unit frames.
- **Change** — Nothing moves on an existing bar. The two new values default to *unset*, and unset means "follow the old square size", so a bar nobody has touched renders exactly as before and no migration runs over the database. Only an explicit override is clamped; an untouched bar exports as it always did.
- **Internal** — The layout maths asked `iconSize` in five places and each assumed a square. They now go through `CDF.IconDims` (width, height) or `CDF.IconExtents` (along and across the growth axis, swapped for a vertical bar), so wrapped rows step by the right dimension on each axis, the anchor re-centres on its own half-extent per axis, and a radial bar sizes its box from the larger of the two so a wide icon at the edge of the circle is not clipped.

#### CooldownForge — An Icon Can Track A Buff Instead Of A Cooldown

- **New** — Any entry can be switched to *tracked buff*: the icon then stays off screen while the aura is absent and appears with its remaining time and stack count while it is up. That is the behaviour Blizzard's "Tracked Buffs" viewer has and a cooldown entry never did, and it is set per entry — so a proc can sit on the same bar as the cooldown that grants it.
- **New** — An optional buff ID, for the procs granted by one spell and applied as another. Left empty, the entry watches its own spell.
- **Fix** — A tracked buff does not have to be a spell you can cast, and until now it effectively did. Every entry passes a presence gate before anything looks at its state, and for a spell entry that gate asked the spellbook — reasonable for a cooldown, wrong for an aura. Proc buffs are granted by a talent or applied by another spell, so `IsSpellKnown` and `IsPlayerSpell` both answer no for them; the entry was rejected before the code that checks whether the buff is up ever ran, and the icon never appeared at all. Which is the main thing tracked buffs are for. An aura entry is now decided by the aura itself.
- **Change** — Under restricted content a buff's duration and stacks can come back as protected values, which cannot be fed to a cooldown swipe or compared. Existence can always be read, and existence alone drives showing and hiding, so each number is checked individually rather than the whole aura being discarded. *Superseded within this version — see "Nothing Was Readable Once A Fight Started" below: existence turned out not to be readable either, and the timer and stacks come back through the instance accessors.*
- **Internal** — A tracked-buff entry makes its bar "filtered", which is what already re-packs a bar whose icon set changes without a layout event; the icons close the gap when a proc drops exactly as they do for the hide-on-cooldown filter. `UNIT_AURA` registration, which is otherwise paid for only when a glow condition needs it, now also counts these entries — a tracked buff cannot appear at all without it.
- **Internal** — That "filtered" rule is also what makes the gate above safe to open. The presence gate now returns yes for every aura entry unconditionally, so the aura test has to run on every pass or an absent proc would sit on screen forever; a bar holding an aura entry is always filtered, which is precisely the condition under which that test is reached.

#### CooldownForge — An Ability And The Buff It Grants Are Two Different Spell IDs

- **Fix** — Tracking a proc meant knowing the buff's own spell ID, which is almost never the ID of the ability you took. Entering the ability — the obvious thing to do, and what the entry already holds — watched an aura nobody ever has, so the icon stayed off screen and looked like the feature was broken. The optional buff ID field existed precisely to work around this, and it required going and looking the number up somewhere else.
- **Change** — An entry now resolves through the link the client already knows about. Blizzard's Cooldown Manager has to solve the same problem for its own Tracked Buffs viewer, and publishes the answer as `overrideSpellID` and `linkedSpellIDs` on each cooldown entry. The ID you typed is tried first, then whatever the client links to it, and the first aura actually present wins.
- **Change** — Nothing about this is a hardcoded table of spells. The map is built from the running client, so it follows a patch that re-points a proc, and a talent that swaps one, without an addon update. It is rebuilt on a specialisation change and on a talent change, since both re-point overrides.
- **Note** — The explicit buff ID field is unchanged and still wins. It stays useful for the cases the client does not link, and any entry already using it keeps working exactly as before.
- **Internal** — The map is built lazily on first use and cached, and `CDF.AuraCandidates` memoises its per-spell answer — it sits behind `GetAuraState`, which runs per icon on every render pass, and this is the hot path the 3.3.2 aura work cleared of allocation churn. The returned list is shared, so callers iterate it and do not modify it.
- **Internal** — Every call into the Cooldown Viewer API is guarded and wrapped, so a client that does not answer degrades to the old behaviour — the typed ID alone — rather than failing. That is quiet enough to be mistaken for "this spell has no linked buff", so `CDF.AuraLinkStatus` reports whether the map was actually built and how many entries it holds, and `/tm forge` prints it. The two failures look identical without it.

#### CooldownForge — Nothing Was Readable Once A Fight Started

- **Fix** — A tracked buff went missing the instant combat began and came back the instant it ended. Every lookup keyed on the aura's spell ID, and under Midnight that field is a protected value in combat: measured at fully readable out of combat against 6.5% in it, with every tracked aura flipping to "not found" in the very frame the fight started. The enumeration was never the problem — the key was.
- **Change** — `UNIT_AURA` carries the spell ID *at the moment the aura is applied*, paired with an instance ID. Learning that pair once and then tracking the **instance** survives the field going protected afterwards, because every later question is asked by instance ID and answered engine-side. The event handler was receiving that payload and discarding it.
- **New** — The timer and the stack count are back under restricted content. The instance-scoped accessors return display-safe values where the raw fields are protected, and the duration goes to the cooldown swipe as an object rather than as arithmetic on two numbers that may not be readable — so nothing here compares a protected value at any point.
- **Internal** — Two sources in order: the instance registry, then a name match. Which two, and why the other candidates were dropped, is the section below.
- **Note** — This supersedes what the tracked-buff entry above says about Mythic+. That note claimed existence stayed readable and only the timer was lost; existence was in fact the first thing to go.

#### CooldownForge — Four Ways Of Finding A Buff, Measured Down To Two

- **Change** — The lookup had grown a source per symptom: the instance registry, a per-frame scan of the HELPFUL index, a direct `GetPlayerAuraBySpellID` call, and a name match, each added because the one before it missed a case. Nothing said which of them was carrying the feature, and a source that never works looks exactly like a source that never gets its turn — the ones ahead of it answer first either way.
- **Change** — Measured across roughly 12 700 resolutions each, the answer was two. The instance registry produced 583 hits, every one of them in combat. The name match produced 323, all but two of them out of combat. They are complements, not a fallback chain: each is useless exactly where the other works. The index scan contributed 5 hits and the direct call 2, so both were removed.
- **Internal** — The direct call is worth naming precisely, since it was the original implementation and its failure was silent: it does not error and it is not blocked, it simply returned nothing 19 143 times in combat. That is why the first version of tracked buffs went dark on the pull and looked like a bug in the filtering rather than in the lookup.
- **Change** — The per-frame snapshot is gone with the scan, and with it a pass over 40 aura slots per frame for every bar holding an aura entry. Two calls now answer what a scan plus three fallbacks used to.
- **Fix** — A buff whose stacks change is reported by the game as an *update*, never as an addition, so an aura first seen mid-fight through a stack change was never learned at all — its instance never entered the registry, and the source that works in combat had nothing to work with. Updates are now read too, and only for instances not already known, so the common case stays a table lookup.
- **Note** — What remains is a client limit, stated plainly rather than worked around: during a fight the game only names some auras. A buff already up when combat starts is tracked normally; a proc applied mid-fight is sometimes not identifiable, and its icon stays hidden. The tracked-buff option in Cooldown Studio says so on the spot — there is no setting to go looking for. *Superseded within this version — see the section immediately below: the client will not name that aura, but it is drawing it on screen the whole time, and that display can be read.*

#### CooldownForge — The Client Was Drawing The Buff It Refused To Name

- **New** — A source ahead of the other two: Blizzard's own Tracked Buffs viewer. The limit the section above ends on was accepted one change too early. The client will not *name* a proc applied mid-fight, but it is displaying that proc correctly the entire time — its own viewer is not subject to the restrictions an addon is. So rather than keep fighting for the aura data, TomoMod reads the verdict Blizzard has already reached: an icon in `BuffIconCooldownViewer` is shown exactly while its buff is up, and the `Cooldown` widget and stack text sitting on it already hold the numbers the player is looking at.
- **Fix** — That closes the case tracked buffs were still missing. A proc applied in the middle of a fight — the one the instance registry could never learn, because learning it requires the client to name it once — now resolves, with its timer and its stack count, since all three were on screen the whole time.
- **Change** — Nothing here is hardcoded and nothing here is protected. The spell-to-frame mapping comes from `CDMScanner`, which already caches it out of combat for exactly this reason: reading a viewer's `cooldownID` during a fight is what taints those frames. What this reads afterwards is a shown flag, a cooldown widget and a font string — display sinks, which cost nothing in taint terms and follow a patch that re-points a proc without an addon update.
- **Change** — Precedence is by accuracy, and the viewer is split across two positions rather than simply placed first. It wins outright when it reports the buff up *and* carries a number, because then it is strictly better than the alternatives. When it reports the buff up but has no numbers to give, it drops below the instance registry — the registry's answer is worth more than a bare yes — and is used only if the registry has nothing, where a verdict with no timer still beats reporting the buff absent.
- **New** — `/tm forge` gains a `source=` column naming which of the three answered for each entry: `viewer`, `aura`, or `-`. The three now overlap by design, and a proc resolving through an unexpected one is the first thing worth knowing when an icon misbehaves.
- **Note** — This depends on the spell actually being in Blizzard's Tracked Buffs viewer. For a proc the viewer does not carry, the source finds nothing and the two older ones answer exactly as before — so this adds cases and removes none.
- **Note** — Hiding a Cooldown Manager viewer with the new per-viewer ticks does **not** cost you this. Those ticks work by opacity and mouse input rather than by hiding the frame, so the viewer keeps drawing and keeps answering. A bar you have taken off your screen still feeds your own.
- **Internal** — Aura IDs the client has been observed naming are now learned at runtime and persisted, on the reasoning that a hand-written table of "readable" IDs is exactly the kind of data that rots at a patch while a learned one maintains itself. `CDF.IsAuraIDReadable` exposes it. It is groundwork: nothing consumes it yet, and it changes no behaviour in this version — it is recorded here so the saved-variable growth is not a mystery.

#### CooldownForge — The Numbers On That Display Were Not Where They Looked

- **Fix** — Stacks came back empty for every tracked buff read through the viewer. `Applications` was read off the item frame, and it does not live there — it sits on the child icon, and the bar variant nests it one level deeper again. Nothing errored; the count was simply nil every time, which reads as "this proc has no stacks" rather than as a lookup pointing at the wrong object. A zero is also rejected now, since a stack text of "0" means the field is present and empty, not that the buff is stacked zero times.
- **Fix** — The timer had a subtler version of the same problem. In combat `GetCooldownTimes` returns nothing usable, yet the client keeps *drawing* the countdown — so the numbers behind it are withheld while the figure on screen is not. The rendered string is now mirrored onto the icon: no swipe, because a sweep needs the values and those are exactly what is missing, but the figure is the one Blizzard settled on rather than a blank.
- **Change** — That mirrored figure obeys the bar's own timer settings — position, size, font and colour — instead of being drawn in Blizzard's font at a fixed size in the middle of the icon. Both countdowns now read their configuration from one place, which is what stops the two drifting apart as either is changed later. A bar set to show no timer stays without one: a number arriving by a different route is not a reason to override that.
- **Fix** — Reading that string is also what broke the module outright. A string read off a Blizzard FontString can come back as a protected value, and comparing one — even against the empty string — raises. The mirror tested `txt ~= ""` before it tested secrecy, so under restricted content it threw on every render pass, better than a thousand times a fight. Strings now pass the same gate the numbers have always had, and the gate compares only after establishing that comparing is allowed.
- **Fix** — The same unguarded comparison had been sitting on the spell-name match since well before this work — `name ~= ""` on a value the client is free to protect. It went unnoticed because that source carries the out-of-combat case, which is precisely where the value is readable. It is gated now too.
- **Internal** — A stale figure could survive on a recycled icon. Icons are pooled by slot, and the clearing branch sat inside the tracked-buff path — so a slot coming back as a plain cooldown entry skipped it entirely and kept the previous entry's number. The clear now runs outside that path, on every pass.
- **Note** — The mirrored countdown refreshes when a cooldown or aura event fires, not on a timer: this module has no ticker and advertises zero idle CPU. Expect the number to step rather than tick, next to a Blizzard icon counting down smoothly. Giving it a ticker would put idle CPU back into the one module built specifically not to have any.

#### CooldownForge — The Instance ID Was Sitting In Clear On The Frame All Along

- **Change** — Scraping the drawn widgets was the wrong route, and a diagnostics dump is what showed it: the viewer's own item frame carries `auraInstanceID` **in clear**, immediately beside an `auraSpellID` the client protects. The instance-scoped accessors are display-safe by design, so duration and stacks now come from `GetAuraDataByAuraInstanceID` and `GetAuraApplicationDisplayCount` — real values, never a protected read, and no text parsing anywhere in the path.
- **Change** — Reading the cooldown widget is demoted to a fallback and skipped entirely when the instance route already produced a timer, and the mirrored FontString below it becomes a last resort rather than the main mechanism. Both remain, because a frame without a readable instance ID still has a number drawn on it.
- **New** — The pair goes back into the instance registry as it is read. The viewer names the spell here even when the enumeration APIs will not, so the source that works during a fight is now *taught* auras it could never have learned on its own — the mid-fight proc case closing from the other side as well as the front.
- **Known limitation** — The two paths disagree about a single stack. The instance route stores a count only above one, on the reasonable view that "1" is noise; the older text path still stores anything above zero. So the same buff can show a "1" or show nothing depending on which source answered, which reads as intermittent rather than as a rule.

#### CooldownForge — Glow On A Buff Carried The Same Blind Spot, Silently

- **Fix** — The "glow while a buff is active on you" condition asked `GetPlayerAuraBySpellID` directly, which is the call measured above as returning nothing for most auras once a fight begins. So the glow was subject to the same combat blackout the tracked buffs had, and nobody had connected the two: a glow that quietly stops during the pull reads as a glow that was never configured properly.
- **Change** — It now goes through the same resolution the tracked-buff entries use, registry first and name match second, so both features see the same auras and a fix to one is a fix to the other by construction.

#### CooldownForge — A Tracked Buff Showed No Timer Even When Its Timer Was Perfectly Readable

- **Fix** — The swipe and the countdown were missing on tracked buffs whose duration and expiry had come back as plain, readable numbers — the case that was supposed to be the easy one. Two ways of driving the cooldown widget were available and the wrong one was preferred: the duration object was tried first, and only if it was absent did the numbers get used.
- **Fix** — The object was the wrong object. `C_UnitAuras.GetAuraDuration` returns a duration in one shape, and `Cooldown:SetCooldownFromDurationObject` consumes another; handing the first to the second is accepted, returns without complaint and draws nothing. It was wrapped in a `pcall` guarding against exactly the failure it could not produce, so the fallback to the numeric path never fired and the icon simply appeared bare.
- **Change** — Readable numbers are used first and the object is now only the fallback, for when the raw fields are protected and there is nothing else left to try. The order is reversed on purpose: the arithmetic is safe precisely when the values are readable, and unnecessary otherwise.
- **Note** — This is what the entry above means by the timer and the stack count being back under restricted content. The values had been read correctly since that change; they were being discarded on the way to the widget, which is why a fix described as restoring the timer could still leave you looking at an icon without one.

#### Micro Menu — A Bar You Can Size, Order And Place

- **New** — A Micro Bar, replacing Blizzard's micro menu strip with buttons of your own: which ones appear and in what order, horizontal or vertical, buttons per line, icon size, spacing, scale and opacity. It has its own entry in the Movers panel, and a Reset position button.
- **New** — Visibility modes — always on screen, on hover, or on hover but always during combat — with the faded opacity as its own slider. Icons can take your class colour, a colour of your choosing or the game's original art, with optional desaturation and a zoom on hover. The game menu button can carry the addon memory readout in its tooltip.
- **Change** — Every button forwards its click to Blizzard's own, rather than reimplementing what it opens. That is what keeps it working in combat, and it is also why the icons are the game's own art rather than a set shipped with the addon: nothing here has to be updated when Blizzard adds a panel.
- **New** — The original buttons keep running underneath, so their state is still live and can be mirrored onto yours: an alert glow with four styles and its own colour, dimming for buttons that are currently unavailable with its own opacity, and the real keybind drawn on the icon with an adjustable text size.
- **Note** — While the Micro Bar is on, the older Micro Menu setting above it no longer applies, and the bag micro-menu module stands down instead of fighting it for the native strip's opacity. Two modules writing alpha to the same frame is a flicker, not a feature.

#### Cooldown Studio — Reordering Entries

- **New** — Each entry in a bar now carries a pair of up/down buttons. Changing the order of icons previously meant removing an entry and adding it back at the end, and rebuilding everything after it.
- **Change** — The options editor follows the entry it was opened on rather than staying on the index. Without that, moving an entry while its options were open left the panel editing whichever entry had taken its place — the same screen, quietly pointed at something else.
- **Note** — The buttons at either end of the list do nothing, deliberately: the underlying move already refuses to run off the end, so there is nothing to disable and nothing to warn about.

#### CooldownForge — An Entry's Specialisation Could Only Be Chosen Once, When It Was Created

- **Fix** — Every entry carries a *visibility (spec)* condition, and the only place it could be set was the "add" form. Once the entry existed, nothing anywhere read it back or offered to change it: an entry added on the wrong spec, or added before you decided it should be spec-restricted, could not be corrected — only deleted and re-added, which until this version also meant losing its position in the bar.
- **New** — The dropdown now sits on the entry itself, in the Studio's Spells tab options panel and on the Cooldowns config page, alongside the entry's other settings.
- **Internal** — `CDF.SetEntrySpec` was already written for this, with the right signature and the right clamping, and had no caller anywhere in the addon. Nothing new was needed on the data side; the setting simply had no way in.
- **Note** — The Studio's dropdown carries a line stating what "All specs" means and that the listed specialisations are those of the class being edited — the game only reports specialisation names for your own class, so a bar built for another class lists its specs by ID rather than by name.

#### Cooldown Studio — Every Edit Threw You Onto Whichever Tab You Had Opened Last

- **Fix** — Changing almost anything in the Studio jumped you to a different tab. Editing an icon's style landed you on Sharing; ticking a visibility condition landed you on Layout. The editor rebuilds its content after nearly every change — twenty-six places do it — and each rebuild reopened the tab recorded in the state. That state was written from inside the tab builders, and a builder runs only the *first* time its tab is opened. So the recorded tab was whichever one you had visited last for the first time, frozen there for the rest of the session; going back to a tab you had already opened never updated it.
- **Change** — The active tab is now recorded on the switch itself rather than during construction, so it is right on the first visit, on every return visit, and on the initial one. The rebuild reopens the tab you are actually looking at.
- **Internal** — `W.CreateTabPanel` gained an optional `onSwitch(key)` callback, fired on every switch including the initial one. It is opt-in and no existing caller passes it, so no other tab panel in the addon changes behaviour. The reason it exists rather than callers reading a field is written above the function: lazy building makes "track it in the builder" look correct and fail silently as soon as a tab is revisited.

#### Cooldowns — The Cooldown Manager Bars Are Hidden One By One, And Hiding One Now Hides It

- **New** — The Cooldowns panel carries four ticks beside the Studio button, one per Blizzard viewer: Essential, Utility, Tracked Buffs as icons, Tracked Buffs as bars. Ticking one takes that viewer off the screen and out of TomoMod's layout mode and leaves the other three exactly where they are. Once your cooldowns live on your own bars it is rarely all four that are redundant — it is the Essential row duplicating the bar you just built, while the buff icons stay useful.
- **Fix** — The single tick this replaces did not hide anything. It turned the reskin module off, which stopped TomoMod dressing the four viewers and left them on screen in Blizzard's own art — so a box labelled *Hide the Cooldown Manager bars* made them more visible rather than less, and the only way to actually be rid of one was Blizzard's Edit Mode. The label described an intent the setting never carried out.
- **Change** — A hidden viewer is dimmed to nothing and made click-through rather than hidden. That is not a shortcut: `Show`, `Hide` and `SetParent` on those frames are protected and this module refuses them by design, and hiding *our* holder would achieve nothing either — the icons are anchored to the holders and never reparented, so the holder carries the position and not the pixels. Alpha and mouse input are neither protected nor inherited from the holder, which leaves exactly one honest way to do this.
- **Fix** — Combat fading would otherwise have undone it. The alpha pass rewrites every viewer's opacity on each combat, target or instance change, and it had no idea one of them was meant to be invisible, so a hidden viewer came back at the first state change and went away again at the next. Both of that pass's branches now go through the hidden state before applying anything.
- **Fix** — Two further routes back on screen were found after that, both writing opacity without consulting the hidden state. The placement-preview branch returns before the filter is ever reached, so entering layout mode restored every viewer. And the branch taken when there is neither a visibility rule nor combat alpha — the default configuration, and therefore most refreshes — set every viewer to full opacity outright. Both filter now. A setting that survives one code path and not the next reads as random rather than broken, which is the harder kind to report.
- **Fix** — Blizzard restores a viewer's own alpha when it becomes active, which is exactly what entering combat does, so a one-shot write could never hold on its own. `SetAlpha` is re-asserted through a hook rather than repeatedly polled — it is not a protected method, unlike the `Show`/`Hide`/`SetParent` this module refuses to call, so hooking it is the same honest route the rest of the feature takes. A re-entrancy flag keeps our own write from re-triggering it, and the hook re-reads the setting on every call, so unticking makes it inert instead of needing to be undone.
- **Fix** — A viewer that had not loaded yet was never hidden at all. `Blizzard_CooldownManager` is load-on-demand, so initialisation usually runs while these frames do not exist: the visibility pass found nothing to apply and no frame to hook, and the late-binding path that exists for exactly this case only re-attached the holder. The setting was stored, shown ticked in the options, and applied to nothing. That path now re-asserts visibility at the moment the viewer actually appears.
- **Change** — A hidden viewer's placement handle disappears with it. Leaving it would put a draggable rectangle in TomoMod's layout mode that moves a bar nobody can see, which is worse than no handle at all. The holder itself stays alive and keeps its saved position, so unticking restores the bar where you left it.
- **Note** — The master switch in CD & Resources is unchanged and answers a different question: whether TomoMod dresses these viewers at all, not which of them you want on screen. The two used to be the same setting phrased two ways, which is what made them able to disagree on screen; they are now genuinely separate and the stale-checkbox limitation reported against the previous tick no longer applies.
- **Note** — This is invisibility, not removal. The viewers still exist and still update behind the alpha, and whether a viewer is enabled at all remains Blizzard's Edit Mode's decision — TomoMod can make one unreadable and unclickable, and does not claim more than that.
- **Internal** — `cooldownManager.hiddenViewers` stores only the keys set to true, so an untouched profile carries an empty table and nothing migrates. `H.ApplyViewerVisibility` is idempotent and runs at initialisation as well as on every toggle, because Blizzard resets its frames' alpha after an Edit Mode reload and the state has to be reasserted rather than assumed.
- **Fix** — Hiding a viewer did nothing when the Cooldown Manager module was switched off — which is the player most likely to want it. That module's initialisation returns immediately when disabled, so it registered no events and nothing ever applied the stored state: the tick was saved, shown ticked in the options, and never reached a frame. Hiding no longer depends on the module running, and does not need to: it writes opacity and mouse input on frames it does not own. A small watcher started at file scope re-asserts the state on entering the world, on the viewers' load-on-demand, and across combat.
- **Fix** — Every alpha filter resolved which viewer it was looking at through a map filled by our own initialisation, and `Blizzard_CooldownManager` loads on demand — so when its load arrived first, the map was empty, the filter found no match and silently passed. That is how a hidden viewer came back even with the earlier fixes in place. Identity is now resolved against the frame's global name, which is true from the moment the frame exists and does not depend on anything the addon has built yet.
- **New** — `/tm forge` prints the hiding state of all four viewers: the stored setting, whether the frame exists, and the opacity actually applied. Those are three separate ways this can fail and they are indistinguishable from the outside — the whole sequence of fixes above was diagnosed by not being able to tell them apart.
- **Known limitation** — The visibility pass writes *full* opacity to every viewer that is not hidden, and the new watcher runs that pass on every combat transition and again half a second later. With combat fading on — which is the default, at 50% out of combat — the delayed pass has the last word and overwrites the fade until the next transition. So on a default profile with nothing hidden, the out-of-combat fade stops taking effect. Hidden viewers are defended by a hook and a watcher; a faded one is actively overwritten by them, and the pass should only assert opacity for viewers it is actually hiding.

#### Action Bars — "Show Empty Button Slots" Was Tainting Blizzard's Own Buttons

- **Fix** — A burst of `ADDON_ACTION_BLOCKED` on `MultiBarBottomLeftButton1..12`, credited to whichever addon happened to be on the stack when it fired — which most recently made it look like a Cooldown Studio problem. It was this option. Showing empty slots was implemented by writing Blizzard's own `showgrid` counter attribute to a high value so its +1/-1 cycles could never reach zero, and by calling `Show()` / `Hide()` on the buttons directly. Action buttons are secure frames: `ActionBar:UpdateShownButtons()` reads that attribute and calls `button:SetShown()`, found addon-written state, and was refused.
- **Change** — The option now drives `alwaysShowActionBars`, which is the setting that does exactly this and which Blizzard reads without taint. Bars that do not want their empty slots are blanked with alpha and mouse input instead — neither is protected — so Blizzard keeps full ownership of Show and Hide and we only decide whether an empty slot is visible and droppable.
- **Note** — That CVar is global while the option is per bar, so it goes on as soon as *one* bar asks for empty slots. It is also a Blizzard setting the addon now writes and does not restore: a player who had turned it on themselves in Blizzard's options will see it turned back off once no TomoMod bar wants empty slots.
- **Note** — Dropping a spell onto an empty slot is unaffected. The grid reveal on pickup no longer forces anything shown; it undoes our own blanking, and Blizzard's native reveal does the rest.
- **Note** — Two `Show()` calls of the same kind remain in the module — one on the action buttons during bar setup, one on the stance buttons — and by this fix's own reasoning those taint the same way. Whether the reported burst disappears entirely is therefore not something this change can be said to guarantee on its own.

#### Config — A Scrollbar Five Pixels Wide Is A Scrollbar You Cannot Use, Or Find

- **New** — Every scroll panel in the settings can be driven by clicking its scrollbar: clicking the track above or below the thumb pages by most of a screenful, and the thumb can be grabbed without having to hit it exactly. An invisible click surface sits over the bar, wider than the bar on both sides, with the thumb raised one frame level above it so a drag still wins over a page.
- **Change** — Making it clickable turned out to solve half the problem. Five pixels of dark grey on a dark panel is not merely hard to hit, it is hard to *see* — a control nobody can find is not much improved by being easier to grab once found. The bar is now 9px rather than 5, in a lighter grey at higher opacity, with a one-pixel black hairline down its inner edge to separate it from the panel behind. The minimum thumb height goes from 20px to 24.
- **Change** — The panel reserves two more pixels for it, so content is not overlapped by the wider bar. This is a visible change to every settings page: the scrollbar is meant to be noticed now, which is the point, but it is no longer the near-invisible hairline it has been.
- **Change** — The multi-line text boxes — import and export strings, notes — carry their own copy of this scrollbar, and it now matches: same width, same colours, same grab margin on the thumb. It had been left at the old five pixels when the shared panel was first made clickable, so the two disagreed for a version.
- **Note** — This is not a CooldownForge change: it is the shared scroll panel, so every category in the settings window gains it at once.
- **Internal** — The grab margins were sized when the bar was 5px and were not revisited, so the clickable strip is now appreciably wider than the bar it serves. It only reaches into the panel's own right margin, so nothing else is shadowed by it, but the numbers no longer follow from the width they were derived from.

#### Mythic+ — A Teleport You Own, Re-Issued Under A Spell The Table Had Never Heard Of

- **Fix** — A dungeon teleport sitting in your spellbook was still reported as not learned, greying the row out and refusing the click. When a dungeon returns in a later season Blizzard re-issues its teleport as a *different spell* — Midnight's Skyreach teleport is cast as "Voie des cieux", not the Warlords spell this table lists — and every ownership test ran against the listed ID alone. Owning the current spell was indistinguishable from owning nothing.
- **Change** — The test now asks the client which spell overrides the listed one and accepts either. That resolution is by spell ID rather than by name, so it holds on every client language, and it follows a season that re-points a teleport without an addon update.
- **Change** — It also asks the right way round. `C_SpellBook.IsSpellKnownOrInSpellBook` is the current test and the one that answers for achievement-granted spells, which every dungeon teleport is; it now runs first, with `IsSpellInSpellBook` and `IsSpellKnown` behind it and the three legacy globals kept last for older clients. Every call is guarded, so a client missing one of them degrades to the next rather than erroring.
- **Note** — This is the half of the Skyreach report that lands everywhere. The rest of it — the wrong dungeon *row* being consulted in the first place — is the section's remaining subject and is not solved on a localised client.

#### Mythic+ — A Dungeon Can Come Back Under A Challenge ID That Already Means Something Else

- **Fix** — The dungeon table is indexed by challenge map ID, and Blizzard issues a *new* ID when a dungeon returns in a later season. Midnight's Skyreach came back under an ID this table still described as Bloodmaul Slag Mines, so the row was answering for the wrong dungeon: the scoreboard abbreviated it "BSM" and the panel offered the Bloodmaul teleport rather than the one the dungeon actually uses.
- **Change** — The client's name is treated as authoritative. When the name the client reports for an ID disagrees with the name on the row, the row is stale for that ID and the right one is looked up by name instead. `GetTeleportSpellID` resolves that way now, so the wrong teleport is no longer offered.
- **Known limitation** — This resolves on an English client only. The table's names are English while the client returns them in its own language, so on any localised client the comparison finds a disagreement on *every* dungeon, the name index has nothing it can match, and the lookup falls back to the row it started from. On those clients the behaviour is exactly what it was before — no worse, but not yet fixed. Making it locale-proof means deciding what to do without a name to search by, and the honest answer is to distrust the row rather than to guess: no abbreviation, no teleport, and the client's own name shown instead. That is the next change, not this one.
- **Known limitation** — The abbreviation is fixed in one of its two paths. `RefreshFromAPI` fills the runtime cache's short name straight from the table row without resolving it, and `GetShortName` reads that cache first — so once the refresh has run, which is within ten seconds of entering the world, the resolver is never reached and a drifted dungeon still reads "BSM". The teleport has no such cache in front of it, which is why that half works and this half does not.
- **Internal** — `TomoMod_DataKeys.ResolveEntry` is exported and the name index is built once, lazily, from a static table. `GetEntry` still reads the raw row and was deliberately left alone: it has no callers outside the file today, and routing it through the resolver without the two limitations above settled would spread a half-working resolution across a third accessor.

#### Internal

- **Internal** — `/tm forge` prints what the engine sees for each of your class's bars: the state of the aura link map, then per bar its visibility verdict and whether it is filtered, then per entry its kind, mode, watched aura ID, the candidate IDs tried, which one matched, the presence verdict and the live aura state. Written for the tracked-buff work — each of those is a step at which an icon can silently fail to appear, and reading them is faster than guessing. It is a diagnostic aid, not a feature, and it is not listed in the help.
- **Internal** — The watcher registered `PLAYER_SPECIALIZATION_CHANGED` twice and tested it twice in the same condition. Harmless — `RegisterEvent` is idempotent and the second test is unreachable past the first — but it read as though spec changes had just been wired up, when the only genuinely new event is `TRAIT_CONFIG_UPDATED`. Both duplicates are gone and the remaining registration says why it is there.
- **Internal** — Two comments in the skin resolver still described `"custom"` as a live preset value after it became a migrated-away sentinel, and one of them had been separated from the function it documents by a constant inserted above it, so it read as documentation for the border thickness bounds. Both corrected.

## ####################################

## CHANGELOG 3.3.4 — The Role Presets Stop Being The Same Configuration Under Three Names, Switching Preset Stops Leaving The Last One Behind, The Dashboard Says Which Preset You Are Actually Running, Every Setting Says Which Role It Is For, Three Role Guides Put Every Setting One Click Away, A Search Result Inside A Nested Tab Stops Landing On The Wrong Page, The Search Index Stops Missing Two Thirds Of The Interface, The Guide Buttons Stop Dropping You On The Last Tab You Used, The Class Reminder Stops Reading The Stance Bar By Position And Becomes A Row You Can Click To Cast, It Learns Weapon Imbues, Rites And Poisons And Stops Talking While You Are Dead Or In A City, The Mythic+ Panel Stops Claiming You Never Learned Teleports You Own, The Group's Keystones Get A Board You Can Open Before The Pull Instead Of After It, The Unit Frame Preview Stops Being A Mock-Up Of The Real Thing, Changing The Bar Texture Stops Needing A Reload, The Chat History Stops Being One Switch With Six Settings Nobody Could Reach, The Restored History Stops Burying Every Addon Load Message, Unticking The Chat History Actually Deletes It, The Cooldown Studio Button Says Why It Did Not Open Instead Of Doing Nothing, A Studio Left Unchecked In The Addon List Repairs Itself On The Click, The Release Zip Refuses To Ship A Sub-Addon Nowhere Anyone Can See It, The Diagnostics Export Stops Fighting Itself Over One Clipboard, And The Contacts Window Skin Is Retired Before Blizzard Rebuilds The Frame Under It

#### Presets — Three Role Archetypes That Were The Same Configuration Under Three Names

- **Change** — The Tank, Healer and DPS presets wrote three, four and three settings respectively. Everything else came from the shared base, so picking a role changed a nameplate width and a couple of toggles and left the rest of the interface identical — three archetypes that were one configuration wearing different names. Each now writes a coherent, role-specific setup across party and raid frames, nameplates, target auras, resources, cooldowns and castbars.
- **New** — *Tank*: wider threat-coloured plates, unselected plates kept bright so the whole pull stays readable, bigger enemy buffs for enrages and shields, a thicker plate castbar for interrupt windows, numeric threat on the target, party interrupt and battle-res cooldowns, personal defensives on the frames, and a personal health bar warning at 40%. HoT tracking is dropped — a tank reading HoTs is a tank not reading the pull.
- **New** — *Healer*: distinctly larger and more clickable party and raid frames, more and bigger HoT icons, a thicker dispel border, defensive and absorb tracking, heal prediction, health shown as a deficit rather than a percentage, stronger out-of-range fading, and a mana warning at 30%. Nameplates are dimmed and thinned out so they stop competing with the frames for the same attention.
- **New** — *DPS*: taller resource bars with a low-resource threshold, proc glow with range checking, target and nameplate auras filtered down to your own casts so DoT tracking stays readable, enemy defensive buffs tracked, the GCD spark on, and raid frames compacted with HoTs off.
- **Fix** — Switching from one archetype to another left the previous one's settings behind. A preset only ever wrote its own overrides, and any key it did not restate kept whatever the last preset put there — so tank → healer left you healing with tank-mode nameplates and 190px plates. The base is now the explicit reset floor: it carries a value for every key any archetype can touch, it is written first every time, and the archetype's overrides land on top of it. Applying a preset produces the same result regardless of what was applied before it, which is what "deterministic and idempotent" claimed to mean already.
- **Change** — *Minimal* also switches off the per-frame trackers — HoTs, defensives, debuffs, heal prediction, target enemy buffs. Those are the expensive part of the group frames, and a preset that advertises a lighter footprint while leaving all of them running was not delivering one.
- **Internal** — The invariant is written down at the top of `Config/Presets.lua` and holds for every delta: no path may appear in an archetype that does not also appear in BASE. It is the only thing standing between the preset engine and the residue bug above.

#### Dashboard — Presets As Cards Instead Of Four Coloured Buttons

- **Change** — "Configuration rapide" was a row of buttons carrying nothing but a name, in colours taken from a rotating list of four that had no relationship to the preset they landed on. Choosing between five configurations required knowing beforehand what each one did. They are cards now: role icon, the archetype's own colour, its tagline, and three bullet points of what it actually changes, with the full description on hover.
- **New** — The card of the preset currently applied is marked *Active* and lit in its own colour; *Recommended* is marked as such while it is not the active one. Nothing on that panel used to say which preset — if any — was running.
- **New** — Three localized highlights per archetype in all six languages, alongside rewritten descriptions that describe the configuration each preset now actually writes rather than the three-setting version it used to.
- **Fix** — With the preset engine unavailable the panel used to fabricate a single "Complet" tile pointing at it anyway. It states that no preset could be loaded instead. The grid also re-lays itself out when the config window is resized, which the fixed four-column button row never did.

#### Config — Every Setting Says Which Role It Is For

- **New** — Settings sections can carry role badges — tank, healer, damage — drawn as small coloured icons in the section or card header, with a tooltip naming the roles. Tagged so far: HoTs, dispels, absorbs, heal prediction and resurrection on both party and raid frames; defensive cooldowns; interrupt and battle-res cooldowns; tank mode; nameplate castbars, auras and enemy buffs; the GCD spark; interrupt feedback; the personal health bar; and target threat text.
- **New** — A role focus bar at the top of the sidebar — All / Tank / Healer / DPS. Choosing one keeps the settings that matter to that role at full brightness and dims the rest to 28%.
- **Change** — It dims rather than hides, deliberately, and an untagged section always stays at full brightness. A filter that removes options teaches you that the settings window is lying about what exists; one that fades them lets you still find something whose location you already know, whatever focus is active. It also means the tagging can stay partial without ever hiding anything.
- **New** — The chosen focus is saved with the rest of the window state and restored on reopen, and re-applied whenever a category or a tab is built for the first time — config pages are built on demand, so a section only enters the registry once you have visited it.
- **Internal** — Role tags are a compact spec string on the existing constructors (`"T"`, `"H"`, `"D"`, combinable as `"TD"`), so tagging a section is a fourth argument on the `CreateCard` / `CreateSectionHeader` call and nothing else. Cards dim as one frame, which carries every option inside them; a bare section header dims its regions as an explicit list, because those are siblings on the page rather than children of a container.

#### Roles — Three Guide Pages, With Every Setting One Click Away

- **New** — A Roles category, carrying a guide page for tanking, healing and damage. Each page states what actually matters for that role and where it lives, rather than leaving a player to infer it from a settings tree organised by module.
- **New** — Every point on a page carries a button that opens the panel holding that setting and highlights the section — not a description of where to look, the actual navigation. The page header also applies the role's preset and switches the sidebar's role focus, so the three lots that shipped this version meet on one page.
- **Internal** — The guide pages declare the full route to each target — category, then one tab key per nesting level, then the section's locale key — and hand it to `GS.JumpToPath`. Resolving against the live index by localized section text was tried first and does not hold: a section only registers once the tab holding it has been built, and most of these live in tabs that are not built until you open them.
- **Internal** — `Config/Panels/Roles.lua` loads immediately before `ConfigUI.lua` and registers its own strings in all six languages, because `ConfigUI` reads `cat_roles` and the tab labels at load time, into a file-scope table.

#### Config Search — A Result Inside A Nested Tab Landed On The Wrong Page

- **Fix** — Searching for something that lives behind a panel's own second row of tabs — raid frame HoTs, resource bar colours, castbar unit tabs — opened the right category and then landed on its first tab. The index stored one tab key per entry, and that key was the *innermost* tab, which the category's outer tab bar could never match, so it fell through to the default.
- **Change** — The build context now carries an ordered `tabPath`, one entry per nesting level. `CreateTabPanel` derives its own depth from the length of the path at the moment it is created, and re-establishes its ancestors before building a tab that is opened long after the page was — by then the live path has moved on to another category entirely.
- **Fix** — A cached page is re-shown without being rebuilt, so no tab bar is created and a pending path would never be read. Deep-links drop the target category from the cache first, through a new `C.InvalidateCategory`, rather than the blanket `InvalidatePanels`.
- **New** — `GS.JumpToSection(cat, sectionLabel)` as a public entry point, ghost-indexing first so it works on pages the player has never opened, and falling back to opening the category when the section cannot be resolved instead of silently doing nothing.

#### Config Search — Two Thirds Of The Interface Was Never In The Index

- **Fix** — Ghost indexing walked the category tree and called each page builder once, which indexes exactly one tab per page: `CreateTabPanel` builds its first tab eagerly and leaves the rest lazy. Everything behind a second or third sub-tab — which is the bulk of the settings — had therefore never registered a single entry, and could not be found by searching for it at all. The indexer now collects every tab panel a build produces and walks the remaining tabs itself.
- **Change** — Walking every tab means building several times as many panels, so the run is no longer synchronous. Jobs are queued and drained on a 6 ms budget every 50 ms, instead of freezing the client for the length of a full GUI build on the first two characters typed into the search box. A result list already on screen re-runs its query when the queue empties, so a search made against a half-filled index does not sit there stale.
- **Fix** — Panels that reuse one builder across sibling tabs — every castbar unit, every unit frame — collapsed into a single entry. The key was `cat + innermost tab + section + label`, and the target castbar and the focus castbar produce the same innermost tab key and the same section text, so each one overwrote the last and every copy but the first vanished. Entries are keyed on the full tab path now.
- **Fix** — A ghost build is offscreen and permanently hidden, and it was overwriting `regionByKey` — the live region the cached-page fallback highlights. Registration from inside a ghost job no longer replaces a live region, and no longer consumes a pending deep-link either: the run is asynchronous now, so it can overlap a jump the player just made.
- **New** — `GS.JumpToPath(cat, path, sectionLabel)`, where the caller names the exact route rather than looking one up. It reconstructs the composite key from the same tab path registration uses, so it lands on a cold client and is unaffected by how far indexing has got.

#### Roles — The Guide Buttons Now Name Their Own Route

- **Fix** — The buttons on the three guide pages opened the right category and then left the player on whatever tab they had last used. They resolved their target against the search index, and the sections they point at — raid frame HoTs, party defensives, nameplate tank mode — were all sitting in non-first sub-tabs, which is precisely what the index did not cover. The lookup missed, and the fallback path is "open the category and stop".
- **Change** — Every one of the eighteen cards now declares its own `path`, one tab key per nesting level, next to the section it targets. Declared rather than derived: only the first tab of a panel is built eagerly, so there is no reliable moment at which the guide page could have discovered the route on its own.
- **Change** — Deep-links drop the target category from the panel cache before switching to it. A cached page is re-shown without being rebuilt, no tab bar is created, and the requested path is never read — which is what made these links land on the last tab used rather than the right one.

#### Class Reminder — It Was Reading The Stance Bar By Position

- **Fix** — Forms and stances were matched by their index on the stance bar: Cat was 2, Bear was 1, Moonkin was 4. That index is a function of which talents are picked, so on any build where it shifted, the reminder was comparing the player's actual form against an unrelated slot — reporting a missing form while standing in it, or staying silent while out of it. Every form is matched by spell ID through `GetShapeshiftFormInfo` now.
- **Fix** — A form absent from the stance bar was reported as missing. It is not missing, it is not learned, and no amount of pressing anything would clear it. Entries whose form is not on the bar are suppressed, and the spell is checked against the player's spellbook before any verdict is formed.
- **Fix** — Warriors had one generic "Stance" entry covering bar slots 1 to 3, on every specialisation, whether or not the character had taken a stance talent at all. There are three entries now — Battle, Berserker, Defensive — each gated to the specialisation that uses it and keyed on its own talent spell.
- **Fix** — Paladin auras were declared as shapeshift forms, spanning seven bar slots. They are player buffs and were never going to be found there. They are looked up as auras now — out of combat only, and never inside an arena or battleground, because the aura data is contextually secret in Midnight and a verdict drawn from it during a fight would be a guess.

#### Class Reminder — Reminders That Could Never Be Satisfied

- **Fix** — Evoker tracked exactly one Blessing of the Bronze buff ID. The spell applies a different ID per receiving class, so twelve classes out of thirteen carried the buff and were told they were missing it, permanently, for as long as the module was on. All thirteen IDs are tracked.
- **Fix** — Same shape for the talent variants: Mark of the Wild and Arcane Intellect each have a second aura ID on some builds, and Moonkin Form and Shadowform each have a second form ID. Only the base ID was listed, so a player on the variant was reminded about a buff they were already running.
- **Change** — Aura reads are gated on a whitelist of IDs that stay readable through combat lockdown. Anything outside it is not evaluated in combat rather than judged on unreadable data — a silent reminder is better than a wrong one, and a wrong one is what the alternative produces.
- **Change** — Every label now comes from the client's own name for the spell, with the locale table kept only as a fallback for the moment before the spell cache is warm. Six translations of "Bear Form" that could drift from the game's own wording were six chances to disagree with the tooltip.

#### Class Reminder — From A Line Of Text To A Row Of Icons

- **Change** — The reminder was a pulsing line of text in the middle of the screen naming what was missing. It is a row of icons now, one per missing buff, form, stance or aura, with the spell's own art and an optional label underneath.
- **New** — Out of combat each icon is a secure action button: left-click casts the missing spell directly, rather than reading its name and going to find it on a bar. Middle-click dismisses that one reminder until the next loading screen, for the buff you have decided you are not taking today.
- **Change** — Nothing is clickable in combat, deliberately. Secure buttons cannot be shown, hidden or reconfigured under lockdown, so combat is served by a parallel pool of plain frames while the secure row is faded out; a row that stayed visible and armed would be lying about what pressing it does. The swap uses the same skin on both pools, so it is invisible.
- **Internal** — The anchor frame is shown once and never hidden again. It parents protected buttons, and hiding the parent of a protected frame during combat is exactly the call that propagates taint; visibility is carried by the icons and the anchor's alpha, neither of which is protected.
- **New** — Icon size, spacing, row scale, opacity, the label and its size, and a glow (none, pixel, autocast shine, action button, proc) with its own colour.
- **Change** — The two position sliders are gone. The row is placed with the mover like every other movable element, and it registers its own entry in the Movers panel; an existing offset is carried over once as a real anchor point and the dead keys are dropped.
- **Change** — Placement mode and the preview both draw the plain pool, never the secure one: a preview you can click into a cast is not a preview.

#### Class Reminder — The Panel Shows The Row It Configures

- **New** — The options panel opens on a live preview of the row, drawn by the module itself from the current settings, so every slider moves the thing you are actually looking at. It owns its own pool of plain frames — the options window must never host a secure action button, or hovering a config widget would arm a real cast.
- **New** — The preview is a navigation surface. Clicking an icon jumps to that reminder's toggle, clicking its label jumps to the label options, clicking the empty space around it jumps to the sizing sliders. The travel is animated and the destination outlined: an instant jump reads as the panel having been rebuilt.
- **New** — The list of supported classes was a paragraph of text per class. It is a four-column grid now, one cell per tracked buff or form, coloured by class, and each cell is a toggle — untick anything you do not want to be reminded about. A missing key means enabled, so a profile that predates the grid tracks everything exactly as before.
- **Internal** — `W.SmoothScrollTo`, `W.FlashHighlight`, `W.ScrollToFrame` and `W.CreateCheckboxGrid` are general widgets rather than panel-local helpers. Grid columns are measured on `OnSizeChanged`: a tab built while its panel is hidden reports a width of zero, which would collapse every column onto the left edge.

#### Class Reminder — Weapon Imbues, Rites And Poisons Enter The List

- **New** — Shaman weapon imbues are tracked: Flametongue, Windfury, Earthliving, Tidecaller's Guard and Thunderstrike Ward, one entry each because Enhancement runs two at once. The "do I know this?" gate keeps the others silent on the specs that cannot cast them, so no per-spec list has to be maintained.
- **New** — The Lightsmith rites — Rite of Adjuration and Rite of Sanctification — share a single reminder, since they are mutually exclusive and having either satisfies it. The icon points at whichever one the paladin has actually taken.
- **New** — Rogue poisons, one reminder per category rather than per poison: Lethal and Non-Lethal. What matters is whether the slots are filled, so the check counts how many of the category's poisons are active against how many the player can apply — one, or two with Dragon-Tempered Blades. That survives any talent build without listing builds.
- **Internal** — Imbues and rites are temporary weapon enchants, not auras, so `UNIT_AURA` never fires for them and the reminder would only have cleared on the next unrelated refresh. `WEAPON_ENCHANT_CHANGED` and `UNIT_INVENTORY_CHANGED` are registered for exactly this.
- **Internal** — Enchants are read through `C_PaperDollInfo.GetTemporaryEnchantmentInfo` where it exists. `GetWeaponEnchantInfo` is a deprecation shim behind a CVar in 12.1; it stays as the fallback rather than the primary.
- **Change** — Every one of these is evaluated out of combat only. None of them can be applied mid-fight, so a reminder during one is an icon you cannot act on.

#### Class Reminder — Shaman Shields, And What Elemental Orbit Does To Them

- **New** — Lightning, Water and Earth Shield are tracked, and Elemental Orbit changes the answer rather than being ignored. With the talent the shaman carries Earth Shield on themselves *and* one of the other two, so that is two entries; without it any one shield satisfies a single entry. The talent gate decides which pair of entries is live.
- **Change** — The shield entry names the category — "Lightning / Water Shield" — and its icon and click resolve to the right spell for the current specialisation, Water for Restoration and Lightning otherwise. A reminder that names one specific shield is wrong for half the specs that see it.
- **Internal** — Earth Shield's self component is added to the combat-readable whitelist, because it can be cast and read during a fight. The other two are not, and stay out-of-combat only.

#### Class Reminder — Where The Row Is Allowed To Appear

- **New** — A *Show reminders* setting: everywhere, in dungeons and raids only, or in a group only. The reminder is worth having before a pull and mostly noise while questing, and that balance is per-player rather than something to be assumed.
- **New** — Hidden in cities and inns by default. The rested state is exactly where you are about to reapply everything anyway.
- **Change** — The row is also silenced while dead or a ghost, in a vehicle, and while flying on a mount. Each of those is a state where nothing on the row can be pressed, so showing it only asks the player to read it and do nothing.
- **Internal** — All of it is event-driven — resting, death, vehicle, mount display, zone — so none of these conditions costs a poll.

#### Class Reminder — It Can Watch The Group Too

- **New** — *Also remind when a group member is missing a buff*, off by default. With it on, a group buff you are carrying still raises its reminder when someone in range does not have it — which is the case the reminder always missed, since a buff on yourself says nothing about the rest of the party.
- **Change** — Only members who actually want the stat are counted. Intellect and attack power each carry a class list, and a class is listed when any of its specs wants it: that over-counts a Retribution Paladin for Intellect and never under-counts anyone who needs the buff. The class gate runs before the aura read, so non-beneficiaries cost nothing.
- **Change** — Out of combat only. Another player's auras are secret values during a fight, and a nil answer there reads as "missing" — which would put a permanent reminder on screen for the whole pull. Only whitelisted IDs are consulted even out of combat.
- **Internal** — Range mirrors the raid frames' own path: `UnitInRange` when it answers in plain Lua, `UnitIsVisible` when it comes back secret. Visible is coarser than cast range but still excludes what matters — another wing, another zone, another phase.
- **Internal** — Broad `UNIT_AURA` fires for every member of a raid, dozens of times a second. It is registered only while the setting is on, the player's class actually has a group buff, and there is a group; otherwise the module keeps its player-only registration. Events that do get through are coalesced into one deferred pass.

#### Class Reminder — The One-Second Ticker Is Gone

- **Change** — The module ran a `C_Timer` ticker at 1 Hz for as long as it was enabled, re-scanning auras and the stance bar whether or not anything had changed. `UNIT_AURA` already fires on gain, loss and expiry and the stance bar has its own events, so the polling was pure overhead. It is event-driven now, with a 0.2 s coalescing window so a burst of events costs one scan.
- **New** — It also listens for talent and spellbook changes. The set of available forms moves when a build changes, and an entry that was "not learned" a moment ago becomes trackable without anything else waking the module up.

#### Unit Frames — The Settings Preview Was A Mock-Up Of The Real Thing

- **Change** — The preview drew its own fake bars. Same numbers out of the database, entirely separate code — which is a guarantee of divergence, not of accuracy, and it had diverged. The frame construction is now split out of the oUF style function into `UF.BuildVisuals` (widget tree) and `UF.ApplyVisuals` (geometry, textures, fonts), and the preview calls exactly those.
- **Change** — What that buys: bar texture, fonts, borders, the info bar, element offsets, the aura grid, enemy buffs, the threat glow and the threat text in the preview are now produced by the same factories as your real frames. There is no second implementation left to drift.
- **Internal** — Scale is applied with `SetScale` on a container, never by multiplying the database values, so the proportions on screen are the ones you configured.
- **Internal** — The preview's aura containers take a name override and are suffixed. Without it, building real containers in the preview would register them as `TomoMod_Auras_player` and overwrite the frame the Movers module uses — including on the late creation path inside `UpdateEnemyBuffs`, which now carries the suffix on the frame.

#### Unit Frames — The Preview Shows Your Actual Units

- **New** — When the unit exists — your target, your focus, your pet — the preview frames are fed real data and tagged LIVE. When it does not, they fall back to simulated values tagged SIM, and the tag flips as the unit appears and disappears. Toggleable, and on by default.
- **New** — A Fit / 1:1 switch, so the frames can be checked at their true pixel size rather than in the scaled-down strip.
- **Internal** — The preview never calls a unit API that can return a Midnight secret value. It tests `UnitExists` and delegates everything else to the engine, where the values are already handled on the C side through `SetValue` / `SetFormattedText` / `SetTexture`.
- **Internal** — The live refresh only runs while the panel is on screen: ticker and events are created on show and torn down on hide. `UNIT_AURA` marks the unit dirty and the ticker absorbs the burst, so a raid-wide aura storm costs one table index per event rather than an aura scan.

#### Unit Frames — Bar Texture And Aura Timers Needed A Reload

- **Fix** — The status bar texture was only read when a frame was first built, so changing it did nothing at all until the next `/reload` — on real frames, not just in the preview. It is reapplied live now, through a helper that puts the tint back: `SetStatusBarTexture` resets the vertex colour to opaque white.
- **Fix** — Same for `showDuration` on aura and enemy buff icons: the countdown numbers were configured at icon creation and never revisited.

#### Mythic+ — Dungeon Teleports You Own Were Reported As Not Learned

- **Fix** — The M+ hub and the scoreboard tested teleports with `IsSpellKnown`, which only reports spells granted through the class or pet spellbook mechanism. Dungeon and raid teleports are granted by achievements, so it answers false for every one of them — including ones sitting in the player's own spellbook. Reported for Skyreach (159898), and it applied to the whole list.
- **Change** — What that looked like: the dungeon name greyed out, the tooltip reading "teleport not available", and clicking the row printing "not learned" while the secure button stayed disabled, so nothing was cast. A teleport you had earned was a teleport the panel refused to use.
- **New** — `TomoMod_DataKeys.IsTeleportKnown` is now the single test, next to the teleport data it guards: `IsPlayerSpell` first, which covers achievement-granted spells, then `IsSpellKnownOrOverridesKnown` for a teleport replaced by a newer rank, then `IsSpellKnown` as the last resort. ProfessionHelper and the CooldownForge catalog already combined the first two; this is the same rule rather than a fourth variation of it.
- **Change** — All seven call sites across the hub and the scoreboard go through it — click handler, tooltip, secure button attribute and the name colouring — so the row's appearance and what pressing it actually does can no longer disagree.

#### Mythic+ Scoreboard — The Group's Keystones, On Demand

- **New** — `/tm keys` opens the scoreboard on the live group: every member with their name, class, Mythic+ score and the keystone they are holding. The board only ever appeared on its own at the end of a run, and the one command that opened it manually — `/tm score` — showed sample data laid out to position the frame, not anyone real. Deciding which key to run was the moment the board was least reachable.
- **Change** — It works outside an instance, which is where it is wanted. The run-data collector was already safe there: the Mythic+ block is gated on the challenge difficulty, the unit list falls back to the player when solo, and the damage totals simply come back at zero.
- **Note** — `/tm score` is unchanged and still opens the sample board for positioning; `/tm keys` is the real one.

#### Mythic+ Scoreboard — Roles At A Glance, And A Stable Order

- **New** — Each row now carries a role icon next to the specialisation icon, tinted with the colours the archetype cards and the config role badges already use. The spec says what the player brought, the role says what they are doing with it, and a keystone board read before pulling wants both. The frame widened from 340 to 360 to fit them.
- **Fix** — Your own specialisation was missing from your row. `GetInspectSpecialization` returns zero for the player themselves and only answers for units whose inspect data is cached — which everyone's is by the end of a run, and nobody's is when the board is opened from town. Your spec is read directly now, with the inspect path kept for everyone else.
- **Fix** — Players in the same role were left in whatever order `pairs` produced. After a run damage separated them, but outside one it is zero for everybody, so the same group came out in a different order on each opening of the same board. Ties now fall through to keystone level, then score, then name.

#### Delete Confirmation — Reading A Field Blizzard Had Already Removed

- **Fix** — The auto-fill that types the confirmation word into the delete popup looked for the edit box on `dialog.editBox` first. That field was removed in 11.2, so the lookup only ever succeeded through its second choice, a guess at the frame's global name — a fallback that holds until the popup stops being a globally named frame, at which point the box silently stops being filled.
- **Change** — It goes through `TomoMod_Utils.PopupEditBox` now, which asks the supported `:GetEditBox()` accessor first and keeps the removed field and the global name only as fallbacks. The helper already existed and was already used by the Cooldown Studio popups; this was the last place still resolving the edit box by hand.

#### Contacts — The Friends Window Skin Is Retired

- **Removed** — The Contacts skin shipped in 3.2.5 and is gone: the module, its tab under Skins, its two settings, and its strings in all six languages. Blizzard rebuilds `FriendsFrame` in 12.1, and the skin worked by reaching for several dozen of that window's regions by name — `NineSlice`, the eight inset border pieces, the bottom tab plates, the Who column headers, `FriendsFrameAddFriendButton` and the rest. Every one of those names is one the rebuild is free to move, rename or drop. A skin written against them does not degrade gently on patch day; it leaves a half-stripped window, and it does so first for the people running it rather than for anyone in a position to fix it.
- **Change** — For anyone who had the skin switched off — the default it shipped with — nothing about the friends window changes. For anyone who had it on, the window returns to Blizzard's own appearance. The skin only ever dimmed Blizzard's artwork with `SetAlpha(0)` and never destroyed a texture, so there is nothing left behind to restore.
- **Note** — The Contacts button added to the chat sidebar in 3.2.4 stays. It opens the friends window and was never part of the skin.
- **Internal** — `TomoModDB.friendsSkin` is dropped by a one-time migration rather than left in every saved profile as a table nothing reads. The module file and its `QOL.xml` include are removed together: an `<Include>` pointing at a deleted file is a load error, not a smaller addon.

#### Chat History — One Switch, And Six Settings Nobody Could Reach

- **New** — The chat history had exactly one control: on or off. It has a section of its own now — how long messages are kept (1 hour, 6 hours, 24 hours, 3 days, or no limit), how many lines are stored (10 to 500), the delay before the replay, a session marker, the per-channel filter, and a button to clear everything.
- **Fix** — The stored line limit was `while #data >= 128`, which trims until the table is at 127. It never kept the 128 lines it claimed to. The cap is `>` against the configured value now.
- **Change** — Both limits are enforced on replay as well as on write, so lowering one takes effect at the next login rather than only governing messages recorded from that point on. Age pruning stops at the first entry that is still fresh — entries are appended chronologically, so the stale ones are always at the front — and an entry with no usable timestamp is treated as stale rather than being left to stall the loop.
- **New** — A session marker is printed after the restored lines, so everything below it is unambiguously from the current session. Nothing used to separate the two, and a conversation replayed from yesterday reads exactly like a live one.

#### Chat History — The Replay Was Burying Every Addon Load Message

- **Fix** — The replay ran inline inside the chat skin's own load, which is precisely when addon load messages and Lua errors reach the chat. Up to a full page of restored lines landed on top of them, every login. The replay is deferred now — two seconds by default, adjustable from 0 to 10.
- **Note** — The reason is stated on the panel next to the slider, because zero looks like the obviously correct value right up until the login where an error you needed to read scrolls past under a hundred lines of yesterday's guild chat.

#### Chat History — Channels, And Deleting What Is Stored

- **New** — The per-channel filter — whispers, guild, officer, party, raid, instance, channels, say, yell, emotes — has been in the database since the feature shipped and had never appeared anywhere in the interface. It is on the panel, as five pairs of checkboxes.
- **Note** — An unchecked channel is not recorded at all rather than merely left out of the replay: the filter is applied on write as well. Re-ticking one does not recover what went past while it was off.
- **New** — A "Clear chat history now" button, behind a confirmation, which reports how many messages it dropped.
- **Change** — Turning the feature off now clears what is already stored. It used to stop recording and leave every saved line in the saved variables indefinitely — a toggle that looked like it had done nothing, on data the player had every reason to believe they had just deleted. The panel states this above the checkbox, along with the fact that the history is stored account-wide and is therefore shared by every character.
- **Internal** — `GetChatHistoryCount`, `ClearChatHistory` and `ApplyHistorySettings` deliberately do not gate on the chat module having initialised. They only touch the saved table, and the config panel has to stay able to clear or re-bound the history while the chat skin itself is switched off.

#### Cooldown Studio — The Button Now Says What Went Wrong

- **Fix** — "Ouvrir le Cooldown Studio" could do nothing at all. `TomoMod_CDStudio` is a LoadOnDemand sibling addon, and every way that load can fail was collapsed into one message that named only the least likely cause: *not installed*. A player whose Studio folder was sitting right there, merely left unchecked in the addon list, was told to go and install something they already had.
- **New** — Each failure token `C_AddOns.LoadAddOn` returns now gets its own explanation and its own fix: `MISSING` says the folder must sit *next to* TomoMod in `Interface/AddOns` and never inside it, `DISABLED` names the entry to tick, `INTERFACE_VERSION` points at "Load out of date AddOns", and the dependency, corruption and security tokens each say which of those they are. The client's own localized wording for the reason is kept and the remediation is appended to it — the game says *what*, we say *what to do*.
- **New** — The common case repairs itself. On `DISABLED` the addon is enabled and the load retried immediately; where the client will not honour that within the same session, the enable still sticks and the message asks for a single `/reload` rather than sending the player to the addon list.
- **New** — The Cooldowns panel states the blocking reason on the card itself, before the click, whenever the Studio cannot currently be loaded. The button deliberately stays enabled: for `DISABLED`, clicking it is exactly what fixes the situation.
- **Fix** — A Studio that loaded but never initialized swallowed the click in silence. `CDStudio.lua` returns early when `TomoMod_Widgets` is unavailable, which left `LoadAddOn` reporting success and nothing on screen. It now publishes `TomoMod_CDStudio.loadError` on the way out, and the launcher reports that instead of pretending the click never happened.
- **Change** — `TomoMod_CDStudio.toc` carries a category, the TomoMod icon, and the same version number as the main addon. It was still declaring `1.0.0` and showing up unbranded in the addon list, which made it look like a foreign addon that happened to share a name — and made "is it even installed" harder to answer than it needed to be.

#### Packaging — A Zip That Cannot Hide The Studio Any More

- **New** — `Tools/build_release.py`, a standard-library-only release builder. It reads `.pkgmeta`, drops everything under `ignore:`, applies `move-folders:` so the sub-addons land as siblings, and writes `.release/TomoMod-<version>.zip`. `--check` validates the layout and writes nothing.
- **New** — The layout gate is the point of it. `TomoMod_CDStudio` lives inside the repo for convenience, but WoW only scans the top level of `Interface/AddOns` — a zip that ships it nested is a zip in which nobody can see the Studio in their addon list at all, which is precisely the state the launcher work above spent its time diagnosing. Every top-level folder must own a matching `.toc`, no addon folder may be nested inside another (bundled libraries excepted), and the build refuses to write the zip otherwise.
- **Change** — `Tools` is excluded from the released zip via `.pkgmeta`, and Python bytecode is ignored by git. The TOC never loaded any of it and players have no use for it.

#### Diagnostics — The Export Window Was Fighting Itself Over One Clipboard

- **Change** — The export window asked the player to copy the report, and named the tracker address in its own title — an address only reachable by copying it, which would have thrown away the report they had just taken. The window now switches between two views, *Report* and *Link*, and says which one is loaded, instead of quietly leaving them to compete for the same clipboard.
- **New** — The tracker address is printed on the window in plain, readable text as well. Reading eight words off the screen beats a round trip through the clipboard for anyone who is going to type it into a browser anyway.
- **New** — A line under the hint states that the report is saved and can be reopened with `/tmdiag tracker`. Entries live in SavedVariables, so copying the link first costs nothing — but nothing said so, and the safe-looking move was to not touch anything.
- **New** — Closing the window prints the tracker address in chat, once per session, so a player who closes too fast still leaves with somewhere to send the report.
- **Change** — The console's button reads "Copy for tracker" rather than "Export Tracker". It copies to the clipboard; it never exported anything anywhere.

## ####################################

## CHANGELOG 3.3.3 — Party And Raid Stop Keeping Two Copies Of The Same Code, The Summon Icon Stops Waiting For A Reload, Defensive Cooldowns Arrive On Party Frames With Categories You Can Filter, A Diagnostics Report Finally Says What Resolution And Scale It Was Written At, And The Stance Bar Stops Putting Ten Empty Squares On Screen

#### Group Frames — The Summon Icon Was Staying Up Until `/reload`

- **Fix** — Accepting or declining a summon left the icon on the frame for the rest of the session. `C_IncomingSummon.IncomingSummonStatus` does not reset to `None` once a summon is resolved server-side — it keeps returning the *last* status, `Accepted` or `Declined`, because the record is flagged inactive rather than cleared. Reading it on its own therefore describes a summon that stopped existing minutes ago, and only a reload rebuilt the client-side cache. `HasIncomingSummon()` is the authoritative gate and is checked first now, which is what Blizzard's own `CompactUnitFrame` does.
- **Fix** — A roster change moves a different player onto the same unit token, and nothing re-read the summon state when it happened: the previous occupant's icon stayed on a frame that now belonged to someone else. `GROUP_ROSTER_UPDATE` and zoning both refresh every frame now.
- **Fix** — The indicator was never refreshed by the frames' own update pass. It was only ever touched by `INCOMING_SUMMON_CHANGED`, so a frame rebuilt for any other reason — a resize, a settings change, a group re-sort — came back with whatever the indicator happened to be showing before. It is part of `UpdateFrame` now, in both modules.
- **Change** — A resolved summon is additionally dropped after six seconds, on a one-shot timer armed at the moment of resolution. `HasIncomingSummon` is the real fix; this exists so that a realm or a future build where that gate misbehaves degrades into a stale icon for six seconds instead of one for the session.
- **Internal** — All of it lives in one shared module now instead of two byte-identical copies, one in the party frames and one in the raid frames. That duplication is the actual reason this bug lasted: there was no way to fix it once.

#### Party & Raid Frames — Defensive Cooldowns, With Categories

- **New** — Party frames show defensive cooldowns active on each member. This existed on raid frames only, and there it was a single icon with no duration and no indication of what kind of cooldown it was.
- **New** — Defensives are split into three categories, and each has its own toggle on both panels. *External* — cast by someone else on this player: Ironbark, Life Cocoon, Pain Suppression, Guardian Spirit. *Raid-wide* — one cast landing on the whole group: Rallying Cry, Darkness, Anti-Magic Zone. *Personal* — the player pressing their own button: Divine Shield, Ice Block, Barkskin. Fifty spells in total.
- **Change** — Externals are on by default and the other two are off. A raid-wide cooldown lights up every frame at once, which is exactly when a healer is least able to read them, and personals are informative but constant. Externals answer the question the display exists for: does this target already have something on it.
- **Change** — Icons are sorted so externals come first whatever else is up, they show remaining time, and the border is coloured by category — gold for external, cyan for raid-wide, red for personal. Up to four per frame, configurable, at a configurable size.
- **Fix** — On raid frames the defensive icon size slider wrote the value and stopped there; nothing reapplied it, so the icons only took the new size after a reload. It applies live now, like every other slider on that panel.

#### Party & Raid Frames — The HoT List Had Already Drifted

- **Fix** — The party frames and the raid frames each carried their own copy of the healer HoT database, and they no longer agreed: the party copy knew about Blessing of Summer, Cloudburst Totem and Enveloping Breath and the raid copy did not, so the same buff on the same player showed on one set of frames and not the other. There is one list now, the union of both, at 35 spells across Priest, Druid, Paladin, Shaman, Monk and Evoker.
- **Internal** — Every duration and expiration time read back from the game passes through one guard before any arithmetic touches it. On group members in 12.x those fields can be handed over as protected values, and subtracting a timestamp from one is the cardinal taint mistake — the same class of bug 3.3.1 fixed across the tooltip files and 3.3.2 fixed in the aura tracker.
- **Internal** — The aura scan sorts by insertion rather than through `table.sort`. At two or three entries it is faster, and it allocates nothing — `table.sort` would need a comparator upvalue on a path that runs on every `UNIT_AURA`.

#### Party & Raid Frames — Dispel Border Thickness

- **New** — The dispel highlight's border thickness is now a slider, 1 to 6, on both panels. At the default of 2 the geometry is identical to what shipped before.
- **Change** — The border grows outwards from the frame edge instead of inwards, so a thicker one never eats into the health bar. It is applied live and on every settings pass, not only at frame creation.

#### Action Bars — The Stance Bar Was Showing Ten Empty Squares

- **Fix** — With "show empty button slots" off, the stance bar could still put all ten of its buttons on screen. The pass that reveals empty slots while a spell sits on the cursor ran over every bar, including pet and stance — whose buttons are not action slots at all. It looked up their action id, found none, fell through to `0`, and `HasAction(0)` is false, so all ten were judged empty and shown. The guard the "show empty buttons" pass already carried for those two bars now applies to the reveal as well.
- **Fix** — The return path was the worse half: re-hiding the slots delegates to that same guarded pass, which skips pet and stance, so nothing ever put them back. They stayed on screen until the next stance change, at which point Blizzard's own per-button update hid the ones without a form — which is why the bar looked like it fixed itself the moment you switched stance, and only then. Both bars are excluded from the reveal outright now: a stance button has no slot to drop a spell into, and the pet bar has Blizzard's own `PET_BAR_SHOWGRID` handling on the buttons themselves.

#### Diagnostics — A Report From An 8K Client Now Says So

- **New** — Reports carry a Display block: physical resolution, UI units, display mode, render scale, `UIParent`'s scale and effective scale, the `uiScale` CVar, and the pixel-perfect scale for that resolution. Above 1200 vertical pixels the client refuses to take `uiScale` below 0.64, so high-resolution players rescale `UIParent` themselves or through another addon — and that rescale is reapplied after every loading screen, leaving anything positioned before it lands holding coordinates computed under the previous scale.
- **New** — A scale or resolution change during the session is logged as its own entry, with the before and after values, so a rescale appears in the report next to the errors it may have caused. Capturing the scale once at login would not have shown that, and *when* it moved is the whole point.
- **New** — The report flags a `UIParent` scale that does not match the CVar. That mismatch means something set the scale directly — a macro, a rescaling addon, or one of our own modules — which is worth knowing before reading anything else in the report as a positioning bug.
- **New** — A Performance block: current framerate, session minimum / average / maximum sampled every five seconds, and home and world latency. Every captured error also records the framerate at the moment it fired. An error that only ever appears on a stuttering client is an ordering race, not a logic bug, and nothing in a report used to distinguish the two.
- **Internal** — Display CVars have been renamed across expansions and `GetCVar` returns nil for a name the client does not know, so each one is probed through a list of candidates rather than assumed. `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` are registered through `C_EventUtils.IsEventValid` for the same reason.
- **Fix** — The "`UIParent` scale does not match the CVar" warning fired on virtually every normal setup. With `useUiScale` off the CVar is inactive and the client falls back to the resolution's own default, floored at 0.64, so comparing `UIParent` against a value nothing is reading reported an override that did not exist. The report now derives what the scale *should* be for the current configuration, prints it as its own line, and flags only a genuine divergence from it.
- **Fix** — The client applies its own scale during login, and that was landing in every report as a mid-session rescale. Display capture stays silent for the first four seconds now and then takes a single reading; if the settled scale is not where the client would have put it, that one entry is the one worth correlating against the errors around it.
- **Change** — A display mode that cannot be interpreted is printed alongside the raw probe: every `gx*` CVar the client actually answered. Those names move between expansions, so a report that says `?` and nothing else costs a round trip to diagnose, and guessing a second name blind is worse than reporting what was asked. `gxWindowedMode` is accepted as an alternative to `gxWindow`, and a maximized window with no windowed flag is named rather than falling through to `?`.
- **Fix** — The loaded-addon list read `vv1.2.3` for any addon whose TOC version already begins with a `v`, and an addon with no version at all would have raised while the list was being built.

#### Internal

- **Change** — New `Modules\Interface\Shared\` folder, loaded before the party and raid modules: the summon state, the aura database and the defensive cooldown track live there. It replaces a little over 250 lines that existed twice, and the three bugs above were all consequences of that — a fix applied to one copy and not the other, or a list edited on one side only.

## ####################################

## CHANGELOG 3.3.2 — The Client Stops Waking Us For Twenty Other People, Skyriding Stops Building A Second Bar, Tooltips Keep Their Item Level In Combat, The Pet Reminder Stops Coming Along For The Flight, And Six Languages Finally Say The Same Thing

#### Companion Status — The Pet Reminder Has Settings

- **New** — QOL → Pet Reminder. The module shipped with three slash commands and no panel at all: enabling it, its scale, its icon size, its display mode and its position were reachable only by editing the saved variables file by hand. All of them are now on a tab — enable, hide while mounted, icon / text / both, scale, icon size, horizontal and vertical offset with a reset button — and every change applies to the reminder as you make it, with no reload.
- **New** — The panel states which specializations the reminder ever appears for — Beast Mastery and Survival hunters, all warlocks, Unholy death knights — and that Lone Wolf and Grimoire of Sacrifice turn it off by themselves. That gating has always been there; nothing anywhere said so, which made a silent reminder indistinguishable from a broken one.
- **New** — `/cs mounted` toggles the ground-mount suppression from chat, alongside the existing `/cs on`, `/cs off` and `/cs debug`. The command list printed by a bare `/cs` lists it.
- **Fix** — "Pet missing" and "Pet dead" were hardcoded English inside the module, so the only two strings the reminder actually puts on screen were the two that ignored the client's language. They are localized in all six now, along with the twenty strings the new panel needs.
- **Internal** — The position sliders move the offsets only; the anchor stays CENTER on both sides. Exposing the anchor points as well would let a profile end up anchored off-screen with no obvious way back, and the reset button exists precisely so that is never a state anyone has to recover from by hand.
- **Internal** — The settings stay in the module's own `CompanionStatusDB` saved variable rather than moving into `TomoModDB`. Folding them in would be tidier and would mean migrating every existing profile for a five-option module, so the panel reaches in through a small API on the module instead of touching its frame directly.

#### Companion Status — It Was Staying On Screen For The Whole Flight

- **Fix** — The reminder is drawn at scale 4.0 in the middle of the screen, and it could sit there for an entire flight. Its only travel test was `IsFlying()`, which is polled state — the client announces nothing when you leave the ground — and it was evaluated from pet, spec and talent events, all of which happen while you are still standing on it. So the answer was decided as "not flying" a moment before takeoff, the reminder was shown, and there was no event left that could ever hide it again.
- **Change** — Being mounted, on a taxi and in a vehicle now suppress it too, and that is what makes the module event-driven rather than quietly dependent on a poll it never had: every entry into and exit from a travel state passes through `PLAYER_MOUNT_DISPLAY_CHANGED`, `PLAYER_CONTROL_LOST` / `GAINED` or `UNIT_ENTERED` / `EXITED_VEHICLE`. Taxi flights take control away rather than firing a mount event and vehicles fire neither, so both were previously invisible to it; all four are registered now, and nothing is put on a timer.
- **Note** — Suppressing on a ground mount is also the honest behaviour: mounted, you cannot summon a companion anyway, so the reminder has nothing left to remind you of. It is the one of the four states that can be switched back off, for anyone who wants the reminder waiting for them when they dismount. Flying, taxi and vehicle are unconditional.
- **Internal** — Mount, taxi and vehicle state is not always settled on the frame its own event fires, so those five events take a second look on the next one rather than trusting the first read.
- **Internal** — `ShouldShowIcon` and `UpdateIcon` are gone. They hid the icon texture on the flying test inside a frame that was already being hidden on the same test, and they ran exactly once, at load — dead weight that read like a second, independent visibility rule.

#### Auras & Castbars — Events Filtered At Registration Instead Of At The Handler

- **Change** — `UNIT_AURA` is now registered player-only in the Aura Tracker and in the Buff Skin. Both handlers only ever acted on `"player"`, but an unfiltered registration wakes the frame for *every* unit whose auras change — twenty-plus raid members plus every visible nameplate, continuously, for the entire pull — and each of those wake-ups existed purely to compare a unit token and throw it away. The client drops them now, before any Lua runs.
- **Change** — Same treatment for the castbar's latency frame: `UNIT_SPELLCAST_SENT`, `SUCCEEDED`, `INTERRUPTED` and `FAILED` are registered against `"player"`. `UNIT_SPELLCAST_SUCCEEDED` unfiltered is the loud one — it fires for every cast of every visible unit, so a pull of trash was dispatching into this addon on every mob's every ability.
- **Note** — This is also a taint measure, not only a performance one. Filtering at registration keeps insecure code out of the dispatch chain the game runs for those other units, and it deletes the `unit == "player"` comparisons themselves — which is the kind of comparison 12.x can hand a protected value to.

#### Aura Tracker — It Was The Overlay's Main Source Of Garbage

- **Change** — The aura scan runs on every player `UNIT_AURA`, several times a second in combat, and the icon layout runs with it. Between them they used to allocate a working table per call, one table per aura, one wrapper table per icon, and a fresh comparator function per layout — all of it thrown away microseconds later. Those tables are now module-scope scratch, wiped and refilled, the comparator is defined once, and the sort works on bare spell IDs. Nothing about the display changed; the churn did.
- **Fix** — Two auras applied in the same frame with the same duration share an expiration time to the millisecond, and with nothing to break the tie their relative order came from hash iteration order — so the two icons could visibly swap places between one refresh and the next. Ties are broken by spell ID now, which is stable.
- **Fix** — Every field read back from the game — name, stack count, duration, expiration — is sanitised at the single boundary where the game hands it over, so no consumer downstream (the sort comparator, the cooldown sweep, the timer text, the stack count) can be handed a protected value to compare or do arithmetic on.
- **Internal** — The guards test for a protected value *before* any comparison touches it, and say so in a comment at each one. The reverse order reads perfectly and raises on exactly the values the guard was written to catch — the same ordering bug 3.3.1 fixed across the tooltip files.
- **Internal** — Trimming the icon list down to the configured maximum iterates downwards instead of calling `table.remove` in a loop that re-measures the array on every pass.

#### Skyriding — `/tm skyride` Was Building A Second Bar Every Time

- **Fix** — `/tm skyride` resets the module's saved variables and re-runs its initialisation, which landed straight in the UI constructor with no guard. Every invocation built a fresh widget tree — four frames, four textures, six font strings — and pointed the global `TomoModSkyRideFrame` at the new one. WoW never collects a frame, so the previous tree stayed parented to UIParent: still rendering, no longer reachable from anywhere, and impossible to hide. The tree is built once now, and the command re-applies the (possibly reset) settings to it, which is what it was always meant to do.
- **Fix** — The same path assigned a new 4 Hz ticker on every run without cancelling the previous one — whose handle had just been overwritten, so nothing could ever stop it. A session accumulated one more permanently-running poll per invocation. The ticker is only started when there is not one already, and it is now cancelled when the module is disabled: the module's own default is off, so a ticker started earlier otherwise kept polling a bar nobody could see.

#### Tooltip — Item Level And Specialization Were Off For The Whole Fight

- **Fix** — Both vanished from every tooltip the moment combat started, and came back when it ended. The inspect engine's eligibility test ended on `CheckInteractDistance`, the only API that measures the real 28y inspect range. That function is nocombat-restricted: insecure code calling it during combat is refused and gets nothing back. So the test failed for every unit, on every tooltip, for the entire duration of every pull — while the taint log filled up with one `ADDON_ACTION_BLOCKED` per hover.
- **Note** — `pcall` did not help and could not have: a taint block is not a Lua error. The call returns `nil` and execution carries on normally, which is why this read as a feature quietly not working rather than as something broken. 3.3.1 had already routed this call through a boolean guard, which made it *safe* — it never made it *answer*.
- **Change** — `UnitIsVisible` stands in for it. It is unrestricted, so it works in combat, but it is coarser: client visibility is roughly 100y against the 28y the server actually requires. Requests that will never be answered therefore do get sent, where before they were correctly filtered out.
- **Change** — A per-GUID backoff is what pays for that. A unit whose request goes unanswered — out of inspect range, or answered with nothing readable — is parked for 20 seconds instead of being retried on the next tooltip pass. Only one inspect can be in flight at a time, and without this, a single out-of-range player under the cursor would take that slot over and over and starve the units close enough to actually reply.
- **Fix** — A request that timed out left the caller on "pending" indefinitely, so the tooltip kept showing its loading placeholder until the mouse moved away. The timeout was only ever evaluated on the send path, which a unit whose own request was already in flight never reached. Both paths go through the same prune step now.
- **Internal** — The comment above the eligibility test explains at length why the accurate API is *not* used, because the obvious future edit is to put it back.

#### Diagnostics — "No Path Available" Is Not A Bug

- **Fix** — Charging a target across a gap, Heroic Leaping onto a ledge, or ordering a pet somewhere it cannot walk logged a `UIError` entry in the diagnostics report. It is ordinary game feedback, like being out of range or facing the wrong way, and it is filtered now: `SPELL_FAILED_NOPATH` is resolved from the game's own strings, with substring fallbacks in all six languages for the locales where the key is missing or gender-inflected.

#### Localization — One Key Was Doing Two Jobs

- **Fix** — `opt_cb_enable` was defined twice in the same table: once as "Enable Standalone Castbars" for the Castbars panel, and again, further down, as "Enable consumable bar" for the Consumables tab. A Lua table constructor keeps the last value, so the key only ever held one of them and the Castbars panel's master checkbox was labelled "Enable consumable bar" — in all six languages. The consumable bar has its own key now.
- **New** — 173 strings per language translated into German, Spanish, Italian and Portuguese: the Cooldown Manager's advanced, visibility and extras sections, the objective tracker's quest buckets, the chat frame UI, the movers list and the cursor textures. They were not missing — they were silently falling back to English, which looks like a half-finished translation rather than a bug, and so had gone unreported.
- **New** — The 49 chat frame UI strings were doing the same thing in French, and are translated too.
- **Change** — A batch of French strings reworded for consistency: the compass and castbar-anchoring descriptions, the resource bar labels, and several places that left "player frame" untranslated or switched between addressing the player informally and formally mid-panel.
- **Fix** — The global search's "no matching option" line showed the raw key `gs_no_results` instead of the message. It was written as `L[key] or "fallback"`, which cannot work here: the locale table returns the key itself for anything undefined, and a key is a truthy string, so the fallback after `or` is unreachable and the key is what reaches the screen. The string is defined in all six languages instead.
- **Fix** — Two What's New lines from 3.1.8 printed `—` where an em dash belonged. That is JSON escape syntax; the game's Lua does not know it and printed it verbatim — the same failure the compass strings had in 3.3.0, from a different escape notation.
- **Internal** — 788 dead keys removed from `Locale_300.lua`, plus around 140 duplicate definitions across the six language files. The duplicates in `Locale_300.lua` were worse than dead weight: that file loads last, and because the base English table keeps the *first* definition while the active language keeps the *last*, an English client and a French client could resolve the same key from two different files and get two differently-worded strings. There is one definition per key per language now.

#### Packaging & Internal

- **Change** — The published package no longer carries the vendored libraries' own baggage: LibStub's test suites, LibDeflate's examples, generated docs and rockspec, and the README / changelog files scattered through `Libs/`. None of it is referenced by any `.xml`, it exists upstream for those libraries' CI, and it was pure download weight.
- **Fix** — The `.toc` referenced `Modules\Interface\CastBars\CastBars.xml` where the folder on disk is `Castbars`. Windows does not care and the game does not either; a packaging step on a case-sensitive filesystem does, and would have shipped a build with the castbars missing entirely.
- **Internal** — `ShowCopyStylePopup` in Cooldown Studio was declared as a global. It is used once, as a callback fifty lines below where it is defined, and an unprefixed global with a name that generic is an open invitation for another addon to collide with it. It is local now.

## ####################################

## CHANGELOG 3.3.1 — The Tooltip Information Layer Actually Shows Up In Midnight

#### Tooltip — Everything 3.3.0 Added Was Silently Switched Off
- **Fix** — The entire unit information layer never appeared in 12.x. Not one line: no guild rank, no target, no Mythic+ score, no mount, no speed, no location, no item level, no specialization, no name-line icons. The layer's first act is to read the unit token back from the tooltip, and Midnight hands that token out as a *secret* value routinely — which the guard rejected, so the post-call returned before writing anything at all. The feature was complete and untestable at the same time.
- **Fix** — Same cause, separate code path, for the reaction-colored border: it read the token through its own guard, got a secret one, and gave up. Every unit fell back to the configured border color, which reads exactly like the option doing nothing.
- **Fix** — The target line was lost twice over. Even reached, it ran the target's name through the same rejecting guard, so the line was dropped for any player whose name came back secret — which, in a group or in the open world, is most of them.
- **Change** — The target's name is no longer wrapped in a `|cff……|r` escape. Building that string means *formatting* the name, and formatting is reading; the name is now handed to the tooltip untouched and the color goes through `AddDoubleLine`'s own color arguments instead. Identical on screen, and it works on a name the client refuses to let an addon look at.
- **Note** — A secret value is not a value to be avoided, it is a value not to be *inspected*. A unit token, or a name that is only ever concatenated and handed straight back, is perfectly usable while secret; only a value this addon compares, pattern-matches or formats has to be refused. 3.3.0 drew that line in the wrong place and refused both.

#### Tooltip — The Guards Themselves Could Raise
- **Fix** — `SafeStr` tested `v == ""` *before* asking whether the value was secret. Comparing a secret value raises outright, so the guard crashed on precisely the values it existed to catch — and it was reached on every tooltip. Every helper now tests secrecy first and compares afterwards, in all three tooltip files.
- **Fix** — Boolean returns were compared raw: `UnitIsPlayer(unit) == true` reads as harmless but is still a comparison, and raises the moment the game returns a secret boolean. Every such test — `UnitExists`, `UnitIsPlayer`, `UnitIsUnit`, `UnitIsConnected`, `UnitIsDeadOrGhost`, `UnitPlayerOrPetInParty`, `CanInspect`, `CheckInteractDistance` — now goes through a boolean guard. That is roughly twenty comparisons across the tooltip and inspect modules, including the one that decided whether Blizzard's inspect window was open.
- **Fix** — The class token from `UnitClass` was type-checked but not secrecy-checked, then used as a table key against `RAID_CLASS_COLORS` and `CLASS_ICON_TCOORDS`. It is now rejected when secret, in both the border color and the class icon.
- **Internal** — A comment on every one of these helpers states the ordering rule explicitly, because the failure mode is invisible on inspection: the wrong order reads perfectly and only breaks on the values nobody has in a test client.

## ####################################

## CHANGELOG 3.3.0 — Tooltips That Tell You Who You Are Looking At, Delves Visible Again, CooldownForge Reads Your Resources & Supercharged Combo Points

#### Tooltip — A Real Unit Information Layer
- **New** — Unit tooltips now carry the information that used to require a dedicated addon: guild rank, the unit's current target, Mythic+ score, the mount being ridden, movement speed and location. Every line has its own toggle in Skins → Tooltip, under a master "Show unit information" switch, so the tooltip stays exactly as busy as you want it.
- **New** — Icons ride on the name line — raid marker, role, and optionally the class icon — at a configurable size. They are inline texture escapes rather than anchored textures, so the tooltip keeps sizing itself correctly around them instead of having its layout measured by hand.
- **New** — The border can take the unit's color: class color for a player, hostile / neutral / friendly for an NPC, grey for a corpse. It is reassigned on every show, so moving the mouse from a hostile unit onto an item falls straight back to the configured border instead of keeping the red one.
- **New** — The level line is recolored by difficulty, red for a boss or a "??" unit. The line Blizzard already built is recolored rather than rewritten: reconstructing "Level 80 Blood Elf Paladin" from parts is exactly where a secret value or a localized classification produces a mangled line.
- **New** — Target and speed refresh in place while the tooltip stays open, four times a second, and only while one of those two lines is actually on screen. Nothing polls when nothing needs it.
- **Change** — The tooltip health bar is now hidden by default — the information layer replaces it. A one-time migration brings existing profiles along; unticking the option puts the bar back and it sticks.
- **Note** — Location is deliberately limited to yourself and your party members. `C_Map.GetBestMapForUnit` returns nothing for an arbitrary target, so the line would be absent half the time rather than sometimes silently wrong. It is opt-in, and off by default.
- **Note** — The feature set is modelled on what TipTac Reborn shows, but nothing here derives from its code: TipTac is GPL-3.0 and TomoMod is not, so everything is written against Blizzard's public API only.
- **Internal** — Every unit read goes through a guarded helper that rejects a secret value and a wrong type alike. Branching on a secret value raises in 12.x, so a doubtful read means the line is skipped — never a guess, never a partial string.
- **Internal** — The layer rides on `TooltipDataProcessor`'s unit post-call rather than a `Show` hook: each appended line resizes the tooltip and re-fires `Show`, which that hook could not survive.

#### Tooltip — Item Level And Specialization
- **New** — Hovering a player now shows their equipped item level and their specialization, with the spec icon. Both require an actual inspect, so they only appear when the player is in range and connected. Out of range the lines are simply left out, rather than filling every open-world tooltip with an "unavailable" placeholder.
- **Change** — Item level is colored by the gap to your own rather than by season thresholds. Those rot at every patch, and the gap is the comparison a player actually makes when inspecting someone.
- **New** — A "..." placeholder holds the line while the server answers, and the value is written into that same line when it lands, so the tooltip does not jump under the cursor a second after it appeared. The placeholder can be turned off.
- **Internal** — Inspection lives in its own module that knows nothing about tooltips. It answers one question — "what do we know about this unit's gear and spec right now?" — with ready / pending / unavailable, and the display side owns everything visual.
- **Internal** — The inspect channel is shared and fragile, so requests are paced 1.5 s apart, only one is ever in flight, a silent request is abandoned after 3 s instead of blocking the queue forever, and results are cached per GUID for 5 minutes — a tooltip can be re-shown many times a second while the mouse sits still on a unit.
- **Internal** — While Blizzard's own inspect window is open the module stands down entirely rather than race it for the same channel, and it releases the channel after every reply so that window keeps working.

#### Party Frames — The Leader Is Marked
- **New** — The group leader now gets a crown above the top-left corner of their frame, with its own toggle and size slider. Party frames include you at index 0, so "I am the leader" is covered without a special case. Assistants are deliberately left out: they only exist in raids, and these are party frames.
- **Internal** — The icon is created on every frame regardless of the option, and the option is read when it updates. `ApplySettings` updates existing frames in place and never rebuilds them, so gating creation on the checkbox would have made it need a /reload.

#### Action Bars — The Stance Bar Stops Showing Ten Empty Squares
- **Fix** — Classes with no shapeshift forms got a stance bar with ten empty buttons on it. Re-parenting a bar's buttons force-showed every one of them — right for action slots, wrong for pet and stance buttons, which are driven by how many abilities or forms the character actually has. The bar now appears only when `GetNumShapeshiftForms` reports forms, and only that many buttons are shown.
- **Fix** — Unchecking "show empty button slots" made the whole stance bar vanish. That pass reads each button's action slot; pet and stance buttons have none, the lookup fell through to slot 0, `HasAction(0)` is false, and all ten were hidden. Both bars are skipped by that pass now.
- **Internal** — The gate is `GetNumShapeshiftForms` rather than a hardcoded class list: it follows specs and talents by itself and cannot rot when Blizzard reshuffles who has forms. The visibility pass also runs last in the bar apply, since the step above it unconditionally re-shows an enabled bar.

#### Leveling Bar — A Hover Panel Instead Of A Tooltip
- **Change** — Hovering the leveling bar now opens a styled panel instead of a GameTooltip: aligned value column, brand accents, and it cannot be pre-empted by whatever else owns the tooltip at that moment.
- **New** — It shows more than the tooltip did — level, raw XP, XP remaining, progress, rested, XP/h, time to level, XP gained since the last ding, and the last quest's contribution. Rows are generic slots filled top-down with whatever is actually available, so a value that does not apply leaves no gap.
- **Change** — The panel flips below the bar when there is no room above it, so it stays readable wherever the bar has been dragged.

#### Bags — Right-Click Actions Work On The First Try
- **Fix** — Disenchanting, milling or prospecting from the bag skin took two attempts. Slots were registered for both press and release, so the press ran the secure handler with a stale click type, and that empty click consumed the targeting cursor; by the time the release fired there was nothing left to apply the spell to and the item was picked up instead. Slots are release-only now. Setting the attribute on the press instead would have been worse — the spell would fire on press and the release would then pick the item up mid-cast. Dragging is unaffected, it goes through its own drag registration.
- **Change** — The "Categories" bag layout has been removed, leaving Combined Grid and Separate Bags. A profile still set to it is moved onto the combined grid once, rather than falling through every layout branch and rendering an empty bag.

#### Chat — The Per-Line Copy Icon Is Gone
- **Fix** — The per-message copy icon put a placeholder glyph in front of every chat line, because its texture never resolved. The option is removed rather than repaired, and it is cleared once for anyone who had it on — otherwise the glyphs would have stayed with no switch left to turn them off.

#### Objective Tracker — A Delve Is Not An Empty Tracker
- **Fix** — Inside a Delve the tracker showed nothing at all: no stage, no criteria, no progress. "Hide when empty" — on by default since 3.2.6 — decides emptiness by counting quest blocks, and a Delve tracks its progress in the scenario module, whose subtree is deliberately excluded from that collection because its internal anchors come apart when re-parented. A run with no quest tracked alongside it therefore read as an empty tracker, and the whole panel was hidden. Emptiness is now decided after the scenario / delve module has been placed, and counts that module's own content.
- **Fix** — The same empty case also returned *before* the pass that positions that module inside the panel, so turning "Hide when empty" off did not help either: the panel stayed, but the delve block was never placed in it. That pass now runs first, and the panel sizes itself to the module when it is the only thing on screen.
- **Fix** — Same root cause in the non-bucketed layout, where the visibility test counted quest blocks only. It now recognises a scenario, delve or bonus-objective module as content too, whether that module currently sits in Blizzard's frame tree or has already been moved into ours.
- **Change** — A module only counts as content, and is only given room, when something is actually rendered inside it — a non-empty label or a status bar. Blizzard keeps several of these containers shown and empty at all times, and treating "shown" as "has content" is precisely what produced the giant empty panel that 3.2.6 removed. The test reads shown state rather than on-screen visibility, since the panel may itself be hidden at the moment it runs — asking for visibility there would keep it hidden for good.
- **Internal** — The module walk now looks a couple of levels below the tracker instead of assuming these modules are direct children of it, and never descends into a quest block, so a widget belonging to a block stays with that block.
- **Internal** — The orphan status-bar sweep moved above the layout branches so the delve-only path can run it too. A delve's criteria bars travel with their module and are untouched; only the bars left behind in Blizzard's tree are swept.

#### CooldownForge — Icons Show What You Cannot Afford
- **New** — An icon can now tint itself when the spell is off cooldown but cannot actually be cast right now — no rage for Ironfur, wrong form, a missing reagent. Three modes per bar: no effect (the default, so no existing bar changes appearance), grey out, or grey out plus a blue tint when the missing resource is specifically what blocks it — the same reading the action bars give. Set in the Cooldowns config tab and in Cooldown Studio, and overridable per spell with an inherit option.
- **Note** — The tint is independent of the "grey out on cooldown" option. Vertex color and desaturation multiply, so a spell that is both running and unaffordable shows both states instead of one cancelling the other.
- **New** — Glow gained a fourth trigger condition: *when the spell is usable*. It is the historic "ready" plus castability, so a rage-starved defensive stops glowing while it waits for resources instead of inviting a press that would fail. Available per bar and per spell.
- **New** — A bar can also drop an icon entirely while you cannot afford it, alongside the existing "hide while on cooldown" filter. The two are independent and stack, and the remaining icons close the gap exactly as before.
- **Change** — Both hide filters now go through a single decision point. The signature that decides whether a bar has to be laid out again used to be a second copy of the same rule, which is precisely the kind of pair that drifts apart; a bar can no longer disagree with itself about which icons belong on it.

#### CooldownForge — Internal
- **Internal** — Castability is read through `C_Spell.IsSpellUsable` / `C_Item.IsUsableItem` behind a `pcall`, with both returned values type-checked. Should either become a secret value in 12.x, branching on it would raise; on any doubt the answer is "usable", which is the previous behaviour, so an API change degrades instead of breaking.
- **Internal** — `SPELL_UPDATE_USABLE` fires on every resource threshold crossing, so it follows the same pay-for-what-you-use rule as `UNIT_AURA`: it is registered only while a bar actually consumes castability — a tint mode, a "usable" glow, or the hide filter — and unregistered as soon as none does. It routes to a light refresh; a filtered bar notices the set change through its signature and re-lays out by itself.
- **Internal** — Preview icons reset their vertex color, so an icon pooled back from a live bar cannot leak a grey or blue state into the settings preview.
- **Internal** — Existing bars need no migration: the new castability axis defaults to "off" on all three presets and resolves from the preset when the bar has no explicit value, and the new filter normalizes to `false` on load.

#### Resource Bars — Supercharged Combo Points

- **New** — Combo points flagged as supercharged are now shown as such. Blizzard marks individual points, not a global state: spending a supercharged point makes a finisher behave as if it had spent two more, so which slot carries the charge decides when the finisher is worth pressing. The bar reads that set through `GetUnitChargedPowerPoints` and follows `UNIT_POWER_POINT_CHARGE`, so it stays in step with the class HUD.
- **New** — The charged color is configurable, next to the regular combo point color in CD & Resource → Colors. It defaults to red, which reads against the standard yellow at a glance. Translated in all six supported languages.
- **Change** — A charged slot is marked whether it is filled or empty, which is the whole point of the mechanic: the player has to see where the charge sits *before* getting there. In icon mode the slot switches to the spiked diamond sprite of the combo point atlas and takes the charged tint (dimmed on an empty slot, full on a filled one); in flat color mode the empty slot gets a darkened charged background instead of the neutral one.
- **Fix** — That spiked diamond sprite existed in the texture coordinate table but was never wired to anything, and its V axis was inverted relative to its neighbours — `empty` and `filled` are both declared flipped, this one was not — so it would have rendered upside down. Corrected along the way.
- **Internal** — The charged set is cached and refreshed on its own event rather than read inside the point update. That update runs on `UNIT_POWER_FREQUENT`, which fires continuously for energy, and the API returns a fresh table on every call — reading it there would have allocated a table per tick for a value that only moves on its own event.
- **Internal** — Gated on the power type rather than on the class: the point display is shared with soul shards, essence, arcane charges and the aura-driven displays, none of which have a charged state, while the API already returns nothing for a class without the mechanic. If Blizzard ever widens supercharging beyond Rogues, this follows on its own.
- **Internal** — Every branch also restores the normal artwork when a slot stops being charged. Point textures are built once and reused, so a charged state that is only ever applied would stick to a slot for the rest of the session.

#### Config — The Color Picker Opens Where You Clicked
- **Fix** — Blizzard's color picker regularly opened *behind* the config window or Cooldown Studio, which reads as the swatch doing nothing. The picker is a toplevel frame, but every TomoMod window lives in `FULLSCREEN_DIALOG` with an explicit frame level, so it lost. It is now raised above them while shown — and put back at its own strata and level on hide, so no other addon borrowing the picker afterwards inherits our z-order.
- **Change** — It also opens next to the swatch that spawned it instead of at the centre of the screen, where on a small resolution it landed under the panel. It flips to the other side of the swatch when there is no room and clamps to the screen as a last resort. The anchor is absolute rather than attached to the swatch, so scrolling the panel behind it no longer drags the picker along.

#### Localization — Accented Text In The Compass Options
- **Fix** — The Compass page printed raw escape codes where accents belonged: "dxC3xA9filer", "quxC3xAAte", "xC3x89chelle", "Large (xC2xB190xC2xB0)". The 3.0 string file wrote those characters as `\xHH` escapes, a syntax that only exists from Lua 5.2 onwards — the game runs 5.1, where the backslash is simply dropped and the escape is printed as literal text. Every affected string is now stored as plain UTF-8, which is what the rest of the addon has always used.
- **Note** — All six languages were affected, not just French: the Spanish "Brújula", the Portuguese "Bússola", the German "durchläuft" and the ±45° / ±60° / ±90° field-of-view labels shared the same defect. The Recipe Tracker's "%s × %d" search line was the last one outside that file.

#### Diagnostics — Two More Gameplay Messages Filtered Out
- **Change** — Being rooted in place, and trying to mail a soulbound item, were collected as errors in the diagnostics report. Both are ordinary game feedback rather than addon faults, so they now join the existing exclusion list: through their GlobalStrings (`ERR_ROOTED`, `SPELL_FAILED_ROOTED`, `ERR_MAIL_BOUND_ITEM`), which resolve to whatever locale the client runs in, plus the usual keyword fallbacks in all six languages for the gender-inflected forms the GlobalString lookup cannot cover.

## ####################################

## CHANGELOG 3.2.7 — Quest Progress Bars Restored, Popups Fixed For 11.2 & Profiles / Diagnostics Split

#### Objective Tracker — Quest Progress Bars Are Back
- **Fix** — Progress bars (kill counts displayed as a bar, enemy forces, scenario and delve criteria) had vanished from the tracker, leaving the mob tooltip as the only way to follow progress. The sweep that hides floating "0%" bars decided ownership by reading a bar's own anchor and checking whether the target sat under the skin frame — a test that could never pass. `ObjectiveTrackerProgressBarTemplate` is a *container* frame holding the real `StatusBar` as its `Bar` child; that child is anchored to the container, and the container is parented to the module's `ContentsFrame` while being only *anchored* to the block. The anchor read therefore landed on the container, which never sits under the skin frame, so every bar was swept away. Ownership is now resolved by walking parents and anchor targets together, which reaches the owning block whatever the nesting.
- **Change** — Bars that are kept are now styled by the sweep itself. They are not children of their block, so the per-block styling pass never reached them; without this they came back with Blizzard's default look on a tracker where everything else is themed.
- **Fix** — A progress bar also survives a collapse / expand round trip on its bucket. The sweep only ever looked at bars that were currently shown, which made hiding a one-way trip: collapsing a bucket hid its progress bar, and expanding it again re-ran the sweep, which skipped that bar precisely because it was no longer shown. Nothing brought it back short of turning the bucketed layout off entirely. Bars hidden by the sweep are now reconsidered on every pass and restored once their block is visible again — tracked with a marker so a bar Blizzard is legitimately keeping hidden stays none of our business.
- **Internal** — That marker also completes the teardown path. The hidden-bar list is rebuilt from scratch on every layout pass, so disabling the bucketed layout only ever restored the bars hidden by the *last* pass; a still-hidden bar is now re-registered each time, and the list is complete when it matters.

#### Objective Tracker — The Position Sticks
- **Fix** — A tracker moved with Blizzard's own Edit Mode went back to its previous spot on the next reload or relog. Our `SetPoint` guard deliberately stands down while an Edit Mode session is running, so the panel follows the cursor there instead of being yanked back on every drag — but nothing ever wrote that new position into the addon's database, so the next login simply re-applied the last anchor the TomoMod mover had saved. The position is now captured when the Edit Mode session ends, one frame later, once Blizzard has settled its layout.
- **Fix** — A tracker scaled to anything other than 100% crept a little further across the screen on every reload. Positions are stored as UIParent-space coordinates but were fed straight back into `SetPoint`, whose offsets are read in the tracker's own coordinate space, so each save/apply round trip multiplied the position by the scale factor. The apply pass now converts back through that same ratio.
- **Fix** — The scale was applied *after* the anchor, which silently shifted a frame that had just been placed. Scale now comes first.

#### Minimap — Indicators Follow Blizzard's Own Visibility Again
- **Fix** — The instance difficulty flag stayed on the minimap outside instances. Re-anchoring the native indicators to the square minimap also forced their alpha to 1 on every pass, which overrode Blizzard's own rule that the flag shows only inside a dungeon or a raid. The addon now only ever undoes a hide it performed itself — restoring exactly the alpha it had overwritten — and leaves Blizzard's show and hide decisions alone.
- **Note** — This is also the answer to the follow-up report that unchecking the option removed the flag while re-checking never brought it back. Re-checking did restore the alpha, once; Blizzard's next update then correctly hid it again because the player was not in an instance. Outside an instance the flag now stays hidden by design, and reappears on entering one.
- **Fix** — Turning an indicator off is now held in place. Blizzard re-reveals these on its own schedule — entering an instance, mail arriving — which a single alpha assignment could not survive. The guard hooks `Show` and `SetAlpha` only: the mouse state and the shown flag stay Blizzard's, since confiscating those is exactly what caused the original bug.
- **Fix** — The expansion / landing page button carried the same defect in a worse form. Its disable path set the alpha to 0 and nothing anywhere restored it, so turning that button off and back on left it invisible for good.

#### Resource Bars — The Centered Power Bar Updates Again
- **Fix** — On any spec whose only resource is the primary one, the standalone power bar sat frozen on the value it was built with — 0 rage, 0 energy — no matter what happened afterwards, while the unit frame's info bar showed the real amount right next to it. The master update returned early whenever the current spec had no entry in the class-resource table, and that table deliberately only lists specs with a *class-specific* resource (combo points, chi, runes, soul shards…). The call that refreshes the centered bar was therefore never reached, so the bar kept whatever the build pass gave it about a second after login. The early return is gone; only the class-power section is guarded now, which is the part that actually needs it.
- **Note** — Affected every spec absent from that table: all three Warrior specs, all three Priest specs, Elemental and Restoration Shaman, Beast Mastery and Marksmanship Hunter, Havoc Demon Hunter, Restoration Druid, Fire Mage and Mistweaver Monk. Specs with a class resource were never affected, which is why this went unnoticed.
- **Internal** — The optional HUD health bar sat in the same blind spot and only kept working by chance, because `UNIT_HEALTH` has its own branch in the event handler that refreshes it directly. It now goes through the normal update path too.

#### Profiles — Rename And Duplicate Actually Do Something
- **Fix** — Renaming or duplicating a profile did nothing at all. Blizzard rebuilt `StaticPopup` on a mixin in 11.2: the dialog's direct `.editBox` field was replaced by a `:GetEditBox()` accessor, so the `OnAccept` handlers read `nil` and bailed out before ever calling the rename. Same cause and same fix in Cooldown Studio, where the Rename bar popup ignored the typed name and every bar created through "+ New" came out called "Nouvelle barre".
- **New** — Pressing Enter in any of those name fields now confirms exactly like clicking the accept button.
- **Fix** — The rename popup pre-fills and selects the current name, and the duplicate popup clears and focuses its field, instead of opening on whatever the previous popup left in the shared dialog.
- **Internal** — Added shared popup helpers to `TomoMod_Utils` (`PopupEditBox`, `PopupText`, `PopupDialogOf`, `PopupAccept`). They resolve the edit box across the old field, the new accessor and the global-name fallback, so the rest of the addon no longer has to care which client shape it is running against.

#### Popups — No Longer Hidden Behind The Config Window
- **Fix** — The config window and Cooldown Studio both live at `FULLSCREEN_DIALOG` with a high frame level, so any popup using the default layer rendered *behind* them and looked like nothing had happened. The reload prompt, the import and export dialogs and every profile confirmation (import, delete, rename, duplicate, reload) are now lifted above whichever TomoMod window is currently open.
- **Fix** — `StaticPopup1..4` are recycled frames shared with Blizzard, so the lift is undone on hide. A popup borrowed afterwards by another addon can no longer inherit our strata and level.

#### Profiles — The List Refreshes After Every Change
- **Fix** — Creating, deleting, renaming or duplicating a profile left the panel showing the previous list, which reads as "nothing happened". Config pages are cached, and until now only a profile *swap* dropped that cache; every operation that rewrites the profile list does so too.

#### Profiles — Faster Import
- **Change** — The import popup already decodes the string to build its preview, and accepting it decoded the very same string a second time. That duplicate decode + decompress + deserialize was most of the freeze players saw when clicking Import; the payload from the preview is now reused. It is handed over once, and only for a string that still matches, since applying it moves the settings out of it.
- **Change** — Importing *as a new profile* now yields a frame between applying the settings and snapshotting them, instead of stacking a full deep copy of the settings tree onto the same frame.

#### Config — Profiles And Diagnostics Are Separate Categories Again
- **Change** — The grouped "Tools" category was split back into two standalone sidebar entries, each with its own icon, accent color, description and search keywords. Both rebuild on every visit so the profile list and the live diagnostics readings are never served stale from the panel cache.
- **Fix** — Deep links from the global search into a single-page category now apply their target tab, which previously only happened for grouped categories. Unknown tab keys are ignored instead of switching to a tab that does not exist, which used to leave the page blank.
- **Change** — Old `tools` deep links still resolve, and the global search's ghost indexing now walks every single-page category instead of only the dashboard, so options on those pages are findable without opening them first.
- **Change** — The two new category descriptions are translated in all six supported languages.

## ####################################

## CHANGELOG 3.2.6 — What's New Popup Fixed, Objective Tracker Cleanup & Draggable Reputation Bar

#### What's New Popup — The Dark Screen Lock Is Fixed
- **Fix** — Closing the "What's New" popup with Escape left the screen dimmed and the mouse dead, with nothing left to click. The dimmer is a separate full-screen mouse-blocking frame with the panel as its child, and only `WN.Hide()` ever hid it — but the panel was registered in `UISpecialFrames`, so Escape made Blizzard hide the panel directly and the dimmer stayed behind. An `OnHide` script on the panel is now the single close authority: whatever hides it — the X, the OK button, Escape, or any external call — hides the dimmer too.
- **Fix** — The version was not marked as seen on that same Escape path, so a popup you had already closed came back on the next login. Marking the version as seen now lives in the same `OnHide` script, so every close path behaves identically.
- **Fix** — Escape is now captured by the window itself instead of going through `UISpecialFrames`, which routes via `ToggleGameMenu` and its protected `ClearTarget()` call — the same taint path already removed from Cooldown Studio in 3.2.2. Every other key still passes through untouched, and the handler stands down in combat since `SetPropagateKeyboardInput` is itself protected.
- **Fix** — The dimmer and the panel are now created hidden and only shown once the content is fully built, matching the installer's pattern. An error during construction can no longer leave a full-screen mouse blocker on screen with no dialog behind it.

#### What's New Popup — When It Shows Up
- **Change** — The popup is now held back while a cinematic or an in-game movie is playing, and while you are in combat. It retries every 2 seconds for up to about 5 minutes; if it never gets a clear window it gives up *without* marking the version as seen, so the changelog simply shows up next session.
- **Change** — A character's very first login no longer gets the popup — it waits for the second one. Brand-new characters were hit hardest by the bug above: the popup was built while the intro cinematic was playing (invisible behind a hidden UIParent), and the first Escape used to skip the cinematic closed a window the player never saw. A per-character login counter (new `TomoModCharDB` saved variable) gates this; the popup is postponed, not consumed.

#### Objective Tracker — No More Giant Empty Panel
- **Fix** — With nothing tracked, the tracker left a dark panel on screen spanning most of the height. Two causes, both fixed. Its "has content" test scanned `ObjectiveTrackerFrame`'s children, but several Blizzard module containers stay shown at nearly full height with nothing tracked — so the tracker read as full when it was empty, and in the default bucketed layout our own blocks are re-parented to the skin frame and were not tracker children at all. Content is now reported by the layout passes themselves, which are the only code that actually knows.
- **Fix** — The empty case also returned early while keeping the height computed from Blizzard's always-shown containers. The panel now collapses to its header instead.
- **Change** — "Hide when empty" is now on by default. Existing profiles are brought along once by a one-time migration; turning it back off sticks, and is never re-applied.

#### Objective Tracker — Draggable Downwards Again
- **Fix** — The tracker could be dragged up, left and right, but never down. Screen clamping was applied to `ObjectiveTrackerFrame`, whose height is Blizzard's and far exceeds the visible content: its bottom edge already sat at or past the bottom of the screen, so the engine refused every downward move. Clamping is now off; "Reset position" in the settings remains the way back if the panel ends up somewhere unreachable.

#### Reputation Bar — Now Actually Draggable
- **Fix** — In Layout mode the reputation bar showed its unlock border but could not be grabbed. The frame never had mouse input enabled — `StatusBar` frames start with the mouse disabled — so `RegisterForDrag` was inert and `OnDragStart` never fired. It now follows the same SetMovable / EnableMouse / RegisterForDrag order as the leveling bar.

#### Internal — One-Time Data Migrations
- **Internal** — Added a migration step to database init. Merging defaults only fills in *missing* keys, so changing a default has never reached an existing database; corrections that must apply to profiles already in the wild now live in `TomoMod_RunMigrations()`, each behind its own flag so it runs exactly once regardless of the version the player is coming from.
- **Internal** — The `_migrations` bookkeeping table is excluded from profile snapshots. Restoring a profile saved before a migration would otherwise bring back an empty flag table and let that migration fire a second time, re-applying a change the player may have deliberately reverted.

#### Config — Tomo Suite Card
- **New** — The dashboard gained a "Tomo suite" card presenting TomoBoss (boss timers with spoken callouts, French and English voice packs included). If TomoBoss is loaded, the card reduces itself to a shortcut that opens its options; if it is not installed, it shows a selectable address field and a "Don't show again" button that hides the card everywhere, permanently. No login message, no popup, nothing repeated.
- **Fix** — The card now reads three states instead of two: loaded, present but disabled for this character, and absent. Testing presence alone was wrong — addons live in a single `Interface/AddOns` folder shared by the whole installation while *enabling* them is per character, so on a character where TomoBoss was disabled the card still announced "installed, type /tmb" for a command that did not exist. That case now shows its own line telling you to enable the addon and reload, with neither the options button nor a download address, both of which would be pointless there.
- **Internal** — The card lives in a single shared implementation (`Config/Panels/_Suite.lua`) rather than being duplicated per panel, so its behavior cannot drift between the pages that display it.

## ####################################

## CHANGELOG 3.2.5 — Contacts Window Reskin & CooldownForge: Radial Layout, Glow Conditions

#### Contacts Window — Reskinned Frame, Tabs & Buttons
- **Change** — The Contacts window skin was a partial pass: it darkened the frame body but left every control untouched, so Blizzard's gold buttons and tabs sat on top of a dark panel. The whole window is now themed as one piece — flat dark body, 1px accent border drawn above the content so the list can no longer overdraw it, restyled title with a hairline divider beneath it, and a plain accent close button.
- **New** — The four bottom tabs and the Friends / Recent Allies / Recruit A Friend sub-tabs lost their parchment plates. They now use a flat inactive fill, a subtle hover tint and an accent underline plus accent label on the selected one.
- **New** — Every button in the window shares a single treatment: flat slot, accent border, and an accent label that brightens on hover. This covers Add Friend, Send Message, the Who tab's Who / Add Friend / Group Invite buttons, Convert to Raid, Raid Info and Quick Join's Join Queue button.
- **New** — The Who tab's column headers are now flat with a hover tint and 1px separators, and its search box gained the same flat field styling as the rest of the addon.
- **Change** — The Add Friend and Send Message buttons now split the bottom row evenly instead of sitting at unequal widths. Their original vertical placement is preserved, and the window's own size and list layout are left exactly as Blizzard builds them.
- **Fix** — The skin no longer targets three scroll frames removed in 11.x, which meant the list panes were never actually being themed. It now themes the real inset panes used by the current client.
- **Fix** — Turning the skin off in the settings restores Blizzard's own look immediately instead of requiring a reload. Hidden artwork is now dimmed and remembered rather than destroyed, so it can be brought back live. Fonts are the one exception and still need a reload to revert.
- **Fix** — The ignore list, raid info popup and friend tooltips could be covered by the window's own border layer; they are now raised above it.
- **Internal** — Hover and selected states are driven by HIGHLIGHT draw-layer textures and font objects rather than OnEnter/OnLeave scripts, so the skin runs none of its own code inside a Blizzard interaction path — which matters on the Raid tab, whose buttons reach protected group APIs.

#### CooldownForge — Radial (Circular) Layout
- **New** — Cooldown bars gained a Layout mode: keep the classic line, or arrange the icons on a circle. Radial bars expose a radius, a start angle (0° = right, 90° = up), an arc amplitude (360° spreads the icons over a full circle, anything smaller lays them along that arc inclusive of both ends) and a clockwise toggle. Available in both the Cooldowns config tab and Cooldown Studio.
- **Note** — The circle is fixed on screen: the game does not let an addon anchor a frame to the character, so you position the ring once via Edit Mode and it stays put.

#### CooldownForge — Independent Row & Column Spacing
- **Change** — Icon spacing is now two separate values: one along the growth axis (within a row/column) and one between wrapped rows. Left untouched, the cross-axis spacing simply follows the along-axis value, so existing bars are unchanged.
- **Change** — The along-axis spacing maximum was raised from 16 px to 64 px for more generous layouts.

#### CooldownForge — Glow Conditions
- **New** — Glow can now trigger on one of three conditions instead of only "when ready": when the spell is off cooldown (the previous, hardcoded behaviour and still the default), while a matching buff is active on you, or always while the icon is shown. Set per bar, and overridable per spell (with an inherit option).
- **New** — For the "buff active" condition, the aura watched defaults to the tracked spell's own ID; an optional buff-ID field lets you point it elsewhere for trinkets and talents whose buff differs from the spell.

#### CooldownForge — Hide Icons On Cooldown
- **New** — A bar can now drop each icon while it is on cooldown, with the remaining icons reflowing to close the gap. The bar re-lays out only when the set of ready spells actually changes, not on every cooldown tick, and it keeps polling while fully hidden so it can reappear on its own.

#### CooldownForge — Internal
- **Internal** — Saved-variable schema migrated 3 → 4. The migration is pure normalization: an untouched bar keeps its exact previous look, since "line" and the "ready" glow condition are the historic defaults.
- **Internal** — `UNIT_AURA` is registered only while at least one on-screen bar actually needs aura state (a glow set to "buff active"), keeping the watcher at zero idle cost otherwise.
- **Internal** — Because spell cooldowns are secret values in 12.x, the "hide on cooldown" filter reads readiness through a shared off-screen Cooldown probe widget (detect-don't-test) rather than reading any cooldown duration.

## ####################################

## CHANGELOG 3.2.4 — Real Preview Icons, Chat Contacts Button & Scrollbar Consistency

#### Cooldown Studio — Preview Now Uses Real Icons
- **Change** — The Style tab's live preview no longer renders three hardcoded demo textures picked from unrelated classes. It now uses real icons, in priority order: the bar's own tracked spells first, then the edited class's spellbook and talents, then a neutral question-mark icon for any remaining slot. Previewing a Warrior bar no longer shows Mage spells.

#### Chat — Contacts Button In The Sidebar
- **New** — The chat sidebar gained a Contacts icon that opens Blizzard's friends list in one click. The skin suppresses the native social/quick-join button, which left no direct way back to the friends panel from the chat frame; this restores that entry point. It sits in the sidebar's middle icon group, between the player status and copy-chat icons.

#### Config — Multi-Line Text Boxes Match The Addon's Scrollbar Style
- **Fix** — Multi-line text boxes (Import/Export fields, notes areas...) inherited Blizzard's `UIPanelScrollFrameTemplate` and rendered the default gold arrow scrollbar, clashing with the addon's own styling everywhere else. They now use a plain scroll frame with the same thin accent-colored scrollbar as the rest of the config window, and the freed horizontal space is given back to the text area.
- **New** — Those text boxes now also scroll with the mouse wheel, and their scrollbar auto-hides when the content fits.

## ####################################

## CHANGELOG 3.2.3 — Cooldown Studio Polish: Style Preview, Copy Style & Quicker Bar Creation

#### Cooldown Studio — Style Tab Live Icon Preview
- **New** — The Style tab now shows a live icon preview using the exact same rendering path as real bars (border, corners, swipe, timer color, glow desaturation...), so style changes are visible immediately without leaving the tab.
- **New** — The preview cycles through ready / on-cooldown / mid-cooldown icon states on a loop, so you can see how the swipe animation and the "desaturate on cooldown" setting actually look before committing.

#### Cooldown Studio — Copy Style Between Bars
- **New** — The Style tab gained a "Coller le style depuis..." button (shown once the class has more than one bar) opening a picker listing every other bar; selecting one copies only its visual style (preset + fine-tuning) onto the current bar — spells, position, layout and visibility are left untouched.
- **Internal** — New `CDF.CopyStyle(class, srcId, dstId)` API, deep-copying the style table so the two bars never share references.

#### Cooldown Studio — Quicker Bar Creation & More Reliable Popups
- **New** — Clicking "+ Nouvelle" now asks for the bar's name up front instead of creating a "Nouvelle barre" placeholder that then needs renaming; leaving it empty or pressing Escape still creates a bar with the default name.
- **Fix** — The rename and create popups are now raised above the Studio's fullscreen window instead of potentially appearing behind it, and the name field is automatically focused and highlighted so you can start typing immediately; pressing Enter confirms either popup without needing to click the button.

#### Config Sliders — Direct Value Entry & Quick Reset
- **New** — Right-clicking a slider's value badge now lets you type an exact number directly instead of dragging the thumb; pressing Enter (or clicking away) applies it, clamped and snapped to the slider's normal range/step.
- **New** — Ctrl+click on a slider's value badge resets it to its default (or initial) value.
- **New** — A tooltip on the value badge now hints at both shortcuts ("Right-click: type a value | Ctrl+click: reset").

#### Action Bars — Pet & Stance Bars Now Placeable in Edit Mode
- **Fix** — The Pet and Stance action bars are hidden at rest when you have no pet or no stances, which made them impossible to select and drag into position in Edit Mode. They're now temporarily force-shown while Edit Mode is active so they can be positioned like any other bar, and return to their normal driver-controlled visibility as soon as Edit Mode is closed.

## ####################################

## CHANGELOG 3.2.2 — Cooldown Studio: Dedicated Full-Screen Bar Editor

#### New Companion Addon — Cooldown Studio
- **New** — Added TomoMod Cooldown Studio, a dedicated full-screen editor for CooldownForge bars, loaded on demand from the Cooldowns tab. It lists every bar of the selected class in a sidebar with full create/rename/delete controls, and organizes each bar's settings into Layout, Style, Spells, Visibility and Sharing tabs, reusing the same widget kit as the main config window for a consistent look. Its edit-mode toggle is wired directly to the Movers manager, and its Sharing tab uses the same Import/Export tools as the Cooldowns config panel.
- **Fix** — The Studio window now uses the `FULLSCREEN_DIALOG` strata instead of `DIALOG`, so it reliably displays above other windows instead of potentially being covered by them.
- **Fix** — Widgets built inside the Studio now correctly inherit its accent color instead of falling back to the default amber, since the window's panel context is now properly registered.
- **Change** — Minor layout adjustment to the class-selector dropdown's vertical position for tighter alignment with the header.

#### Cooldown Studio — Conditional Bar Visibility & Fine Style Controls
- **New** — The Visibility tab now supports per-bar conditional visibility: require (or forbid) being in combat, in an instance (dungeon/raid), in a group, or in a raid, via simple "Indifferent / Yes / No" dropdowns for each condition. A bar with every condition left on "Indifferent" behaves exactly as before (always shown whenever its entries would otherwise display). Conditions are evaluated live and purely from non-secret, event-driven signals (combat lockdown state, group/raid roster, zone changes) — no combat log parsing, no polling.
- **New** — The Style tab gained a "Fine-tuning" section: a per-bar opacity slider, a border color mode (class color / neutral / fully custom with its own color picker), a border thickness slider, an optional custom timer text color override, and a drop shadow toggle. Adjusting any of these automatically switches the bar's style preset to "Custom" so it no longer follows the base preset.
- **Internal** — CooldownForge's saved-variable schema bumped to v3 with an automatic, one-time migration that normalizes every existing bar's visibility data — no user action required and existing bars keep displaying exactly as before until conditions are explicitly set.

#### Cooldown Studio — Sidebar & Window Interaction Fixes
- **Fix** — The sidebar's "+ Nouvelle", "Dupliquer", "Renommer", "Supprimer" and blueprint buttons could silently swallow clicks, because the content panel (built after the sidebar) sat at the same frame level and intercepted input in front of them. The content area is now kept below the sidebar in the frame stack so its buttons always receive clicks.
- **Fix** — The sidebar's button rows now use an explicit width so two buttons consistently fit cleanly side-by-side within the sidebar instead of overflowing its edge.
- **Fix** — Pressing Escape to close the Studio window no longer causes a taint error. It previously closed through Blizzard's `UISpecialFrames`/game-menu path, which calls the protected `ClearTarget()`; Escape is now captured directly by the window itself, closing it and letting every other key pass through untouched.
- **Fix** — Switching bars or classes (or otherwise triggering a content rebuild) no longer resets the Studio back to the "Disposition" tab — the previously open tab (Disposition/Style/Sorts/Bibliotheque/Visibilite/Partage) is now correctly restored, fixing an initial-tab parameter that was silently being ignored.

#### Cooldown Studio — Library Now Includes Talents & Hero Talents
- **New** — The Bibliotheque (spell library) tab now also lists your currently committed talents and hero talents, alongside spellbook spells, so they can be added to a cooldown bar just like any other spell. Passive talents are skipped (there's no cooldown to time), and a talent already granted through the spellbook is never listed twice.
- **Internal** — The library cache now also refreshes automatically when your talent loadout changes (`TRAIT_CONFIG_UPDATED`), in addition to the existing specialization/spellbook triggers. Every talent API call is `pcall`-guarded, matching the addon's secret-value-safe conventions.
- **Fix** — The talent scan initially found nothing in-game: `entryIDsWithCommittedRanks` is not reliably populated outside a preview/loadout context. Only nodes actually taken (`currentRank > 0`) are now considered, and the selected choice is read via `activeEntry.entryID`, falling back to the previous field only when that's unavailable.

#### Internal — Shared "Forge" Library for Deep-Editing Modules
- **Internal** — Extracted the machinery shared by CooldownForge and Cooldown Studio into a new internal `Core/Forge` library: pixel-perfect scaling, class-color resolution and accent folding (`Forge.Util`), the versioned share-string import/export codec (`Forge.IO`), the addon-wide edit-mode session with its grid/snap/movable overlays (`Forge.Edit`), stepwise schema migration with pre-migration auto-backup (`Forge.Schema`), and the studio window-chrome factory (`Forge.Studio`). CooldownForge, Cooldown Studio and the config window's global search now consume these shared helpers instead of duplicating the logic, laying the groundwork for future deep-editing modules (e.g. an upcoming UnitFrames studio) to reuse the same building blocks. No user-facing behavior changes.

#### Diagnostics — Exclusive Ownership of Taint Events (Fewer Phantom Reports)
- **Fix** — Diagnostics now takes exclusive ownership of the taint-related events instead of sharing them with Blizzard's own handling. Leaving `ADDON_ACTION_FORBIDDEN`/`ADDON_ACTION_BLOCKED` registered on `UIParent` (and `LUA_WARNING` on the default script-error frame) let Blizzard's own handling re-enter and re-propagate the taint TomoMod was only trying to observe, producing phantom `ADDON_ACTION_FORBIDDEN` reports (e.g. `UseToy`, `SetNote`) misattributed to whichever addon happened to be active at that moment. Diagnostics now unregisters those default listeners — the same approach used by BugGrabber — so its own frame is the sole observer of these events, on every client version including 12.1+'s `GameEvent`-based internal events.

#### Action Bars — Bar Management Info Text Clarified
- **Change** — The Bar management tab's info text now also mentions that expanding a bar below reveals its per-bar button size and scale sliders, so that existing option is easier to discover instead of being hidden without any hint.

#### Objective Tracker — No Longer Fights Blizzard's Edit Mode
- **Fix** — Dragging the Objective Tracker while Blizzard's native Edit Mode was active could freeze the tracker mid-drag: TomoMod's `SetPoint` hook re-asserted the saved anchor every time Edit Mode called `SetPoint` to follow the cursor, canceling the move. The hook now yields entirely while `EditModeManagerFrame:IsEditModeActive()` is true, letting the tracker follow the drag normally — the saved position is picked back up the next time anything else moves the tracker after Edit Mode ends.

## ####################################

## CHANGELOG 3.2.1 — CooldownForge: Custom Per-Class Cooldown Bars

#### New Module — CooldownForge
- **New** — Introduced CooldownForge, a fully custom, display-only cooldown tracking system, independent from the Blizzard Cooldown Manager reskin. Create any number of bars per class, each tracking spells, items, item presets (Healthstone, Health/Mana/Invisibility Potion...), an equipped trinket or your racial ability, with its own icon size, spacing, growth direction, orientation, wrap, glow style (Pixel/Autocast/Button) and text mode (timer/name/none).
- **New** — A dedicated **Cooldowns** tab (Config window, Combat category) lets you pick a class, create/rename/delete bars, add or remove tracked entries (with optional per-spec filtering) and tweak every bar setting with live preview.
- **New** — Every CooldownForge bar can be dragged independently into place through the unified Movers manager (new "Cooldown Bars" entry), with its position saved per bar and restored the same scale-agnostic, center-anchored way as other TomoMod frames.
- **New** — Import/Export: share a class's full cooldown bar setup as a compact string, using the same Serialize + Deflate pipeline as profile import/export. Importing merges bars by id into the target class only — other classes' bars and personal bar positions are never touched or overwritten.
- **Internal** — Event-driven, secret-value-safe engine: no polling, spells feed duration objects straight into the native Cooldown widget, items/trinkets use plain non-secret numbers, and "ready" state is always detected via `IsShown()` rather than reading a secret cooldown value directly. Racial abilities are pre-mapped for every playable race.

## ####################################

## CHANGELOG 3.2.0 — Global Config Search, Instant Panel Switching & Full Config Localization

#### Config Window — Global Search Across Every Option
- **New** — The sidebar search box in the `/tm` config window is now a true global search: typing 2+ characters shows a results popup listing every matching option across **all** categories and tabs, not just the visible page. Selecting a result (click or Enter) deep-links straight to the right category/tab, scrolls the panel to the exact option and briefly flashes it so it's easy to spot.
- **New** — Pages you haven't opened yet are indexed automatically the first time you search (built once, off-screen), so the search always covers the entire GUI regardless of which tabs you've actually visited this session.
- **New** — Added a "No matching option" message shown when a search finds nothing.

#### Config Window — Instant Category/Tab Switching
- **Change** — Switching between category tabs in the config window no longer destroys and rebuilds the panel every time — panels are now cached and simply shown/hidden, making tab switching effectively instant after the first visit. The Accueil (dashboard/presets) and Tools (profile list, live diagnostics) tabs still always rebuild so their dynamic content stays current.
- **Fix** — Applying a preset or switching profiles now correctly invalidates the cached panels so every widget reflects the newly loaded values instead of showing stale state from before the switch.

#### Config UI — Full Localization Pass
- **Change** — Every remaining hardcoded French string in the configuration panels (category and tab names, descriptions, the reload-confirmation dialog, the FPS/memory footer, and the ActionBars, Castbars, CooldownResource, Diagnostics, General, MythicPlus, Nameplates, PartyFrames, Profiles, QOL, RaidFrames, RFPreview, Skins, Sound, UFPreview and UnitFrames panels) is now routed through the locale system. Non-French clients now see a fully translated settings UI instead of French labels bleeding through everywhere.

#### Internal — Composite Widget Helpers
- **New** — Added a set of reusable multi-column widget builders (2/3-column rows, triple sliders, triple dropdowns, dropdown-with-offset-sliders, multi-swatch color rows) and a persistent reorder dropdown (checkbox + up/down arrows to enable and reorder list entries) used to build more consistent config panel layouts going forward.

## ####################################

## CHANGELOG 3.1.12 — Mythic+ Scoreboard Taint Fix & Config Window Resize/Scale

#### Mythic+ Scoreboard — No Longer Blocked by Combat Taint on Dungeon Completion
- **Fix** — Diagnostics reports showed a burst of `ADDON_ACTION_BLOCKED` errors (`Button:SetAttribute()`, `Button:EnableMouse()`, `Button:ClearAllPoints()`, `Button:SetPoint()`, `Button:Show()`, plus the same on `TomoScoreFrame` itself) firing when the end-of-dungeon scoreboard tried to display after `CHALLENGE_MODE_COMPLETED`. Root cause: `PopulateScoreboard` sets a `SetAttribute` on each row's secure teleport button (a `SecureActionButtonTemplate`, used for the keystone-dungeon teleport spell), which taints the rest of that function call — including the otherwise-ordinary `SetPoint`/`Show`/`SetSize` calls on the plain `TomoScoreFrame` further down the same call chain — if the player is still in combat lockdown at that moment (e.g. lingering adds right after the final boss dies). The scoreboard display path now checks `InCombatLockdown()` before populating/showing and, if still in combat, defers itself until `PLAYER_REGEN_ENABLED` fires instead of running immediately.

#### Config Window — Resizable & Scalable
- **New** — The `/tm` configuration window can now be resized by dragging a new grip added to its bottom-right corner (clamped between 1020×720 and 1680×1080), and a **Config window scale** slider (70–130%, General panel) lets you shrink or enlarge the whole panel independently of its size. Both the saved size and scale are restored automatically the next time the window opens.
- **Change** — Default window size increased from 1020×720 to 1240×820, and the sidebar from 190px to 210px, giving every panel more room out of the box. A new **Reset window size & scale** button next to the slider (General panel) instantly restores both to their defaults.
- **Change** — Tab bars and scrollable content areas inside category panels now recompute their layout (tab widths, child width) whenever the window is resized instead of assuming a fixed width, so tabs and scroll content reflow correctly at any window size.

## ####################################

## CHANGELOG 3.1.11 — Castbar Stale-State Fix & Objective Tracker "Find Group" Button Hiding

#### Castbars — No Longer Get Stuck When the Casting Unit Dies or Changes
- **Fix** — Castbars for non-player units (target, focus, boss, party/raid members, etc.) could stay visible and frozen on screen if the unit died, disappeared, or otherwise became invalid without WoW ever firing a matching `UNIT_SPELLCAST_STOP`-family event (e.g. a target that dies mid-cast while still selected, or a boss dying during an empowered cast). The castbar's `OnUpdate` now checks `UnitExists`/`UnitIsDeadOrGhost` every frame for non-player units and immediately resets and hides the bar the moment the unit is gone or dead.
- **Fix** — Switching target or focus (`PLAYER_TARGET_CHANGED`/`PLAYER_FOCUS_CHANGED`) now fully resets the castbar's internal state before checking the newly selected unit's cast, instead of only clearing the fail-state timer. Previously, if the previous unit had been mid-cast, its leftover `casting`/`channeling`/`empowered` flags could keep the bar shown even though the newly selected unit wasn't casting anything.

#### Objective Tracker — "Find Group" Button Now Hidden With Collapsed Quest Categories
- **Fix** — Collapsing a quest category bucket only hid the quest's item button, leaving its "Looking For Group" / "Find Group" button (when present) still visible floating in the tracker — it's anchored to the block but parented directly to the tracker's pooled content frame, so `block:Hide()` never covered it. Collapsing/expanding a bucket now hides and restores every right-edge button belonging to the block (item button and "Find Group" button alike), not just the item button.

## ####################################

## CHANGELOG 3.1.10 — Action Bar Spell-Drag Fix (Empty Slots) & Skyriding Taint Hardening

#### Action Bars — Moving a Spell/Macro/Mount Already on a Bar Onto an Empty Slot Now Works
- **Fix** — The 3.1.9 empty-slot drag fix only listened for `ACTIONBAR_SHOWGRID` / `ACTIONBAR_HIDEGRID`, which Blizzard fires reliably for items and when the Spellbook/Talents force the grid, but **not** when picking up a spell/macro/mount that is already sitting on a bar to move it to another slot. So with "Show empty button slots" disabled the empty slots stayed hidden during those bar-to-bar drags and there was nowhere to drop — reproducing the exact original bug for spells (opening the Spellbook/Talents was still the only workaround). The empty-slot reveal now also listens for `CURSOR_CHANGED` and reads `GetCursorInfo()`: for the drag cursor types that don't fire `ACTIONBAR_SHOWGRID` (`spell`, `macro`, `mount`, `petaction`, `companion`, `flyout`) it reveals the empty slots on pickup and re-hides them once the cursor is cleared. Items keep using the existing `ACTIONBAR_SHOWGRID` path (which fires reliably for them), so empty slots don't flash during bag sorts or vendor operations.

#### Skyriding — Recurring Secret-Value Taint on Ground Speed (Hardened Fix)
- **Fix** — Diagnostics reports showed `SkyRide.lua:426: attempt to perform arithmetic on local 'speed' (a secret number value...)` still firing hundreds of times per session despite the existing `issecretvalue()` guard added around `GetUnitSpeed("player")`. The read-and-check-and-zero sequence is now wrapped in a dedicated `SafeGroundSpeedPercent()` helper that `pcall`-wraps both the `GetUnitSpeed` call **and** the subsequent division/multiplication arithmetic (matching the existing `Castbar.lua` `FormatTimer` pattern), so any case the plain `issecretvalue()` check doesn't catch can no longer throw an uncaught error — it silently falls back to `0` instead.
- **Fix** — The flying/gliding branch (`C_PlayerInfo.GetGlidingInfo()` + `forwardSpeed * SPEED_MULTIPLIER`) received the same treatment: the API call is now `pcall`-wrapped and the multiplication that derives the displayed speed is also `pcall`-wrapped, closing the same class of taint error on the airborne speed-bar path.

#### Diagnostics — Two New UIError Exclusion Keywords
- **New** — 2 new UIError keyword groups added to the exclusion filter (from session report #676): the merchant refusing to buy an item ("Vous ne pouvez pas vendre d'objets à ce marchand") and looting being blocked while Challenge Mode is active ("Vous ne pouvez pas ramasser de butin tant que le mode Défi est actif."). Each entry covers FR / EN / DE / ES / IT / PT variants, so these normal gameplay-feedback messages are no longer captured as bugs in the diagnostics console.

## ####################################

## CHANGELOG 3.1.9 — Movable-Frame Position Fixes, Action Bar Drag Fix, Native Bar Suppression & Diagnostics Popup Stacking

#### Action Bars — Empty Slots Now Droppable While Dragging a Spell
- **Fix** — With "Show empty button slots" disabled, it was impossible to drag a spell/item onto an empty slot at all, unless the Spellbook or Talents window happened to be open. Root cause: Blizzard's native "reveal empty slots while dragging" behavior relies on the `ACTIONBAR_SHOWGRID` / `ACTIONBAR_HIDEGRID` events (fired when the cursor picks up / releases a placeable), which the empty-slot hider never listened for — opening the Spellbook/Talents only "worked" because Blizzard's own grid-forcing code for those panels bypassed it. Empty slots are now temporarily revealed on `ACTIONBAR_SHOWGRID` and re-hidden on `ACTIONBAR_HIDEGRID` (once the cursor is actually clear), so they can be dropped onto during any pickup while still staying fully hidden at rest, exactly as configured.

#### Objective Tracker — Mover Position No Longer Resets
- **Fix** — Dragging the Objective Tracker via its mover could stop "sticking": Blizzard's Edit Mode (or other UI code re-anchoring the tracker, e.g. opening the Quest Journal) could call `SetPoint` on `ObjectiveTrackerFrame` at any time and silently override the saved position, even though `IsUserPlaced()` was overridden to return true. The tracker now hooks its own `SetPoint` and re-applies the saved anchor the same tick anyone else moves it, exactly like the existing module/block-frame anchor guards in this file.

#### Objective Tracker — Quest Limit Slider Now Works in the Default Layout
- **Fix** — The "Max quests shown" slider had no effect at all in the default **Categories** (bucketed) layout: `LimitDisplayedQuests()` was only ever invoked from the "buckets disabled" branch of the update loop. It is now applied unconditionally after layout, regardless of whether bucketed categories are enabled.

#### Minimap — Position No Longer Drifts After a Reload
- **Fix** — The minimap could silently move itself back to a different spot after `/reload`, `SetupEditMode()` marks the Minimap as an Edit Mode system, and Edit Mode can still reposition it afterward (e.g. on `PLAYER_ENTERING_WORLD`) — the Minimap now hooks its own `SetPoint` and re-asserts the saved position anchor whenever anything else moves it (same pattern as the Objective Tracker mover), but only when the position actually drifted, so it doesn't fight Blizzard's own harmless internal layout adjustments. A `PLAYER_ENTERING_WORLD` / `EDIT_MODE_LAYOUTS_UPDATED` backstop re-applies the saved position once more shortly after login as an extra safety net.
- **Fix** — Found the actual root cause of the drift: `SavePosition()` was multiplying the saved coordinates by `Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale()`, but the Minimap already carries its own `SetScale()` from the Minimap scale slider, so its effective scale already includes that factor — multiplying by it again double-scaled the saved position toward the screen's bottom-left corner every time the UI reloaded. The saved/restored coordinates are now the raw, unscaled frame edges, which round-trip correctly regardless of the configured minimap scale.

#### Minimap — Button Collector No Longer Re-Hides Other Addons' Buttons When Disabled
- **Fix** — Disabling the TomoMod button collector and reloading previously still hid every other addon's minimap button (alpha 0) at login, with nothing to ever restore them, since the pre-hide pass ran unconditionally before the enabled/collector-style check. It now skips pre-hiding entirely when the collector is disabled or set to "Blizzard (native)" style, matching the setting immediately after every reload.

#### Minimap — Tracking Button Visibility & Native Button Clickability
- **Fix** — Added a defensive `Hide`/`SetAlpha` safeguard on TomoMod's own tracking button so it re-shows itself immediately if anything else (another addon walking the minimap's children, Blizzard's own square-minimap code, Edit Mode) silently hides it — a plain `Hide()` call throws no Lua error, so this kind of interference never showed up in Diagnostics even though the button visibly vanished.
- **Fix** — Fixed Blizzard's native tracking button staying permanently unclickable after being "revealed" (by switching the tracking style to Blizzard, or disabling TomoMod's custom button): `EnableMouse()` was only ever applied once per settings change, unlike `Show`/`SetAlpha` which were continuously re-enforced. It's now kept in sync the same way, so the native button is guaranteed clickable whenever it's shown.

#### Reputation Bar — Blizzard's Bar Fully Suppressed
- **Fix** — The default Blizzard reputation/honor/artifact tracking bar could still show through even with "Hide Blizzard reputation bar" enabled: some of its pooled child bar frames call `SetIgnoreParentAlpha(true)`, so setting the *container's* alpha to 0 didn't actually hide them. Suppression now recurses into the container's child tree, clears `SetIgnoreParentAlpha` before zeroing alpha on each one, and re-applies on every `StatusTrackingBarManager` bar update (bars are pooled/recreated by Blizzard).

#### Tooltip — Less Transparent Default Background
- **Change** — Default tooltip background opacity raised from 92% to 97% for better readability out of the box. The existing **Background opacity** slider (Skins → Tooltip, 0–100%) still allows full customization.

#### Tooltip — Custom Anchor No Longer Shown Outside Layout Mode
- **Fix** — The draggable "Custom" position anchor swatch used to stay visible on screen permanently once that anchor mode was selected, even during normal play far outside any placement/edit mode — unlike every other movable element in the addon. It's now hidden by default and only appears while actively placing it.
- **New** — The tooltip anchor is now registered with the addon's unified **Layout Mode** toggle, so pressing "Layout" reveals it like any other movable element and hides it again automatically afterward.
- **New** — A dedicated **"Show/Hide anchor"** button was added directly in Skins → Tooltip for quick access without opening the full Layout panel.

#### Diagnostics — "Copy Report" Popup No Longer Hidden Behind the Console
- **Fix** — Clicking **Copy Report** appeared to do nothing: the diagnostics console was previously raised to `FrameLevel 600` + `SetToplevel(true)` (to always render above the config menu), but the separate export popup opened by that button was never given a level above it, so it opened invisibly behind the still-open console. The export popup's level is now computed relative to the console's current level (always above it) instead of being hardcoded, so it stays correctly on top even if the console's level changes again later.

## ####################################

## CHANGELOG 3.1.8 — Bag Skin Category Rework (Enum.ItemClass & Extensible Ordering)

#### Bag Skin — Locale-Independent Category Matching
- **Change** — Category matching in the **Categories** layout no longer compares raw numeric `classID` literals (e.g. `2`, `4`, `12`). It now resolves the proper `Enum.ItemClass` constants (`Armor`, `Weapon`, `Consumable`, `Questitem`, `Tradegoods`, `Reagent`, `Gem`, `ItemEnhancement`, `Recipe`, `Miscellaneous`, `Battlepet`) at load time, each with a numeric fallback so categorization stays correct even if a constant name is ever unavailable on a given client.

#### Bag Skin — Reordered Default Categories
- **Change** — Default category order updated to an priority: **Quest Items** is now checked (and displayed) right after **Equipment**, ahead of **Consumables** and **Trade Goods**, instead of appearing after them.

#### Bag Skin — Extensible Category Order/Visibility (Foundation)
- **New** — `GetActiveCategories()` builds the active, ordered category list from two new saved-variable fields: `bagCategoryState` (per-category `hidden` flag) and an optional `bagCategoryOrder` (custom key order). **Miscellaneous** and **Free Slots** are always forced active and always sorted last, so an item can never disappear from the bag entirely. No config UI is exposed for this yet — this patch only lays the groundwork for an upcoming hide/reorder settings panel.
- **Change** — `Categorize()` now accepts an explicit category list to bucket items against (defaulting to all categories), so it can be reused with the new active/filtered category set from `GetActiveCategories()`.
- **New** — Database defaults: `bagSkin.bagCategoryState = {}` added (existing profiles get it merged in automatically); `bagCategoryOrder` remains unset by default (nil = default order).

## ####################################

## CHANGELOG 3.1.7 — Save/Export Namespace Fix, Reliable Frame Drag & Drop & Objective Tracker Combat Fix

#### Profiles — LibSerialize Namespace Fix
- **Change** — The embedded `LibSerialize` library is now registered under a private namespace, `TomoSerialize-1.0`, instead of the shared `LibSerialize` name. `Core/Profiles.lua`'s Export/Import/Preview functions were updated to look it up via the new `LibStub` name.
- **Fix** — Prevents profile export/import breaking (or silently sharing state) when another installed addon also embeds `LibSerialize` under the same `LibStub` registration — each addon now gets its own private copy.
- **Fix** — `libs.xml` load order corrected: `LibStub.lua` is now loaded before `LibDispel` and `oUF`, both of which expect `LibStub` to already exist when they run.

#### Frame Dragging — Screen-Absolute Position Saving
- **Fix** — Saved positions for draggable frames could drift or flip after a drag, because `GetPoint()` returns whichever anchor/relativePoint pair is currently in effect — a pair that `StartMoving()`/`StopMovingOrSizing()` can silently change (e.g. a corner anchor becoming `CENTER`-relative). All drag-to-save call sites now read `GetLeft()`/`GetBottom()` (converted to `UIParent`-relative coordinates via `GetEffectiveScale()`) and always store a stable `BOTTOMLEFT`/`BOTTOMLEFT` anchor pair, regardless of how the frame was last moved.
- **Change** — Affected modules: Leveling Bar, Movers header bar, AuctionRecipeTracker, Mythic+ Tracker, TomoScore UI, Frame Anchors, Bag Skin (both drag handlers), Castbars, Party Frame anchor, Arena Frames anchor, Raid Frame anchor, Compass, Consumable Bar, Loot Browser, Minimap, Objective Tracker, Skyriding speed bar, Resource Bars container, and Unit Frame drag-to-move.

#### Objective Tracker — Combat Taint Fix
- **Fix** — Fixed a possible taint error when Blizzard re-shows a collapsed quest bucket block during an in-combat quest update: the block's `Show` hook now bails out early with `InCombatLockdown()`, matching the guard already used on the quest item button hook, instead of calling `self:Hide()` on a protected tracker block mid-combat.

#### Internal Cleanup — Dead Code Removal
- **Removed** — Several unused/disabled modules were deleted to reduce addon size: `Modules/Housing/DecorHover.lua`, `Modules/Housing/TeleportMacros.lua`, `Modules/Interface/UnitFrames/Elements/Castbar.lua`, `Modules/QOL/Combat/CoTankTracker.lua`, `Modules/QOL/CooldownManager/CooldownResource.lua`, `Modules/QOL/Skins/BagBank.lua`, `Modules/QOL/Skins/BagCategories.lua`, `Modules/QOL/Skins/ChatButtonHandlers.lua`, `Modules/QOL/Skins/ChatFrameSkinV2.lua`, `Modules/QOL/Skins/ChatFrameUI.lua`, `Modules/QOL/Skins/DamageMeterSkin.lua` — none were referenced by any `.xml`/`.toc` load list, so there is no user-facing change.
- **Change** — `Modules/QOL/QOL.xml` cleaned up: removed the leftover commented-out `<Include>` lines for the deleted Skins modules.

#### Localization — Missing French ChatFrameUI Strings
- **New** — Added the 12 missing French translations for the (currently disabled) ChatFrameUI config block: `sublabel_chatframeui`, `opt_cfui_enable`, `opt_cfui_editbox_height`, `opt_cfui_editbox_position`, the 4 frame-corner labels, `opt_cfui_icons_anchor`, `opt_cfui_raid_frame_mgr` and `opt_cfui_swap_in_combat`.

#### Raid Frames — Group Leader Panel No Longer Hidden
- **Fix** — `RF.HideBlizzardFrames()` (in `Modules/Interface/RaidFrame/Core.lua`) was suppressing both `CompactRaidFrameContainer` (the default member-frame rows, replaced by TomoMod's own raid frames — intended) and `CompactRaidFrameManager` (the "Groupe" leader toolbar docked to the left edge — ready check, raid target markers, convert to raid, ping limit, leave group/instance). The latter hosts leader/utility controls TomoMod does not reimplement, so hiding it removed useful functionality with no TomoMod equivalent.
- **Change** — `CompactRaidFrameManager` is no longer touched by `RF.HideBlizzardFrames()`; only `CompactRaidFrameContainer` is suppressed (via the existing taint-safe `SetAlpha(0)` + `SetScale(0.001)`). The default group leader toolbar is now visible again while TomoMod's custom raid frames remain in place.

#### Raid Frames — New Group Leader Panel Skin
- **New** — `Modules/QOL/Skins/GroupManagerSkin.lua`: full ElvUI-style reskin of the Blizzard `CompactRaidFrameManager` leader toolbar in the TomoMod dark/mint theme — outer card with accent border and top accent strip, and every control repainted with flat dark slots + 1px borders: the mode dropdown and ping-restriction dropdown, the role/group filter buttons, the toolbar icon buttons (edit mode, settings, hide toggle, everyone-assist, difficulty, ready check, role poll, countdown), the raid target marker buttons and their "Unit"/"Ground" tabs (with an accent underline on the active tab), and the "Leave Group" / "Leave Instance Group" buttons (dedicated red "danger" styling). Poppins font is applied to every label, and the pooled row/column dividers are hidden for a cleaner flat look.
- **Change** — All interactive states (hover, pressed, selected, applied, disabled, active tab) are reproduced on TomoMod's own slots by shadowing the exact texture/atlas Blizzard drives internally, so the reskin reacts correctly to ready checks, marker selection, filter toggles, etc. without fighting Blizzard's own updates.
- **Change** — Icon/glyph textures themselves (toolbar icons, raid marker glyphs, dropdown arrows) are never destroyed — only their surrounding chrome (backgrounds, borders, plates) is replaced — so nothing ever disappears, and colors are pulled from the shared `TomoMod_Utils.BRAND` / `BRAND_HOVER` / `BRAND_DARK` palette instead of hardcoded values.
- **New** — The skin is now fully reversible live: toggling the option off immediately restores every original Blizzard texture/divider without needing `/reload`.
- **New** — New "Skin the group leader panel" checkbox in Config → Raid Frames (enabled by default, database key `raidFrames.skinGroupManager`), translated in all 6 languages.
- **Fix** — The outer card frame is now parented to `CompactRaidFrameManager.displayFrame` instead of the manager itself: the manager stays fully sized (just moved off-screen) when the panel is collapsed, so the old card was left poking out as a stray full-height strip on the left edge. Parenting to `displayFrame` (which Blizzard actually hides on collapse) makes the card disappear automatically with zero extra hooks.
- **New** — Collapsed state gets a dedicated pull-tab look (`SkinCollapseTab`) instead of being reskinned like a normal toolbar button: a compact dark tab flush to the screen edge with a mint accent stripe on the open edge and a mint-tinted arrow, with its own hover feedback — replacing the plain expand/collapse handle.

## ####################################

## CHANGELOG 3.1.6 — Combat-Safe Party & Raid Roster Updates & Cooldown Manager Holders & Resource Bars Health Bar

#### Party Frames — Secure Visibility Driver
- **Change** — Party frame visibility (player + party1-4) is now driven by `RegisterStateDriver` macro conditionals (`[group:raid] hide; [group] show; hide` for the player frame, `[group:raid] hide; [@partyN,exists] show; hide` for party members) instead of `RegisterUnitWatch`. This moves show/hide logic to Blizzard's secure state-driver side, so joining/leaving a group and switching between party and raid are handled correctly even while in combat.
- **Fix** — `RegisterUnitWatch` alone could not express the "hide in raid" rule, which previously forced a deferred watch re-registration on every roster change — a call that silently failed while `InCombatLockdown()` was true, leaving frames stuck visible or hidden mid-fight.
- **Change** — `PF.RefreshGroup()` no longer fully bails out during combat: frame creation and layout are still deferred, but already-shown frames are repainted immediately through the new `PF.UpdateAllFrames()` helper, since refreshing non-protected child regions is combat-safe.
- **Fix** — `UNIT_NAME_UPDATE` now triggers a full `PF.UpdateFrame()` repaint instead of only `PF.UpdateName()`, so a roster shift that moves a different player onto the same unit token (e.g. party2 leaves and former party3 becomes party2) refreshes class color, absorbs and dispel highlighting along with the name — including in combat.
- **New** — Frames hook `OnShow` to trigger a full repaint the instant the secure driver reveals them, covering mid-combat joins.

#### Raid Frames — Secure Visibility Driver
- **Change** — Raid frame visibility (raid1..40) is now driven by a `RegisterStateDriver` `[@raidN,exists] show; hide` conditional, replacing the previous manual `Show()`/`Hide()` loop over `GetNumGroupMembers()`. Members joining or leaving mid-combat are now shown/hidden correctly, and no "ghost" frames are left behind when a member disconnects or leaves during a fight.
- **New** — `RF.EnsureFrames()` pre-creates the full raid1..raid40 frame set once, out of combat, so late joiners during a fight already have a driver-managed frame ready to be revealed without any protected `SetAttribute` calls mid-combat.
- **New** — `RF.UpdateAllFrames()` repaints every currently shown frame; used by `RF.RefreshGroup()` and as the combat-safe fallback when a full refresh is requested mid-fight.
- **Fix** — `UNIT_NAME_UPDATE` now triggers a full `RF.UpdateFrame()` repaint instead of only `RF.UpdateName()`, so a roster shift (e.g. raid20 leaves and former raid21 becomes raid20) refreshes class color, absorbs and dispel state along with the name.

#### Cooldown Manager — Phase 4: Holders Architecture
- **New** — `CDMHolders.lua`: four movable anchor frames (Essential, Utility, Buff Icons, Buff Bars) that Blizzard's secure Cooldown Viewer icons attach to. Each position is saved per-viewer in `cooldownManager.viewerLayout` and can be dragged into place without touching Blizzard's Edit Mode grid.
- **Change** — `CDMLayout.lua` (v3.2.0) no longer resizes or repositions the Blizzard viewer frames directly (no `SetParent`/`Show`/`Hide`/`SetScale` on secure frames); icons are now anchored to the new holder containers instead, removing a class of Edit-Mode/taint conflicts.
- **Change** — `CooldownManager.lua` rewritten (V3.2, "Phase 1+2+3+4"): coordinates `CDMScanner`, the new `CDMHolders`, `CDMLayout`, `CDMProcGlow` and `CDMKeybinds` behind a single coherent module.
- **New** — Lock/unlock toggle and live preview icons/bars for each holder, so empty viewers can still be positioned before any cooldown is active.
- **Change** — Internal per-viewer state (stable slot tracking, viewer settings lookup) moved to weak tables keyed by canonical viewer key instead of writing custom fields onto Blizzard's protected frames.

#### Resource Bars — v2.8: Health Bar
- **New** — Optional health bar for the Resource Bars module: configurable height, text format (percentage / value / both), class-colored fill, smooth bar animation, and a low-health color threshold (custom color + percentage trigger).
- **New** — Database defaults added: `healthBarEnabled`, `healthBarHeight`, `healthTextFormat`, `healthClassColored`, `healthThresholdEnabled`, `healthThresholdPct`, `smoothBars`, `powerTicks`, `powerThresholdEnabled`, `powerThresholdPct`, plus `health` / `healthLow` / `powerLow` colors.

#### Config UI — CD & Resource Panel v2.9.0
- **New** — Cards layout for the Cooldown Manager section, and a new **Bars** tab grouping all Resource Bars / health bar settings.
- **New** — Holder placement controls exposed in the config panel to drag/reset each of the 4 holder positions directly from the UI.

#### Localization — CD & Resource Panel Missing Strings
- **Fix** — The **Bars** tab (`tab_cdm_bars`), the placement/live-preview cards (position sliders, icon size, spacing, row limit, direction & secondary direction dropdowns, unlock/reset buttons) and the Resource Bars **health bar** & **animations** sections were displaying raw locale keys (e.g. `opt_cdm_pos_x`, `section_rb_healthbar`) instead of translated text — these keys had never been added to any of the 6 locale files. All ~45 missing keys are now translated in EN / FR / DE / ES / IT / PT-BR.
- **Fix** — The direction dropdowns for cooldown icon layout and the BuffBar direction dropdown were using hardcoded French text instead of `TomoMod_L` lookups; they now reuse the existing localized `dir_*` / `buffbar_*` keys so they display correctly in every language.

#### Chat — Taint Fix (Secret Values)
- **Fix** — Fixed a taint error (`attempt to perform string conversion on a secret string value`) thrown from `ChatFrameSkin.lua` whenever a channel or whisper message was processed. `FCFManager_GetChatTarget` called `tostring()` on the channel/player target without the `issecretvalue()` guard used everywhere else in the file — it now checks for secret values before converting, matching the rest of the module.

#### Skyriding — Taint Fix (Secret Values)
- **Fix** — Fixed a taint error (`attempt to perform arithmetic on local 'speed' (a secret number value)`) in `SkyRide.lua`'s speed bar update. `GetUnitSpeed("player")` (and `C_PlayerInfo.GetGlidingInfo()`'s `forwardSpeed`) can now return a protected "secret" number; dividing/multiplying it directly tainted execution. Both call sites now guard with `issecretvalue()` and fall back to `0` when the value is secret, matching the pattern already used elsewhere in the addon.

#### Minimap — Configurable Durability Position
- **New** — The gear durability text position is now configurable from **Interface → General → Info Panel**: a corner dropdown (Top Left / Top Right / Bottom Left / Bottom Right) plus X/Y offset sliders. Useful since the new patch 12.0.7 expansion landing-page button can appear on the minimap and overlap the default bottom-left corner.
- **New** — `IP.ApplyDurabilityPosition()` repositions the durability text live as the settings change; new database defaults `durabilityAnchor`, `durabilityX`, `durabilityY` (default to the previous fixed Bottom Left / 6 / 6 position, so existing setups are unaffected).

## ####################################

## CHANGELOG 3.1.5 — Objective Tracker Fixes & Talking Head GUI Toggle

#### QOL — Talking Head — GUI Toggle Restored
- **Fix** — The **Hide Talking Head** checkbox is back in the config GUI (**Comfort → QOL → Automations**), next to *Hide Blizzard cast bar*. The `hideTalkingHead.enabled` setting and its module already existed, but the toggle was only reachable from the Installer — the option had disappeared from the main config panel.
- **Change** — `HideTalkingHead.lua` now reacts at runtime like `HideCastBar`: new `TomoMod_HideTalkingHead.SetEnabled()` / `Toggle()` API. The `OnShow` hook re-reads the DB toggle on every show, so checking/unchecking the box takes effect **immediately without a `/reload`** and is **reversible** — unchecking restores the scrolling dialogue frames (the previous `UnregisterAllEvents` approach was one-way).
- **Change** — Load-on-demand handling: the module now hooks the frame via `ADDON_LOADED` for `Blizzard_TalkingHeadUI`, so it works even though the TalkingHead frame is created on first use.
- **New** — `opt_hide_talking_head` locale key added to all 6 locale files (EN / FR / DE / ES / PT-BR / IT).

#### QOL — Objective Tracker — Quest Item Button Collapse Fix
- **Fix** — Quest item buttons (`block.itemButton`, e.g. "Use: Kilnmaster's Orders") are now correctly hidden when their bucket is collapsed. The button is parented to the native tracker rather than to the quest block, so `block:Hide()` had no effect on it — the button floated visibly above collapsed buckets. It is now explicitly hidden on collapse (with a `hooksecurefunc("Show")` guard to prevent Blizzard's `Update` calls from re-showing it while the bucket is collapsed, with a `InCombatLockdown()` safety check) and restored on expand (only if TomoMod hid it, so Blizzard's own visibility logic remains in control afterwards).

#### QOL — Objective Tracker — Progress Bar Anchor Fix
- **Fix** — Quest/scenario progress bars (`StatusBar`) that stay parented to `BlocksFrame` while only being *anchored* to their block were wrongly hidden by the `STEP 4` stray-bar sweep, blanking the progress bar of tracked, expanded objectives (e.g. enemy forces, weekly/WQ progress). The sweep now reads each bar's anchor target via `f:GetPoint(1)` and keeps the bar visible when that target is one of TomoMod's reparented, currently-visible frames under `skinFrame`.
- **New** — `IsUnderSkinFrame(f)` helper — walks up to 12 ancestors from a frame to determine whether it sits under `skinFrame` (i.e. belongs to a reparented quest block or scenario/delve module). Used by `HideStrayBars` to distinguish genuinely orphaned bars (floating "0%" WQ module bars, collapsed/hidden blocks) from anchored-but-active ones.

## ####################################

## CHANGELOG 3.1.4 — Tooltip Position System & Locale Fixes

#### Tooltip — Position Mode
- **New** — Four positioning modes for the game tooltip: **Default** (Blizzard’s native behaviour), **Cursor** (explicit mouse-follow via the CursorRing anchor), **Corner** (pinned to any screen corner — Bottom Right / Left, Top Right / Left — with configurable padding) and **Custom** (drag-to-place: a movable teal anchor frame sets the exact position).
- **New** — `TS.RefreshAnchor()` shows or hides the movable anchor frame whenever the active mode changes.
- **New** — `EnsureTooltipMover()` lazily creates the `TomoMod_TooltipMover` drag frame; the chosen position is persisted in `tooltipSkin.moverX / moverY`.
- **Change** — CursorRing mouse-follow logic now reads `tooltipSkin.anchor`: in Corner and Custom modes the tooltip is anchored statically by `TooltipSkin` and is no longer chased by the cursor-ring `OnUpdate` hook.
- **New** — Two new dropdowns in **Skins → Tooltip**: anchor mode selector and corner selector (active only in Corner mode), plus an info text for Custom mode.
- **New** — Database defaults: `tooltipSkin.anchor = "default"`, `tooltipSkin.anchorCorner = "BOTTOMRIGHT"`.

#### Locales — Tooltip Color Keys Fix
- **Fix** — `opt_tooltip_bg_color` and `opt_tooltip_border_color` keys added to all 6 locale files. These keys were referenced in the Skins → Tooltip config panel (introduced in 3.1.3 with the color picker controls) but missing from the locale tables, causing raw key names to appear in the UI instead of the translated labels.

#### Chat Frame Skin — Cursor Drag Lockup Fix
- **Fix** — `FCF_StopDragging = NoOp` override removed from `ChatFrameSkin.lua`. This line was preventing the game engine from restoring the cursor after dragging a chat frame, leaving the cursor locked in drag mode for the remainder of the session until the next `/reload`.

#### Minimap — Collected Buttons Release Fix
- **Fix** — `TomoMod_Minimap.ReleaseCollectedButtons()` is now called whenever the collector is disabled or when Blizzard mode is active. Previously, buttons that had been captured into the collector box were left hidden with no way for the game to reclaim them until a reload.

#### Tooltip — Configurable Background & Border Colors
- **New** — Two color pickers added to **Skins → Tooltip**: **Background color** and **Border color**. The previous hardcoded dark values are now editable at runtime via the config panel.
- **New** — `TooltipSkin` reads `s.bgColor` / `s.borderColor` from the saved database with fallback to the built-in constants (`BG_COLOR` / `BORDER_CLR`), so existing installs without saved values remain visually unchanged.
- **New** — Database defaults: `tooltipSkin.bgColor = { r=0.06, g=0.06, b=0.08 }`, `tooltipSkin.borderColor = { r=0.20, g=0.20, b=0.24 }`.

## ####################################

## CHANGELOG 3.1.3 — Grouped Navigation, Accent Context & SegmentedControl

#### Config UI — Grouped Navigation (6 Categories)
- **Change** — The 16 individual nav buttons have been consolidated into 6 top-level groups: **Accueil**, **Interface** (General, Action Bars, Skins, Sound), **Units** (UnitFrames, Nameplates, Party, Raid), **Combat** (Castbars, CD & Resource, Mythic+), **Comfort** (QOL, Housing) and **Tools** (Profiles, Diagnostics). Each group opens a tabbed sub-panel.
- **New** — Each category carries its own accent color. The title bar accent line, header glow and context label all update to match the active category.
- **New** — `CreatePageShell` injects a header above each grouped panel: icon, title and description rendered in the category accent color.
- **New** — `categoryAliases` map: calling `SwitchCategory` with a legacy key (e.g. `"general"`, `"raidframes"`) automatically redirects to the correct group and pre-selects the right tab — full backward compatibility.

#### Widgets — Per-Panel Accent Context
- **New** — `W.SetPanelContext` / `W.ApplyPanelContext` / `FindDesign(parent)` — widgets walk up the parent chain to find the nearest `_muiDesign` context. Cards, section headers, separators, checkboxes, dropdowns, buttons and tab panels all automatically adopt the accent color of their host panel with no extra parameters.
- **Change** — All widget draw calls (`CreateCard`, `CreateSectionHeader`, `CreateSeparator`, `CreateInfoText`, `CreateCheckbox`, `CreateDropdown`, `CreateButton`, `CreateButtonRow`, `CreateTabPanel`) derive their accent RGB from context rather than the global `T.accent`.

#### Widgets — New SegmentedControl
- **New** — `W.CreateSegmentedControl(parent, text, options, selected, yOffset, callback, columns)` — a compact row of toggle buttons replacing short dropdowns (2–3 options). Supports multi-row layouts, adapts to parent width on resize, and uses the panel accent color for the active segment.

#### Widgets — Dropdown Improvements
- **Fix** — Dropdown menus are now parented to `UIParent` at strata `TOOLTIP` / level 9000, preventing them from being clipped inside scroll panels or cards.
- **New** — `W.CloseDropdowns()` closes any open dropdown when switching panels or hiding a frame. Dropdowns also self-close on `OnHide`.

#### Widgets — Tab Panel Rebuild
- **Change** — Tab content is fully destroyed and rebuilt on every tab switch (`ClearContent`), preventing stale panels from lingering in the frame hierarchy. `OnHide`/`OnShow` hooks ensure content is properly recycled when the wrapper is hidden.

#### QOL / Skins / Sound — SegmentedControl Replacements
- **Change** — Bag Bar mode, Micro Menu mode → `SegmentedControl` (2 columns) in the **QOL** panel.
- **Change** — Chat skin style, Bag layout mode, Bag sort mode → `SegmentedControl` (2–3 columns) in the **Skins** panel.
- **Change** — Audio channel selector → `SegmentedControl` (3 columns) in the **Sound** panel.

#### Diagnostics — UIError Exclusion Keywords
- **New** — 7 new UIError keyword groups added to the exclusion filter (from session report #605): merchant not interested, on a mount, can't carry more items, can't delete item, item can't be upgraded, already have that appearance, target engaged in a duel. Each entry covers FR / EN / DE / ES variants.

#### Diagnostics — Console Always on Top
- **Fix** — The diagnostic console strata raised from `DIALOG` (level 200) to `FULLSCREEN_DIALOG` (level 600, `SetToplevel(true)`), so it always renders above the config menu when both are open.

#### Accueil — Dashboard Rewrite
- **Change** — The Accueil panel has been completely rewritten as a mission-control dashboard.
- **New** — **Hero banner**: TomoMod logo, active module count and a live diagnostics status badge (`Ready` / `Check` / `External`) driven by `TomoMod_Diagnostics`. Hovering the badge shows a tooltip with the issue count.
- **New** — **Quick action row**: four shortcut buttons — Installer, Profiles, Diagnostics, Reload — for the most common tasks without leaving the dashboard.
- **Change** — Module toggles redesigned as compact on/off rows; preset and profile sections retained with updated copy.
- **Fix** — `StaticPopupDialogs` key renamed from `MYSTICALUI_MODULE_RELOAD` to `TOMOMOD_MODULE_RELOAD` to avoid naming conflicts with other addons.

#### Loot — Class Filter Fix (Armor Type Fallback)
- **Fix** — Items absent from `TomoMod_ItemClasses` (e.g. new raid drops like Sporefall) were treated as class-universal and shown for all classes, causing plate/mail/leather/cloth pieces to appear for incompatible classes.
- **New** — `ArmorTypeMatches(itemID, classID)` helper refactored as a dedicated function: correctly handles **shields** (Warrior / Paladin / Shaman only via `SHIELD_CLASSES`), **cloaks** (always visible despite Cloth sub-type) and generic armor (ring, neck, trinket — always visible).
- **Change** — When an item has no entry in the IDB, the fallback now applies `ArmorTypeMatches` instead of assuming universal.
- **Change** — Both code paths (IDB loaded / IDB absent) now share the same `ArmorTypeMatches` logic, removing the duplicated inline fallback.

#### Loot Data — Sporefall Raid
- **New** — Sporefall raid (`journalInstanceId` 1305, `ejEncounterID` 2711) added to `TLD.raidBosses` with 15 item IDs from the KeystoneLoot dataset (build 12.0.7, 2026-06-17).

#### Nameplates — Live Preview Panel
- **New** — A **live preview** is injected at the top of the Nameplates config panel, showing three representative plates: a friendly ally, a hostile target (with cast bar) and a marked boss.
- **New** — The preview reacts in real-time to bar width, bar height, cast bar height, cast bar visibility and name font size changes — no reload required to see the effect.
- **New** — Preview is clip-guarded (`SetClipsChildren`) so oversized bar values can never overflow the card boundary.
- **New** — `TomoMod_NameplatesPreviewRefresh()` global hook called automatically after any nameplate setting change.

## ####################################

## CHANGELOG 3.1.2 — Brand Color Refresh & Code Fixes

#### UI — Brand Color Updated (#0cd29f → #2ed884)
- **Change** — The addon accent color has been updated from the old teal `#0cd29f` to a new mint green `#2ed884` across the entire interface: title bar, all Config panels, chat messages, in-game popups, progress-bar tints and every default color value stored in the database.
- **Change** — Every RGB float triplet (`0.047, 0.824, 0.624`) that was previously hardcoded has been replaced with a reference to the new centralised `TomoMod_Utils.BRAND` constant, so a future recolor only requires changing one place.

#### Core — BRAND Color Constants (New API)
- **New** — `TomoMod_Utils.BRAND` `{ r, g, b }` — primary mint accent (`#2ED884`).
- **New** — `TomoMod_Utils.BRAND_DARK` `{ r, g, b }` — darker pressed-state variant (`#1C8A55`).
- **New** — `TomoMod_Utils.BRAND_HOVER` `{ r, g, b }` — lighter hover-state variant (`#52F0A6`).
- **New** — `TomoMod_Utils.BRAND_HEX` — hex string `"2ed884"` for use in `|cff` color codes.
- All `Config/` panels, the `Widgets.lua` Theme table (`accent`, `accentDark`, `accentHover`, `accentBg`, `textHeader`) and the `Installer.lua` local palette now read from these constants.

#### QOL — CompanionStatus Global Leak Fix
- **Fix** — `UpdateIcon()` was declared without `local` in `Modules/QOL/Classes/CompanionStatus.lua`, silently leaking a global variable. It is now correctly declared `local function UpdateIcon()`.

#### Locales — frFR Unicode Fix
- **Fix** — The French locale string `info_cb_desc` contained a raw Lua 5.1-incompatible Unicode escape (`\u00a0`). It has been replaced with the correct literal byte sequence (`\194\160`, a UTF-8 non-breaking space), preventing a potential load error on strict Lua 5.1 interpreters.

## ####################################

## CHANGELOG 3.1.1

#### ResourceBars — Frost Mage Icicles (New)
- **New** — Frost Mage (spec 3) now displays an **Icicles tracker** in the Resource Bar: 5 dot-segments track the `Icicles` aura (spell 205473), giving a visual indication of when Glacial Spike is ready.
- **New** — When all 5 Icicles are stacked the bar pulses with a **PixelGlow** effect (via LibCustomGlow-1.0); a brightness fallback is used when the library is unavailable.
- **New** — Custom color for Icicles (`icicles`) added to the **CD & Resource → Colors** panel (default: light icy blue).
- **New** — `GetAuraColorKey` updated so the Icicles bar respects the user-chosen color.

#### Tooltips — Midnight Secret-Money Taint Fix (EncounterJournal)
- **Root cause** — In 12.x an item's sell price is a *secret* number; Blizzard's `MoneyFrame_Update` does arithmetic on it, legal only while execution is untainted. TomoMod injected/restyled on item-comparison tooltips (EncounterJournal, ShoppingTooltip1/2), tainting that arithmetic → `attempt to perform arithmetic on a secret number value (… tainted by 'TomoMod')`.
- **Fix** — New shared guard `TomoMod_IsCompareOrMoneyTooltip()` (Core/Utils.lua). TooltipIDs (item ID line), AuctionRecipeTracker (TomoHDV price line) and TooltipSkin (font/backdrop restyle) now skip compare/EncounterJournal tooltips.
- **Trade-off** — Normal tooltips (bags, bank, equipped, chat links) keep all features; only compare/EncounterJournal tooltips lose the injected lines and the dark skin.

#### AuctionRecipeTracker — Quantity Reminder on Reagent Search
- Clicking a reagent searches the Auction House (by name) and shows the required quantity in the status bar (e.g. "× 14"), so you know how many to buy while browsing results.
- Note: the quantity is a reminder only — the AH browse API has no quantity filter and `SendSearchQuery` can't drive the UI, so the buy amount can't be pre-filled and quality-tiered reagents still group by name.

## ####################################

## CHANGELOG 3.1.0 — Battle Rez Counter, Resurrection Indicator & Per-Size Raid Layouts

#### Raid & Party — Battle Rez Counter (New)
- **New** — A movable on-screen **Battle Rez counter** showing how many combat resurrections are currently available and the time remaining until the next charge.
- **New** — Reads the **shared combat-res charge pool** (`C_Spell.GetSpellCharges`), so it is correct for the whole group and works on any class — it does not depend on who can cast a brez, and a per-cast spell ID is a protected value in 12.x anyway.
- **New** — Cooldown swipe + live MM:SS timer; the count turns green when at least one rez is ready and red (desaturated icon) when the pool is empty.
- **New** — Draggable in **Layout Mode** with a representative preview while unlocked; position saved to profile.
- **New** — Configurable in **Raid Frames → Features → Battle Rez Counter**: enable, "only inside dungeons/raids", counter size and font size. Outside instances the pool query returns nothing, so the counter naturally stays hidden.
- **Note** — Taint-safe by design: a plain (non-secure) HUD frame, no protected calls, and no Lua arithmetic on secret values — charge fields are read through a value-type / `issecretvalue` guard.

#### Raid & Party — Resurrection Indicator (New)
- **New** — A **rez icon** now appears on a party or raid member while a resurrection is being cast on them (combat-res or a normal out-of-combat rez), driven by `UnitHasIncomingResurrection` and `INCOMING_RESURRECT_CHANGED`.
- **New** — Per-frame, lazily created overlay icon; size is configurable independently for party and raid frames.
- **New** — Configurable in **Party Frames → Cooldowns** and **Raid Frames → Features**: enable + icon size.
- **Note** — Non-secure overlay child, updated on events, so it is safe to show/hide during combat.

#### Raid Frames — Per-Size Layouts (10 / 25 / 40)
- **New** — Optional **per-size layout overrides**: frame width and height adapt automatically to the current group size, across three brackets — Small (up to 10), Medium (up to 25) and Large (26–40).
- **New** — Spacing and group-spacing presets are applied per bracket too, so a 40-player raid packs together more tightly than a 10-player group.
- **New** — Configurable in **Raid Frames → Features → Per-Size Layout (10/25/40)**: master enable + width/height sliders per bracket. When disabled, the single base layout is used exactly as before.
- **Change** — Layout recalculation is **combat-gated**: bracket changes that land mid-combat are deferred and replayed on `PLAYER_REGEN_ENABLED`, so resizing never taints protected frames.

#### Party Frames — Battle Rez Cooldown (Fix)
- **Fix** — The party-frame battle-rez tracker never visually entered cooldown: capable classes always showed the icon as "ready", so you could not tell how many resurrections were left or when the next one would be up.
- **Change** — The brez tracker is now **pool-driven** — it reads the shared combat-res charge pool, so the icon correctly greys out and shows the recharge timer for everyone in the instance the moment a brez is used, independent of which member cast it. (Per-cast detection is no longer possible in 12.x because the cast's spell ID is a protected value.)
- **Note** — The interrupt tracker is unchanged and still uses `UNIT_SPELLCAST_SUCCEEDED`.

#### Localization
- **Note** — New strings (Battle Rez counter, resurrection indicator, per-size layout) ship with inline English fallbacks; localized keys for the 6 locales (enUS / frFR / deDE / esES / itIT / ptBR) can be filled in next.

## ####################################

## CHANGELOG 3.0.7 — Objective Tracker Fixes & ResourceBars Improvements

#### QOL — Objective Tracker
- **Fix** — World Quest blocks are now correctly collected and sorted into the **World Quests** bucket. Previously the WorldQuest module subtree was excluded from block scanning, causing WQ entries to remain at their original Blizzard position and visually displace the entire tracker.
- **Fix** — The WorldQuest module container frame (now empty after its blocks are re-parented into the bucket) is suppressed via `SetAlpha(0)` after each layout pass so it no longer overlaps the skin.
- **Fix** — Progress bars (enemy forces, weekly %, etc.) that are parented to the module frame rather than to individual quest blocks are now hidden when their bucket is collapsed. A `HideStrayBars` pass walks the tracker tree after layout and stores bars for restoration when buckets are disabled.

#### ResourceBars — Guardian Druid
- **New** — Guardian Druid Rage is now shown as the **centered primary resource** by default (spec flag `primaryPower = true` added to `CLASS_RESOURCES.DRUID[3]`). Mana remains as the secondary bar below. The UnitFrame power bar is suppressed automatically when any primary power bar is active.

#### ResourceBars — Height Sliders Fixed
- **Fix** — The class power height and druid mana height sliders had no effect after the first load. All seven resource bar child frames were created with shared global names (`TomoMod_RB_Points`, `TomoMod_RB_DruidMana`, etc.). WoW silently ignores a second `CreateFrame` call for an already-registered name, so `BuildResourceDisplay` reused the old frames at their original dimensions. All global names replaced with `nil`.
- **New** — Added a **primary power bar height** slider (CD & Resources → Resource Bars → Dimensions) controlling the height of the centered rage/mana/energy bar.

#### UnitFrames — Player Power Bar Option
- **New** — New checkbox in **UnitFrames → Player → Dimensions**: *"Show primary resource centered"*. When enabled, the UnitFrame power bar is hidden and the resource is displayed in the centered ResourceBars container instead. Mirrors the existing option in CD & Resources without requiring the user to navigate away from the UnitFrames panel.

## ####################################

## CHANGELOG 3.0.6 — Extra Action Button, Compass & BagSkin Slot Factory

#### ActionBars — Extra Action Button
- **New** — The Extra Action Button (the special button that appears for certain quests, items and boss encounters) is now managed by the TomoMod action bar system.
- **New** — It can be repositioned in **Layout Mode** like any other bar, with a live preview while unlocked; its position is saved to your profile.
- **New** — The **Zone Ability** button (the current zone's special action) moves together with the extra button so the pair stays grouped.
- **New** — Configurable in **Action Bars → Bar Management**: enable/disable, **scale** (50–200%) and a **reset-position** button.
- **Change** — Taint-safe by design: instead of reparenting the protected button, TomoMod relocates the Edit Mode container (`ExtraAbilityContainer`). The container's internal layout still positions the button relative to itself, so it appears at your chosen spot even when it first shows up mid-combat. The anchor is re-asserted after leaving Edit Mode, and all repositioning is deferred out of combat.
- **Note** — Disabling the option releases the button back to Blizzard's default placement after a `/reload` (consistent with the rest of the action bar system).

#### QOL — Compass (New Module)
- **New** — New on-screen **heading bar** that scrolls through the cardinal directions (N / E / S / W) as the camera turns, driven by `GetPlayerFacing()`. A center pointer marks the direction the player is currently looking.
- **New** — **Quest marker** (amber): an azimuth marker points toward the super-tracked quest — the same objective as the Waypoint beam — read from `C_SuperTrack.GetNextWaypointForMap` so cross-zone redirects are handled by Blizzard.
- **New** — **Waypoint marker** (teal): a second marker points toward the user map waypoint (`C_Map.GetUserWaypoint`) when one is placed, so a tracked quest and a manual waypoint can be shown at the same time. Markers stick to the bar edge when their target is outside the visible field.
- **New** — Optional **heading readout** below the bar (16-point abbreviation, e.g. `245° SW`).
- **New** — Azimuth uses world coordinates (`C_Map.GetWorldPosFromMapPos`) for correct bearings on non-square maps; distance shown in yards/km matching the Waypoint module.
- **New** — Configurable via GUI (Quality of Life → Compass): enable, bar width (240–520), height (18–44), scale (0.6–1.8), **field of view** (Narrow ±45° / Standard ±60° / Wide ±90°), and per-marker toggles (quest / waypoint / distance / heading).
- **New** — Draggable in Layout Mode (mover system) with a live preview while unlocked; position saved to profile. New slash commands `/tm compass` (toggle) and `/tm compass debug` (print internal state).
- **Change** — 100% read-only: no protected functions are called, so the module cannot introduce taint. Updates run on a throttled `OnUpdate` (~33 fps) only while the bar is shown, and cardinal ticks are repositioned only when the heading actually changes.
- **Fix** — `C_Map.GetWorldPosFromMapPos` returns `(continentID, worldPosition)` — the `pcall` wrapper now correctly discards `continentID` and unpacks `worldPosition`, fixing a high-frequency Lua error (`attempt to index local 'world' (a number value)`, x417 per session).

#### Bags — BagSkin Slot Factory (Rewrite)
- **Fix** — Template sub-frames (IconBorder, overlays, quest texture, junk icon, upgrade icon, glow animations, etc.) are now explicitly hidden via `NeutralizeTemplate` so Blizzard code that references them by name never encounters nil.
- **Fix** — The icon and cooldown frames are reused from the template rather than creating duplicate textures on top, keeping the frame hierarchy clean.
- **Fix** — Slot buttons are no longer created inside `InCombatLockdown()`. If the bag is opened during combat when new pool entries are needed, layout is deferred and replayed automatically on `PLAYER_REGEN_ENABLED`.
- **Fix** — Tooltip reads bag and slot live from `GetParent():GetID()` / `GetID()` instead of a stored `btn.bag` field that could be stale after pool recycling.

#### Localization
- **New** — Added Compass strings (incl. localized cardinal letters: FR/ES/IT N·E·S·O, DE N·O·S·W, PT N·L·S·O) across all 6 locales (enUS / frFR / deDE / esES / itIT / ptBR), with equal key counts per language.
- **New** — Added Extra Action Button strings across all 6 locales.
- **New** — Added Compass fix and BagSkin What's New strings across all 6 locales.

## ####################################

## CHANGELOG 3.0.5 — RareAlert (New Module) & /tm RareScanner Fix - Compass Bar (Waypoint 2.0)

#### QOL — RareAlert (New Module)
- **New** — New QOL module that alerts you (sound + clickable banner) when a rare NPC enters minimap range, using Blizzard's vignette API — no NPC database required.
- **New** — Left-clicking the banner targets the rare (`/targetexact`), places the **Skull** raid marker and drops a waypoint. The marker is set via the native `/targetmarker` command run inside the button's secure context (right-click dismisses).
- **New** — Configurable in **QOL → Rare Alert**: enable, alert sound, banner display duration (5–60 s). The banner is draggable in Layout Mode with a reset-position button.
- **New** — Alerts are suppressed automatically in **dungeons and raids** (open-world / scenarios / delves only). The banner is dismissed as soon as the rare dies or leaves minimap range.
- **Note** — Like RareScanner, targeting cannot be re-armed during combat: the sound still fires and, if the rare is still present, the banner appears once combat ends. All show/hide is deferred out of combat (the banner is a protected secure button).

#### Slash Commands — /tm
- **Fixed** — Clicking a RareScanner rare alert opened the TomoMod config panel. RareScanner's "marker on target" macro appends `/tm <1-8>`, which collided with TomoMod's `/tm` handler. Numeric `/tm` arguments are now ignored. To mark a target manually, use the native `/targetmarker <0-8>` command (`SetRaidTarget` is protected and cannot be called from addon code).

#### UnitFrames — Player Auras
- **Fixed** — The player frame's buffs/debuffs could drift from the position you dragged them to after a `/reload` — the saved drag position was being combined a second time with the per-element offset. The dragged position is now the single source of truth.

#### Minimap — Collector Clock Anchor
- **Fixed** — The "left/right of the clock" anchor for the addon-button collector targeted the hidden native clock and silently fell back to the corner. It now anchors to the **InfoPanel** clock (`TomoMod_ClockBar`), positioned next to the time text, with deferred re-positioning since the clock is created late at login.

#### Leveling Bar — Visibility
- **Fixed** — Enabling the XP bar placed it at the bottom of the screen, hidden behind the action bars. With no saved position it now appears centered on screen so it can be found and dragged into place.

## ####################################

## CHANGELOG 3.0.4 — ConsumableBar, Cursor Ring Textures & MythicHub Teleport Fix

#### QOL — ConsumableBar (New Module)
- **New** — New QOL bar displaying **Flask** and **Well Fed** buff status with icon and countdown timer.
- **New** — Heuristic food detection (buff duration 3000–3720 s) covers all current Well Fed food buffs without requiring a hardcoded list.
- **New** — Configurable via GUI: enable/disable, icon size (24–56), gap, **orientation** (horizontal / vertical), **timer position** (below / above / right / left), show-when-missing toggle.
- **New** — Draggable in Layout Mode (mover system). Position saved to profile.

#### Cursor Ring — New Textures
- **New** — Two new cursor ring textures: **Cygle** and **Heart**, replacing the previous Sparkle and Star entries.
- **New** — Texture selector dropdown in the General → Cursor Ring tab (Ring, Glow, Cygle, Heart).

#### MythicHub — Teleport Fix
- **Fixed** — Clicking a dungeon row to teleport triggered `ADDON_ACTION_FORBIDDEN` taint (`CastSpellByID` called from an unsecured click handler). Rows are now plain Buttons; each row has a paired `SecureActionButtonTemplate` button parented to the main frame and positioned absolutely, matching the TomoScore pattern.
- **Fixed** — After the initial taint fix, a second crash appeared: `Cannot anchor protected frames to regions` because the new secure buttons were anchoring to `sep2` (a Texture). Secure buttons are now anchored absolutely to `F` (the main frame) using pre-computed Y offsets, never to a Texture or non-secure frame.
- **Fixed** — Secure buttons were being intercepted by the row buttons below them (same FrameLevel). Secure buttons now have `FrameLevel = row FrameLevel + 10` so they correctly capture clicks and forward OnEnter/OnLeave to the underlying row for tooltip display.

#### DataKeys — Spell ID Corrections
- **Fixed** — Corrected teleport spell IDs for **Maisara Caverns** and **Windrunner Spire** (Midnight season).

## ####################################

## CHANGELOG 3.0.3 — Minimap Custom Panels & UI Polish

#### Minimap — Custom Tracking Panel
- **New** — Clicking the tracking button now opens a **TomoMod-styled panel** anchored to the left of the minimap instead of the native Blizzard dropdown. Dark background, Poppins font, teal title, teal/grey checkbox squares. Supports mouse-wheel scroll for long tracking lists.
- **New** — Three custom TGA icons (32×32) created for the sidebar home button (`ico_gui.tga`), the tracking button (`ico_minimap_tracking.tga`) and the collector button (`ico_minimap_collector.tga`).

#### Minimap — Button Collector Panel
- **New** — The addon button collector now opens as a **TomoMod-styled panel** (matching the tracking panel): dark background, teal title "Boutons d'addon", separator line, class-color border. Anchored to the left of the minimap.
- **New** — Buttons are laid out **vertically** by default (1 column). The columns slider in the GUI still allows horizontal layouts.
- **New** — The collector panel **auto-closes 0.5 s after login/reload** once buttons are captured, keeping the UI clean on entry. If the user manually opened the panel, it stays open.
- **Fixed** — On the second open, the panel was showing "No buttons detected" because `RefreshButtonBag` was rescanning parents where buttons no longer live (already reparented). Now uses `RelayoutBag()` for subsequent opens — rescan only happens when the list is empty.
- **Fixed** — Buttons were briefly visible on the minimap on login/reload before being collected. A pre-hide pass at `t=0` now masks candidate buttons immediately, eliminating the flash.

#### Minimap — Button Border Fix
- **Fixed** — The tracking and collector toggle buttons had a **white square border** visible around them. The backdrop border is now fully transparent (`alpha 0`) on both buttons at creation and on every live update pass.

#### Tooltip — Black Rectangle Bug Fix
- **Fixed** — With the TomoMod tooltip skin enabled, hovering a unit or spell could produce a **large black rectangle** extending beyond the tooltip frame. Root cause: `NineSlice.Center:SetAlpha()` in TWW 12.x affects a larger area than expected. Replaced with `SetBackdrop` + `SetBackdropColor` + `SetBackdropBorderColor`, which is strictly bounded to the frame. NineSlice fallback also updated to use `SetVertexColor(r,g,b,a)` in one call instead of separate `SetAlpha`.

#### Minimap — Coordinates Position
- **Changed** — Player coordinates moved from **top-right** to **bottom-center** of the minimap overlay (6 px above the bottom edge), for better readability and less overlap with other indicators.

## ####################################

## CHANGELOG 3.0.2 — Minimap Collector Reliability & Bug Fixes

#### Minimap — Button Collector Overhaul
- **Fixed** — The addon button collector now captures buttons it previously missed, including ones that floated on the minimap ring or vanished when dragged. Detection is significantly more reliable across all addon types.
- **New** — Collected buttons get a **clean, uniform look**: decorative borders are stripped, icons normalized, and LibDBIcon's locked layering is unlocked so every button renders correctly inside the box.
- **New** — Buttons from addons that **load late** are detected automatically via a polling pass — no manual rescan needed.
- **New** — Blizzard's native **tracking button** and **addon compartment** are now hidden by default when the collector is active. A new GUI option lets you choose, per element, between the TomoMod version and Blizzard's own.
- **Fixed** — The collector can now be placed to the **left or right of the clock** so it no longer overlaps the minimap.

#### Player Auras — Layout Mode (Mover)
- **Fixed** — Player aura icons were not appearing in Layout Mode (the `/tm layout` mover). The aura container was registered in the Movers system but the `SetLocked()` method was never implemented, so the unlock/lock calls were silently ignored. `SetLocked(bool)` is now implemented on the container: it enables drag (`EnableMouse` + `SetMovable`) and shows a teal overlay label while unlocked, matching all other mover elements.

#### Cinematic Skip — TWW API Fix
- **Fixed** — A Lua error (`attempt to call a nil value`) occurred when a cinematic triggered the `MovieFrame` skip path. `MovieFrame_PlayMovie()` and `GameMovieFinished()` were removed from the WoW API in TWW. Both calls are replaced with `MovieFrame:StopMovie()` and a guarded `if GameMovieFinished then` check, fixing the crash without breaking the skip logic.

#### Diagnostics — Exclusion List
- **Fixed** — The "There is nothing to loot" (`ERR_LOOT_NOTHING`) message was being logged as a UIError in the Diagnostics panel. It is standard game feedback, not a bug. It is now excluded at runtime (resolved via GlobalString for all locales). A developer comment has been added to the exclusion table explaining how to find and add GlobalString keys for future messages of this type.

## ####################################

## CHANGELOG 3.0.1 — Locale Fix, Combat Safety & Minimap Refinements

#### Localization — Startup Crash Fix
- **Fixed** — A startup crash in the localization file left many config panels showing raw locale keys (Minimap, ButtonBag, Skins, Resource Bars…). All labels are now correctly translated in all 6 supported languages.

#### Layout Mode — Combat Safety
- **Fixed** — Toggling Layout Mode in combat triggered blocked-action errors. It is now safely refused while in combat. If combat starts while the interface is already unlocked, all frames re-lock automatically when combat ends (via `PLAYER_REGEN_ENABLED`).

#### Cooldown Manager — Proc Glow Taint Fix
- **Fixed** — A taint error occurred on Cooldown Manager proc glows caused by a Lua comparison against a protected (secret) spell ID value in TWW. The comparison is now done entirely on the C side.

#### Skyriding — Ground Speed Default
- **Changed** — Ground movement speed is now shown **by default** on the SkyRide bar. The option can be toggled off from the SkyRide tab.

#### Minimap — Collector Clock Positioning
- **Fixed** — The minimap button collector could overlap the clock. It can now be positioned to the left or right of the clock.

## ####################################

## CHANGELOG 3.0.0 — UI & Installer Overhaul

#### Installer — Presets-First Rewrite
- **New** — The setup assistant now opens on a **preset picker**: choose Recommended, Tank, Healer, DPS, Minimal or Custom. Picking a preset applies a complete, coherent configuration and jumps straight to a recap + reload — setup takes seconds.
- **New** — The **Custom** path keeps the full guided walkthrough (Frames → Bars & Skins → Mythic+ & Comfort → recap). The flow is dynamic: detailed steps are added or removed depending on whether a preset was chosen, with the dot navigation sized to the active flow.
- **Change** — Rebuilt panel chrome (820×600). All writes are DB-only and applied on the final reload, so nothing runs during combat and no taint is introduced.

#### Preset Engine — `TomoMod_Presets`
- **New** — Six setup presets. Each applies a recommended baseline, then a role-tuned delta: Tank → threat-colored, wider nameplates + target threat; Healer → larger raid/party frames with mana, HoTs, dispel and defensives; DPS → emphasized resource bar + enemy defensive tracking; Minimal → essentials only (no cosmetic skins/nameplates/extras); Custom → marker only. Idempotent and reusable at any time.
- **New** — Dev slash command `/tmpreset <complet|tank|healer|dps|minimal>` to apply a preset directly.

#### Config Panel — Home Dashboard
- **New** — `/tm` now opens on a **Home dashboard**: 12 quick module toggles, relaunch the assistant, apply a preset, switch profile, and reset — all in one place, with confirmation popups and a one-click reload.

#### Config Panel — Searchable Sidebar
- **New** — A **search box** filters the category sidebar by name, key and keywords (type `heal`, `cd`, `bag`…). The nav list is now scrollable to comfortably hold every category.

#### Minimap — Native Indicators
- **New** — Restored a **tracking button** on the square minimap (mailbox, battle pets, mining, herbs…). It delegates to the modern native tracking menu (`MinimapCluster.Tracking.Button`, 11.0+), so Townsfolk and Hunter tracking work out of the box, with a `MenuUtil` fallback that handles both the structured 11.0+ and the legacy `GetTrackingInfo` signatures.
- **New** — The **mail indicator** is re-anchored onto the square minimap and shows automatically when you have pending mail.
- **New** — The **instance difficulty indicator** (Normal/Heroic/Mythic, raid sizes) is re-anchored and appears while you are inside an instance.
- **New** — The **expansion/landing-page button** (Garrison, Order Hall, Covenant sanctum and later expansion features) is re-anchored, with `SetSize` / `UpdateIconForGarrison` / `SetLandingPageIconOffset` hooks that keep Blizzard from snapping it back out of place.
- **New** — The **crafting orders indicator** is re-anchored next to the mail icon.
- **New** — Each indicator has its own toggle under `/tm → General → Minimap`, and the tracking button is tinted with your class color (following the minimap border).
- **New** — A **"Minimap indicators"** panel lets you set each indicator's **corner, size and X/Y offset** from the GUI (selector + live preview), so you can lay them out exactly how you want on the square minimap.
- **New** — An **addon button collector** adds a button on the minimap that opens a box gathering all your minimap addon buttons (DBM, Details!, WeakAuras…), de-cluttering the minimap. It auto-detects LibDBIcon and raw buttons while skipping Blizzard frames and map overlays (HandyNotes, GatherMate2, TomTom…), with GUI controls for corner, columns, icon size and a rescan button.
- **Fixed** — Addon buttons that stayed on the minimap used to anchor to the old round Blizzard ring instead of the square edge. TomoMod now declares `GetMinimapShape() = "SQUARE"`, so LibDBIcon-based buttons position correctly along the square border; existing buttons are refreshed to the new shape (those moved into the collector box are left untouched).

#### Action Bars — Empty Buttons, Hotkey Font & Uniformize
- **Fixed** — Empty button slots reappeared after a `/reload` even with **"show empty buttons"** unchecked. The masking path was gated on a runtime flag that was lost on reload, so Blizzard's default (empty slots visible) took over at login. Masking is now applied unconditionally, so hidden empty slots stay hidden across reloads.
- **New** — **Hotkey font size** is now adjustable per bar (8–24), applied while preserving the original font face and outline.
- **New** — A **"Match all bars to this one"** button copies a bar's appearance (columns, spacing, button size, orientation, grow direction, alpha, scale, fade, click-through, count/hotkey text and hotkey font size) to every other bar. Each bar keeps its own position and enabled state; a confirmation popup guards the action.

#### Previews — Sound, Cast Bars, Class Reminder, Cooldowns & Resources
- **New** — **Sound test**: selecting a sound now plays it immediately, and a **"▶ Play this sound"** button sits right under the sound dropdown — no more configuring blind.
- **New** — **Cast bar preview on every unit tab**: the show/hide preview button is now available on the Player, Target, Focus, Pet and Boss tabs (previously only on the General tab).
- **Fixed** — Cast bar preview could show nothing for a unit you had just enabled: the preview state was only restored on already-existing bars. An explicit preview mode now re-shows the preview on **every** recreated bar, so a freshly enabled unit appears right away.
- **New** — Each non-player cast bar tab notes that the bar **anchors to its unit frame** (target/focus/pet/boss), clarifying why only the player bar moves freely.
- **New** — **Class reminder**: a **Preview** button shows a sample message at the configured position/scale/color for a few seconds, plus a **coverage list** of supported classes and the buffs/forms tracked for each.
- **New** — **Cooldowns & resources**: a **Preview** card with an **"Open Edit Mode"** button on both the Cooldown Manager and Resource Bars tabs. This uses Blizzard's native Edit Mode (which shows these bars with sample icons) to position them safely — no fake cooldowns, no taint on the protected cooldown viewers.

#### Character Skin — Movable Window
- **New** — The **Character frame can now be moved** (in addition to scaling). Enable **"Movable window"**, then drag the frame; its position is remembered and re-applied after Blizzard's UIPanel system repositions it (with a reentrancy guard to avoid loops). A **"Reset position"** button hands control back to Blizzard.

#### Skyriding — Ground Speed
- **New** — A **"Show ground speed"** option keeps the speed bar visible on the ground (useful with movement-speed buffs). The flight gauges (Vigor / Second Wind) stay hidden when not flying, so only the speed bar is shown. The grounded performance optimization is preserved when the option is off.

#### Waypoint — Arrow Direction Fix
- **Fixed** — The off-screen navigator arrow pointed the wrong way on the **front/back axis**: a quest directly behind you showed the arrow pointing up. The arrow texture actually rests pointing down, which made the rotation formula invert the vertical axis. The rotation is corrected so the arrow points at the quest in all directions (left/right were already correct and are unchanged).

#### Unit Frame Auras — Wrapping & Consistent Layout
- **New** — Aura icons on unit frames now **wrap to a new line** when they exceed a configurable max width, instead of running off in a single endless row. New **"Max width (wrap)"** and **"Spacing"** sliders are available per unit (spacing had no GUI control before).
- **Fixed** — Player and Target auras could look slightly different (size/spacing) despite identical settings. Two different layout paths existed — one at creation, another in `RefreshUnit` (an older horizontal-chaining layout with a hardcoded width). Both now use the same grid layout, so identical settings produce an identical result.

#### Localization — 6 Languages
- **New** — Every new 3.0 string (presets, installer, dashboard, search, What's New) is fully localized across the **6 supported languages**.

## ####################################

## CHANGELOG 2.9.21 — Player Aura Mover & Module Reload Safety & Waypoint Navigator Arrow Reversed

#### Player Aura Mover (Edit Mode)
- **New** — Player UnitFrame aura container now has a dedicated **mover overlay** in Edit Mode (Layout), matching the visual style of all other movers (teal accent, labeled "Auras player", hover feedback). The aura container was previously draggable but had no visual indicator.
- **New** — Dedicated **mover entry** `"Auras du joueur"` added to the Movers system (header bar), allowing the player aura container to be unlocked/locked independently of the full UnitFrame mover.
- **New** — `SetLocked(bool)` / `IsLocked()` API added to the aura container for clean integration with both the UnitFrame ToggleLock and the Movers system.
- **Refactor** — `UnitFrame.ToggleLock()` now uses `container:SetLocked()` instead of raw `EnableMouse()` calls, with backward-compatible fallback.

#### GUI — Aura Configuration
- **New** — **Icon Spacing** slider (0–12 px) added to the Auras sub-tab for Player, Target, and Focus units.
- **New** — **Reset Aura Position** button added to the Auras sub-tab, restoring the aura container to its default position from `TomoMod_Defaults`.

#### Module Reload Safety
- **New** — Toggling the master enable/disable of any major module (UnitFrames, Nameplates, Castbars, ActionBars, Party Frames, Raid Frames) or their "Hide Blizzard" options now triggers a **reload confirmation popup**. Previously, users could disable a module from the GUI without realizing a `/reload` was needed for Blizzard frames to fully restore (standard WoW addon behavior — permanent hooks from `hooksecurefunc`, `UnregisterAllEvents`, and `SetParent(hiddenParent)` cannot be undone at runtime).
- **New** — Info text `"Requires /reload to take effect"` displayed under each major module's enable toggle in the Config UI.

#### Waypoint — Navigator Arrow Position
- **Fix** — The off-screen navigator arrow is now positioned on the **opposite side** of the orbit circle relative to the target. When the goal is directly ahead (navFrame at the top of the screen), the arrow now appears at the **bottom** and points upward toward the goal — which is more intuitive than the previous behavior where the arrow was placed near the target itself.

#### Localization
- **New** — 8 new locale keys added across all 6 languages (enUS, frFR, deDE, esES, itIT, ptBR): `mover_player_auras`, `opt_auras_spacing`, `btn_reset_aura_position`, `msg_module_reload`, `info_module_reload`, and 3 What's New highlight keys.

## ####################################

## CHANGELOG 2.9.20 — Smart Waypoint

#### Waypoint — Cross-Zone Path Redirect
- **New** — The waypoint now uses `C_SuperTrack.GetNextWaypointForMap(mapID)` to detect the **next navigation step on the current map** (portal to another zone, dungeon entrance) instead of always pointing to the final destination. Registered on the new `SUPER_TRACKING_PATH_UPDATED` event and refreshed on every zone change and tracking change, so the beacon always reflects the reachable intermediate target.
- **New** — The destination label in the Waypoint beacon is now **dynamic**: priority order is (1) manual waypoint name, (2) redirect step description returned by `GetNextWaypointForMap` (e.g. "Travel to Durotar"), (3) the title of the super-tracked quest. Previously the label was blank for all quest-tracking waypoints.

#### Waypoint — Stuck "0 m" Fix
- **Fix** — The beacon no longer freezes at 0 m when the player is standing inside or directly above a quest objective area. `C_Minimap.IsInsideQuestBlob(questID)` is checked in `ShouldBeActive()` and returns `false` while the player is inside the blob, hiding the waypoint until they leave the area. Prevents the nav frame from pointing straight down at an underground or blob-anchored objective and locking the displayed distance at zero.

## ####################################

## CHANGELOG 2.9.19 — Objective Tracker Stability & Bucket Refinements

#### Objective Tracker — Anti-Flicker Feedback Loop
- **Fix** — Eliminated the visible "trembling" of the tracker caused by a feedback loop between TomoMod's bucket layout and Blizzard's native tracker. Each call to `block:Layout()`, `block:SetParent()` and `block:SetPoint()` re-fired Blizzard's `Update / MarkDirty` hooks, which retriggered our `OnTrackerUpdate`, which ran `LayoutBuckets()` again — endlessly oscillating
- **New** — Re-entry guard `_tmInLayout` blocks recursion into `LayoutBuckets()` while a layout pass is already running
- **New** — `PumpUpdateSoon()` coalesces all `Update / SetShown / Show / MarkDirty` hook callbacks and quest events into a single deferred `OnTrackerUpdate` per 0.10 s window
- **New** — Post-layout silence window (`_tmSilenceHook`, 0.20 s) ignores Blizzard's own deferred `OnUpdate` reactions caused by our re-parenting mutations, so they no longer queue a new pump

#### Objective Tracker — Collapsed Bucket Persistence
- **Fix** — Quest blocks under a collapsed bucket would reappear because Blizzard's next layout pass re-`Show()`ed them. Each block now receives a one-time `hooksecurefunc(block, "Show", …)` that re-hides it automatically when its bucket key is marked collapsed in `TomoModDB.objectiveTracker.bucketsCollapsed`

#### Objective Tracker — Module Header Detection
- **New** — Accent- and case-insensitive matching in `GetHeaderColor()`. Lua's `string.upper` only folds ASCII bytes (the `é` in "Métier" stays lowercase), so "Métier"/"métier"/"MÉTIER" all map to the same keyword now via dual upper/lower/raw comparison
- **New** — Added singular and accent-stripped variants `MÉTIER`, `METIERS`, `METIER`, `PROFESSION` to `HEADER_COLORS` so French module headers in the singular form are also caught
- **Fix** — `IsModuleHeader()` now returns `false` immediately for any frame that has `HeaderText` (quest block) or `Dash` (objective line). Previously, a quest title or objective description containing a header keyword could be mistaken for a module header and hidden by `HideModuleHeaders`, removing the entire quest description from the tracker
- **Fix** — Module header scan now runs on **both** the Blizzard tracker and our custom `skinFrame` so re-parented Profession recipe blocks (which embed their own "Métiers" header in the block hierarchy) no longer leak the localized header text on top of the recipe title

#### Objective Tracker — Block Height Measurement
- **Fix** — Profession recipe blocks underestimated their height because `block:GetHeight()` only reflected the header line, not the reagent lines. The deepest-descendant bottom measurement now runs **unconditionally** (instead of only when `bh < 10`) and walks **8 levels deep** (instead of 4) to reach reagent FontStrings nested inside `TrackedRecipe → Lines → Line[i]`
- **Fix** — Resolves the visible overlap between "Rouleau de soie du feu solaire" (with 3 reagent lines) and the quest "Clé imprégné du sol" that followed

#### Objective Tracker — Reward Preview & Special Module Exclusion
- **New** — `collectAll()` now skips entire subtrees whose frame name contains `BonusObjective`, `Scenario`, `WorldQuest` or `UIWidget` — these modules render rich reward previews (Delves like "La Sombrevoie", M+ scenarios, world quest reward popups) whose internal anchors break when re-parented
- **New** — `HasRewardPreview()` detection skips any block that embeds a reward / item preview / dungeon score popup (Delves attached to weekly quests, M+ weekly vault objectives like "Halte de l'Ombre-Garde" showing ilvl + heart count). Detection runs on frame names (`Reward`, `ItemPreview`, `DungeonScore`, `Loot`) **and** on template-set table members (`RewardsFrame`, `ItemPreviewFrame`, `itemPreviewPool`). These blocks stay in Blizzard's native location and no longer overlap our bucketed quests

## ####################################

## CHANGELOG 2.9.18 — Objective Tracker Quest Buckets

#### Objective Tracker — Collapsible Quest Categories
- **New** — Quests, world quests, campaign quests, weeklies, dailies and achievements are now grouped into **collapsible category buckets** (Campaign, Important, Legendary, Weekly, Daily, World, Dungeon, Raid, Profession, Achievement, Complete, Default, Other); each bucket header shows a colored label, an arrow indicator and a live quest count badge
- **New** — Click any bucket header to collapse/expand that category; per-category state is persisted in `TomoModDB.objectiveTracker.bucketsCollapsed`
- **New** — Bucket classification uses `C_QuestInfoSystem.GetQuestClassification` (with smart folding: Calling → Daily, Prey/Delves/Scenario/Adventure → Other) so quests land in the right bucket automatically
- **New** — Master toggle **"Group quests into collapsible categories"** added in *Config → Skins → Objective Tracker*; disabling it instantly restores Blizzard's native module layout (no `/reload` required) — blocks are re-parented back to their original frames
- **Fix** — Tracker panel widened by 10 px (anchor pad `-12/+12` → `-17/+17`) so quest item icons no longer clip against the right edge
- **Fix** — Re-parented Blizzard quest blocks now anchor with both `TOPLEFT` and `TOPRIGHT` to prevent width collapse inside the custom bucket frames
- **Fix** — Stale block heights after collapse/expand resolved via `pcall(block.Layout, block)` + recursive `GetBottom` fallback measurement and a multi-pass `LayoutBuckets()` re-run on next frame

#### Localization
- **New** — 14 new locale keys added across all 6 languages (enUS, frFR, deDE, esES, itIT, ptBR) for the bucket toggle and the 13 bucket category labels

## ####################################

## CHANGELOG 2.9.17 — Installer Overhaul · Action Bar Master Toggle · Bug Fixes

#### Action Bars — Master System Toggle
- **New** — Added a master "Enable TomoMod Action Bar system" checkbox in both the Installer (Step 9) and Config Panel (Action Bars → tab 1); disabling it fully bypasses container creation, Blizzard bar hiding, and button reparenting — after a `/reload`, Blizzard's default action bars are fully restored
- **Fix** — Previously, users could only toggle the visual skin (`actionBarSkin.enabled`), which removed the cosmetic overlay but left TomoMod's bar management active (hidden Blizzard frames, custom containers, paging driver); disabling the skin no longer leaves an invisible system running underneath

#### Installer — Full Module Coverage (17 Steps)
- **New** — Step 5 "Raid Frames" added: enable/disable, hide Blizzard raid frames, dispel highlight, HoT tracking, debuff icons, defensive CDs, grid/list layout dropdown
- **New** — Step 9 "Action Bars" now has a "System" section with the master toggle above the existing skin options
- **New** — Step 11 "Skins" expanded: Objective Tracker skin, Mail skin, Reputation bar toggles added
- **New** — Step 14 "QOL" expanded: Auto Summon, Auto Fill Delete, Auto Quest, Class Reminder, Leveling Bar, Waypoint, World Quest Tab, Frame Anchors, Profession Helper toggles added
- **Fix** — Step count updated from 16 to 17 with correct step progression dots

#### Installer — Bug Fixes
- **Fix** — Chat Skin toggle wrote to orphan key `chatSkin` instead of the actual `chatFrameSkin` key read by `ChatFrameSkin.lua`; toggling the chat skin in the installer had zero effect on the module — now correctly targets `chatFrameSkin`
- **Fix** — HideTalkingHead module applied unconditionally on every login regardless of the installer checkbox; module now checks `TomoModDB.hideTalkingHead.enabled` before suppressing the TalkingHead frame
- **Fix** — Action Bar skin style dropdown was missing the 5th style "Minimal" (borderless with inner shadows) despite being implemented in `ActionBarSkin.lua` — all 5 styles now selectable
- **Fix** — Duplicate `actionBarSkin.enabled` checkbox in the Skins step removed (already present in the Action Bars step)
- **Fix** — CoTankTracker section removed from Tank Mode step (module not yet loaded in `QOL.xml`)

#### Database — Missing Defaults
- **New** — `hideTalkingHead = { enabled = false }` added to `TomoMod_Defaults`
- **New** — `fastLoot = { enabled = true }` added to `TomoMod_Defaults`

#### Localization
- **New** — 25 new locale keys added across all 6 languages (enUS, frFR, deDE, esES, itIT, ptBR) covering Raid Frames step, expanded Skins, expanded QOL modules, and Action Bar system toggle

## ####################################

## CHANGELOG 2.9.16 — Layout Button Fix · AuctionRecipeTracker Totals · Auto Vendor/Repair GUI

#### Core — Module Initialization Safety
- **Fix** — Layout button silent failure on fresh installs: clicking *Layout* did nothing because `M.SetUnlocked` early-returns while `initialized == false`, and an earlier module's `Initialize()` could fail silently due to WoW's default `scriptErrors=0` setting, breaking the rest of the init chain. `M.Toggle` in `Modules/QOL/Movers/Movers.lua` now lazy-initializes via `pcall(M.Initialize)` and reports the error to chat instead of doing nothing
- **Fix** — `Core/Init.lua` now wraps every module `Initialize()` call (~45 modules) in a `safeInit(name, mod)` helper using `xpcall` with `debugstack`; a failing module no longer prevents subsequent modules from initializing, and a TomoMod-coloured chat line surfaces the offending module name + stack while still routing through `geterrorhandler()`

#### QOL — AuctionRecipeTracker
- **New** — Each tracked recipe header now displays the **total cost of its reagents** on the right-hand side; computed by summing `(unit price × required quantity)` for every reagent that has a recorded price, then formatted via `FormatGold`
- **New** — When at least one reagent in a recipe is missing a recorded price, a discreet grey `(~)` suffix is appended to the total to indicate the figure is a partial estimate (`123g 45s |cff808080(~)|r`); the recipe label automatically anchors to the left of the total so long names truncate cleanly

#### QOL — Auto Vendor / Repair (Config GUI)
- **New** — The hardcoded `SELL_GRAYS` / `AUTO_REPAIR` / `PRINT_SUMMARY` flags in `Modules/QOL/Auto/AutoVendorRepair.lua` are now backed by saved variables under `TomoModDB.autoVendorRepair` (defaults: all on); a `GetSettings()` helper reads the live DB on every `MERCHANT_SHOW`, so toggles take effect immediately without `/reload`
- **New** — Two checkboxes added to *Config → QOL → Automations*, in a new "Auto Vendor / Repair" section: **Auto repair on merchant** and **Auto sell gray (poor) items**
- **New** — Localization — added `sublabel_auto_vendor_repair`, `opt_avr_auto_repair`, `opt_avr_sell_grays` in all six locales

## ####################################

## CHANGELOG 2.9.14 and 2.9.15 — AuctionRecipeTracker (QOL) · Tooltip Prices · UI Polish

#### QOL — AuctionRecipeTracker (New Module)
- **New** — Recipe Tracker GUI that appears automatically when speaking to an auctioneer if at least one crafting recipe is being tracked in the profession window; lives in `Modules/QOL/AuctionRecipeTracker/AuctionRecipeTracker.lua` and is wired through `Modules/QOL/QOL.xml`
- **New** — Reagent rows show, in order, the **required quantity in TomoMod accent (`14x`)**, the reagent icon, the item name, and the per-stack price (when a scan has been recorded); the quantity column is right-aligned on a fixed 30 px width so icons line up regardless of digit count
- **New** — Click on any reagent row to switch the AH to Buy mode and run `C_AuctionHouse.SendBrowseQuery` for that exact item name (sorted by lowest price); hovering shows the standard Blizzard item tooltip
- **New** — Manual full Auction House scan via the "Scan AH" button at the bottom of the window — uses `C_AuctionHouse.ReplicateItems()` and respects Blizzard's 15-minute throttle (persisted in `TomoModDB.auctionRecipeTracker.lastScan`); stores the lowest unit price per `itemID`
- **New** — TomoHDV tooltip injection — after a scan, every tooltip on items in bags, bank, equipment, item links in chat, etc. shows a `|cff0cd29fTomoHDV|r` line with the recorded unit price; if the hovered button has a stack count > 1, a second "Pile (N)" line shows the full stack price; a third grey line tells you how long ago the scan was made (`à l'instant`, `il y a Xm/h/j`)
- **New** — Modern TomoMod-styled scrollbar — replaces `UIPanelScrollFrameTemplate` with a 4 px slim track (translucent dark grey) and an accent-coloured thumb (`#0CD29F`) sized proportionally to the content; supports drag, click-on-track to jump, and mouse wheel; auto-hides when the content fits the visible area
- **New** — Default anchor — the frame attaches to `TOPLEFT, AuctionHouseFrame, TOPRIGHT, 8, 0` so it sits glued to the right edge of the AH window; user-dragged positions are persisted in `TomoModDB.auctionRecipeTracker.framePos` and take priority over the default
- **Fix** — Scan button reliability — `f:OnShow` now force-resets `scanInProgress = false`, re-enables the button and restores its label every time the frame is shown; previously, an AH closed during a scan could leave the button permanently disabled across sessions
- **Fix** — Silent early-returns in `StartScan` (scan already running, AH closed, API unavailable) now display a red status message instead of doing nothing, so the user always knows why a click had no visible effect
- **New** — Slash command `/tmrecipe` to manually show/hide the window when the AH is open
- **New** — Localization — added 18 `art_*` keys in all six locales (enUS, frFR, deDE, esES, itIT, ptBR) covering UI strings, scan states, tooltip relative-time labels (`art_tt_*`), and error messages

## ####################################

## CHANGELOG 2.9.13 — M+ Boss Names Fix

#### MythicTracker — Boss Names
- **Fix** — Boss names in the M+ tracker now show correctly instead of "Boss 1", "Boss 2" etc.; in WoW 12.x (Midnight) `C_ScenarioInfo.GetCriteriaInfo` returns the boss name in the `description` field (renamed from `criteriaString`); TomoMod now reads `description` first and falls back to `criteriaString` for backward compatibility
- **Fix** — Blizzard's leading checkmark prefix (added to completed objectives in 12.x) is stripped from boss names before display
- **Fix** — `EncounterJournal_OpenJournal` call inside `FetchEJBossNames` is now wrapped in `pcall` to prevent potential taint in 12.x; the EJ lookup continues to function as a localisation enhancement when available

## ####################################

## CHANGELOG 2.9.12 — PartyFrame CD Tracking Fix · Healer Interrupt · Performance

#### PartyFrame — Interrupt & Battle-Rez CD Tracking Rewrite
- **Fix** — Replaced `COMBAT_LOG_EVENT_UNFILTERED` with `UNIT_SPELLCAST_SUCCEEDED`; registering CLEU from addon code causes taint in WoW 12.x, blocking protected-frame API calls
- **Fix** — Party spellIDs are tainted in 12.x and cannot be used as table indices; added taint-safe `ResolveSpellID()` using `string.format("%.0f", id)` → `tonumber` to launder the value — mirrors `BIT.Taint:ResolveNumber()` from BliZzi_Interrupts
- **Fix** — When spellID is fully unresolvable (tainted and strip failed), fall back to the class-default interrupt for that unit if it is not already tracked as on cooldown ("WilduTools" approach: trust the known spell rather than requiring a readable runtime ID)
- **Fix** — Interrupt tracker icon now hidden for healers; since patch 12.x healers no longer have an interrupt ability — `UnitGroupRolesAssigned(unit) ~= "HEALER"` guard added to `CD.UpdateFrame`

#### CooldownManager — UpdateButtonState API Cache
- **Perf** — `UpdateButtonState` now caches `GetCooldownTimes()`, `Scanner.GetCachedCooldownID()` and `pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo)` once per button per tick; previously each was called twice (once for the pandemic/CD-text block, once for desaturation/range-check) — approximately **50% fewer API calls** in the main 0.25 s update loop

#### AuraTracker — Ticker Rate
- **Perf** — Timer refresh rate reduced from 10 fps (0.1 s ticker) to 5 fps (0.2 s); visual difference is imperceptible on duration labels, overhead halved

#### ResourceBars — OnUpdate Throttle
- **Perf** — DK rune / Monk stagger `OnUpdate` processing threshold raised from 50 ms to 100 ms; execution frequency halved with no perceptible impact on the display

## ####################################

## CHANGELOG 2.9.11 — Summon Indicator on Raid & Party Frames · CooldownManager · CDMProcGlow · BuffSkin Bug Fixes

#### Raid Frames & Party Frames — Summon / Teleport Indicator
- **New visual** — Each unit frame on both the custom Raid Frames and Party Frames now shows an 18×18 icon at the bottom-center of the frame reflecting the unit's incoming summon status
- **Three states** — `RaidFrame-Icon-SummonPending` (yellow hourglass, awaiting response) · `RaidFrame-Icon-SummonAccepted` (green check, accepted) · `RaidFrame-Icon-SummonDeclined` (red X, declined); icon is hidden when there is no active summon
- **Implementation** — `RF.UpdateSummon` / `PF.UpdateSummon` query `C_IncomingSummon.IncomingSummonStatus(unit)`; both modules now register and handle the `INCOMING_SUMMON_CHANGED` event so the indicator updates immediately for every group member

#### CooldownManager — Unified SetCooldown Hook
- **Fix** — The two separate `hooksecurefunc(button.Cooldown, "SetCooldown", ...)` calls (one for swipe colors, one for GCD hiding) have been merged into a single combined hook per button; this halves the number of hook callbacks fired on every GCD tick across all visible icons
- **Fix** — GCD hiding no longer calls `pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)`; it now uses `Scanner.GetCachedSpellID` + `C_Spell.GetSpellCooldown` directly, eliminating the taint-unsafe pcall path entirely

#### CDMProcGlow — Race Condition + Ticker Architecture
- **Fix** — Glow is now applied **synchronously** in the `ShowAlert` hook (`StartGlow` called immediately) instead of being deferred with `C_Timer.After(0, ...)`; the `C_Timer.After` is kept only for the redundant `HideBlizzardGlow` call — this prevents a race condition where a very short proc fires `HideAlert` in the same frame before the deferred `StartGlow` executes
- **Fix** — Per-frame persistence timers (`persistTimers[frame] = C_Timer.NewTicker(...)`) replaced by a **single global ticker** (`persistTicker`) that scans all active glows at a fixed rate; eliminates O(n) ticker objects and associated GC pressure
- **Fix** — `RefreshAll` now snapshots only frames with `_cdm_procActive = true` (live proc) instead of all frames in `activeGlows`; the `wipe(activeGlows)` after `StopGlow` has been removed as it was redundant and could race with procs firing during the loop
- **Fix** — `StopGlow` simplified: per-frame timer cancellation removed (global ticker handles persistence)

#### BuffSkin — Frame Recycling + Toggle Fix
- **Fix** — `SkinButton` no longer bails on `if not skinnedButtons[button]`; all icon anchor, mask, and overlay operations are now applied unconditionally (idempotent); this ensures correct rendering when Blizzard recycles a frame object (same pointer, new aura) and resets its layout
- **Fix** — `buffHookDone` / `debuffHookDone` flags replaced by a single `hooksInstalled` guard; hooks are now installed exactly once and survive `SetEnabled(false)` → `SetEnabled(true)` cycles — previously, disabling then re-enabling the module left the hooks uninstalled and updates stopped firing
- **Fix** — `TemporaryEnchantFrame.Update` is now hooked in `InstallHooks`; weapon buff icons are skinned correctly when enchants appear or change mid-session
- **Fix** — `InstallHooks` is called immediately in `BS.Initialize` instead of being deferred inside a `C_Timer.After(1, ...)`; the debounce in `ScheduleUpdate` (0.1 s) is sufficient to avoid spam without delaying hook installation
- **Fix** — Hiding hooks for `BuffFrame` and `DebuffFrame` (previously duplicated inside `ApplyFrameHiding`) consolidated into the single `InstallHooks` path alongside the skin hooks, each frame using one combined hook

## ####################################

## CHANGELOG 2.9.10 — RaidFrames Taint Fix · MythicTracker: EJ Boss Name Lookup

#### RaidFrames — Config Panel Taint Fix
- **Root cause** — Slider and checkbox callbacks in the Raid Frames config panel were calling `ApplySettings()` directly from WoW's widget event context, which is tainted; this caused `ADDON_ACTION_BLOCKED` errors for `ClearAllPoints`, `SetPoint`, and `SetSize` on every raid frame and the raid anchor whenever a setting was changed
- **Fix** — Wrapped the `ApplyRF()` helper in `Config/Panels/RaidFrames.lua` with `C_Timer.After(0, ...)`, deferring the `ApplySettings` call to the next game frame tick where the execution context is clean and protected frame operations are allowed

#### MythicTracker — Localised Boss Names via Encounter Journal
- **New system** — Boss names in the Mythic+ tracker are now resolved through the Encounter Journal (`EJ_GetEncounterInfoByIndex`) instead of using the raw `criteriaString` from the scenario API, giving fully localised, accent-safe names
- **3-level fallback** — Resolution priority:
  1. Exact match by `dungeonEncounterID` (via `criteriaType == 165` + `assetID`) — most reliable
  2. Ordered position in the EJ boss list for the active dungeon
  3. Filtered `criteriaString` (strips noise words like "Defeated") as last resort
- **Coverage** — `_mapIDToEJID` hardcoded table covers all M+ dungeons from Cataclysm to The War Within (499–506)
- **Retry logic** — `RefreshEJNames()` retries up to 5 times with a 2-second delay if the `Blizzard_EncounterJournal` addon isn't loaded yet at challenge start
- **Triggered on** — `CHALLENGE_MODE_START` (clears cached names first) and `PLAYER_ENTERING_WORLD` when already inside an active key

## ####################################

## CHANGELOG 2.9.9 — CooldownManager Layout · MerchantTools Fix · CharacterSkin Performance

#### CooldownManager — Buff Icon Horizontal Layout
- **Root cause fixed** — `viewer.iconLimit = 1` was flowing into `ResolveDirections` as `rowLimit = 1`, forcing every buff icon viewer to produce exactly one icon per row regardless of the configured direction — resulting in a vertical column even when "Centered (horizontal)" was selected
- **Fix** — For `isBuff` viewers, `CDMLayout.LayoutViewer` now injects the `buffIconDirection` DB value via a lightweight `setmetatable` wrapper over the viewer's settings table; this overrides any direction derived from `iconLimit`, restoring true horizontal flow
- **Config panel** — New "Avancé" card (`card5`) in the CD & Resource panel adds:
  - *Buff icon direction* dropdown (`CENTERED` / `LEFT` / `RIGHT` / `UP` / `DOWN`)
  - *BuffBar direction* dropdown (`VERTICAL` / `HORIZONTAL`)
  - *Bar width (horizontal)* slider (60–400 px, default 120)
- **Database** — New default keys in `cooldownManager`: `buffIconDirection = "CENTERED"`, `buffBarDirection = "HORIZONTAL"`, `buffBarWidth = 120`, `buffBarSpacing = 2`
- **Localization** — New keys added to **enUS** and **frFR** (all 6 locales now updated in this release):
  `opt_cdm_bufficon_direction`, `opt_cdm_buffbar_direction`, `opt_cdm_buffbar_width`, `buffbar_vertical`, `buffbar_horizontal`, `dir_centered`, `dir_left`, `dir_right`, `dir_up`, `dir_down`

#### MerchantTools — TOC 120005 Compatibility Fix
- **Bug** — `frame:GetChild("AltCurrencyFrame")` was called at line 305 of `MerchantTools.lua`; this method does not exist in the Mists of Pandaria client (TOC 120005), causing a nil-method error when the merchant frame opened
- **Fix** — Removed the `frame:GetChild()` call; the code now relies solely on the `_G["MerchantItem" .. i .. "AltCurrencyFrame"]` global lookup, which works across all supported client versions

#### CharacterSkin — ITEM_DATA_LOAD_RESULT Lag Spike Fix
- **Root cause** — `ITEM_DATA_LOAD_RESULT` fires for every item loaded into the client cache (dozens of times during crafting or vendor interactions); each fire scheduled a new independent `C_Timer.After(0.1, UpdateAllItemInfoOverlays)` call — when the Character Frame was open, this stacked 20+ simultaneous tooltip scans (one `scanTip:SetInventoryItem` per equipped slot per timer), causing noticeable frame-rate spikes
- **Fix** — Introduced a `itemInfoPending` debounce flag in `SkinCharacterFrame`; only one timer is active at a time — subsequent events while the timer is pending are silently ignored; the delay is also extended from 0.1 s to 0.3 s to allow WoW's own item cache to settle before scanning

#### New Module — Merchant Tools (`Modules/QOL/Auto/MerchantTools.lua`)
Two QOL features merged into a single lightweight module, inspired by ElvUI_WindTools (AlreadyKnown & ExtendMerchantPages), fully rewritten for TomoMod (no ElvUI / AceHook dependency).

#### Already Known
- Automatically desaturates or colour-tints items in the **merchant** and **buyback** windows that the player already owns
- Detects: **mounts**, **battle pets**, **toys**, **transmog appearances / sets**, **recipes**, and any learnable spell (via tooltip parsing fallback using `COLLECTED` / `ITEM_SPELL_KNOWN` globals)
- Two display modes configurable via the config panel:
  - **Monochrome** — icon rendered in grayscale (`SetDesaturated`)
  - **Color tint** — custom RGBA tint applied; out-of-stock items are tinted at 50 % brightness
- Known-link cache is reset automatically every time the merchant window closes (`CloseMerchant` hook)
- Detects and yields to the standalone **AlreadyKnown** addon if loaded

#### Extended Vendor Pages
- Expands the merchant frame to show **N columns** of 10 items each (configurable 1–4, default 2) instead of the single Blizzard column
- Dynamically creates extra `MerchantItemTemplate` frames and repositions all items, the buyback slot, and the Prev/Next page buttons to match the wider frame
- Conflict check against popular vendor-extend addons (`ExtVendor`, `Krowi_ExtendedVendorUI`, `CompactVendor`)
- Disabled by default; requires a UI reload after enabling or changing column count (noted in config)

#### Config Panel — New "Vendor Tools" Tab
- Added a new tab `tab_qol_merchant_tools` to the QOL config panel
- **Already Known** section: enable toggle, display mode dropdown (Mono / Color), colour picker for tint
- **Extended Vendor Pages** section: enable toggle, column-count slider (1–4), reload reminder

#### Database
- New default block `merchantTools` in `TomoMod_Defaults`:
  - `alreadyKnown.enabled = true`, `mode = "MONOCHROME"`, `color = {r=0.047, g=0.824, b=0.624}`
  - `extendPages.enabled = false`, `numberOfPages = 2`

#### Localization — 2.9.9 Keys
- New keys added to **all 6 locale files** (enUS, frFR, deDE, esES, itIT, ptBR):
  `tab_qol_merchant_tools`, `section_already_known`, `info_already_known`, `opt_ak_enable`, `opt_ak_mode`, `ak_mode_mono`, `ak_mode_color`, `opt_ak_color`, `section_extend_pages`, `info_extend_pages`, `opt_ep_enable`, `opt_ep_columns`

#### LustSound — False Alert on Sated Flicker & Zone Transitions (Fix)
- **Root cause** — `OnPollTick` reset `active = false` immediately whenever `HasSatedDebuff()` returned false. During a server aura resync or loading-screen transition the Sated debuff can disappear for one or two poll cycles (0.5 s each), then reappear. The immediate reset caused the sound to fire again on the very next poll that saw Sated come back, producing a spurious alert even though the player never lost the debuff
- **Fix 1 — Flicker grace period** — Introduced `FLICKER_GRACE = 1.5 s` and `ScheduleRearm()`. When Sated disappears while `active = true`, a one-shot timer is started; if Sated is still absent after 1.5 s it is treated as genuinely gone, otherwise the timer is silently cancelled. Mirrors the same strategy used by BLDetect
- **Fix 2 — `PLAYER_ENTERING_WORLD` handler** — Bumps a `satedGen` generation counter (invalidating any pending flicker timer), sets a 3 s sound-suppress window, then after a 2 s settle delay snapshots the real aura state: if Sated is present `active` is set silently; if absent the state is reset cleanly. Prevents a false re-trigger every time a player enters an instance while the debuff is still active
- **New variables** — `satedGen` (generation counter), `flickerTimer` (handle to the pending rearm timer), `FLICKER_GRACE` constant

## ####################################

## CHANGELOG 2.9.8 — Housing Module

#### Housing — Config Panel Checkboxes Not Working (Fix)
- **Root cause** — At `PLAYER_LOGIN`, all handlers (`DecorHover`, `Clock`) were created with `enabled = nil`; `InitSubModules()` saw `anyEnabled = false` and registered no events — the module never started regardless of the checkboxes state
- **Secondary cause** — `H.Refresh()` had an early `if not IsHousingAvailable() then return end` guard at the top, preventing it from syncing handler states when called outside a housing zone
- **Fix 1** — `H.Refresh()` is now called **before** `Controller:InitSubModules()` in the boot timer so handlers have their DB-backed enabled state before initialization
- **Fix 2** — The `IsHousingAvailable()` guard removed from the top of `H.Refresh()`; handler flag sync involves no housing API calls; a `Controller:RequestUpdate()` is still triggered at the end only when housing APIs are available

#### Housing — Editor Clock Improvements
- **Position** — Clock relocated from `CENTER` on top of the `HouseEditorButton` to `TOP` anchored at `BOTTOM` of the button (4 px gap); the button is now fully clickable when the clock is visible
- **Default mode** — Clock defaults to **digital** (`clock_analog = false`); previous default was analog
- **24-hour format** — Digital mode now always displays `HH:MM` (00–23); AM/PM conversion and the `timeMgrUseMilitaryTime` CVar check have been removed

#### Unit Frames — InfoBar Current HP
- **Bug** — The bottom-right corner on the player frame and the bottom-left corner on the target frame displayed `UnitHealthMax` (total HP, e.g. `566 K`) instead of the live current HP
- **Fix** — `UpdateInfoBar` in `Elements/Power.lua` now reads `UnitHealth(unit)` instead of `UnitHealthMax(unit)`; the value updates every time `UNIT_HEALTH` fires via `Health.Override`

#### Housing — New Module
- **Housing module** — Full editor-enhancement suite for the Midnight / The War Within housing system (HousingCore, DecorHover, EditorClock, TeleportMacros sub-modules)
- **Decor Hover** — In Basic Decor mode, hovering a placed decoration shows its name, placement budget cost and remaining stock in a lightweight overlay; hold a modifier key (Ctrl or Alt) to instantly start placing a duplicate
- **Editor Clock** — Analog or digital clock shown below the "House Editor" button while the housing editor is open; tracks time spent in the editor per session and lifetime total (persisted in TomoModDB)
- **Teleport `/tm home`** — New slash command: teleports to your current-faction house (Alliance → Founder's Point, Horde → Razorwind Shores) or auto-leaves if you are visiting another player's house; uses SecureActionButtonTemplate so it works in combat
- **Config panel** — New "Housing" category in the config sidebar with a dedicated 5-section panel: General, Decor Hover, Editor Clock, Teleportation, Commands

#### Housing — Taint Fix (`ADDON_ACTION_FORBIDDEN`)
- **Root cause** — `TeleportHome()` is a Blizzard-protected C function; calling `Button:Click()` on a `SecureActionButtonTemplate` from a non-secure context (slash command handler, config panel `OnClick`) raised `ADDON_ACTION_FORBIDDEN` and propagated taint through `SecureTemplates.lua`
- **`H.ShowTeleportPrompt()` introduced** — replaces direct `SmartTeleportHome()` calls in all non-secure contexts; surfaces the appropriate secure button (Leave or CurrentFaction) centred on screen at 220×36 px with a label; the player's physical click completes the protected action through a clean hardware-event → secure-template chain
- **5-second auto-hide** — `C_Timer.NewTimer(5, …)` automatically hides the prompt if the player does not click; cancelled immediately on `PostClick`
- **`SmartTeleportHome()` retained** — function still exists for macro `/click` chains and future programmatic secure contexts; its internal `Button:Click()` calls are now only reachable from legitimate secure paths
- **`SetAction_ReturnHome` fixed** — was erroneously setting `PostClick` to `nil` on the Leave button, leaving it without cleanup; now assigns the shared `PostClick` handler like all other buttons
- **`PostClick` hardened** — checks `self:GetAttribute("type")` before calling `CheckTeleportInCooldown` so it is safe on both `teleporthome` and `returnhome` buttons
- **Call sites updated** — `Core/Init.lua` (`/tm home` slash command) and `Config/Panels/Housing.lua` (test button) both redirected from `SmartTeleportHome` → `ShowTeleportPrompt`

#### Housing — Config Panel Invisible Fix
- **Root cause** — `Config/Panels/Housing.lua` was missing from `TomoMod.toc`; `TomoMod_ConfigPanel_Housing` was never defined in `_G`, so `ConfigUI.lua` silently skipped panel construction and the Housing tab showed nothing
- **Fix** — Added `Config\Panels\Housing.lua` to the TOC between `Skins.lua` and `Profiles.lua`

#### Icons — New Config Sidebar Icons
- **`icon_housing.tga`** — 32×32 white house-silhouette TGA (triangular roof, two windows, centred door); pixel-drawn to match the monochrome style of all other sidebar icons; `SetVertexColor` in `CreateNavButton` applies the accent colour at runtime
- **`icon_diagnostics.tga`** — 32×32 white monitor/EKG TGA icon for the Diagnostics category in the config sidebar
- **Bug fixed** — both files were previously valid TGA containers (correct 18-byte header, 4140 bytes total) but contained entirely zero pixel data, rendering as fully transparent; rebuilt with actual pixel art

#### Localization — 2.9.8 Keys
- **Housing + Diagnostics panel keys** — full locale support added in frFR, deDE, esES, itIT, ptBR (previously English-only fallback)
- **6 new `wn_298_*` keys** added across all 6 locale files (enUS, frFR, deDE, esES, itIT, ptBR)

## ####################################

## CHANGELOG 2.9.7 — Raid Frame Live Preview & Bug Fixes

#### Config Panel — Live Raid Frame Preview
- **Embedded live preview** — The Raid Frames config panel now shows a live preview of 20 simulated members directly above the tabs (same architecture as the UnitFrames preview strip)
- **Real-time updates** — Any parameter change (frame size, spacing, health color, name, power bar, etc.) is reflected instantly in the preview without leaving the panel
- **Simulated data** — 20 members with varied names, class colors, different HP values, roles (2 tanks in G1/G2, 4 healers, 14 DPS), absorb indicators, heal prediction, HoTs and dispellable debuffs
- **Adaptive scaling** — The preview auto-scales to the panel width; grid mode (4 groups × 5) with G1–G4 group labels, list mode (2 columns × 10)
- **Visual consistency** — "LIVE PREVIEW" header with pulsing dot, separator, strip height auto-adjusts based on frame height
- **Initial render fix** — `GetWidth()` returned 0 before the first layout pass; preview now self-retries via `C_Timer.After(0.05)` until width is available, and fires an initial `Refresh` on creation

#### Raid Frames — Taint & Stability Fixes
- **Blizzard frame hiding rewritten** — `CompactRaidFrameContainer` and `CompactRaidFrameManager` are now hidden via `SetAlpha(0) + SetScale(0.001)` instead of `Hide()` / `SetParent()` — eliminates the `CompactPartyFrame:SetShown()`, `PartyFrame:SetSize()` and `CompactArenaFrame:HideBase()` taint chain (errors 1–4 in diagnostics)
- **Range fade fixed for Midnight+** — `UnitInRange` returns secret booleans in Midnight+; `UpdateRange()` now calls `SetAlphaFromBoolean(inRange, 1, oorAlpha)` instead of direct comparison — restores correct fade-out for out-of-range raid members
- **Default role icon size doubled** — `roleIconSize` default raised from `10` to `20`

#### Action Bars — Combat Lockdown Fix
- **Initialization deferred past combat** — `AB.Initialize()` now defers to `PLAYER_REGEN_ENABLED` when the addon loads during combat lockdown (e.g. reconnecting mid-fight), eliminating `SecureStateDriverManager:SetAttribute()` taint (x30, errors 5–6 in diagnostics)

#### Mythic+ — Objective Tracker Suppression
- **Root frame now suppressed** — Added `"ObjectiveTrackerFrame"` to `BLIZZARD_FRAMES` in `MythicTracker.lua`; only sub-modules were previously suppressed, leaving the root visible during challenge mode

#### What's New — Scrollbar Fix
- **BackdropTemplate mixin** — Scrollbar created from `UIPanelScrollFrameTemplate` lacks `BackdropTemplate`; fixed with `Mixin(sb, BackdropTemplateMixin)` before `SetBackdrop` calls to prevent a nil-method crash

#### Castbars — Player Bar Vanishing Mid-Combat Fix
- **`FadeOut` made idempotent** — If `_fadeAG` is already playing when `FadeOut` is called a second time (e.g. `UNIT_SPELLCAST_STOP` fires right after `UNIT_SPELLCAST_SUCCEEDED`), the running animation is now left to finish instead of being cut short by a `self:Hide()` call
- **`OnUpdate` fade guard** — After `FadeOut` resets the cast flags, `OnUpdate` was calling `self:Hide()` on the very next tick, killing the fade animation before it could play; now checks `_fadeAG:IsPlaying()` before hiding
- **`CheckCast` nil-info guard** — `UnitCastingInfo`/`UnitChannelInfo` can return `nil` transiently on mid-cast events (`INTERRUPTIBLE`, `NOT_INTERRUPTIBLE`, `DELAYED`); the bar no longer hides immediately in that case — canonical `STOP`/`SUCCEEDED` events handle the end of cast

#### Diagnostics — UI Error Exclusions
- **Mount restriction messages excluded** — "Ground mounts are not allowed here" (and locale equivalents) no longer captured as `UIError`
- **Battle pet cap messages excluded** — "You have reached the maximum number of pets of this type" (and locale equivalents) no longer captured as `UIError`

#### Localization — 2.9.7 Keys
- **10 new `wn_297_*` keys** added across all 6 locale files (enUS, frFR, deDE, esES, itIT, ptBR)

## ####################################

## CHANGELOG 2.9.6 — Raid Frames

#### Raid Frames — New Module
- **Custom raid frames** — Full raid frame system (raid1–raid40) with grid (groups as columns) or list (single column) layout modes
- **Health bars** — Class-colored or gradient health bars with absorb overlay and incoming heal prediction
- **Power bar (healers only)** — Thin power bar displayed only for healer-role raid members
- **Debuff tracking** — Up to 3 debuff icons with debuff-type colored borders (Magic, Curse, Disease, Poison) and duration/stack text
- **HoT tracking** — Up to 3 HoT indicators with class-colored borders; supports Priest, Druid, Paladin, Shaman, Monk, Evoker HoTs
- **Defensive CD icons** — Shows active defensive buffs (Pain Suppression, Ironbark, Divine Shield, etc.) on each raid member
- **Dispel highlight** — Border color changes when a dispellable debuff is present on a raid member
- **Range check** — Fades out-of-range members with configurable opacity; uses UNIT_IN_RANGE_UPDATE + 0.5s ticker fallback
- **Role icons & raid markers** — Configurable role icons (tank/healer/DPS) and raid target markers
- **Ready check** — Ready/waiting/not-ready icons with 6s post-check display
- **Hide Blizzard frames** — Option to hide default CompactRaidFrameContainer and CompactRaidFrameManager
- **Sort by role** — Tank > Healer > DPS ordering within each group
- **Mover system** — Drag-to-position via `/tm layout`, position saved per profile
- **ClickCast support** — Frames registered with ClickCastFrames for click-casting addon compatibility

#### Config Panel — Raid Frames
- **2-tab config panel** — General tab (layout, dimensions, display options, font) and Features tab (power, absorb, heal prediction, range, dispel, HoTs, debuffs, defensives)
- **New category icon** — 32×32 TGA grid icon in the config sidebar

#### Localization — 2.9.6 Keys
- **~80 new `rf_*` keys + 5 `wn_296_*` keys** added across all 6 locale files (enUS, frFR, deDE, esES, itIT, ptBR)

## ####################################

## CHANGELOG 2.9.5 — Taint Fix, Diagnostics Improvements & Config Reorganization

#### CooldownTrackers — Taint Fix
- **Removed COMBAT_LOG_EVENT_UNFILTERED** — This event caused `ADDON_ACTION_FORBIDDEN` taint errors in Midnight; detection now relies solely on `UNIT_SPELLCAST_SUCCEEDED` (BliZzi_Interrupts pattern)
- **File-scope event registration** — `RegisterEvent` calls moved back to file scope (main chunk) instead of inside `CD.Initialize()` to avoid taint propagation from the `PLAYER_LOGIN` handler chain
- **Runtime flag gate** — `cdTrackingEnabled` flag prevents event processing until `CD.Initialize()` is called, keeping the pattern taint-safe

#### Diagnostics Console — Always Capture Taint
- **Taint always captured** — `ADDON_ACTION_FORBIDDEN` / `ADDON_ACTION_BLOCKED` events from TomoMod are now captured even when diagnostics are disabled (`db.enabled = false`)
- **Auto-open on taint** — Console auto-opens for TomoMod taint errors (previously only triggered for Lua errors)
- **CaptureEntry bypass** — `KIND_TAINT` entries skip the `IsEnabled()` check in the capture engine

#### Chat Frame Skin — Text Offset
- **Container offset adjusted** — TUI skin container shifted 8px further left (`-30` instead of `-22`) to create visual clearance between the sidebar icons and chat text
- **SetTextInsets removed** — `SetTextInsets` does not exist on `ScrollingMessageFrame`; the nil method call error from 2.9.4 is fixed

#### Config Panel — Tooltip IDs Moved
- **Tooltip IDs → Skins > Tooltip tab** — All 8 Tooltip ID options (enable, spell, item, NPC, quest, mount, currency, achievement) moved from the QOL panel to the Skins > Tooltip tab, grouped after the guild name color picker
- **QOL panel cleaned** — Tooltip IDs section removed from `Config/Panels/QOL.lua`

#### Skins Panel — ChatFrameUI Block Disabled
- **CFUI options commented out** — The ChatFrameUI config block in `BuildChatFrameTab` was wrapped in `--[[ ... --]]` by the user; fixed the resulting missing `end` syntax error by closing `BuildChatFrameTab` before the comment block

#### Localization — 2.9.5 Keys
- **4 new `wn_295_*` keys** added across all 6 locale files (enUS, frFR, deDE, esES, itIT, ptBR)

## ####################################

## CHANGELOG 2.9.4 — Installer Expansion, What's New Popup, Secret Value Fixes & Locale Update

#### What's New Popup — New Module
- **Automatic post-update notification** — Styled popup displayed once on first login after each addon update, showing version highlights
- **Version tracking** — Compares `TomoModDB.lastSeenVersion` (new SavedVariable field) with current TOC version; popup only shown when they differ
- **Installer-aware** — Skips popup when the installer hasn't been completed yet (first-time users see the installer instead)
- **Styled UI** — Dark themed DIALOG-strata panel (520×480) with dimmer overlay, teal accent palette matching the installer, scrollable content area, logo + version badge
- **Changelog data** — Lua table with per-version highlight entries (2.9.2, 2.9.3, 2.9.4); easily extensible for future versions
- **Fully localized** — ~25 `wn_*` locale keys across all 6 languages (enUS, frFR, deDE, esES, itIT, ptBR)
- **ESC-closable** — Registered in `UISpecialFrames`; OK button or ESC marks version as seen
- **3-second delay** — Triggered via `C_Timer.After(3, ...)` after `PLAYER_LOGIN` to avoid UI congestion on load

#### Installer — Expanded from 12 to 16 Steps
- **Step 3 — Unit Frames (new)** — Enable/disable TomoMod UnitFrames, hide Blizzard defaults; reload warning
- **Step 4 — Party Frames (new)** — Enable/disable TomoMod Party Frames, hide Blizzard defaults; interrupt & battle-rez cooldown trackers; reload warning
- **Step 5 — Castbars (new)** — Enable/disable TomoMod castbars, hide Blizzard default, class-color fill toggle; reload warning
- **Step 9 — Resources & Cooldown Manager (new)** — Resource bars (enable + icon/bar display mode), cooldown manager (enable, hide GCD swirl, desaturate buttons)
- **Steps renumbered** — Previous steps 3–12 shifted to accommodate new steps; TankMode now step 7, ActionBars step 8, Skins step 10, LustSound step 11, Mythic+ step 12, QOL step 13, CVars step 14, SkyRide step 15, Done step 16
- **Skins step enhanced** — Added bag skin and tooltip skin toggles
- **QOL step enhanced** — New "Interface" section with minimap, cursor ring, AFK screen, diagnostics, and aura tracker checkboxes
- **TOTAL_STEPS** constant updated from 12 to 16

#### Bug Fixes — Midnight Secret Value Safety
- **TooltipIDs** — Added `issecretvalue()` guard on spell/item IDs before displaying in tooltips
- **CooldownTrackers** — Added `issecretvalue()` guard in `COMBAT_LOG_EVENT_UNFILTERED` handler for source/dest GUIDs and spellID; prevents taint errors in Midnight

#### Diagnostics Console — French Keyword Exclusions
- **Expanded French keyword list** — Added missing French UI error substrings to the keyword exclusion filter (étourdi, désorienté, en l'air, trop loin, hors de portée, plafond, cible amicale, jet de dés, impossible, pas encore)

#### Localization — All 6 Locales Updated
- **~75 new locale keys** added across all 6 locale files (enUS, frFR, deDE, esES, itIT, ptBR)
- **Installer key groups**: `ins_uf_*` (Unit Frames), `ins_pf_*` (Party Frames), `ins_cb_*` (Castbars), `ins_res_*` / `ins_cdm_*` (Resources & Cooldown Manager), `ins_skin_bag`, `ins_skin_tooltip`, `ins_qol_interface_section`, `ins_qol_minimap`, `ins_qol_cursor`, `ins_qol_afk`, `ins_qol_diag`, `ins_qol_aura_tracker`
- **What's New key group**: `wn_title`, `wn_version`, `wn_subtitle`, `wn_btn_ok`, `wn_footer`, `wn_29x_*` (per-version highlights for 2.9.2, 2.9.3, 2.9.4)
- **Welcome description** updated in all locales to reference 16 steps and expanded feature list
- **Relaunch installer** description updated from 12 to 16 steps in all locales

## ####################################

## CHANGELOG 2.9.3 — PartyFrame Polish, Taint Fixes & Diagnostics Hardening

#### Party Frames — Bug Fixes & New Features
- **GetFrameForUnit nil fix** — `local function GetFrameForUnit` was declared after its first use in `StartRangeChecker`; Lua does not hoist local functions — moved declaration before first call, eliminating 58 errors/minute on `UNIT_IN_RANGE_UPDATE`
- **Raid marker rewrite** — Refactored from plain texture to Frame+texture child structure with `SetFrameLevel(content + 5)` and `SetDrawLayer("OVERLAY", 6)`; uses `SetRaidTargetIconTexture()` (Blizzard helper) instead of manual `SetTexCoord`; `pcall`-wrapped `GetRaidTargetIndex` for Midnight secret value safety
- **Ready check icons (new)** — Frame+texture at `OVERLAY` sublevel 7, centered on each party frame; `UpdateReadyCheck()` queries `GetReadyCheckStatus(unit)` and displays Ready (green check) / Waiting (yellow ?) / Not Ready (red X); icons persist 6 seconds after `READY_CHECK_FINISHED` then auto-hide; events: `READY_CHECK`, `READY_CHECK_CONFIRM`, `READY_CHECK_FINISHED`
- **Tooltip on hover** — Added `OnEnter`/`OnLeave` scripts with `GameTooltip:SetUnit()` on each `SecureUnitButtonTemplate` frame — previously no tooltip was shown when hovering party members

#### ActionBars — Runtime Fixes
- **Bars 1–4 interactivity fix** — Removed `btn:UnregisterAllEvents()` from `HideBlizzardBar` which killed button event handlers; added `btn:Show()` after reparenting to ensure buttons remain visible
- **Show Empty Buttons fix** — Implemented `showgrid=32` attribute approach (ElvUI pattern): Blizzard's `ACTIONBAR_SHOWGRID`/`HIDEGRID` counter cycles 33→32→33, never reaching 0; when disabled, reset to 0 to let `HasAction` visibility take over
- **Spacing slider** — Was already functional, appeared broken due to bars 1–4 not being interactive

#### Chat Frame Skin — Midnight Taint Fixes
- **Secret GUID guard** — `unitGUID` passed to `C_ChatInfo.IsTimerunningPlayer` / `C_RecentAllies.IsRecentAllyByGUID` in `GetPFlag` could be a Midnight secret value — added `issecretvalue(unitGUID)` check
- **Secret BN toast guard** — `arg1` in `BN_INLINE_TOAST_ALERT` handler used as `_G["BN_INLINE_TOAST_" .. arg1]` table index — added `issecretvalue(arg1)` early return
- **SetTextInsets removed** — `SetTextInsets` does not exist on `ScrollingMessageFrame` (ChatFrame1), only on `EditBox` — removed the call that caused a nil method error

#### Diagnostics Console — Exclusion Hardening
- **Pattern-based exclusion** — GlobalStrings containing `%s`/`%d`/`%1$s` format tokens are now converted to Lua patterns via `FormatToPattern()` and matched against incoming UI errors (previously only exact string matches worked)
- **Keyword substring fallback** — 40+ lowercase keyword substrings covering 6 locales (EN, FR, DE, ES, IT, PT) for messages that don't have matching GlobalString keys: stunned, disoriented, in the air, too far, out of range, currency cap, friendly target, dice roll, impossible, can't do yet
- **pcall-protected matching** — `string.find` in the pattern loop is wrapped in `pcall` to prevent a malformed pattern from crashing the entire filter chain
- **New excluded keys** — `ERR_MAIL_DATABASE_ERROR`, `ERR_CURRENCY_LIMIT_REACHED_S`, `ERR_LOOT_CURRENCY_S_QUANTITY_OVERFLOW`

#### AutoFillDelete — Midnight Fix
- **STATICPOPUP_NUMDIALOGS nil** — Global removed in Midnight 12.x; replaced with `(STATICPOPUP_NUMDIALOGS or 4)` fallback

## ####################################

## CHANGELOG 2.9.2 — ActionBar Rewrite & Diagnostics Console

#### ActionBars v4.0.0 — Complete Rewrite
- **Container-based architecture** — Each bar (bar1–bar8, pet, stance) is a `SecureHandlerStateTemplate` container with Blizzard buttons reparented into it
- **Shared BAR_DEFS** — Single source of truth for all action bar files (`AB.BAR_DEFS`), eliminating 4× duplicated bar definitions
- **Grid Layout Engine** — Per-bar configurable columns, spacing, buttonSize, orientation (H/V), growDirection (4 directions), with pixel snapping
- **Bar1 Paging** — Restricted Lua `_childupdate-offset` for taint-free stance/vehicle/override page switching
- **Vehicle/Override SecureHandler** — `tomo-user-shown` attribute + `RegisterStateDriver` for petbattle/vehicle/override visibility gating
- **Position Persistence** — Drag-to-reposition with automatic save to `TomoModDB.actionBars.positions`
- **Mover Integration** — All bars registered with `TomoMod_Movers.RegisterEntry()` for unified layout mode (`/tm layout`)
- **Fade System** — Per-bar fade with smoothstep interpolation, configurable delays/durations, SpellFlyout awareness, cooldown spark suppression at alpha 0
- **Display Conditions** — 8 macro-conditional presets (always, combat, shift, ctrl, alt, combat+shift, group, hostile) via `RegisterStateDriver`
- **Click-Through** — Per-bar toggle
- **Shift Reveal** — Global Shift-held override for faded bars
- **Combat Deferred Queue** — Protected operations queued and flushed on `PLAYER_REGEN_ENABLED`

#### ActionBarSkin v4.0.0 — Unified with New System
- **Uses AB.BAR_DEFS** — No more duplicate bar definitions; iterates `AB.GetButtons(id)` for skinning
- **Removed duplicate systems** — barOpacity, combatShow, shiftReveal, vehicle handling all now in ActionBars.lua
- **Added `ReskinBar(id)`** — Per-bar reskin function called from `AB.RefreshBar()`
- **Boot timing** — 1.0s delay to let containers initialize before skinning

#### Config Panel v4.0.0
- **Tab 1 (Skin)** — Streamlined: skin enable, style, class color, shift reveal
- **Tab 2 (Bars)** — Per-bar cards showing columns/spacing/size/alpha/scale + feature badges (Fade, Click-through, Condition)
- **Layout mode** — Opens unified Movers system instead of custom unlock/lock

#### Database Updates
- **New `actionBars` entry** — `{ enabled, shiftReveal, bars = {}, positions = {} }`
- **Cleaned `actionBarSkin`** — Removed obsolete `barOpacity`, `combatShow`, `shiftReveal` (migrated to `actionBars`)

#### Diagnostics Console v1.0.0 — New Module
- **Background error capture** — `seterrorhandler()` hook captures Lua errors with stack traces and locals
- **5 capture sources** — Lua errors, `ADDON_ACTION_FORBIDDEN`/`BLOCKED` taint events, `LUA_WARNING`, `UI_ERROR_MESSAGE`, manual `D.LogDebug()`
- **Zero combat popups** — `ScriptErrorsFrame` suppression (Hide + no-op Show + HookScript OnShow)
- **Flood control** — 30 captures/sec limit with dropped-count warning injection
- **Dedup** — Same error within 2s window increments count instead of duplicating
- **FIFO pruning** — Max 500 stored entries with oldest-first eviction
- **Re-entry & stack overflow guards** — `inHandler` flag + skips `debugstack()`/`debuglocals()` on stack overflow
- **Console UI** — Dark themed 700×500 frame with filter bar (All/Errors/Taint/Warnings/TomoMod), expandable stack traces
- **Export: Readable** — Human-friendly prose report with environment snapshot and loaded addons list
- **Export: Tracker** — Structured `@@TOMOMOD_DIAG@@`/`@@END@@` delimited format with `[env]`/`[addons]`/`[error N/M]` blocks and heredoc `msg<<<...>>>`/`stack<<<...>>>`/`locals<<<...>>>` for tracker-tomomod.onkoz.fr
- **Config panel** — Enable/disable, capture-all toggle, suppress popups, auto-open on TomoMod error
- **Slash commands** — `/tmdiag` (toggle), `/tmdiag clear`, `/tmdiag export`, `/tmdiag tracker`, `/tmdiag on`, `/tmdiag off`
- **Public API** — `D.ShowConsole()`, `D.LogDebug(msg)`, `D.LogDebugSource(source, msg)`, `D.GetErrorCount()`, `D.GetTomoModErrorCount()`

## ####################################

## CHANGELOG 2.9.1 — Midnight Compatibility & Fixes

#### TWW / Midnight Taint Fixes
- **PartyFrame LayoutFrames** — `SetSize` sur l'anchor protégé différé hors combat (`PLAYER_ROLES_ASSIGNED` en combat → `_pendingLayout` appliqué à `PLAYER_REGEN_ENABLED`)

#### Party Frame — Range Check Rewrite
- **Event-driven + timer fallback** — `UNIT_IN_RANGE_UPDATE` pour la réponse instantanée + `C_Timer.NewTicker(0.5)` pour les cas edge (phase, déconnexion, changement de zone)
- **`SetAlphaFromBoolean`** — Gère nativement les secret booleans de Midnight sans tester en Lua
- **`UnitPhaseReason`** — Joueurs phasés (warmode, phase de quête) correctement marqués hors portée
- **`UnitIsConnected`** — Joueurs déconnectés dimmés immédiatement

#### Waypoint Fixes
- **Icône Blizzard masquée** — `C_Navigation.GetFrame()` caché (`SetAlpha(0)`) quand le beacon custom est actif, restauré quand inactif
- **TGA headers réparés** — `ring.tga`, `arrow.tga`, `beam.tga`, `glow.tga`, `chevron.tga` avaient des headers corrompus (18 bytes à zéro), données pixels intactes — headers reconstruits
- **`TEX_ARROW` corrigé** — Chemin pointait vers `arrow_right` (inexistant), corrigé vers `arrow`
- **Beam** — Remplacé la texture `beam.tga` (carré 128x128 étiré) par `SetColorTexture` pour un trait vertical propre

#### Previous 2.9.1 Fixes
- **ArenaFrames** — Replaced `cur/max*100` with `UnitHealthPercent()` (C-side) to avoid crash on secret values for arena opponents
- **UnitFrame** — Wrapped `UnitDetailedThreatSituation` in `pcall()` for threat text to prevent crash on secret floats
- **Nameplates** — Replaced `UnitDetailedThreatSituation` with `UnitThreatSituation` (safe integer 0-3) in `GetUnitRole()` to avoid arithmetic on secret values
- **ReputationBar** — Replaced `hooksecurefunc → Hide()` with `SetAlpha(0) + EnableMouse(false)` to prevent taint propagation on Blizzard status tracking bars
- **BagSkin** — Replaced `hooksecurefunc(cf, "Show", → Hide())` with reparenting ContainerFrame1..13 under hidden frame to prevent taint on protected inventory frames
- **MythicTracker** — Replaced `Hide()` with `SetAlpha(0)` on ObjectiveTrackerFrame/ScenarioObjectiveTracker + added proper restore on M+ end to prevent taint propagation
- **Castbar** — Replaced `frame:Hide()` / `OnShow → Hide` with `SetAlpha(0) + EnableMouse(false)` in HideBlizzCastbar/RestoreBlizzCastbar to prevent taint
- **BuffSkin** — Replaced `hooksecurefunc(BuffFrame/DebuffFrame, "Show", → Hide())` with `SetAlpha(0) + EnableMouse(false)` via `HideFrameSafe`/`ShowFrameSafe` helpers; hook changed from `"Show"` to `"Update"` to avoid tainting EditMode-managed frames (`ClearTarget()` ADDON_ACTION_FORBIDDEN)
- **ActionBarSkin** — Removed `hooksecurefunc(button, "SetButtonState")` and `button:HookScript("OnUpdate")` which tainted secure action buttons; replaced with a single external polling frame (`_tmRangeFrame`) for range-check coloring and pushed state, preventing `SetAttribute()` ADDON_ACTION_BLOCKED on `MultiBarLeftButton1` etc.

#### Performance Optimizations
- **ActionBarSkin** — Dirty-check `(shift, inCombat)` in Shift Reveal OnUpdate; skips ~95% of identical ticks at 60 FPS
- **Castbar** — Reuse scratch table `_sparkArgs` instead of allocating per-frame (~1920 allocs/sec GC pressure avoided)
- **SparkAnimations** — Hoisted constant tables `COMET_POSITIONS`, `HELIX_OFFSETS`, `HELIX_PHASES` to module scope
- **ChatFrameSkin** — Factored `AttachChatFollowOnUpdate` with dirty-check on `(w, h)`; 4 skins × 60 FPS reduced to ~0 work when idle
- **Movers** — Hoisted `math.sqrt/abs/min/max` to module scope for grid flashlight OnUpdate

#### Bug Fixes
- **AuraTracker** — Fixed mover position save using `GetLeft()/GetBottom()` with scale conversion instead of unreliable `GetPoint()` after `StartMoving()`

#### Version Automation
- **Dynamic Version** — ConfigUI title bar, Installer title, and all 6 locale `about_text` strings now read version from `.toc` metadata via `C_AddOns.GetAddOnMetadata()` — only `## Version:` in the `.toc` needs updating per release

## ####################################

## CHANGELOG 2.9.0 — Bug Fixes, Minimap Mover & Party Frame Polish

#### Minimap Mover
- **Minimap & InfoPanel** now registered in the unified Layout system (`/tm layout`)
- Drag to reposition the minimap (zone bar + clock bar follow automatically)
- Position saved/restored across sessions in `TomoModDB.minimap.position`
- Teal mover overlay with "Minimap" label when unlocked

#### Party Frames — Bug Fixes
- **Secret value taint fixes** — `issecretvalue()` guards on UnitHealth, UnitHealthMax, UnitGetTotalAbsorbs, GetRaidTargetIndex, UnitIsConnected; raw values passed to StatusBar C-API (handles secrets natively), only Lua arithmetic/comparison guarded
- **GetTexCoordsForRoleSmallCircle removed** — replaced with manual `ROLE_TEX_COORDS` UV lookup table for TANK/HEALER/DAMAGER
- **Combat lockdown protection** — `RegisterUnitWatch`/`UnregisterUnitWatch` gated by `InCombatLockdown()` with deferred refresh on `PLAYER_REGEN_ENABLED`
- **Right-click toggle menu** — `EnableMouse(false)` on overlay frames (content, dispelHighlight) so clicks pass through to SecureUnitButtonTemplate; `RegisterForClicks("AnyUp")` prevents double-fire
- **CD Tracker tainted spellIDs** — pcall-wrapped equality check loop over known spell databases instead of silently dropping events

#### Party Frames — Improvements
- **Name centered** — nameText anchored TOP-CENTER with LEFT+RIGHT padding, `SetWordWrap(false)`, `SetMaxLines(1)` for truncation
- **Name max letters slider** — new `nameMaxLength` setting (0 = no limit) with ellipsis truncation in config Display card
- **Power bar healer-only** — power bar hidden for non-HEALER roles via `UnitGroupRolesAssigned` check
- **Power bar sliders now live-refresh** — changing power height/visibility instantly resizes health + power bars via `ApplySettings`
- **Horizontal mover** — anchor size adapts to `growDirection` (horizontal for RIGHT/LEFT, vertical for DOWN/UP)

#### Party Frames — CD Tracker Overhaul
- **Always-visible CD icons** — interrupt and battle rez icons now show as placeholders when ready (teal border, full color) and switch to desaturated + red border + swipe when on cooldown; hidden only if the class lacks the ability
- **Class-based spell lookup** — `CLASS_INTERRUPT` (13 classes) and `CLASS_BREZ` (4 classes) tables map each class to its default interrupt/brez spellID
- **Dynamic spell textures** — icons resolved via `C_Spell.GetSpellTexture(spellID)` with cache instead of hardcoded texture paths (fixes missing icons for some classes like Monk)
- **CD container parented to `f`** — moved from `content` sub-frame to the main secure frame with `SetFrameLevel(+10)` so icons always render above the health bar
- **Horizontal layout auto-detection** — CD icons automatically display below the frame (centered) when `growDirection` is RIGHT or LEFT, regardless of `cdLayout` setting
- **CD icon size slider live-refresh** — changing icon size in config now instantly resizes all CD icons, container, and re-layouts via `ApplySettings`

#### Castbar — Bug Fixes
- **Secret timer value** — `GetRemainingDuration` wrapped in `pcall` + `issecretvalue` check, fallback to 0
- **Secret interrupter GUID** — guarded GUID comparison and `UnitNameFromGUID` call; shows "Interrupted" without name when tainted

#### UnitFrames
- **RegisterForClicks fix** — changed from `"AnyDown", "AnyUp"` to `"AnyUp"` to prevent toggle menu double-fire

#### Aura Tracker — Improvements
- **Proper mover overlay** — BackdropTemplate mover (teal bg + border + label) instead of simple texture overlay
- **Mover resizes** to full icon strip area when unlocked, back to single icon when locked

#### Spell Database
- Updated from TWW Season 2 to **Midnight Season 1** — removed S2 trinket and Algari enchant IDs, added placeholder entries for Midnight S1 trinkets and weapon enchants; evergreen Gladiator's Badge/Insignia kept

## ####################################

## CHANGELOG 2.8.18 — Aura Tracker (WeakAura-lite)

#### New QOL Module: Aura Tracker (`Modules/QOL/AuraTracker/`)
- **Simple icon overlay** tracking important player buffs: trinket procs, weapon enchant procs, self-buff cooldowns, defensives, and raid buffs
- **5 filterable categories** — Trinkets, Enchants, Self-Buffs, Raid Buffs, Defensives — each togglable in config
- **Extensive spell database** (`SpellDB.lua`) covering TWW S2 trinkets, Algari weapon enchant procs, and all 13 class major cooldowns/defensives
- **Cooldown sweep** on each icon with timer text (flashes red below threshold)
- **Stack count** display for multi-stack buffs
- **Teal glow animation** on fresh proc detection
- **Icon pool** system for efficient frame recycling
- **Sort by expiration** — soonest-to-expire auras shown first
- **0.1s timer ticker** for smooth countdown updates
- **Growth direction** — Right, Left, Up, Down layout options
- **Blacklist / custom spells** — user-configurable spellID overrides in DB
- **Mover integration** — unlock/drag via `/tm layout` with preview icons
- **Config tab** in QOL panel with appearance, display, categories, and position sections
- **No COMBAT_LOG_EVENT_UNFILTERED** — uses `UNIT_AURA` + `C_UnitAuras.GetBuffDataByIndex` with `pcall`/`issecretvalue` safety
- Locale strings added for all 6 languages (EN, DE, ES, FR, IT, PT-BR)

## ####################################

## CHANGELOG 2.8.17 — Party Frames Module

#### New Module: Party Frames (`Modules/Interface/PartyFrame/`)
- **Secure party frames** for up to 4 party members using `SecureUnitButtonTemplate` + `RegisterUnitWatch`
- **Health bar** with class color, green, or gradient modes — absorb overlay and heal prediction via `CreateUnitHealPredictionCalculator`
- **Power bar** — thin bar below health showing unit power
- **Name text** with role icon (Tank/Healer/DPS) and raid marker support
- **Dispel highlight** — border glows by debuff type (Magic, Curse, Disease, Poison) via `C_UnitAuras` scanning
- **HoT tracking** — class-colored icon indicators for healer HoTs (Priest, Druid, Paladin, Shaman, Monk, Evoker)
- **Interrupt CD tracker** — monitors party kick cooldowns via `UNIT_SPELLCAST_SUCCEEDED` (all 13 classes)
- **Battle Rez CD tracker** — monitors brez cooldowns (DK, Druid, Paladin, Warlock) with icon display
- **Range check** — out-of-range members fade to configurable opacity using `UnitIsVisible` + 0.2s ticker
- **Role sorting** — optional Tank > Healer > DPS sort order
- **Growth direction** — Down, Up, Right, or Left layout
- **Blizzard frame hiding** — auto-hides CompactPartyFrame and PartyFrame when enabled
- **Mover integration** — unlock/drag via `/tm layout`

#### Arena Enemy Frames
- **Arena frames** (1–3) with health, power, name display
- **PvP trinket cooldown** tracking via `C_PvP.GetArenaCrowdControlInfo`
- **Spec icon** support via `ARENA_PREP_OPPONENT_SPECIALIZATIONS`
- Separate mover anchor from party frames

#### Config Panel
- **4-tab config** — General, Features, Cooldowns, Arena
- Full slider/checkbox/dropdown controls for all settings
- Reset Position buttons for both party and arena anchors

#### Technical
- **No `COMBAT_LOG_EVENT_UNFILTERED`** — all cooldown tracking uses `UNIT_SPELLCAST_SUCCEEDED` only
- All `C_UnitAuras` / `C_PvP` calls wrapped in `pcall` / `issecretvalue` safety checks
- Auto-hides in raid groups (> 5 members)
- Added `icon_partyframes.tga` category icon (white monochrome, 32×32)
- Added 80+ locale strings (`pf_*` prefix) in enUS.lua

## ####################################

## CHANGELOG 2.8.16 — Castbar Anchoring & Cleanup

#### Castbar UnitFrame Anchoring
- **Target, Focus, Pet and Boss castbars** now automatically anchor below their respective UnitFrame and match its width
- **Per-unit settings** — `anchorToUnitFrame` and `anchorOffsetY` allow fine-tuning or disabling the anchor behavior per unit
- **Dynamic re-anchor** — castbars re-sync width and position when UnitFrames are resized or refreshed
- **Dragging disabled** for anchored castbars (non-player); player castbar remains freely movable

#### UnitFrame Castbar Element Removed
- **Removed `Elements/Castbar.lua`** — the embedded UnitFrame castbar element is no longer loaded; the standalone module handles all castbar rendering
- **Cleaned up UnitFrame.lua** — removed castbar creation, positioning, refresh and lock/unlock helper functions
- **Removed UF castbar database defaults** — `castbarColor`, `castbarNIColor`, `castbarInterruptColor` and per-unit `castbar` blocks removed from `unitFrames` section
- **Removed UF castbar config panel** — castbar dimensions section and Colors tab removed from UnitFrames config
- **Removed Mover fallback** — mover system no longer falls back to UF castbar helpers
- **Removed Init.lua reference** — `/tm layout` no longer calls `UF.TogglePlayerCastbarLock()`

#### Castbar Color Changes
- **Player castbar** now uses class color by default (`useClassColor = true`)
- **Other castbars** (Target, Focus, Pet, Boss) use `castbarColor` (red) for interruptible casts
- Fixed `→` character replaced with `>` to avoid unsupported glyph display in WoW fonts

#### Misc
- Added `icon_castbars.tga` category icon (white monochrome, 32×32)

## ####################################

## CHANGELOG 2.8.15 — Standalone Castbars Module

#### New: Standalone Castbars
- **Full castbar module** — standalone castbars for Player, Target, Focus, Pet and Boss (1–5), replacing reliance on UnitFrame-embedded castbars
- **Spark animations** — 4 animated spark styles: Comet, Pulse, Helix, Glitch with configurable colors and opacity
- **Class color casting** — optional class-colored cast bars for all units
- **Channel tick markers** — automatic tick markers for channeled spells with known tick data
- **Empowered cast support** — stage markers and progressive stage overlays for Evoker empowered casts
- **Interrupt feedback** — on-screen text notification when you successfully interrupt a target's cast
- **Latency indicator** — optional latency overlay on the player castbar showing network delay
- **GCD spark** — optional thin progress bar below the player castbar showing Global Cooldown
- **Cast transitions** — smooth fade-out and flash animations on cast completion / interruption
- **Blizzard castbar hiding** — automatically hides default Blizzard castbars when enabled

#### Castbar Config Panel
- **New "Castbars" category** in the config GUI with tabbed layout: General, Player, Target, Focus, Pet, Boss
- **General tab** — global settings: texture, font size, background mode, timer format, spark style, colors, GCD, interrupt feedback
- **Per-unit tabs** — enable/disable, dimensions, icon side, timer, latency (player only), position reset

#### Layout / Mover Integration
- **Player castbar** is now movable via `/tm layout` (Mover system integration)
- **Mover entry updated** — castbar mover now prefers the standalone module, with fallback to UnitFrame castbar

## ####################################

## CHANGELOG 2.8.14 — Chat Skin Selection, Mover Integration & Taint Fixes

#### Chat Frame Skin System
- **Multiple skin styles** — new dropdown in Skins > Chat Frame to choose between 4 skins:
  - **TUI** (default) — sidebar + window textures with sidebar icons
  - **Classic** — old-style framed look with golden border and gradient overlay
  - **Glass** — frosted glass effect with teal accent border and top highlight line
  - **Minimal** — flat dark background, no border
- **Live switching** — skin changes apply instantly via `ApplySettings()`, no reload required
- **Database** — added `skinStyle` setting to `chatFrameSkin` defaults

#### Chat Frame Mover Integration
- **Layout mode support** — chat frame is now registered with `TomoMod_Movers` and can be repositioned via `/tm layout`
- **Blizzard Edit Mode disabled** — `FCF_StartDragging`/`FCF_StopDragging` are overridden to prevent Blizzard's default chat drag behavior
- **Position persistence** — chat frame position saved to `TomoModDB.chatFrameSkin.position` and restored on login
- **Drag overlay** — teal-highlighted overlay with "Chat Frame" label shown when layout mode is active

#### Unit Frames — Mover Fix
- **Fixed unit frames not draggable in layout mode** — added missing `frame:SetLocked(false/true)` calls in `UF.ToggleLock()` so that `dragFrame` overlays are properly shown/hidden when entering/exiting layout mode

#### Taint / Secret Value Fixes (TWW Compatibility)
- **Aura stack count** — fixed `attempt to compare secret string` crash in `UpdateAuras` and `UpdateEnemyBuffs` by avoiding `GetText()` readback on tainted stack count values
- **Chat GUID taint** — added `issecretvalue(guid)` guard in `TM_GetPlayerInfoByGUID` to skip tainted GUIDs from NPC/monster chat events
- **Chat TEXT_EMOTE taint** — added `issecretvalue(arg2)` guard in `MessageFormatter` to safely handle tainted player names in emote messages
- **Rune cooldown nil** — added nil guard for `GetRuneCooldown()` returning nil values during spec changes or loading

#### Localization
- **New keys** — added skin style labels (`opt_chat_skin_style`, `opt_chat_skin_style_tui/classic/glass/minimal`) and mover label (`mover_chatframe`) to all 6 locale files (enUS, frFR, deDE, esES, itIT, ptBR)

## ####################################

## CHANGELOG 2.8.13 — Cooldown Manager V3.1: Sound Alerts, Pandemic Detection, Range Check

#### Sound Alerts
- **Cooldown-ready notification** — plays a configurable sound when an Essential or Utility spell comes off cooldown
- **Debounce system** — 1-second minimum gap between alerts to avoid sound spam
- **Sound picker** — choose from 4 bundled sounds (Golden Lust, Chipi, Spinning Cat, Taluani BL) in the config panel
- **Per-spell tracking** — tracks individual spell CD states; only fires when a spell transitions from on-cooldown to ready

#### Pandemic Detection
- **Buff refresh window indicator** — displays an orange border on buff icons when remaining duration is within the pandemic threshold (default: 30% of total duration)
- **Configurable threshold** — slider in config panel to adjust the pandemic window from 10% to 50%
- **Dedicated 9-slice border** — separate orange border layer that overrides both default and active borders during pandemic window

#### Range Check Coloring
- **Out-of-range tinting** — Essential and Utility spell icons turn red when the target is out of spell range
- **Smart detection** — uses `C_Spell.IsSpellInRange()` which only tints when a target exists AND the spell has a range component AND the target is out of range
- **Automatic recovery** — icon color resets immediately when target comes back in range or is lost

#### Localization
- **Missing locale keys** — added all V3/V3.1 CDM keys to `frFR.lua` and `enUS.lua` (CD Swipe, Advanced, Visibility Rules, Sound/Pandemic/Range options)
- **Config panel fix** — labels now display properly translated text instead of raw key names (e.g. `opt_cdm_hide_gcd` → "Masquer le GCD")

## ####################################

## CHANGELOG 2.8.12 — Cooldown Manager V3 Overhaul (Inspired by CooldownManagerCentered)

#### Runtime & Stability
- **Runtime readiness system** — checks `IsInitialized()` and `layoutApplyInProgress` before any viewer operation, preventing errors during Edit Mode transitions and layout changes
- **Edit Mode callbacks** — hooks `EditMode.Enter/Exit` and `CooldownViewerSettings.OnDataChanged` for automatic refresh when layout settings change
- **Client scene awareness** — tracks `CLIENT_SCENE_OPENED/CLOSED` to properly handle vehicle/cinematic states

#### Cooldown Tracker (Performance)
- **Spell cooldown duration caching** — caches `C_Spell.GetSpellCooldownDuration()` objects instead of creating new ones every tick
- **Charge cooldown caching** — separate cache for `C_Spell.GetSpellChargeDuration()` on charge-based spells
- **Event-driven cache invalidation** — updates on `SPELL_UPDATE_COOLDOWN`, `SPELL_UPDATE_CHARGES`, and `PLAYER_ENTERING_WORLD`

#### Keybind System Improvements
- **Macro spell support** — extracts spell IDs from macros via `GetMacroSpell()` for accurate keybind display
- **Item spell support** — resolves item action slots to their spell IDs via `C_Item.GetItemSpell()`
- **ElvUI bar support** — reads keybinds from `ElvUI_Bar1Button` through `ElvUI_Bar10Button` using `GetBindingKey()`
- **Dominos bar support** — scans `DominosActionButton1`–`168` for keybind text
- **`GetBindingKey` API** — uses Blizzard's native binding API for Blizzard bars instead of parsing HotKey text, improving reliability
- **Override/base spell fallback** — tries `C_Spell.GetOverrideSpell()` and `C_Spell.GetBaseSpell()` before slot lookup
- **CooldownID extraction** — uses `C_CooldownViewer.GetCooldownViewerCooldownInfo()` for more reliable spell ID resolution on keybind display
- **Improved key formatting** — handles gamepad bindings (LT, RT, LB, RB), German keyboard (STRG), META key, and more edge cases

#### Swipe Color System
- **Separate active aura swipe** — configurable color and alpha for active aura (buff) swipe overlay
- **Separate cooldown swipe** — new independent color and alpha for normal cooldown swipe (defaults: black, 0.7 alpha)
- **Dual swipe hook** — single `SetCooldown` hook applies the correct color based on aura vs cooldown state

#### GCD Hiding
- **Hide Global Cooldown option** — new `hideGCD` toggle that intercepts `SetCooldown` and replaces GCD swipes with an empty duration object
- Uses `C_Spell.GetSpellCooldown().isOnGCD` for reliable GCD detection

#### Desaturation on Cooldown
- **Desaturation curve** — icons on cooldown are desaturated (greyed out) using `C_CurveUtil` (0 when ready, 1 when on cooldown)
- Only applies to Essential/Utility viewers, not buff icons
- Skips desaturation on active aura spells

#### Buff Icon Alignment Modes
- **CENTER** — center-outward pattern (1st center, 2nd left, 3rd right) — existing V2 behavior
- **START** — left-aligned (or top-aligned in vertical mode)
- **END** — right-aligned (or bottom-aligned in vertical mode)
- Configurable via dropdown in the CDM settings panel

#### Vertical Layout Support
- **Essential/Utility viewers** now support vertical orientation when `isHorizontal` is false
- **Buff icons** support vertical alignment with proper anchor calculation
- Uses `PositionRowVertical()` with `CenteredColYOffsets` for column-based positioning

#### Charge-Aware Utility Dimming
- **Charge cooldown duration** — spells with charges now use `GetSpellChargeDuration()` for dimming calculation instead of the full spell cooldown
- Detected via `cooldownChargesShown` property on the cooldown frame

#### Visibility Rules (Advanced)
- **Hide when mounted** — detects mount and druid travel forms (shapeshift IDs 3, 27, 29)
- **Hide in vehicles** — combines `CLIENT_SCENE`, `HasOverrideActionBar`, and `UnitInVehicle`
- **Hide out of combat** — hides when not in combat and no target exists
- **Show in combat** — override that forces display during combat
- **Show in instance** — override that forces display inside instances
- **Show with enemy target** — override that forces display when targeting an attackable unit
- Visibility rules are evaluated with priority: hide conditions first, then show overrides
- Backward-compatible with the V2 simple combat alpha system

#### Additional Events
- `UPDATE_SHAPESHIFT_FORM` — triggers re-layout and visibility update on form changes
- `SPELL_UPDATE_COOLDOWN` — triggers immediate utility dimming refresh
- `MOUNT_JOURNAL_USABILITY_CHANGED` / `PLAYER_MOUNT_DISPLAY_CHANGED` — visibility updates on mount state changes

#### Config Panel — New Options
- **Advanced card** — Hide GCD toggle, Desaturation toggle, Buff alignment dropdown (Center/Start/End)
- **Overlay & Swipe card** — expanded with CD swipe color picker, CD swipe alpha slider, and separate active/CD swipe toggles
- **Visibility Rules card** — 6 toggleable rules (hide mounted, hide vehicle, hide OOC, show combat, show instance, show enemy target)

## ####################################

## CHANGELOG 2.8.11 — AFK Display Screen

#### AFK Display Module
- **Stylized AFK screen** — automatically shown when player goes AFK, hides UIParent for a clean cinematic look
- **3D player model** — race/gender-aware positioning with drag support, falling animation, and idle/pickup emotes
- **Elapsed timer** — displays time spent AFK in MM:SS format
- **Player info overlay** — shows character name, realm, level, specialization, and class-colored text
- **Chat counters** — tracks whisper and guild messages received while AFK
- **Camera rotation** — optional slow camera pan while AFK (configurable)
- **Auto-hide safety** — automatically exits AFK screen on combat, Auction House, or cinematic playback
- **Configurable settings** — `enabled`, `rotateCamera`, `playerModel`, `modelScale` via saved variables

## ####################################

## CHANGELOG 2.8.10 — Chat System Overhaul (TUI_Core Visual Style)

#### TUI_Core-Inspired Chat Container
- **Sidebar + Window layout** — vertical sidebar (`sidebar.tga`) with adjacent window background (`window.tga`) forming a unified chat container
- **Tab bar texture** — custom `tabs.tga` strip replaces default Blizzard tab chrome for a clean, modern look
- **Sidebar icons** — five quick-access buttons on the sidebar: Professions (`book.tga`), Shortcuts (`shortcuts.tga`), Copy Chat (`copyIcon.tga`), Emotes (`speechIcon.tga`), and Player Status
- **Scroll bar theming** — colored thumb (purple accent), hidden by default, appears on scroll via `OnScrollChangedCallback`
- **Blizzard fading disabled** — `FCF_FadeInChatFrame`/`FCF_FadeOutChatFrame` overridden with NoOp for always-visible chat

#### Tab System (TUI_Core Style)
- **Clean tab styling** — all default Blizzard tab textures killed; white text, alpha-based visibility
- **Tab notification flash** — uses `notify.tga` icon with `UIFrameFlash` for unread tab alerts
- **Dock-aware tab positioning** — tabs repositioned left-to-right following the dock order

#### Message Formatting & Display
- **Timestamps** — optional configurable timestamps (`%H:%M` default) with customizable color via `timestampColor`
- **Short channel names** — abbreviates channel prefixes (Guild → [G], Party → [P], Raid → [R], etc.)
- **Class-colored mentions** — highlights player names in messages using their class color
- **Keyword highlighting** — custom keyword list with orange highlight alerts (supports `%MYNAME%` placeholder)
- **URL detection (TUI_Core style)** — converts URLs to clickable links; click opens a `StaticPopup` copy dialog instead of inserting into edit box
- **LFG role icons** — displays tank/healer/DPS role icons next to player names in group chat
- **BattleNet friend coloring** — applies class colors to BattleNet friend names in whispers

#### Edit Box (TUI_Core Style)
- **Backdrop styling** — dark background with tooltip-style border, colored by active chat type (say/whisper/guild etc.)
- **Character counter** — displays remaining character count while typing
- **History navigation** — Up/Down arrow keys cycle through previously sent messages (20-line buffer)

#### Chat Utilities
- **Copy chat frame** — sidebar icon opens a draggable/resizable scrollable text window with the last 128 messages
- **Per-line copy arrow** — optional inline arrow icon per message for quick copy
- **Chat history persistence** — saves and restores whisper, guild, party, raid, instance, officer, and emote chat across sessions
- **Spam throttle** — suppresses duplicate messages from the same author within a 10-second window

#### Emoji System
- **Inline emoji replacement** — converts text emoticons (`:)`, `:D`, `;)`, etc.) to display strings in chat messages

#### Config Panel — Chat Options
- Toggle options: Short Channel Names, Timestamps, URL Detection, Emoji, Class Color Mentions, Chat History, Copy Chat Lines, Font Size

#### Assets
- **76 new textures** added under `Assets/Textures/Chat/` (chat UI elements, emoji sprites, chat bubble textures)

## ####################################

## CHANGELOG 2.8.9 — ActionBar System Overhaul (Dominos-inspired)

#### Centralized Fade Manager
- **Polling-based fade system** (150ms cycle) replaces per-button HookScript approach
- **Proper focus detection** — checks descendants, spell flyouts, and GetMouseFoci for accurate hover tracking
- **Per-bar fade timing** — configurable fade-in delay, fade-in duration, fade-out delay, and fade-out duration
- Transparent bars automatically **hide cooldown sparks** at 0 alpha

#### Display Conditions (Macro-Conditional Visibility)
- **SecureHandlerStateTemplate wrapper** per bar for combat-safe show/hide
- **8 built-in presets**: Always visible, Combat only, Shift/Ctrl/Alt held, Combat or Shift, In group only, Hostile target
- **Custom macro conditions** supported via editbox (e.g. `[combat,mod:shift]show;hide`)
- Replaces the previous basic `combatOnly` toggle

#### Per-Bar Button Controls
- **Click-through** toggle per bar — buttons pass clicks to the world
- **Show/hide count text** (stack numbers) per bar
- **Show empty button slots** toggle per bar

#### Bar Editor — Expanded UI
- Reorganized into sections: Opacity/Scale, Fade, Visibility, Buttons
- Display condition presets shown as compact 2-column button grid with active state highlighting
- Custom condition editbox appears when a non-preset condition is detected

#### Button Skinning — New Style & Improvements
- **New "Minimal" skin style** — borderless with subtle inner shadow edges and tighter icon inset
- **Pushed overlay** — proper dark tint on click replaces hidden pushed texture
- **Out-of-range coloring** — red tint when out of range, blue when out of mana, grey when unusable (0.2s polling)

#### Config Panel Updates
- "Minimal" added to the skin style dropdown
- Bar management cards now show **status badges** (Fade ON/OFF, Click-through, Display condition active)

## ####################################

## CHANGELOG 2.8.8 — Mythic+ Tracker Display Overhaul

#### Timer Bar — 3-Tier Chest System
- **3 chest countdown timers (+3/+2/+1)** displayed below the timer bar, replacing the previous 2-tier system
- **3 tick marks** on the timer bar at 60%, 80%, and 100% thresholds with 2px width for better visibility
- Timer bar and boss rows slightly taller (22px / 20px) for improved readability

#### Forces Bar — 5-Stage Color Gradient
- **5-stage color progression** for enemy forces (< 20%, < 40%, < 60%, < 80%, < 100%) inspired by MPlusTimer's gradient system, replacing the 2-color interpolation
- **Forces completion time** — when forces reach 100%, the exact completion time is displayed below the bar
- Forces completion state resets properly on new key start

#### Boss Rows — Split Times & Name Truncation
- **Split times column** — each boss now shows the time elapsed since the previous boss kill (or from start for the first boss)
- **UTF-8 safe name truncation** — boss names capped at 22 characters to prevent overflow, using a proper multibyte-aware substring function
- Boss rows now support `SetMaxLines(1)` and `SetWordWrap(false)` for clean single-line display

#### Death Tracking — Per-Player Breakdown
- **Death tooltip on hover** — hovering the skull/death counter in the header shows a tooltip with per-player death counts
- Deaths tracked via `COMBAT_LOG_EVENT_UNFILTERED` / `UNIT_DIED` with class-colored player names
- Feign Death correctly ignored
- Death data resets on each new key start

#### Completion Banner — Upgrade Display
- Completion banner now shows the **keystone upgrade level** (+1, +2, +3) when the timer is beaten

#### Layout & Frame
- Frame width increased from 260px to 300px for better content spacing
- Update rate improved from 0.25s to 0.20s for smoother timer updates
- `LayoutFrame()` now called in the ticker loop to handle dynamic resizing (forces completion row)

## ####################################

## CHANGELOG 2.8.7 — Objective Tracker Color Overhaul (HorizonSuite-inspired)

#### Objective Tracker — Quest Type Color System
- **17 quest categories** now detected and color-coded (up from 6), inspired by HorizonSuite's color matrix system
- New quest title colors:
  - **Green** — complete (ready to turn in)
  - **Gold** — campaign quests
  - **Pink** — important quests
  - **Orange** — legendary quests
  - **Blue** — calling quests
  - **Epic purple** — dungeon quests
  - **Red** — raid quests
  - **Purple-violet** — world quests
  - **Cyan** — weekly / daily quests
  - **Dark crimson** — Prey quests (Midnight)
  - **Teal** — Delves
  - **Deep blue** — scenarios
  - **Artifact gold** — adventure quests
  - **Bronze** — achievements
  - **Sage green** — profession quests
  - **Light grey** — default
- **Quest classification engine** (`GetQuestBaseCategory`) using `C_QuestInfoSystem.GetQuestClassification()` (WoW 12.x API) with multi-level fallback chain: `C_CampaignInfo`, `IsImportantQuest`, `IsWorldQuest`, `GetQuestTagInfo` (tagID for dungeon/raid), frequency detection, `IsQuestCalling`
- **Objective lines now tinted by quest type** — incomplete objectives use a slightly dimmed version of the quest category color instead of flat grey
- **Category cache** (`questCategoryCache`) with automatic invalidation on each tracker update for responsive state changes

#### Objective Tracker — Category Header Colors
- Header colors realigned with HorizonSuite palette across all categories
- New header keywords added: Dungeon/Donjon, Raid, Calling/Appel, Weekly/Hebdomadaire, Daily/Quotidien, Prey/Proie, Delves, World Quests/Quêtes Mondiales
- Full FR+EN bilingual keyword support for all category headers

## ####################################

## CHANGELOG 2.8.6 — UnitFrame Redesign, Tooltip Skin & Objective Tracker

#### UnitFrames — Visual Redesign
- **New info bar** below the health bar displaying power value (left) and total HP (right) for the player, mirrored layout for the target
- **Thin 2px power accent bar** between health and info bar, with matching left/right 1px borders to align perfectly with the health bar edges
- **Health bar** now shows centered percentage text by default
- **Tooltip on hover** — player and target UnitFrames now display the standard GameTooltip on mouseover (oUF's `Spawn()` does not set this by default)

#### Tooltip Skin — New Module
- **Dark semi-transparent background** with NineSlice vertex color override and subtle class-colored accent line at the top
- **Class-colored unit names** for players
- **Guild name** displayed in teal color below the unit name
- **Font override** using Poppins across all tooltip text
- **Optional features**: hide health bar, hide player server name, hide player title
- **Config panel** under Skins > Tooltip with controls for background/border alpha, font size, and all toggle options
- Hooks applied to `GameTooltip`, `ShoppingTooltip1/2`, and `ItemRefTooltip`

#### Objective Tracker — Quest Title Coloring
- Quest titles are now **color-coded by quest type**:
  - **Green** — ready to turn in (complete)
  - **Golden yellow** — campaign quests
  - **Pink** — important quests
  - **Violet** — world quests
  - **Blue** — weekly quests
  - **White** — default for all other quests
- Color detection uses `C_QuestLog.IsComplete`, `C_CampaignInfo.IsCampaignQuest`, `C_QuestLog.IsImportantQuest`, `C_QuestLog.IsWorldQuest`, and quest frequency checks

#### Config Panel
- Fixed **empty "World Quests" tab** caused by function name typo (`BuildWorldQuestTabTab` → `BuildWorldQuestTab`)
- New **Tooltip Skin tab** under Skins panel with full configuration options

#### Database
- New `tooltipSkin` defaults: `enabled`, `bgAlpha` (0.92), `borderAlpha` (0.8), `fontSize` (12), `hideHealthBar`, `useClassColorNames`, `hidePlayerServer`, `hidePlayerTitle`, `useGuildNameColor`, `guildNameColor`
- Updated player/target defaults: `powerHeight=2`, `infoBarHeight=18`, `healthTextFormat="percent"`

#### Locale
- **enUS/frFR**: 17 new tooltip skin locale keys added

## ####################################

## CHANGELOG 2.8.5 — BagSkin v4 Rewrite (GW2_UI-inspired)

#### BagSkin — Complete Rewrite (v4)
- **Full rewrite** of `BagSkin.lua` (~1700 lines) inspired by GW2_UI's inventory system architecture
- **Resizable frame** with live column recalculation during resize (drag handle bottom-right)
- **3 layout modes**: Combined Grid, Categories (collapsible sections), Separate Bags (per-bag sections with collapse)
- **Bag bar sidebar** (left) showing each bag icon, tooltip, and free slot count per bag
- **Settings context menu** (GW2_UI-style) via cogwheel button — layout mode, sort mode, and all toggle options accessible in-game without opening the config panel
- **5 sort modes**: Manual (no sorting — preserves natural bag/slot order), Quality, Name, Type, Item Level
- **Manual sort mode** keeps items AND empty slots in their natural bag/slot position — drag-and-drop reordering is preserved across refreshes
- **Sort button** triggers `C_Container.SortBags()` with delayed re-layout
- **Item level badges** on equipment slots (toggleable)
- **Junk coin icon** (`bags-junkcoin` atlas) on poor-quality items (toggleable)
- **Crafting quality icons** (Tier 1–5 atlas) on trade goods
- **Quality borders** with per-quality color coding (0=gray through 8=WoW Token blue)
- **Cooldown overlays** on items with active cooldowns
- **Search bar** with real-time filtering — non-matching items desaturated and dimmed
- **Free slots display** with count badge per section (separate bags: `used/total` format)
- **Gold + tracked currencies** in footer bar
- **Drag-and-drop** between bags and within same bag — cursor detection (`GetCursorInfo()`) prevents pick-up/place conflict
- **Right-click use** via secure macro attribute (`/use bagID slotIndex`)
- **Stack splitting** via Shift+click with `OpenStackSplitFrame`
- **Chat linking** via Shift+click with `ChatEdit_InsertLink`
- **Escape to close** via `UISpecialFrames` registration
- **Mover integration** with `TomoMod_Movers`

#### BagSkin — Blizzard Suppression
- `ContainerFrameCombinedBags` parented to hidden frame with scripts cleared (GW2_UI approach — more robust than hook-only)
- Individual `ContainerFrame1–13` suppressed via `hooksecurefunc` Show hook
- `combinedBags` CVar forced to `0` on init and monitored via `CVAR_UPDATE`
- Bag open/close hooks with `hookGuard` + `C_Timer.After(0)` deferral to prevent recursion

#### Database
- Updated `bagSkin` defaults: `slotSpacingX`/`slotSpacingY` (replaced single `slotSpacing`), `width`, `showItemLevel`, `showJunkIcon`, `layoutMode`, `sortMode`, `reverseBagOrder`, `showBagBar`, `collapsedSections`
- DB migration: old `slotSpacing` → separate `slotSpacingX`/`slotSpacingY`

#### Config Panel (Skins > Bags)
- **Layout Mode** dropdown: Combined Grid / Categories / Separate Bags
- **Sort Mode** dropdown: Manual / Quality / Name / Type / Item Level / Recent
- **Slot Spacing X** and **Slot Spacing Y** separate sliders (0–20, matching GW2_UI range)
- **Slot Size** slider range updated to 26–48 (matching GW2_UI)
- New checkboxes: Show Item Level, Show Junk Icon, Reverse Bag Order, Show Bag Bar

#### Locale
- **enUS**: 12 new keys — `opt_skin_bags_layout_mode`, `opt_skin_bags_layout_combined`, `opt_skin_bags_layout_categories`, `opt_skin_bags_layout_separate`, `opt_skin_bags_slot_spacing_x`, `opt_skin_bags_slot_spacing_y`, `opt_skin_bags_show_ilvl`, `opt_skin_bags_show_junk_icon`, `opt_skin_bags_reverse_order`, `opt_skin_bags_show_bag_bar`, `opt_skin_bags_settings`, `opt_skin_bags_sort_none`
- **frFR**: matching French translations with proper UTF-8 octal encoding (`\195\169` etc.)
- Updated `info_skin_bags_desc` in both locales to reflect v4 architecture

## ####################################

## CHANGELOG 2.8.0 — Performance & Stability Audit

#### Global Safety
- Protected all 14 module globals with `X = X or {}` pattern to prevent data loss on `/reload` or double-load: Loots, CursorRing, Minimap, WorldQuestTab, InfoPanel, Waypoint, FrameAnchors, DataKeys, LevelingBar, MythicHub, TomoScore, ProfessionHelper, CinematicSkip, ObjectiveTracker

#### SavedVariables
- Added `CompanionStatusDB` to `.toc` `SavedVariables` — previously declared in Lua but never persisted across sessions

#### Profiles (CPU/RAM)
- Added `_snapshotCache` to `Core/Profiles.lua` — avoids redundant `DeepCopy` of the entire database on repeated profile saves
- Cache is automatically invalidated on profile load, delete, and switch

#### Namespace Collision
- Renamed bare `MK` global (MythicKeys) to `TomoMod_MythicKeys` — short name had high collision risk with other addons; local `MK` alias preserved for internal use

#### GameMenuSkin (CPU)
- Removed redundant `SetAtlas("")` and `SetColorTexture(0,0,0,0)` calls in `NukeTextures` — `SetTexture(nil)` is sufficient
- Replaced per-texture closure creation in `LockoutTextures` with shared `_tmHookShow` / `_tmHookSetAlpha` functions — eliminates ~160 closures when opening the game menu

#### BagSkin (CPU)
- Added `GetCachedItemExtras()` with a 10-second TTL cache for expensive `C_Item.GetCurrentItemLevel` and `C_TradeSkillUI.GetItemReagentQualityByItemInfo` queries — avoids repeated `pcall` + `ItemLocation` creation on every bag refresh

#### Waypoint (CPU)
- Localized `math.sqrt`, `math.atan2`, `math.pi` for the OnUpdate hot path
- Replaced `while` loop angle normalization with single modulo operation: `((diff + pi) % TWO_PI) - pi`
- `SetPoint` and `SetRotation` now only called when position/angle delta exceeds threshold — reduces unnecessary layout invalidation

## ####################################

## CHANGELOG 2.7.8

#### Waypoint — Zone Restriction & Visual Customization
- **Zone-only visibility**: waypoint beacon and navigator are now automatically hidden when the player is outside the zone where the waypoint was placed — re-appear instantly on zone entry; controlled via the new `zoneOnly` DB flag (enabled by default); uses `C_Map.GetPlayerMapPosition(waypointMapID, "player")` to detect zone presence without any additional map API calls
- **`WP.ApplySettings()`** — new public function that reads `TomoModDB.waypoint` and applies color, shape, and size live without a reload:
  - **Color**: glow ring, beacon icon, vertical beam, navigator arrow, and distance text all recolor together from the stored `{ r, g, b }` table
  - **Shape**: `"ring"` uses the existing `TEX_RING` texture; `"arrow"` swaps to `TEX_ARROW` on the beacon icon
  - **Size**: beacon frame and proportional glow ring resize from `beaconSize` (16–64 px)
- **`WP.CheckActivePublic()`** — thin wrapper around `CheckActive()` exposed for the config UI to re-evaluate visibility after toggling zone-only without waiting for the next event
- **`waypointMapID`** stored at `NewWaypoint()` time and cleared at `ClearWaypoint()` — used as the reference map for zone detection
- All new symbols and icon references use `|T...|t` WoW texture escapes (Poppins font compatibility)

#### Config GUI — QOL > Waypoint tab (new)
- New **"Waypoint"** tab added to the QOL config panel (`BuildWaypointTab`):
  - **Checkbox** — "Show only in current zone" (`opt_way_zone_only`): hides the waypoint when not in its zone; calls `WP.CheckActivePublic()` on change
  - **Slider** — "Beacon size" (`opt_way_size`): 16–64 px, updates `TomoModDB.waypoint.beaconSize` and calls `WP.ApplySettings()` live
  - **Dropdown** — "Shape" (`opt_way_shape`): Ring / Arrow; switches the beacon icon texture live
  - **Color picker** — "Waypoint color" (`opt_way_color`): full RGB picker; recolors all beacon, beam, and navigator elements live

#### Database
- Extended `waypoint` defaults: added `zoneOnly = true`, `beaconSize = 32`, `shape = "ring"`, `color = { r = 0.047, g = 0.824, b = 0.624 }`

#### Locale
- **8 new keys** across all 6 locales (enUS, frFR, deDE, esES, itIT, ptBR): `tab_qol_waypoint`, `section_waypoint`, `opt_way_zone_only`, `opt_way_size`, `opt_way_shape`, `way_shape_ring`, `way_shape_arrow`, `opt_way_color`

## ####################################

## CHANGELOG 2.7.7 — Hotfix

#### Bug Fix — ChatFrameSkinV2
- Removed `CHAT_MSG_BN_CONVERSATION` from `ALL_EVENTS` — this event was removed from WoW in Midnight 12.x and caused an immediate Lua error (`Frame:RegisterEvent(): Attempt to register unknown event`) on login when the skin was enabled
- Removed `"BN_CONVERSATION"` from the `chucho` tab's `chatTypes` list accordingly

## ####################################

## CHANGELOG 2.7.6

#### Waypoint — In-world Navigation (`/tm way`)
- **New module** `Modules/QOL/Waypoint/Waypoint.lua` — self-contained in-world waypoint system inspired by WaypointUI (AdaptiveX)
- **Beacon mode** (target on-screen): teal circle icon + vertical beam anchored to `C_Navigation.GetFrame()` — Blizzard's navigation frame that tracks the super-tracked target in 2D screen space; scales dynamically with distance (closer = larger, base scale at ~1800 yds)
- **Navigator mode** (target off-screen): rotating arrow positioned on an elliptical orbit around screen centre, interpolated to face the off-screen target; switches automatically when the nav frame reaches the screen edge
- **Distance & ETA**: live distance text (yards / km) with a moving-average arrival-time estimate appended (`42s`, `3m05s`) displayed below the beacon or next to the navigator arrow; updates at 20 fps
- **Slash command** `/tm way` — place waypoint at current player position
- **Slash command** `/tm way x y [name]` — waypoint at (x, y) on the current map with optional label
- **Slash command** `/tm way mapID x y [name]` — waypoint on any map by ID
- **Slash command** `/tm way clear` — remove active waypoint and stop tracking
- **MapPin API** (`TomoMod_Waypoint`):
  - `NewWaypoint(name, mapID, x, y)` — sets `C_Map.SetUserWaypoint` + `C_SuperTrack.SetSuperTrackedUserWaypoint`
  - `ClearWaypoint()` — clears map pin and super-tracking
  - `NewWaypointHere([name])` — places pin at player's current coordinates
  - `HandleSlashCommand(args)` — full slash-command parser
- **State machine**: `HIDDEN` → `WAYPOINT` ↔ `NAVIGATOR`; resets on `SUPER_TRACKING_CHANGED`, `NAVIGATION_FRAME_DESTROYED`, zone transitions
- **Session label** persisted to `TomoModDB.waypoint.sessionName` (restored after `/reload`)
- All print messages use `|T...|t` texture escapes instead of Unicode symbols (Poppins font compatibility)

#### Database
- Added `waypoint` defaults: `enabled`, `beaconScale`, `showBeam`, `showETA`, `sessionName`
- Added `favorites = {}` to `loots` defaults (backfill from v2.7.5)

#### Locale
- **11 new keys** across all 6 locales: `msg_help_way`, `msg_help_way_coords`, `msg_help_way_clear`, `way_cleared`, `way_set`, `way_here`, `way_no_map`, `way_no_pos`, `way_bad_map`, `way_bad_coords`, `way_usage`

#### Load Order
- `Waypoint\Waypoint.lua` added to `QOL.xml` (before Loots)
- `TomoMod_Waypoint.Initialize()` called in `Core/Init.lua` on `PLAYER_LOGIN`

## ####################################

## CHANGELOG 2.7.5

#### Loot Browser — Global Filter Bar (`/tm loot`)
- **Global filter bar** added between the header and the content panels, spanning the full 840 px frame width — class, specialization, and difficulty are now chosen once and apply to both the Dungeons and Raids tabs
- **Class filter (Row 1 — left):** "Tous" button + one 22×22 button per class; icons rendered via `|T...|t` texture escapes inside Poppins FontStrings using `AtlasIconStr("classicon-<class>")` — fully locale-independent; class color tinted background; tooltip shows class name on hover
- **Difficulty filter (Row 1 — right):** four buttons always visible — Raid Find · Normal · Héroïque · Mythique; clicking a difficulty triggers a redraw of the raid item grid; ignored for Dungeon tab (dungeons have a single M+ loot pool)
- **Specialization filter (Row 2):** spec buttons appear when a class is selected; each button shows the spec icon (`|T fileDataID:14:14|t`) + localized spec name via `GetSpecializationInfoByID`; clicking toggles selection (click again to deselect); `CLASS_SPECS` table covers all 13 classes including Evoker (Devastation / Preservation / Augmentation)
- **Filter persistence:** selected class and difficulty are saved to `TomoModDB.loots.filterClass` / `.filterDiff` and restored on next `/tm loot` open; `filterClass = 0` encodes the explicit "Tous" choice
- **Per-panel filter bar removed:** difficulty row and class row that previously lived inside the right panel have been removed; item scroll frame now starts at `y = -30` (immediately below the instance name label), reclaiming ~60 px of vertical item display space
- **`AtlasIconStr(atlasName, size)`** helper — resolves atlas `leftTexCoord / rightTexCoord / topTexCoord / bottomTexCoord` into a full `|T file:h:w:0:0:texW:texH:l:r:t:b|t` pixel-accurate escape
- **`FileIconStr(fileDataID, size)`** helper — shorthand `|T fileDataID:h:w|t` for spec icons returned by `GetSpecializationInfoByID`

#### Database
- Added `filterClass = nil` and `filterDiff = 15` to `loots` defaults in `Core/Database.lua`

#### Loot Browser — Item Level Fix
- **BonusId-based item links**: items now display the correct item level in tooltips based on active difficulty — LFR=233, Normal=246, Héroïque=259, Mythique=272 (was always showing base ilvl 44)
- **`DIFF_BONUS_ID` table** maps each `difficultyID` to its Season 16 rank-1 bonusId (sourced from KeystoneLoot `upgrade_tracks.lua`)
- **`ItemLink(itemID, bonusId)`** helper builds `item:ID:0:0:0:0:0:0:0:0:0:0:0:1:BONUSID` hyperlinks; falls back to `item:ID` when no bonusId available
- **`DUNGEON_BONUS_ID = 12785`** — Champion track rank 1 (ilvl 246) applied to all M+ dungeon drops

#### Loot Browser — Class & Spec Filter Fix
- **`ItemClasses.lua`** — new file (`Modules/QOL/Loots/ItemClasses.lua`) with 347 entries mapping `itemID → { [classID] = { specID, ... } }`; auto-generated from KeystoneLoot `data/items.lua`; registered globally as `TomoMod_ItemClasses`
- **`ItemMatchesClass`** rewritten to use `TomoMod_ItemClasses`: items absent from the table are treated as universal (rings, necks, trinkets); items present must match classID and optionally specID — e.g., Evoker no longer sees glaives, Warriors no longer see wands
- **Load order**: `ItemClasses.lua` included in `QOL.xml` between `Data.lua` and `Loots.lua`

#### Loot Browser — Favorites Tab
- **New "Favoris" tab** added beside Donjons and Raids; tab label updates dynamically to "Favoris (N)" when N items are pinned
- **Pin indicator**: `pin_alert.tga` (16×16, OVERLAY, TOPRIGHT corner) displayed at full alpha when pinned, 35% alpha on hover, hidden otherwise — implemented as a plain texture on the main button to avoid nested-button click-capture issues
- **Left-click**: toggles favorite state (pin/unpin) and refreshes the tab label counter
- **Shift+click**: inserts the bonusId-encoded item hyperlink into the active chat edit box
- **Persistence**: saved to `TomoModDB.loots.favorites[itemID] = bonusId` across sessions; removed by clicking the item again

#### Loot Browser — Favorites Grouped by Source
- **Grouped display**: favorites rendered grouped by dungeon or raid source; each group is one horizontal row — source label on the left, item icons to the right
- **Source label** (170 px): "Donjon : Name" or "Raid : Name" in teal (`C.TEXT_ACC`); dungeon names via `C_ChallengeMode.GetMapUIInfo`, raid boss names via `EJ_GetEncounterInfo`
- **Vertical teal separator** (1 px) between label column and item grid; items wrap to additional rows if count exceeds `FAV_PER_ROW`
- **Sort order**: dungeons listed before raids; alphabetical within each type
- **Horizontal border** separates each source group
- **Reverse-lookup** built at render time from `TomoMod_LootsData.dungeons` and `.raidBosses`

#### Database
- Added `favorites = {}` to `loots` defaults in `Core/Database.lua`

## ####################################

## CHANGELOG 2.7.4

#### New "Skins" Config Category
- **New top-level sidebar category** added to the config panel with a dedicated teal diamond icon (`icon_skins.tga`)
- **7-tab panel** (`Config/Panels/Skins.lua`): Chat Frame, Bags, Objective Tracker, Character, Buffs, Game Menu, Mail
- Proxy tabs for existing skins delegate to their original builders; placeholder text shown for skins not yet implemented
- Category wired into `builderMap` and `categories` array in `ConfigUI.lua`

#### ChatFrameSkinV2 — Tabbed Chat Panel
- **New module** `Modules/QOL/Skins/ChatFrameSkinV2.lua` — full chat panel replacement with 4 tabs: General, Instance, Personal, Combat
- **Tab routing**: ~30 `CHAT_MSG_*` events intercepted and routed to the correct tab based on chat type (SAY/YELL → General, RAID/PARTY/INSTANCE → Instance, WHISPER/BN → Personal, etc.)
- **Pin indicators**: collapsed mode shows small dots per tab — dark gray idle (`pin_idle.tga`), teal alert (`pin_alert.tga`) for unread messages
- **Collapse/expand**: click header to toggle between full panel and compact pin-only strip
- **Edit box**: auto-targets the correct channel based on active tab (SAY, RAID/PARTY, GUILD)
- **Mover-compatible**: registers with `TomoMod_Movers` for drag positioning; position persisted to `TomoModDB.chatFrameSkinV2.position`
- **Config options**: enable/disable, width, height, scale, opacity, font size, default tab

#### BagSkin — Unified Bag Grid
- **New module** `Modules/QOL/Skins/BagSkin.lua` — replaces default bags with a single unified grid
- **Quality borders**: slot borders color-coded by item quality (Poor → Legendary) using `ITEM_QUALITY_COLORS`
- **Cooldown overlays**: `CooldownFrameTemplate` on each slot, updated on `BAG_UPDATE_COOLDOWN`
- **Quantity badges**: stack count shown bottom-right on stacked items
- **Search/filter bar**: live search dims non-matching items; Escape to clear
- **Sort button**: triggers `C_Container.SortBags()` with a 0.5s delayed grid refresh
- **Sort modes**: quality, name, type, recent (configurable in Skins panel)
- **Hooks**: `OpenAllBags`, `ToggleAllBags`, `CloseAllBags` intercepted to show/hide the custom frame
- **Auto-refresh**: listens to `BAG_UPDATE`, `BAG_UPDATE_DELAYED`, `ITEM_LOCK_CHANGED`, `BAG_UPDATE_COOLDOWN`
- **Mover-compatible**: draggable frame with position persistence + `TomoMod_Movers` registration
- **Config options**: enable/disable, unified mode, columns, slot size, slot spacing, scale, opacity, quality borders, cooldowns, quantity badges, search bar, sort mode

#### New Assets
- `Assets/Textures/pin_idle.tga` — 8×8 dark gray circle for idle tab pin
- `Assets/Textures/pin_alert.tga` — 8×8 teal circle for unread tab pin
- `Assets/Textures/icons/icon_skins.tga` — 22×22 teal diamond sidebar icon

#### Database Defaults
- Added `chatFrameSkinV2` defaults: enabled, width (480), height (280), scale (100), opacity (88), fontSize (13), defaultTab, position
- Added `bagSkin` defaults: enabled, unified, columns (12), slotSize (36), slotSpacing (3), scale (100), opacity (92), quality borders, cooldowns, quantity badges, search bar, sortMode

#### Locale
- **~50 new locale keys** added to `enUS.lua`: `cat_skins`, all `tab_skin_*`, `section_skin_*`, `info_skin_*`, `opt_skin_*` keys for Skins category, Chat Frame, and Bags config panels

#### Load Order
- `Config\Panels\Skins.lua` added to `TomoMod.toc` (before `Profiles.lua`)
- `Skins\ChatFrameSkinV2.lua` and `Skins\BagSkin.lua` added to `QOL.xml`

## ####################################

## CHANGELOG 2.7.1

#### TomoScore — Keystone Columns
- **Two new columns** added to the end-of-dungeon scoreboard between M+ Rating and Damage:
  - **Key Level** — displays each player's current keystone level (`+14`, `+11`, etc.) with color-coded tiers (green 5+, blue 7+, purple 10+, orange 12+), or `—` if no key
  - **Dungeon Name** — shows the abbreviated dungeon name of each player's keystone (e.g., "ARAK", "PSF", "SV"); displayed in **teal** if the teleport spell is known, **grey** if not
- **Click-to-teleport** — clicking a dungeon name casts the corresponding teleport spell (`CastSpellByID`); tooltip shows "Click to teleport" (green) or "Teleport not learned" (grey)
- **Data source**: keystone info pulled from **LibOpenRaid** (`GetAllKeystonesInfo` / `GetKeystoneInfo`) at dungeon completion; dungeon name and teleport spell resolved via `TomoMod_DataKeys`
- **Preview data** updated with sample keystones (4/5 players have keys, 1 without for `—` display)
- **Frame width** increased from 520px to 680px to accommodate the new columns
- **Locale keys** added: `ts_col_key_level` ("Key" / "Clé"), `ts_col_key_name` ("Dungeon" / "Nom des Clés") in enUS and frFR

#### ActionBar Skin — Taint & Boot Fixes
- **SetScaleBase taint fix** — `MultiBarBottomLeft:SetScaleBase()` is protected in Midnight 12.x; now checks `bf.SetScaleBase` existence and scales individual buttons instead of the parent frame when EditMode is detected
- **Boot sequence fix** — bars didn't fade out of combat and Shift-reveal didn't work after login; boot now calls `ApplyCombatShow()` and `SetShiftReveal(true)` after `SkinAllButtons()`
- **CombatShow logic fix** — bars set to 0% opacity with "combat only" enabled now correctly show at 100% in combat (was re-using barOpacity of 0%)
- **CombatShow conflict fix** — `ApplyAllOpacities()` (vehicle handler) and `SetShiftReveal` OnUpdate now both respect `combatShow` bars instead of overriding them

#### BuffSkin — Midnight Compatibility
- **Detection rewrite** — switched from `child.buttonInfo` to `IsShown() + GetTexture()` detection for buff/debuff buttons
- **Hooks** added for `BuffFrame:Update()` and `DebuffFrame:Update()` to re-skin after Blizzard updates
- **Symbol text** hidden via `button.Symbol:SetAlpha(0)`
- **Count & Duration** FontStrings set to `OVERLAY, 7` draw layer (above icon at `ARTWORK, 0`)

#### Font & Unicode — Texture Escapes
- **Replaced 6 Unicode symbols** that were missing from Poppins font with native WoW `|T...|t` texture escapes across all 6 locale files:
  - `←` → `UI-SpellbookIcon-PrevPage` (installer Previous button)
  - `→` → `UI-SpellbookIcon-NextPage` (installer Next/Finish/recap arrows)
  - `↺` → `UI-RefreshButton` (Reload UI button)
  - `▶` → `UI-SpellbookIcon-NextPage` (Sound preview button)
  - `⚡` → `UI-OptionsFrame-NewFeatureIcon` (Apply CVars button)
  - `✓` → `RAIDFRAME/ReadyCheck-Ready` (CVar success, Done check, import valid)
- **Em dash `—` and middle dot `·` preserved** — these glyphs exist in Poppins and render correctly

#### Localization — Config Panel i18n
- **31 hardcoded French strings** in 5 config panel files replaced with `L["key"]` references:
  - `Config/Panels/ActionBars.lua` (13 strings): style, opacity, bar select, combat-only, management, unlock, quick settings, tab labels
  - `Config/Panels/General.lua` (2 strings): relaunch installer button + info
  - `Config/Panels/Sound.lua` (1 string): preview section header
  - `Config/Panels/UFPreview.lua` (14 strings): header, unit names, spell names, labels, click-to-navigate tooltip
  - `Config/ConfigUI.lua` (1 string): footer hint
- **31 locale keys** added to all 6 languages (enUS, frFR, deDE, esES, itIT, ptBR) with proper translations

#### Bar Editor — Fixes
- **Backdrop restoration** fixed after cleanup
- **Positioning** — editor now opens to the right of the config panel

#### Widget & Layout Fixes
- **MythicPlus panel** — replaced TwoColumnRow slider pairs with full-width stacked sliders (slider controls need full width for drag precision)
- **UnitFrames panel** — fixed SectionHeader label overlap, preview right-side cutoff
- **TwoColumnRow** — changed column anchoring from `CENTER` to `TOP` for proper vertical alignment
- **Checkbox** — changed to 2-point anchoring `TOPLEFT`/`TOPRIGHT` for reliable width

##### #########

#### Installer — First-Run Setup Wizard (12 steps)
- **New file `Config/Installer.lua`** (946 lines) — guided wizard launched automatically on first startup; reopenable via `/tm install` or the button in General → Reset
- **Step 1 — Welcome**: animated logo, TomoMod description, 12-step overview
- **Step 2 — Profile**: editbox for naming your profile, "Create Profile" button calls `TomoMod_Profiles.CreateNamedProfile()` + `LoadNamedProfile()`, note about per-spec assignment
- **Step 3 — Visual Skins**: checkboxes for Game Menu, ActionBar, Buffs, Chat, Character + button style dropdown (Classic / Flat / Outlined / Glass)
- **Step 4 — Tank Mode**: tank mode nameplates, threat indicator and text on target, CoTank Tracker
- **Step 5 — Nameplates**: enable/disable, class colors, castbar, health text, auras, role icons, width slider
- **Step 6 — Action Bars**: skin enable, class color border, shift-reveal, global opacity slider applied to all bars simultaneously
- **Step 7 — LustSound**: enable, sound dropdown from `TomoMod_LustSound.soundRegistry`, channel dropdown, preview button
- **Step 8 — Mythic+**: M+ Tracker (enable/timer/forces/hide Blizzard) + TomoScore (enable/auto-show)
- **Step 9 — CVars**: list of 6 included optimizations, "Apply all CVars" button → `TomoMod_CVarOptimizer.ApplyAll()`, success indicator
- **Step 10 — QOL**: 8 toggles (auto-repair, fast loot, skip cinematics, hide talking head, auto-accept invites, tooltip IDs, combat text, hide Blizzard castbar)
- **Step 11 — SkyRide**: enable, width/height sliders, reset position button
- **Step 12 — Done**: slash command recap (`/tm`, `/tm sr`, `/tm install`), reminder that everything is editable in the GUI, "Reload UI" button (marks `installer.completed = true`)
- **Navigation**: progress dot bar (12 dots, active = teal/large, past = dim teal, future = grey), Previous/Next/Finish buttons, "Skip installation" link
- **Auto-open**: `PLAYER_LOGIN` + `C_Timer.After(1.5)` checks `TomoModDB.installer.completed`; if `false` → opens the installer
- **Fullscreen dimmer**: 60% black overlay behind the panel during installation

#### Integrations
- **`/tm install`** added to `Core/Init.lua` → `TomoMod_Installer.Show()`
- **`/tm help`**: added `/tm install — Relaunch the setup wizard` line
- **General panel**: "⚙ Relaunch Installer" button added to the General card, above the Reset button
- **`Core/Database.lua`**: added `installer = { completed = false, step = 1 }` to defaults

#### Localization
- **Full i18n for the Installer** — all 118 user-facing strings (step titles, descriptions, section headers, checkbox labels, button labels, navigation) use `L["ins_*"]` locale keys instead of hardcoded text
- **6 languages supported**: enUS (English), frFR (French), deDE (German), esES (Spanish), itIT (Italian), ptBR (Brazilian Portuguese)
- Installer text automatically matches the game client language

## ####################################

## CHANGELOG 2.7.0

#### Config GUI — Full Redesign
- **Panel enlarged to 1020×720** (was 840×620) — gives 810px of content width vs 670px previously, enabling two-column layouts throughout
- **Style icon-box navigation** — each sidebar category button now features a styled icon container with `BackdropTemplate` (dark bg + accent border on selection), left accent bar indicator, and smooth hover states; replaces the previous simple text+icon buttons
- **Gradient header wash** — subtle teal-tinted gradient under the title bar in the content area
- **Live performance footer** — FPS and memory usage sampled every 2 seconds via `C_Timer.NewTicker`, displayed bottom-right; ticker auto-stops when panel is hidden to avoid OnUpdate overhead
- **Close, Reload, Layout buttons** refined — new sizing, consistent hover states, tooltip on Reload

#### Config Widgets — Complete Overhaul
- **`CreateSectionHeader`** — now renders a tinted bg strip + 3px left accent bar + bold title; far more visually prominent than the old text+line version
- **`CreateSlider`** — added **filled track** (accent color fills left portion proportional to value) + right-aligned value badge in a framed box; visual state is always clear at a glance
- **`CreateCheckbox`** — box uses `BackdropTemplate` with accent-tinted bg and accent border when checked; clicking the label also toggles
- **`CreateButton`** — accent invert on hover (teal fill + dark text)
- **`CreateDropdown`** — accent border on open, accent highlight on item hover
- **`CreateColorPicker`** — swatch right-aligned, RGB values displayed inline
- **`CreateTabPanel`** — bottom indicator line on active tab, accent bg tint; no more top-flush style
- **`CreateCard()`** *(new)* — framed group container with optional title strip, left accent stripe, inner padding; used in MythicPlus and available for all panels
- **`CreateTwoColumnRow()`** *(new)* — splits available width into two equal columns for placing two widgets side by side
- **`CreateCheckboxPair()`** *(new)* — convenience wrapper for two checkboxes on one line
- **`CreateColorPickerPair()`** *(new)* — two color pickers side by side
- **`CreateButtonRow()`** *(new)* — horizontal row of multiple buttons with consistent spacing

#### Config Panels — Layout Improvements (all panels, no logic changes)
- **General** — minimap size/scale, cursor ring class-color/tooltip in 2-column pairs
- **Sound** — preview/stop buttons side by side; chat/debug checkboxes paired
- **Nameplates** — name/level, threat/class-color, tank/healer role icon checkboxes paired; 3 pairs total in Display section
- **UnitFrames** — frame width/health height paired; show name/level paired; class color/faction color paired; castbar width/height paired; castbar icon/timer paired; castbar color pickers paired; boss frame width/height paired; lock button now uses `CreateButtonRow`
- **CooldownResource** — CDM show-hotkeys/combat-alpha paired; combat+target alpha sliders side by side; custom overlay/swipe checkboxes paired; overlay/swipe color pickers paired; resource bar width/scale paired; primary/secondary bar height paired; all 21 resource color pickers rendered in 2-per-row grid
- **MythicPlus** — fully uses `CreateCard` containers + `CreateTwoColumnRow` throughout; timer/forces, bosses/hide-blizzard paired; scale/alpha sliders paired; action buttons in 2-col rows
- **QOL** — auto-quest accept/turnin paired; auto-accept-invite friends/guild paired

#### Action Bars — New `TomoBar` Management System (`ActionBars.lua`)
- **`TomoBar` class** wraps each of the 10 native Blizzard action bars (bar1–bar8, pet, stance) with per-bar settings management
- **Drag overlay** — red handle frame anchored above each bar (visible in unlock mode), draggable to reposition the Blizzard bar; right-click opens the per-bar **BarEditor**
- **BarEditor popup** — per-bar config: alpha slider, scale slider, fade toggle, fade-alpha slider, show hotkey, show macro, hotkey/macro font size; slides update live
- **Fade system** — `UIFrameFadeIn/Out` on bar + button hover with configurable resting alpha
- **`AB.LockAll()` / `AB.UnlockAll()`** — toggle all overlays; unlock button in ActionBars config panel
- **`TomoMod_ActionBars`** global exposes `Initialize`, `ApplyAll`, `GetBar`, `ShowBarEditor`, `LockAll`, `UnlockAll`

#### Action Bar Skin — Four Visual Styles (`ActionBarSkin.lua`)
- **`classic`** — original 9-slice rounded border (unchanged behavior)
- **`flat`** — dark bg + thin teal border via `CreateFlatBorder`
- **`outlined`** — 30% transparent bg + subdued 55% opacity flat border
- **`glass`** — semi-transparent blue-dark bg + outer glow layer + teal flat border
- **`ABS.Reskin()`** — clears and re-skins all buttons when style changes at runtime
- Style selector dropdown added to ActionBars panel → Skin tab

#### Database
- Added `actionBarSkin.skinStyle = "classic"` default
- `TomoModDB.actionBars.bars[id]` per-bar settings lazily initialized by `TomoBar:Create`

## ####################################

## CHANGELOG 2.6.0

#### UnitFrames — oUF Engine Migration
- **Replaced the custom UnitFrame engine with oUF** — TomoMod now uses the battle-tested oUF library as the foundation for all unit frames (player, target, focus, target-of-target, pet)
- **oUF bundled as a library** — added `Libs/oUF/` (43 files) and registered it via `X-oUF: TomoMod_oUF` in the TOC; the library is exposed as `_G["TomoMod_oUF"]` at load time without conflicts
- **Removed ~200 lines of manual event handling** — `RegisterUnitEvents()`, the dirty-flag batch system (`uf_dirtyHealth`, `uf_dirtyPower`, `uf_dirtyAbsorb`, `uf_dirtyAuras`), the `throttleFrame` OnUpdate for target-of-target, and all manual `RegisterUnitWatch()` calls are now handled by oUF internally
- **Style callback** — `StyleTomoMod(self, unit)` replaces `CreateUnitFrame()`: creates all sub-elements using the existing `UF_Elements` API and registers `Health.Override` / `Power.Override` so TomoMod's color logic and text formatting remain fully intact
- **oUF:DisableBlizzard(unit) called automatically** on every `oUF:Spawn()` — PlayerFrame, TargetFrame, FocusFrame, and PetFrame are hidden via oUF's `hiddenParent` technique; `HideBlizzardExtra()` handles castbars and `ActionBarActionEventsFrame` cast overlay separately
- **All existing Elements unchanged** — `Health.lua`, `Power.lua`, `Castbar.lua` (empowered stages, channel ticks, latency overlay), and `Auras.lua` required zero modifications; logic is preserved via `Override` callbacks
- **Full public API preserved** — `ToggleLock`, `RefreshUnit`, `RefreshAllUnits`, `TogglePlayerCastbarLock`, `RefreshThreatPreview`, and `IsLocked` all work identically; `UpdateAllElements` is now available on every frame for external use
- **Supplementary events** (threat, absorb, UNIT_AURA, raid icons, leader icons) are registered via a separate `RegisterSupplementaryEvents()` step after all frames are spawned, maintaining the same behavior as before with no new overhead

#### Nameplates — Hybrid oUF Approach
- **Replaced custom offscreen-parent technique with `oUF:DisableBlizzardNamePlate`** — the previous approach reparented UnitFrame children under a hidden frame; oUF's approach uses `hooksecurefunc(UnitFrame, "SetAlpha")` to permanently force `SetAlpha(0)`, which is more robust against Blizzard restoring visibility
- **Removed ~130 lines** — `npOffscreenParent`, `hookedUFs`, `storedParents`, `MoveToOffscreen()`, `RestoreFromOffscreen()`, `HideBlizzardFrame()`, and `RestoreBlizzardFrame()` are all gone
- **Added `HideBlizzardExtra()`** — lightweight replacement that masks residual regions on the base nameplate frame (role icon textures, `BuffFrame`) that `oUF:DisableBlizzardNamePlate` does not touch
- **WidgetContainer transfer** — `nameplate.UnitFrame.WidgetContainer` is now reparented to the custom plate with `SetIgnoreParentAlpha(true)`, ensuring TWW interaction icons (vendor, repair, quest) display correctly above TomoMod nameplates
- **SoftTargetFrame transfer** — `nameplate.UnitFrame.SoftTargetFrame` is reparented to the custom plate, restoring the soft-target ring indicator that was previously invisible
- **Full motor unchanged** — `CreatePlate()`, `UpdatePlate()`, `UpdateCastbar()`, the dirty-batch system, friendly mode, role icons, and all config remain untouched
- **Disable() note** — because `hooksecurefunc` cannot be unregistered, disabling TomoMod nameplates without `/reload` will leave Blizzard UnitFrames at alpha 0

## ####################################

## CHANGELOG 2.5.1

#### 12.x Secret Number Fixes
- **Aura duration (UnitFrames)**: Fixed "attempt to perform arithmetic on a secret number value" — `GetRemainingDuration()` now returns a secret number in TWW 11.1; replaced `math.floor(durObj:GetRemainingDuration() + 0.5)` with direct `SetFormattedText("%.0f", ...)` which passes the value to the C-side formatter without Lua arithmetic (affects initial setup, ticker debuffs, and ticker enemy buffs)
- **Aura duration (Nameplates)**: Same fix applied to all 3 duration display paths (initial aura setup, 0.5s aura ticker, 0.5s enemy buff ticker)
- **MythicHub**: Fixed "attempt to compare number with table" — `C_MythicPlus.GetSeasonBestForMap()` now returns an info table instead of two numbers; added `type(result)` check to handle both new table format and legacy number format

#### BuffSkin — Visual Improvements
- **Teal border**: All buff and debuff icons now display a teal border (addon accent color `0.047, 0.824, 0.624`) instead of black (buffs) / dark red (debuffs); debuffs retain red glow to distinguish them
- **Fixed dark overlay on icons**: Removed Blizzard circular mask (`SetMask("")`, `IconMask:Hide()`, `CircleMask:Hide()`), hidden `IconOverlay` and `Highlight` overlays that were darkening the icon textures; also checks `IconBorder` in addition to `Border`

#### Slash Commands
- **`/rl`**: New shortcut to reload the UI (`ReloadUI`)
- **`/kb`**: New shortcut to open the Blizzard keybinding panel (`Settings.OpenToCategory`)

#### Login Message
- Added a red-colored message at login prompting users to report issues on CurseForge
- Fully localized: enUS, frFR, deDE, esES, itIT, ptBR

## ####################################

## CHANGELOG 2.5.0 - Fix

#### Performance Optimization Pass — CPU & RAM
- **CursorRing**: Added 60fps throttle to OnUpdate — prevents redundant `GetCursorPosition()` + math at 120+fps
- **CooldownManager**: Replaced continuous OnUpdate accumulator with `C_Timer.NewTicker` — eliminates per-frame Lua callback overhead
- **SkyRide**: Ticker now early-exits when grounded + locked (single `IsFlying` check, skips all heavy UpdateSpeed/Vigor/Wind work); also caches speed text to skip redundant `SetText` + string concatenation
- **ClassReminder**: Replaced OnUpdate (60fps callback for 1s poll) with `C_Timer.NewTicker(1.0)` — eliminates 59 wasted frames per second
- **ChatFrameSkin**: Replaced OnUpdate accumulator (2s poll) with `C_Timer.NewTicker(2)` — same result, no per-frame callback
- **CoTankTracker**: Replaced dual OnUpdate accumulators (0.1s health + 0.5s auras) with `C_Timer.NewTicker` — synced with Show/Hide lifecycle
- **Nameplates aura duration**: Added integer cache on all aura/buff duration text — skips `SetFormattedText` when displayed value hasn't changed (affects initial update, 0.5s ticker, and enemy buff processor)
- **Nameplates castbar**: Added tenths-precision cache on timer text — skips `SetFormattedText` when 1-decimal display unchanged
- **UnitFrames castbar**: Same tenths-precision cache on timer text
- **UnitFrames aura duration**: Added integer cache in 0.5s ticker — same pattern as Nameplates
- **Movers grid overlay**: Reduced cursor flashlight from ~33fps to ~20fps (visual glow effect, imperceptible difference)

#### MythicTracker — Timer & Forces Fix
- **Fixed timer stuck at 0:00**: `select(2, GetWorldElapsedTime(...) or 0, 0)` always returned the literal `0` because `or` truncated multiple return values before `select` could pick the second one — replaced with `select(2, GetWorldElapsedTime(1))` (elapsed time is the 2nd return value)
- **Fixed forces bar stuck at 0%**: Switched from unreliable `cr.quantity` to parsing `cr.quantityString:match("%d+")` (matches WarpDeplete's approach — the field contains a raw number with a `%` sign)
- **Fixed frame not showing**: Removed `CRITERIA_UPDATE` event registration — this event fires before the frame is built, causing a nil-access crash on `self.Frame.BossRows` that killed the entire OnEvent handler
- **Forces & deaths now update in real-time**: Ticker (0.25s) now also calls `UpdateForcesBar()` and `UpdateHeader()` instead of only `UpdateTimerBar()`
- Added `TMT.Frame` nil guards in ticker and event handler to prevent crashes during early loading

#### LustSound — Rewrite with Dual Detection & Force-Sound
- **Instant detection**: Added `UNIT_SPELLCAST_SUCCEEDED` event listener with 17 Bloodlust spell IDs (all class lusts, drums, and pet abilities from PedroBL) — sound now triggers with zero delay instead of waiting up to 0.5s for the next poll tick
- **Sated polling kept as fallback**: The existing Sated/Exhaustion debuff polling (0.5s interval) remains active to catch any spell the ID list might miss, and handles the "lust ended" transition
- **Force-sound when muted**: New CVar override logic saves and restores `Sound_MasterVolume` and `Sound_EnableAllSound` — the alert now plays even if the game audio is muted (toggle in config, enabled by default)
- **6 new sounds**: Added Pedro Classic, Golden Kpop, Spinning Cat, Shika Lust, Chipi Chapa, and ShakyMutt to the sound registry (9 total choices)
- New config checkbox: "Force sound even if game is muted"
- Full localization for new option (enUS/frFR, deDE, esES, itIT, ptBR)

## ####################################

## CHANGELOG 2.5.0

#### Performance & Stability Audit
- **Nameplates**: Replaced per-unit `CreateFrame()` with a frame pool — eliminates GC pressure in raids (40+ frames no longer created/destroyed per pull)
- **Nameplates**: Simplified `SetAlpha` hook to check `GetAlpha() > 0` instead of recursive lock pattern
- **Movers**: Added ~33fps throttle to grid overlay OnUpdate (was running unthrottled every frame with heavy math)
- **CursorRing**: Removed `ClearAllPoints()` on GameTooltip anchor hook — `SetPoint` now replaces the anchor in-place, avoiding layout invalidation
- **ProfessionHelper**: Added debounce flags on `BAG_UPDATE` and `GET_ITEM_INFO_RECEIVED` to prevent timer accumulation during rapid bag activity
- **ResourceBars**: Guarded `UnitPowerMax()` returning 0 in UpdatePrimaryBar, UpdatePoints, and UpdateDruidMana (prevents undefined statusbar behavior)
- **Power.lua**: Guarded `UnitPowerType()` nil return (fallback to 0) and `UnitPowerMax()` zero guard

#### Taint Fixes
- **ObjectiveTracker**: Added `InCombatLockdown()` guard before modifying ObjectiveTrackerFrame header regions/children (protected frame in retail)
- **HideTalkingHead**: Replaced `SetScript("OnShow")` override with `HookScript` + `InCombatLockdown()` guard + double-apply prevention flag
- **UnitFrame**: Added `InCombatLockdown()` guard on `SetAttribute`/`RegisterUnitWatch` during lock toggle
- **BossFrames**: Same combat lockdown guard on `SetAttribute`/`RegisterUnitWatch` during lock toggle
- **HideCastBar**: Guarded `PlayerCastingBarFrame:UnregisterAllEvents()` with `InCombatLockdown()` check

#### Lua Error Prevention
- **Keystone**: Added nil guard on `C_Item.GetItemInfoInstant()` before `select(6, ...)` — prevents crash when item data is not yet cached
- **WorldQuestTab**: Added nil guard on `C_Item.GetItemInfo()` and `C_Item.GetItemInfoInstant()` return values
- **AutoVendorRepair**: Cleaner destructuring of `GetItemInfo()` return for vendor price

#### Dungeon Scoreboard
- Scoreboard now only triggers on `CHALLENGE_MODE_COMPLETED` (Mythic+ only) — removed Mythic 0 auto-show
- Removed M0 boss tracking events (`ENCOUNTER_END`, `SCENARIO_CRITERIA_UPDATE`, `SCENARIO_COMPLETED`)
- Removed M0 helper functions (`_UpdateBossCount`, `_UpdateBossProgress`, `_CheckM0Completion`)
- Removed `autoShowM0` setting, config checkbox, and locale strings (enUS, frFR)

#### GameMenuSkin — Improved Escape Menu Skin
- Rewrote button texture stripping with recursive `NukeTextures()` that destroys all nested Blizzard sub-elements (NineSlice, Left/Right/Middle, Border, TopLeft/TopRight, etc.)
- Added `LockoutTextures()` hooks on SetNormalTexture/SetHighlightTexture/SetPushedTexture/SetDisabledTexture to prevent Blizzard from re-applying textures after skinning
- Buttons without a name are now also skinned (removed `GetName()` filter on child iteration)
- Added OnMouseDown/OnMouseUp pressed state with deeper teal overlay
- Added subtle left accent bar on hover (2px teal indicator)
- Frame border now uses teal tint instead of grey
- PortraitContainer and TitleText explicitly handled
- Font strings forced to OVERLAY layer 7 to render above all custom textures

#### Nameplates — Friendly Name-Only Mode (New Feature)
- Friendly units (reaction >= 5) now display only their colored name — no health bar, absorb, auras, castbar, threat, classification, or level text
- Player names colored by class color, NPC names use the friendly green color
- Nameplate anchored to plate center instead of health bar top
- Glow frame, target arrows, and mouseover highlight disabled for friendly plates in `OnTargetChanged_Deferred` and `UPDATE_MOUSEOVER_UNIT` handlers
- Castbar blocked for friendly units when name-only mode is active
- Plates automatically restore full mode if unit reaction changes (e.g. mind control)
- New setting: `friendlyNameOnly` (enabled by default)
- Config checkbox: "Friendly: name only (no health bar)"
- Full localization (enUS, frFR, deDE, esES, itIT, ptBR)

#### Nameplates — Friendly Role Icons in Dungeons/Delves (New Feature)
- Role icons (Tank shield, Healer cross, DPS axes) displayed above friendly player names in dungeons (all modes) and delves
- Uses custom TGA textures with circular dark background (`Circle128x128.tga`)
- Icons colored by player class color, with role-based fallback colors (blue/green/red)
- Instance detection via `InDungeonOrDelve()` checking for `party` and `scenario` instance types
- Raid markers automatically repositioned above the role icon when both are present
- Role icon frame created lazily on first use (`EnsureRoleIcon`) and resized dynamically
- Per-role visibility filters: show/hide Tank, Healer, and DPS icons independently
- Configurable icon size via slider (16–60px, default 32)
- New settings: `friendlyRoleIcons`, `roleIconSize`, `roleShowTank`, `roleShowHealer`, `roleShowDps`
- Cleanup on `OnNamePlateRemoved` and `RAID_TARGET_UPDATE` respects friendly positioning
- Full localization (enUS, frFR, deDE, esES, itIT, ptBR)

#### GameMenuSkin — Escape Menu Skin (Skins Category)
- New skin module for the Blizzard Game Menu (Escape menu)
- Dark background with TomoMod teal accent strip at top
- All menu buttons restyled: dark flat background, subtle border, Poppins font
- Hover effect: teal highlight border and teal text color matching the addon theme
- Strips Blizzard NineSlice chrome and default button textures for a clean modern look
- OnShow hook catches buttons injected by other addons and skins them dynamically
- Config toggle in QOL > Skins tab (requires /reload to revert)
- Full localization (enUS, frFR, deDE, esES, itIT, ptBR)

#### BuffSkin — Buff/Debuff Icon Skin (Skins Category)
- New skin module for Blizzard buff/debuff icons in the top-right corner
- Replaces default borders with rounded 9-slice borders using the Nameplate `border.png` texture for a consistent TomoMod look
- Optional ADD-blend glow effect (`background.png`) — red for debuffs, teal (addon accent) for buffs when enabled
- Dark background behind icons and cropped icon edges (`SetTexCoord 0.07–0.93`) for a clean, modern appearance
- Hides default Blizzard aura borders automatically
- Applies Poppins font to duration and stack count text with configurable font size
- Option to completely hide the Buff Frame and/or Debuff Frame (taint-safe, deferred via `C_Timer.After`)
- Skinning can be toggled independently for buffs and debuffs
- Hooks into `BuffFrame.Update`, `DebuffFrame.Update`, `AuraContainer.Update`, and `UNIT_AURA` event with 150ms debounce for performance
- All hooks use `C_Timer.After(0)` deferral to avoid taint in the Midnight (12.0+) taint model
- Config panel integrated into QOL > Skins tab with enable, per-type toggles, glow toggle, hide frame options, and font size slider
- Full localization (enUS, frFR, deDE, esES, itIT, ptBR)

#### MythicHub — Mythic+ Overview Panel (Mythic+ Category)
- Custom Mythic+ Hub panel replacing the default Great Vault shortcut on CharacterFrame
- Overall M+ rating displayed prominently at top with tier-based coloring
- Season dungeon table: icon, name, key level, rating, and best time for each dungeon
- Clickable dungeon icons to cast teleport spell (if learned) directly from the panel
- Fortified/Tyrannical best scores shown per dungeon via `C_MythicPlus.GetSeasonBestAffixScoreInfoForMap()`
- Great Vault section with 9 slots (3×3 grid): Dungeons, Raids, World activities
- Vault slots show reward status (locked/unlocked/completed) with item level tooltips via `C_WeeklyRewards` API
- Dark/teal themed UI consistent with TomoMod aesthetic
- Anchored to CharacterFrame, toggled via the M+ score widget click
- Slash commands: `/tm mhub` or `/tm mythichub`
- Full localization (enUS + frFR)

#### TomoScore — Dungeon Scoreboard (Mythic+ Category)
- End-of-dungeon scoreboard showing damage, healing, interrupts and M+ rating for all group members
- Uses the Midnight `C_DamageMeter` API for data collection (no CLEU parsing)
- Auto-shows after Mythic+ completion (`CHALLENGE_MODE_COMPLETED`) and Mythic 0 last boss kill (via scenario tracking)
- Dark/teal themed UI matching TomoMod's aesthetic: accent strip, proportional stat bars, role-based bar colors
- Supports up to 40 players (raid-safe), sorted by role (Tank → Healer → DPS) then by damage
- Rating color tiers: orange (2500+), teal (2000+), blue (1500+), green (1000+), grey (below)
- Footer row with group totals and average M+ rating
- Draggable frame with saved position, scale, and opacity
- Config panel integrated into the Mythic+ category: enable/disable, auto-show toggles (M+ and M0 separately), scale/alpha sliders, preview, show last run, reset position
- Slash commands: `/tm score` (preview), `/tm score last` (show last run)
- Saves last run data to `TomoModDB.TomoScore.lastRun` for recall after logout
- Full localization (enUS + frFR)

#### Mythic+ Tracker — Config GUI Integration
- Integrated the Mythic+ Tracker settings into TomoMod's main Config panel as a new "Mythic Plus" category with a dedicated sidebar icon
- Full config panel with Enable/Display/Frame/Actions sections: toggle tracker, show/hide timer, forces, bosses, Blizzard overlay, lock frame, scale/alpha sliders, preview and reset position buttons
- `/tmt` slash command now opens the integrated Config GUI at the Mythic Plus category instead of the standalone config panel

#### Mythic+ Tracker — Movers/Layout Integration
- Registered MythicTracker in the Movers/Layout system so the frame can be positioned via `/tm unlock`
- Unlock shows a preview of the tracker frame; lock hides it when not in an active M+ dungeon

## ####################################

## CHANGELOG 2.4.4

#### Performance & GC Pressure Optimizations
- **CooldownManager**: Pre-allocate reusable tables (`_cdm_visible`, `_cdm_buffVisible`, `_cdm_positions`) at module scope with `wipe()` instead of creating new tables every layout pass — eliminates ~30-60 ephemeral tables/sec in combat
- **CooldownManager LayoutEngine**: Pre-allocate `_le_offsets` and `_le_rows` (with sub-table reuse) — eliminates ~16 table allocs per layout flush
- **CoTankTracker**: Pre-allocate `_ctk_wantedSet` and `_ctk_found` tables, hoist sort comparator `SortBySpellId` — eliminates 3 allocs × 2/sec in combat
- **ClassReminder**: Pre-allocate `_cr_missing` table with `wipe()` instead of allocating in `CheckMissing()` every tick
- **Castbar**: Use `wipe(self._stageBoundaries)` instead of `= {}` for empowered casts; write stage data directly in-place instead of intermediate local table
- **InfoPanel**: Replace per-frame `OnUpdate` throttle with `C_Timer.NewTicker(1, ...)` — eliminates ~60-144 unnecessary calls/sec
- **ProfessionHelper**: Hoist sort closure to named module-scope function `SortItemsByQualityName`
- **Nameplates**: Add safety cap (200 entries) on `questIconCache` to prevent unbounded growth in open world
- Replace `table.insert(t, v)` with `t[#t + 1] = v` across hot paths (ClassReminder, ProfessionHelper, WorldQuestTab, CharacterSkin, MythicKeys)

#### Chat Frame Skin — Redesign (QOL — Skins)
- Complete visual overhaul matching the ObjectiveTracker panel style
- Dark wrapper frame per chat window with 1px borders and teal accent line
- Tab header bar with dark background and accent underline (like OT header)
- Tabs: inactive grey text, active white text, teal accent underline on selected tab, teal hover highlight
- Styled editbox with dark background and vertical teal accent bar on the left
- Status line (bottom-right) showing message count and fade timer (e.g. "500 lines | 24s + 8s fade")
- Periodic status updater (every 2s) keeps line count and fade info current
- Hook on `FCF_DockUpdate` to resync skin positions when chat frames move
- Visibility sync: skin frames show/hide with their parent chat frame

#### Mythic+ Score Widget (Character Skin)
- Displays the player's overall Mythic+ dungeon score in the top-left corner of the Character Frame
- Dark panel styled to match ObjectiveTracker (dark background, 1px borders, accent line)
- Score color dynamically adapts based on rating tier: orange (2500+), purple (2000+), blue (1500+), green (1000+), white (500+), grey (below 500)
- Accent line color matches the score tier
- Click to open/close the Great Vault (Weekly Rewards); auto-loads the Blizzard addon if needed
- Tooltip on hover with score and "Click to open Great Vault" hint
- Updates on Character Frame open, `CHALLENGE_MODE_COMPLETED`, and `PLAYER_ENTERING_WORLD`

## ####################################

## CHANGELOG 2.4.3

#### Class Reminder (QOL)
- Displays missing class buffs and auras on screen with a pulsing animation
- Per-class tracked buffs: Priest (Fortitude), Mage (Arcane Intellect), Shaman (Skyfury), Druid (Mark of the Wild + form tracking), Warrior (Battle Shout + stance), Paladin (Aura tracking), Evoker (Blessing of Bronze)
- Configurable scale, text color, and X/Y offset

#### CoTankTracker (QOL)
- Monitors co-tank health, debuffs, and defensive cooldowns in raids
- Health bar with click-to-target, active debuff display with duration timers, defensive cooldown status (grayed out when on CD)
- Supports up to 8 debuffs and 6 defensive CDs
- Auto-detects the other raid tank; only visible in raids when player is tank role
- Per-class defensive cooldown sets (Blood DK, Demon Hunter, Druid, Evoker, Monk, Paladin, Warrior, Shaman)

#### Hide Blizzard Castbar (QOL — Automations)
- Completely hides the default player casting bar frame
- Complements UnitFrames' built-in player castbar
- Toggle in Config > QOL > Automations

#### TooltipIDs — TWW Compatibility Upgrade
- Added support for TWW "secret values" across all tooltips
- Improved tooltip hook system using `TooltipDataProcessor` for spell/item/unit tooltips
- New tooltip types: achievements, currencies, auras (`SetUnitBuffByAuraInstanceID` / `SetUnitDebuffByAuraInstanceID`)
- Deferred `Show()` calls to prevent FontString metrics tainting
- Duplicate ID prevention on tooltip refresh

#### ResourceBars — New Class/Spec Support
- Demon Hunter Devourer: aura-based Soul Fragments bar with talent detection
- Shaman Enhancement: Maelstrom Weapon aura stack display (adaptive max from talents)
- Hunter Survival: Tip of the Spear tracking
- Improved Druid form detection and adaptive resource display

#### LevelingBar — Session XP Tracking
- Added session XP tracking to calculate XP/hour
- Rested XP shown as a separate overlay bar with different color
- Displays 5 text elements: Level, XP current/max, percentage, XP/hour, Rested %
- Number formatting with thousand separators
- Animated progress bars with smooth color transitions
- Session tracking resets on level-up

#### CooldownManager — New Customization Options
- Custom overlay color for active auras
- Custom swipe color and opacity slider for cooldown animation
- Utility icon dimming when off cooldown
- Per-module on/off toggle for each feature

#### FastLoot — Behavior Refinement
- Throttle system (0.2s) prevents double-triggering
- Respects CVar `autoLootDefault` + `AUTOLOOTTOGGLE` modifier (XOR logic)
- Cursor item detection prevents conflicts with other addons (TSM/Destroy compat)

#### AutoVendorRepair — Improved Implementation
- Ticker-based gray item selling (0.15s intervals) prevents lag spikes
- Dynamic price calculation per stack
- Colored gold amounts in chat messages

#### CursorRing — Performance Optimization
- Only calls `SetPoint` when cursor position actually changes (pixel-level snapping)
- Reduces sub-pixel jitter with `math.floor` rounding
- Tooltip anchoring optimized with early-exit when disabled

#### FrameAnchors — Enhanced Visual Design
- Added teal accent line at top of anchor frame
- Improved label positioning and 1px black border backdrop

#### Profiles — Migration & Cleanup
- Automatic migration from old `specs = { [specID] = snapshot }` format
- Cleanup of legacy "Spec-NNN" profiles from previous versions
- Performance flag prevents redundant initialization work

#### ConfigUI — Enhanced Title Bar
- Added Layout button (⊹) with icon and tooltip
- Reload UI button (↺) with hover effects
- Active state indicator for Layout mode
- Version display updated to v2.4.3

#### Config Panel — New Automations Tab (QOL)
- Consolidated automation settings: HideCastBar, AutoAcceptInvite, AutoSkipRole, AutoSummon, AutoFillDelete, CombatText
- Per-automation enable toggles and fine-tuning options

#### Widgets — UI Polish
- Custom scrollbar with hover feedback and smooth thumb dragging
- Improved visual theme consistency

### Bug Fixes
- Fixed TooltipIDs crash on TWW secret number operations
- Fixed TooltipIDs tooltip layout invalidation causing metrics corruption
- Fixed CursorRing excessive OnUpdate calls causing performance loss
- Fixed FastLoot auto-loot not respecting modifier keys correctly
- Fixed LevelingBar XP session not resetting on level-up
- Fixed LevelingBar max-level detection for Shadowlands+ expansions
- Fixed ConfigUI icon rendering for title bar buttons (now uses texture icons)

## ####################################

## CHANGELOG 2.4.2

### Profession Helper (New QOL Module)
- New batch processing tool for Disenchant
- Visual UI with 1 tabs
- Automatically scans bags for eligible items matching your professions
- Quality filters for Disenchant (Uncommon, Rare, Epic)
- Item list showing name, icon, quality color stripe, item level / processable count
- Process button using SecureActionButtonTemplate — click repeatedly to process each item
- Stop button to cancel at any time
- Slash commands: `/tm prof` or `/tm ph` to open
- Config panel under QOL > Professions with enable toggle, quality filters, and open button

### Nameplates — Raid Marker Positioning
- New config section "Raid Marker" in Nameplates > General tab
- Dropdown to choose raid icon anchor point (Top, TopLeft, TopRight, Bottom, BottomLeft, BottomRight, Left, Right, Center)
- X and Y offset sliders (-50 to +50) for fine-tuning position
- Icon size slider (10 to 60)
- Changes apply in real-time to all active nameplates

## ####################################

## CHANGELOG 2.4.1

### World Quest Tab (New Module)
- New side panel attached to the World Map displaying all available World Quests
- Toggle button ("WQ List") on the top-right of the World Map
- Sortable columns: Name, Zone, Reward, Time remaining (click headers to sort asc/desc)
- Detailed reward classification: Gold, Gear (with ilvl), Reputation, Currency, Anima, Pet, Other
- Color-coded quality indicator per quest (Common / Rare / Epic)
- Elite quest marker (★)
- Tooltip on hover with full details: zone, faction, reward, time left, elite status, quest ID
- Click a row to navigate to the quest's zone on the map
- Shift-Click to super-track the quest
- Scans child zones automatically for full continent coverage
- Auto-refresh on map zone change + 60-second timer update for time remaining

### Config Panel (QOL > World Quests)
- Enable / Disable toggle
- Auto-show panel when opening the World Map
- Max quests shown slider (0 = unlimited)
- Minimum time remaining filter (in minutes)
- 7 individual reward type filters (Gold, Gear, Reputation, Currency, Anima, Pet, Other)

## ####################################

## CHANGELOG 2.3.0

### Systeme Layout Unified (Movers)
- New centralized system for moving all UI elements
- Layout button in the Config panel title bar
- The command `/tm layout` (alias `/tm l`) to enable/disable Layout mode
- Floating header bar in Layout mode with Lock and Reload UI buttons
- Replaces all separate commands: `/tm uf`, `/tm sr`, `/tm rb` now unlock via the unified system (backward compatible)
- All elements unlocked in a single action: UnitFrames, BossFrames, ResourceBars, SkyRide, LevelingBar, FrameAnchors, CoTankTracker
- RL (Reload UI) button added to the Config title bar for quick reloading
- Animated transition, grid overlay

### Ameliorations internes
- Added `IsLocked()` to all mobile modules (UnitFrames, BossFrames, ResourceBars, LevelingBar)
- Improved synchronization between layout mode and the actual state of modules 

## ####################################

## CHANGELOG 2.2.8

- Fix Absent enchant
- Fix Buffs on Target
- Fix Tooltip ID
- Fix Widget drag

## ####################################

## CHANGELOG 2.2.4

- Fix MythicKeys and Delete Tp

## ####################################

## CHANGELOG 2.2.3

- Add New Minimap and InfoPanel
- XP Bar config in /tm and lock unlock /tm sr

## ####################################

## CHANGELOG 2.2.2

- FIX ERROR BOOS FRAME

## ####################################

## CHANGELOG 2.2.1

- Fiche Personnage + Inspect
- Quest icon on NamesPlates
- Fix error on LustSound

## ####################################

## CHANGELOG 2.2.0

- Add QOL ToolTip Skin config in /tm
- Add Skin on Quest config in /tm
- Fix Error UnitFrame throttle
- Fix Error Aura NamesPlates
- Fix error UnitAura in LustSound

## ####################################

## CHANGELOG 2.1.17

- Fix Update on Castbar and Namesplates
- Fix Profiles.lua: Import/Export DeSerialize
- Fix UnitFrame.lua: ToT permanent throttle
- Fix BossFrames.lua: C_Timer.After(0) by redundant event
- Fix Nameplates.lua: Events prematurely registered to the file scope

## ####################################

## CHANGELOG 2.1.16

- FIX Empower Bar

## ####################################

## CHANGELOG 2.1.15

- FIX MAJEUR CastBar For Evocater now OK
- Add Blood Lust Sound

## ####################################

## CHANGELOG 2.1.13

- BIG FIX PERFORMANCE in RAID and DUGEON on NamesPlates
- Fix new Update on UnitFrames

## ####################################

## CHANGELOG 2.1.12

- Add Bar Boss 1 to 5
- Fix error lua multiples

## ####################################

## CHANGELOG 2.1.11

- Fix error log 2.1.10
- Fix error slashcommand
- Add inCombat option Per-actionbar
- Fix Tp in /tm key

## ####################################

## CHANGELOG 2.1.10

- Fix Ids in Combat
- Add Datakey for key in /tm key
- Add Tp in /tm key
- Add Skin Action Bar + Overlay
- Add Border Rework on all icons

## ####################################

## CHANGELOG 2.1.9

- Add QOL Id on ToolTips with Spells & Items
- Add QOL AutoSkipRole
- Rewrite MythicKeys

## ####################################

## CHANGELOG 2.1.8

- NamesPlates Upgrade
- NamesPlates Better Visual change Border and Gloss
- NamesPlates Better color by Types for DPS and Tank
- NamesPlates Tracks Buff and Debuff, change positioning.
- Target Frame Better color by type like NamesPlates
- Truncate on Target and Tot for Name too long
- Save Positioning CastBar Player and Target
- Border Modification in CooldownManager

## ####################################

## CHANGELOG 2.1.7

- GUI Upgarde For Unitframes
    add Font choices
    Fix Size Font
- GUI Upgarde For NamesPlates
    add New Tab
- GUI Upgarde For CD & Ressources
    add New Tab
- GUI Upgarde For Profils
    add editbox create Profil Name
    Fix in Import/export

## ####################################

## CHANGELOG 2.1.6

- Fix Soul fragment bar Devourer
- Fix AutoFill Delete
- Fix CooldownManager Overlay bug on Two Class
- Add Auras buffs purgeable/spellstealable, on Target and NamesPlates
- fix bug Position ToT and Pet.

## ####################################
Note Dev : /run for k,v in pairs(_G) do if type(v)=="string" and v:find("texte du message") then print(k,v) end end
## ####################################

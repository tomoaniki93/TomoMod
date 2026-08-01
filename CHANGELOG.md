## ####################################

## CHANGELOG 3.3.0 — Delves Visible Again, CooldownForge Reads Your Resources, Supercharged Combo Points & Color Picker Fixes

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
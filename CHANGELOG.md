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
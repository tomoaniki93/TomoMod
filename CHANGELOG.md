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
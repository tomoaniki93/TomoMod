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
# ![TomoMod](https://img.shields.io/badge/TomoMod-v2.9.8-0cd29f?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120005-orange?style=for-the-badge)

# **TomoMod — Complete UI Replacement for WoW**

> **One addon. Zero bloat. Your entire interface — reimagined.**

Tired of juggling 15 addons to get a clean UI? **TomoMod** replaces Blizzard's default interface with a dark, modern, teal-accented design — **UnitFrames, Nameplates, Action Bars, Bags, Chat, Tooltips, Objective Tracker**, and **25+ quality-of-life modules**, all configurable from a single panel.

Built from the ground up for **Midnight 12.x** with native handling of Blizzard's secret values. Lightweight, taint-free, and optimized for high-end raiding and Mythic+.

**Author:** TomoAniki  
**CurseForge Project ID:** 1446255

---

## 📥 Getting Started

1. Download the latest release from CurseForge
2. Extract the `TomoMod` folder into `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or type `/reload`
4. **First launch:** a 12-step setup wizard walks you through every module — pick your skins, enable your features, and you're done
5. Type `/tm` anytime to open the full configuration panel

---

## 🖼️ What You Get Out of the Box

| Category | Modules |
|----------|---------|
| **Frames** | UnitFrames (oUF), Party Frames, Nameplates, Resource Bars, Aura Tracker, Cooldown Manager |
| **Castbars** | Standalone castbars for all units — spark animations, channel ticks, empowered casts, GCD spark |
| **Action Bars** | 4 skin styles, per-bar fade, display conditions, click-through |
| **Skins** | Chat, Bags, Tooltips, Buffs/Debuffs, Game Menu, Character Frame, Objective Tracker |
| **Mythic+** | M+ Tracker, Dungeon Scoreboard, MythicHub, Group Keys, Teleportation |
| **Navigation** | Waypoint system, World Quest browser, Loot Browser |
| **QOL** | 25+ automation & utility modules |
| **Profiles** | Named profiles, per-spec assignment, import/export |

---

## ✨ Core Modules

### 🎯 UnitFrames — *Powered by oUF*

Full replacement for Blizzard's unit frames with a clean, minimal aesthetic built on the battle-tested **oUF** library.

- **Supported units:** Player, Target, Target-of-Target, Pet, Focus, Boss 1–5
- **Health bars** with class colors, faction colors, absorb shields overlay, and centered percentage text
- **Info bar** below the health bar — power value (left) + total HP (right) with a thin 2px power accent bar
- **Power bars** with accurate power type coloring
- **Non-interruptible indicator** — secret-safe grey overlay
- **Auras** (buffs/debuffs) with duration timers, stack counts, and configurable grow direction
- **Threat glow** on target frame
- **Raid icons** and **Leader/Assistant icons** with configurable offsets
- **Tooltip on hover** — standard GameTooltip on player and target frames
- **Health text formats:** current, percent, current+percent, current/max, deficit
- **Drag-to-move** via Layout Mode — unlock all frames, reposition freely, lock again
- **Per-unit configuration** — enable/disable, dimensions, offsets for each element

### 👥 Party Frames

Secure party frames for up to 4 members with full M+ integration.

- **SecureUnitButtonTemplate** — proper left-click target, right-click toggle menu
- **Health bar** with class color, green, or gradient modes — absorb overlay and heal prediction
- **Power bar** — healer-only visibility, configurable height with live-refresh slider
- **Name text** — centered, truncatable with configurable max letters (0 = no limit, ellipsis when truncated)
- **Role icon** (Tank/Healer/DPS) with configurable size
- **Dispel highlight** — border glows by debuff type (Magic, Curse, Disease, Poison)
- **HoT tracking** — class-colored icon indicators for healer HoTs (Priest, Druid, Paladin, Shaman, Monk, Evoker)
- **Interrupt CD tracker** — always-visible icon per party member showing their kick spell; teal border when ready, desaturated + red border + swipe when on cooldown
- **Battle Rez CD tracker** — same always-visible pattern for brez classes (DK, Druid, Paladin, Warlock)
- **Range check** — out-of-range members fade to configurable opacity
- **Role sorting** — optional Tank > Healer > DPS sort order
- **Growth direction** — Down, Up, Right, Left layout with auto-adapting mover
- **Arena enemy frames** (1–3) with PvP trinket cooldown and spec icon tracking
- **4-tab config** — General, Features, Cooldowns, Arena

### 🎯 Standalone Castbars

Full castbar system for all units — Player, Target, Focus, Pet, Boss 1–5.

- **4 spark animation styles:** Comet, Pulse, Helix, Glitch with configurable colors
- **Class color casting** — optional class-colored bars
- **Channel tick markers** — automatic ticks for channeled spells
- **Empowered cast support** — stage markers and progressive overlays for Evoker
- **Interrupt feedback** — on-screen text when you successfully interrupt
- **Latency indicator** — network delay overlay on the player castbar
- **GCD spark** — optional thin progress bar below the player castbar
- **Cast transitions** — smooth fade-out and flash on completion/interruption
- **UnitFrame anchoring** — Target, Focus, Pet, Boss castbars auto-anchor below their UnitFrame
- **Player castbar** freely movable via `/tm layout`

### 🔵 Resource Bars

Comprehensive class resource display system — all 13 classes with spec-specific logic.

- **Segmented point displays** for Combo Points, Holy Power, Chi, Arcane Charges, Soul Shards (partial fill), Essence, DK Runes (per-rune cooldowns)
- **Aura-tracked resources:** Soul Fragments, Tip of the Spear, Maelstrom Weapon stacks
- **Brewmaster Stagger** with adaptive color (green → yellow → red)
- **Druid form-adaptive:** auto-switches between Mana, Energy, Rage, and Astral Power depending on shapeshift form
- **Visibility modes:** Always, Combat only, Target only, Hidden
- **Fully configurable:** width, height, scale, text alignment, font, font size, all resource colors editable

### � Aura Tracker

Configurable aura watch panel anchored to the player UnitFrame.

- **5 categories:** Buff, Debuff, Cooldown, Totem, Enchant — each with its own grow direction
- **Spell database** — pre-populated for every class/spec in Midnight Season 1
- **Cooldown sweep** — animated radial countdown directly on each icon
- **Stacks & timer text** — readable countdown + stack count
- **Custom icon list** — add or remove tracked spells per category
- **Growth directions:** Left, Right, Up, Down — per-category setting
- **Size & spacing** — icon size, gap, and max icons configurable
- **Mover overlay** — unlock via `/tm layout` to reposition independently

### �🔲 Nameplates

Custom nameplate system with performance-optimized frame pooling.

- **Health bars** with class colors for players, reaction colors for NPCs
- **Classification colors:** Boss (red), Elite (purple), Rare (cyan), Normal (brown), Trivial (grey)
- **Castbars** integrated per-nameplate with interrupt indicator
- **Auras** with configurable max count, size, "only mine" filter
- **Tank mode** — threat-based coloring (red = no threat, yellow = losing, green = tanking)
- **Friendly name-only mode** — friendly players/NPCs show only a colored name, no health bar or overlays
- **Friendly role icons** in dungeons/delves — Tank/Healer/DPS icons above player names, class-colored
- **Raid marker** positioning — configurable anchor point, offset, and size
- **Optimized UNIT_AURA handling** — split dirty levels for CPU reduction in raids

### ⚡ Cooldown Manager

Reskins Blizzard's cooldown icons (Essential, Utility, Buffs) with a clean, unified look.

- **1-pixel black borders** — clean edge styling
- **Class-colored overlay** when an ability is active (buff/proc)
- **Custom cooldown text** — Poppins-SemiBold font, intelligent formatting: `3m` / `28` / `1.2` (yellow under 3s)
- **Center-outward buff positioning** — icons alternate left/right from center
- **Custom overlay & swipe colors** with opacity control
- **3-level alpha system:** in combat / with target / no target — all configurable

### 🎨 Action Bars — *Dominos-Inspired*

Complete action bar management system with 4 visual styles and per-bar controls.

- **4 skin styles:** Classic (rounded 9-slice), Flat, Outlined, Glass, and Minimal (borderless with inner shadows)
- **Per-bar opacity** slider (0–100%) for all 10 bars
- **Fade system** — configurable fade-in/out delays and durations on mouse hover
- **Display conditions** — macro-conditional visibility: Combat only, Shift/Ctrl/Alt held, In group, Hostile target, or custom macro strings
- **Click-through** toggle per bar — pass clicks to the world
- **Shift Reveal** — hold Shift to temporarily show all hidden bars at full opacity
- **Out-of-range coloring** — red (out-of-range), blue (no mana), grey (unusable)
- **Bar Editor popup** — per-bar config with live preview

**Supported bars:** Action Bar 1–8, Pet Bar, Stance Bar

---

## 🎨 Skins — Unified Visual Overhaul

### 💬 Chat System

Complete chat replacement inspired by TUI_Core's visual style.

- **Sidebar + Window layout** — vertical sidebar with adjacent window, custom tab bar, scroll bar theming
- **5 sidebar shortcuts:** Professions, Shortcuts, Copy Chat, Emotes, Player Status
- **Tab notification flash** for unread messages
- **Message formatting:** configurable timestamps, short channel names (`[G]`, `[P]`, `[R]`), class-colored mentions, keyword highlighting, clickable URL detection, LFG role icons
- **Edit box** with chat-type coloring, character counter, and message history navigation
- **Copy chat frame** — scrollable window with the last 128 messages
- **Chat history persistence** — saves whisper, guild, party, raid messages across sessions
- **Spam throttle** — suppresses duplicate messages within 10 seconds
- **Inline emoji replacement** — text emoticons converted to display glyphs

### 🎒 Bag System — *TUI-Inspired*

Full inventory replacement with a modern, resizable grid.

- **3 layout modes:** Combined Grid, Categories (collapsible sections), Separate Bags
- **5 sort modes:** Manual (preserves drag-and-drop), Quality, Name, Type, Item Level
- **Bag bar sidebar** with per-bag free slot count
- **Settings context menu** via cogwheel — change layout/sort in-game without config panel
- **Item level badges**, junk coin icons, crafting quality tiers
- **Quality borders** with per-quality color coding
- **Search bar** with real-time filtering — non-matching items desaturated and dimmed
- **Gold + tracked currencies** in footer bar
- **Resizable frame** with live column recalculation

### 🗨️ Tooltip Skin

Dark, semi-transparent tooltips with a modern look.

- **Class-colored unit names** and **guild name** in teal
- **Poppins font** across all tooltip text
- **Optional:** hide health bar, hide server name, hide player title
- Hooks on GameTooltip, ShoppingTooltips, and ItemRefTooltip

### 🧿 Buff/Debuff Skin

- Rounded borders matching the TomoMod aesthetic (9-slice style)
- Optional glow effect — red for debuffs, teal for buffs
- Dark background, cropped icon edges, Poppins font for duration/stacks

### 🎮 Game Menu Skin

- Dark background with teal accent strip
- All buttons restyled: flat dark bg, teal hover highlight, Poppins font
- Dynamically skins buttons injected by other addons

### 📋 Objective Tracker — *17 Quest Type Colors*

Quest titles and objectives are color-coded by quest type for instant visual recognition.

- Green (complete), Gold (campaign), Pink (important), Orange (legendary), Blue (calling), Purple (dungeon), Red (raid), Violet (world quests), Cyan (weekly/daily), Crimson (Prey — Midnight), Teal (Delves), Deep blue (scenarios), and more
- Objective lines tinted by quest category — dimmed version of the title color
- Full FR+EN bilingual keyword support

---

## ⚔️ Mythic+ Toolkit

### 📊 Mythic+ Tracker

In-dungeon HUD for timer, forces, bosses, and deaths.

- **3-tier chest countdown** (+3/+2/+1) with tick marks at 60%, 80%, 100% thresholds
- **5-stage forces color gradient** (< 20% → < 100%) with completion time display
- **Split times** per boss — time elapsed since the previous kill
- **Death tracking** — hover the skull icon for a per-player death breakdown with class colors
- **Completion banner** with keystone upgrade level (+1, +2, +3)

### 🏆 TomoScore — Dungeon Scoreboard

End-of-dungeon scoreboard for the entire group.

- Damage, healing, interrupts, M+ rating, keystone level, and dungeon name per player
- Click a dungeon name to teleport directly (if spell known)
- Role-sorted rows (Tank → Healer → DPS), proportional stat bars
- Auto-shows after Mythic+ completion
- Saves last run for recall after logout

### 🔑 MythicHub — M+ Overview Panel

Custom panel replacing the Great Vault shortcut on CharacterFrame.

- Overall M+ rating with tier-based coloring
- Season dungeon table: icon, name, key level, rating, best time
- Fortified/Tyrannical best scores per dungeon
- Great Vault section with 9 reward slots (Dungeons, Raids, World)
- Click dungeon icons to cast teleport spells

### 🗝️ Mythic Keys

Compact display of all group members' keystones.

- Multi-protocol detection: TMKeyTracker, AstralKeys, AngryKeystones, chat link parsing
- Database of 80+ dungeons (WotLK → Midnight) for name resolution
- Teleportation tab for the current M+ season's 8 dungeons

---

## 🧭 Navigation & Exploration

### 📍 Waypoint System

In-world navigation system with beacon and arrow modes.

- **Beacon mode** (on-screen): teal circle icon + vertical beam, scales with distance
- **Navigator mode** (off-screen): rotating arrow on an elliptical orbit around screen center
- **Distance & ETA** display — live distance (yards/km) with arrival time estimate
- **Zone restriction** — optional auto-hide when outside the waypoint's zone
- **Configurable:** beacon size, shape (ring/arrow), color picker
- `/tm way x y [name]` — place waypoint at coordinates
- `/tm way clear` — remove active waypoint

### 📦 Loot Browser

Visual loot table for all M+ dungeons and raid bosses.

- **Global filter bar** — class, specialization, and difficulty filters applied across all tabs
- **Correct item level display** by difficulty (LFR/Normal/Heroic/Mythic)
- **Favorites tab** — pin items grouped by source (dungeon or raid), persisted across sessions
- **Class/spec filtering** — 347-entry database for accurate loot matching (no more glaives on your Evoker)
- Shift+click to link items in chat

### 🌍 World Quest Tab

Side panel on the World Map with a sortable list of all available World Quests.

- Sortable columns: Name, Zone, Reward, Time remaining
- Detailed reward classification: Gold, Gear (with ilvl), Reputation, Currency, Pet
- Color-coded quality (Common/Rare/Epic) with elite quest markers
- Click to navigate, Shift+click to super-track

---

## 🧩 Quality of Life — 25+ Modules

### 😴 AFK Display Screen

Stylized cinematic AFK screen with a 3D player model.

- Race/gender-aware model with falling animation and idle emotes
- Elapsed AFK timer, character info overlay (name, realm, level, spec)
- Whisper and guild message counters while AFK
- Optional camera rotation
- Auto-exits on combat, Auction House, or cinematic playback

### 🗺️ Layout Mode & Alignment Grid

- **Single toggle** unlocks every movable element at once — UnitFrames, Party Frames, Castbars, Aura Tracker, Minimap & Panel, Mythic+ Tracker
- **Alignment Grid** with 3 modes: Grid (dimmed), Grid+ (bright), OFF
- **Cursor flashlight** — grid lines near the cursor glow for pixel-perfect alignment
- Activate with `/tm layout` or the Layout button in the config panel

### Other QOL Modules

| Module | Description |
|--------|-------------|
| **Minimap** | Square minimap with class-colored border, configurable size/scale, movable via Layout Mode with position persistence |
| **Info Panel** | Durability, Time (12h/24h), FPS in a draggable bar |
| **Cursor Ring** | Animated ring following your cursor, optional class color |
| **Cinematic Skip** | Auto-skips previously-seen cinematics (Shift to watch again) |
| **Skyriding Bar** | Vigor tracking, speed %, surge/ascent indicators |
| **LevelingBar** | Session XP tracking, XP/hour, rested XP overlay |
| **Class Reminder** | Pulsing display for missing class buffs (Fortitude, Intellect, etc.) |
| **CoTank Tracker** | Monitors co-tank health, debuffs, and defensive CDs in raids |
| **LustSound** | 9 sound choices for Bloodlust alerts — plays even if game is muted |
| **Profession Helper** | Batch disenchant tool with quality filters |
| **Frame Anchors** | Movable anchors for AlertFrame and LootFrame |
| **TooltipIDs** | SpellID, ItemID, NPC ID, QuestID in tooltips — TWW safe |

### Automations

| Module | Description |
|--------|-------------|
| **AutoAcceptInvite** | Auto-accepts group invites from friends and guild |
| **AutoSummon** | Auto-accepts summons with configurable delay |
| **AutoFillDelete** | Auto-fills "DELETE" in item destruction popups |
| **AutoVendorRepair** | Sells grey items and auto-repairs at vendors |
| **FastLoot** | Instant auto-loot with modifier key support |
| **HideCastBar** | Hides the default player castbar |
| **HideTalkingHead** | Removes the TalkingHead popup |
| **AutoQuest** | Auto-accept / auto-turn-in quests (Shift to override) |

---

## 🧷 Profile System

Named profiles with per-specialization assignment and full import/export.

- **Named profiles** — create, rename, duplicate, delete
- **Spec assignment** — each specialization maps to a profile; changing spec automatically loads the assigned profile
- **Auto-save** — active profile saved before every switch and on Config panel close
- **Import / Export** — compressed string via LibSerialize + LibDeflate; import as a new profile without overwriting
- **Boot-time sync** — orphaned profiles reconciled automatically on login

---

## ⚙️ Configuration

Open the config panel with `/tm` — a custom **1020×720** dark-themed interface with icon-box sidebar navigation, gradient header, and live performance footer.

| Category | Contents |
|----------|----------|
| **General** | About, Minimap, Info Panel, Cursor Ring, Cinematic Skip, Frame Anchors, Waypoint |
| **UnitFrames** | Per-unit tabs with dimensions, elements, castbar, auras, info bar |
| **Party Frames** | General (size, growth, power), Features (dispel, HoTs, range), Cooldowns (CD tracker, icon size), Arena |
| **Castbars** | Per-unit castbar config, spark style, channel ticks, empowered, latency, GCD spark |
| **Nameplates** | Dimensions, colors, classification, tank mode, friendly mode, role icons, auras |
| **CD & Resource** | Cooldown Manager, Resource Bars (visibility, dimensions, colors, text), Aura Tracker |
| **Action Bars** | Skin style, per-bar opacity/fade/display conditions, bar editor |
| **Mythic+** | M+ Tracker, TomoScore, MythicHub |
| **QOL / Auto** | SkyRide, Waypoint, Mythic Keys, all automations |
| **Sound** | LustSound configuration with preview |
| **Skins** | Chat, Bags, Tooltip, Buffs, Game Menu, Objective Tracker, Character |
| **Profiles** | Named profiles, per-spec assignment, import/export |

---

## 📋 Slash Commands

| Command | Action |
|---------|--------|
| `/tm` | Open config panel |
| `/tm help` | Show all commands |
| `/tm install` | Relaunch the 12-step setup wizard |
| `/tm layout` / `/tm l` | Toggle Layout Mode |
| `/tm way x y [name]` | Place a waypoint |
| `/tm way clear` | Remove active waypoint |
| `/tm key` | Show/hide group keystones |
| `/tm score` | Preview dungeon scoreboard |
| `/tm loot` | Open the Loot Browser |
| `/tm prof` | Open Profession Helper |
| `/tm reset` | Reset ALL settings + reload UI |
| `/rl` | Reload UI (shortcut) |

---

## 📦 Libraries

- [oUF](https://github.com/oUF-wow/oUF) — UnitFrame engine
- [LibStub](https://www.curseforge.com/wow/addons/libstub) — Library versioning
- [LibDeflate](https://github.com/SafeteeWoW/LibDeflate) — Compression for profile export
- [LibSerialize](https://github.com/rossnichols/LibSerialize) — Serialization for profile export
- [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) — Shared media (fonts, textures, statusbars)
- [LibOpenRaid](https://github.com/Tercioo/Open-Raid-Library) — Group inspection and keystone data
- [LibDispel](https://github.com/ablackright/LibDispel) — Dispel detection

---

## 🌐 Localization

| Language | Status |
|----------|--------|
| **English (enUS)** | Full support (default) |
| **French (frFR)** | Full support |
| **German (deDE)** | Full support |
| **Spanish (esES)** | Full support |
| **Italian (itIT)** | Full support |
| **Portuguese (ptBR)** | Full support |

---

## 💬 Feedback & Issues

Use the CurseForge project page to report bugs or suggest features.  
When reporting issues, please include:
- Your class and specialization
- Steps to reproduce the problem
- Any error messages from BugSack / BugGrabber if available

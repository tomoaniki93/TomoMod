# ![TomoMod](https://img.shields.io/badge/TomoMod-v2.5.1-0cd29f?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120001-orange?style=for-the-badge)

# **TomoMod**

**Lightweight, modular WoW addon** — Custom UnitFrames, Nameplates, Resource Bars, Cooldown Manager & 17+ QOL modules.
Fully compatible with **Midnight 12.x** with native handling of Blizzard's secret values.

**Author:** TomoAniki
**CurseForge Project ID:** 1446255

---

## 💬 Feedback & Issues

Use the CurseForge project page to report bugs or suggest features.
When reporting issues, please include:
- Your class and specialization
- Steps to reproduce the problem
- Any error messages from BugSack / BugGrabber if available

---

## ✨ Features Overview

### 🎯 UnitFrames

Full replacement for Blizzard's unit frames with a clean, minimal aesthetic.

- **Supported units:** Player, Target, Target-of-Target, Pet, Focus, Boss 1 to 5
- **Health bars** with class colors, faction colors, and absorb shields overlay
- **Power bars** with accurate power type coloring
- **Castbars** on Player, Target, and Focus — supports both casts and channels with TWW secret-safe timers using `GetRemainingDuration(0)`
- **Non-interruptible indicator** — grey overlay using `EvaluateColorValueFromBoolean` (no boolean test on secrets)
- **Auras** (buffs/debuffs) with duration timers, stack counts, and configurable grow direction
- **Threat glow** on target frame
- **Raid icons** on target
- **Leader/Assistant icons** on player and target with configurable X/Y offset
- **Health text formats:** current, percent, current+percent, current/max, deficit
- **Drag-to-move** via Layout Mode — unlock all frames, reposition freely, lock again
- **Per-unit configuration** — enable/disable, dimensions, offsets for each element
- **Blizzard frames hidden** automatically when custom frames are enabled

### 🔵 Resource Bars

Comprehensive class resource display system sitting below the action bars.

- **All 13 classes supported** with spec-specific primary, secondary, and tertiary resources
- **Segmented point displays** for Combo Points, Holy Power, Chi, Arcane Charges, Soul Shards (partial fill), Essence, and DK Runes (with per-rune cooldown timers)
- **Aura-tracked resources:** Soul Fragments, Tip of the Spear, Maelstrom Weapon stacks
- **Brewmaster Stagger** with adaptive color (green → yellow → red)
- **Druid form-adaptive:** automatically switches between Mana, Energy, Rage, and Astral Power depending on shapeshift form, with secondary Mana bar when in form (except Restoration)
- **Visibility modes:** Always, Combat only, Target only, Hidden
- **Alpha transitions** — configurable combat/out-of-combat opacity
- **Fully configurable:** width, height, scale, text alignment (L/C/R), font, font size
- **All resource colors editable** individually in the config panel
- **Width sync** with Cooldown Manager via `/tm rb sync`
- **Draggable** via Layout Mode or `/tm rb`

### 🔲 Nameplates

Custom nameplate system replacing Blizzard's default nameplates.

- **Health bars** with class colors for players, reaction colors for NPCs
- **Classification colors:** Boss (red), Elite (purple), Rare (cyan), Normal (brown), Trivial (grey)
- **Name and level text** with configurable font and size
- **Castbars** integrated per-nameplate with interrupt indicator
- **Auras** on nameplates — configurable max count, size, with "only mine" filter
- **Tank mode** — threat-based coloring (red = no threat, yellow = losing, green = tanking)
- **Selected/unselected alpha** for visual focus on current target
- **Overlap and inset** settings for fine-tuning plate stacking
- **Per-unit event registration** — no global `UNIT_*` events, completely taint-free
- **Friendly plates** toggle
- **Optimized UNIT_AURA handling** — split into two dirty levels: full update only for health/threat events, aura-only update for buff/debuff ticks (significant CPU reduction in raids)

### ⚡ Cooldown Manager (CDM)

Reskins Blizzard's cooldown icons (Essential, Utility, Buffs) with a clean, unified look.

- **1-pixel black borders** around each icon — clean edge styling
- **Class-colored overlay** when an ability is active (buff/proc)
- **Custom cooldown text** — Poppins-SemiBold font, intelligent formatting: `3m` / `28` / `1.2` (yellow under 3s)
- **Center-outward buff positioning** — 1st icon center, then alternating left/right (1, 3, 5… right | 2, 4, 6… left)
- **Hotkey text** — hidden by default, toggle in config
- **3-level alpha system:** in combat (1.0), with target out of combat (0.8), no target (0.5) — all configurable
- **Blizzard Edit Mode** used for positioning — no custom position system needed

### 🎨 Action Bars

Complete reskin of action buttons with 9-slice borders.

- **Rounded borders** for all buttons (10 bars supported)
- **Optional class color** for borders
- **Opacity per bar:** individual slider for each action bar (0–100%)
- **Shift Reveal:** hold `Shift` to temporarily reveal all hidden bars at 100% opacity — releasing restores configured values
- Removal of Blizzard's NormalTexture, SlotArt, and Border textures

**Supported bars:** Action Bar 1–8, Pet Bar, Stance Bar

---

### 🗺️ Layout Mode *(New in 2.3.0)*

Centralized system to move and reposition all UI elements at once.

- **Single toggle** unlocks every movable element simultaneously: UnitFrames, BossFrames, ResourceBars, SkyRide, LevelingBar, FrameAnchors, CoTankTracker
- **Floating header bar** during Layout Mode with Lock, Reload UI, and Grid buttons
- Activate with `/tm layout` (alias `/tm l`) or the **Layout** button in the Config panel header
- Per-module slash commands (`/tm uf`, `/tm sr`, `/tm rb`) remain functional and route through the unified system

### 🔲 Alignment Grid *(New in 2.3.0)*

Full-screen grid overlay displayed while Layout Mode is active.

- **Three modes** cycled via the Grid button in the Layout header: Grid (dimmed), Grid+ (bright), Grid OFF
- Brighter center crosshair for pixel-perfect screen-center alignment
- **Cursor flashlight effect** — grid lines near the cursor glow with a smooth radial falloff, making it easy to align frames to specific coordinates
- Zero per-frame allocations — pre-allocated texture pool, no garbage on hover

---

### 🧩 QOL Modules

#### Minimap
- Square minimap with class-colored or black border
- Configurable size and scale
- Hides Blizzard round elements (border, zoom buttons, compass, tracking)

#### Info Panel
- Displays Durability, Time (12h/24h, local/server), and FPS
- Draggable, configurable display order
- Hides Blizzard's clock

#### Cursor Ring
- Animated rotating ring following your cursor
- Optional class color
- Can anchor tooltip to cursor position
- Per-frame pixel-position caching — zero layout invalidation

#### Cinematic Skip
- Automatically skips previously-seen cinematics
- Tracks viewed cinematics per zone
- Hold Shift to watch again
- Clear history with `/tm clearcinema`

#### Frame Anchors
- Movable anchors for AlertFrame and LootFrame
- Invisible during gameplay, visible border when unlocked

#### Skyriding Bar
- Vigor tracking bar for Dragonriding/Skyriding
- Speed percentage display
- Surge Forward and Skyward Ascent indicators
- Fully configurable dimensions, colors, and position

#### MythicKeys
- Compact display of Mythic Keys for the entire group
- **Multi-protocol detection:** TMKeyTracker, AstralKeys, AngryKeystones, chat link parsing
- **DataKeys.lua:** database of 80+ dungeons (WotLK → Midnight) for name resolution
- **Teleportation Tab:** teleportation buttons for the 8 dungeons of the current Mythic+ season (S3 TWW)
- Teleportation ownership detection (owned/locked), anti-combat protection
- `/tm key` to show/hide

#### TooltipIDs
- Displays IDs in tooltips: SpellID, ItemID, NPC ID, QuestID, Mount, Currency, Achievement
- Compatible with TWW Secret Values

#### Auto Modules

| Module | Description |
|--------|-------------|
| **AutoAcceptInvite** | Auto-accepts group invites from friends and guild members |
| **AutoSummon** | Auto-accepts summons from friends/guild with configurable delay |
| **AutoFillDelete** | Auto-fills "DELETE" in item destruction popups |
| **AutoVendorRepair** | Sells grey items and auto-repairs gear at vendors |
| **FastLoot** | Instant auto-loot on every loot window |
| **HideCastBar** | Hides the default player castbar |
| **HideTalkingHead** | Removes the TalkingHead popup frame |
| **AutoQuest** | Auto-accept / auto-turn-in quests (hold Shift to override) |

---

## 🧷 Profile System *(Reworked in 2.3.0)*

Named profiles, per-specialization assignment, and import/export.

- **Named profiles** — create, rename, duplicate, delete
- **Spec assignment** — each specialization maps to a named profile; changing spec automatically loads the assigned profile (specs point to profile names, so editing a profile reflects on all specs assigned to it)
- **Auto-save** — active profile saved before every switch and on Config panel close
- **Import / Export** — full-screen modal popup with compressed string (LibSerialize + LibDeflate); import can be saved as a new named profile without overwriting the active one
- **Boot-time sync** — orphaned profiles automatically reconciled into the display list on login

---

## ⚙️ Configuration

Open the config panel with `/tm` — a custom dark-themed interface with sidebar navigation.

| Tab | Contents |
|-----|----------|
| **General** | About, Minimap, Info Panel, Cursor Ring, Cinematic Skip, Frame Anchors |
| **UnitFrames** | Per-unit tabs with dimensions, elements, castbar, auras |
| **Nameplates** | Enable/disable, dimensions, colors, classification, tank mode, auras, alpha |
| **CD & Resource** | Cooldown Manager (enable, hotkeys, alpha), Resource Bars (visibility, dimensions, colors, text) |
| **QOL / Auto** | SkyRide, Mythic Keys, AutoAcceptInvite, AutoSummon, AutoFillDelete, HideCastBar, AutoQuest |
| **Profiles** | Named profiles, per-spec assignment, import/export |

---

## 📋 Slash Commands

| Command | Action |
|---------|--------|
| `/tm` or `/tomomod` | Open config panel |
| `/tm help` | Show all commands |
| `/tm reset` | Reset ALL settings + reload UI |
| `/tm layout` / `/tm l` | Toggle Layout Mode (move all elements at once) |

---

## 📦 Libraries

- [LibStub](https://www.curseforge.com/wow/addons/libstub) — Library versioning
- [LibDeflate](https://github.com/SafeteeWoW/LibDeflate) — Compression for profile export
- [LibSerialize](https://github.com/rossnichols/LibSerialize) — Serialization for profile export
- [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) — Shared media (fonts, textures, statusbars)

---

## 🌐 Localization

- **English (enUS)** — Full support (default fallback)
- **French (frFR)** — Full support

---

## 📥 Installation

1. Download the latest release from CurseForge
2. Extract the `TomoMod` folder into `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or type `/reload`
4. Type `/tm` to open the configuration panel

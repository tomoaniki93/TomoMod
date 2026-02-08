# ![TomoMod](https://img.shields.io/badge/TomoMod-v2.1.5-0cd29f?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120001-orange?style=for-the-badge)

# |cff0cd29fTomo|rMod

**Lightweight, modular WoW addon** — Custom UnitFrames, Nameplates, Resource Bars, Cooldown Manager & 17+ QOL modules.
Fully compatible with **Midnight 12.x** with native handling of Blizzard's secret values.

**Author:** TomoAniki
**CurseForge Project ID:** 1446255

---

## ✨ Features Overview

### 🎯 UnitFrames

Full replacement for Blizzard's unit frames with a clean, minimal aesthetic.

- **Supported units:** Player, Target, Target-of-Target, Pet, Focus
- **Health bars** with class colors, faction colors, and absorb shields overlay
- **Power bars** with accurate power type coloring
- **Castbars** on Player, Target, and Focus — supports both casts and channels with TWW secret-safe timers using `GetRemainingDuration(0)`
- **Non-interruptible indicator** — grey overlay using `EvaluateColorValueFromBoolean` (no boolean test on secrets)
- **Auras** (buffs/debuffs) with duration timers, stack counts, and configurable grow direction
- **Threat glow** on target frame
- **Raid icons** on target
- **Leader/Assistant icons** on player and target with configurable X/Y offset
- **Health text formats:** current, percent, current+percent, current/max, deficit
- **Drag-to-move** with `/tm uf` — unlock all frames, reposition freely, lock again
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
- **Draggable** via `/tm uf` or `/tm rb`

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

### ⚡ Cooldown Manager (CDM)

Reskins Blizzard's cooldown icons (Essential, Utility, Buffs) with a clean, unified look.

- **1-pixel black borders** around each icon — clean edge styling
- **Class-colored overlay** when an ability is active (buff/proc)
- **Custom cooldown text** — Poppins-SemiBold font, intelligent formatting: `3m` / `28` / `1.2` (yellow under 3s)
- **Center-outward buff positioning** — 1st icon center, then alternating left/right (1, 3, 5… right | 2, 4, 6… left)
- **Hotkey text** — hidden by default, toggle in config
- **3-level alpha system:** in combat (1.0), with target out of combat (0.8), no target (0.5) — all configurable
- **Blizzard Edit Mode** used for positioning — no custom position system needed

### 🛠️ QOL Modules

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

#### Cinematic Skip
- Automatically skips previously-seen cinematics
- Tracks viewed cinematics per zone
- Hold Shift to watch again
- Clear history with `/tm clearcinema`

#### Frame Anchors
- Movable anchors for AlertFrame and LootFrame
- Invisible during gameplay, blue border when unlocked
- Toggle lock with `/tm sr`

#### Skyriding Bar
- Vigor tracking bar for Dragonriding/Skyriding
- Speed percentage display
- Surge Forward and Skyward Ascent indicators
- Fully configurable dimensions, colors, and position

#### Mythic Keys (MK)
- **Group key tracker** — shares keystones between party members via addon comms
- Mini frame display + full detail frame
- Auto-refresh on group changes
- Send keys to chat with one click
- Auto-insert keystone at the font
- Toggle with `/tm key`

#### Auto Modules
| Module | Description |
|--------|-------------|
| **AutoAcceptInvite** | Auto-accepts group invites from friends and guild members |
| **AutoSummon** | Auto-accepts summons from friends/guild with configurable delay |
| **AutoFillDelete** | Auto-fills "DELETE" in item destruction popups + focuses confirm button |
| **AutoVendorRepair** | Sells grey items and auto-repairs gear at vendors |
| **FastLoot** | Instant auto-loot on every loot window |
| **HideCastBar** | Hides the default player castbar (useful with custom UF castbar) |
| **HideTalkingHead** | Removes the TalkingHead popup frame |
| **AutoQuest** | Auto-accept / auto-turn-in quests (hold Shift to override; won't auto-pick when multiple rewards) |

#### Companion Status
- Tracks and displays pet companion status with configurable icon/text display

---

## ⚙️ Configuration

Open the config panel with `/tm` — a custom dark-themed interface with sidebar navigation.

| Tab | Contents |
|-----|----------|
| **General** | About, Minimap, Info Panel, Cursor Ring, Cinematic Skip, Frame Anchors |
| **UnitFrames** | Per-unit tabs (Player, Target, ToT, Pet, Focus) with dimensions, elements, castbar, auras |
| **Nameplates** | Enable/disable, dimensions, colors, classification, tank mode, auras, alpha |
| **CD & Resource** | Cooldown Manager (enable, hotkeys, alpha), Resource Bars (visibility, dimensions, colors, text) |
| **QOL / Auto** | SkyRide, Mythic Keys, AutoAcceptInvite, AutoSummon, AutoFillDelete, HideCastBar, AutoQuest |
| **Profiles** | Per-specialization profiles, import/export (LibSerialize + LibDeflate encoded) |

---

## 📋 Slash Commands

| Command | Action |
|---------|--------|
| `/tm` or `/tomomod` | Open config panel |
| `/tm help` | Show all commands |
| `/tm reset` | Reset ALL settings + reload UI |
| `/tm uf` | Toggle UnitFrames + ResourceBars lock (drag to reposition) |
| `/tm uf reset` | Reset UnitFrames to defaults + reload |
| `/tm rb` | Toggle ResourceBars lock only |
| `/tm rb sync` | Sync ResourceBars width with Cooldown Manager |
| `/tm np` | Toggle Nameplates on/off |
| `/tm sr` | Toggle lock for SkyRide bar + Frame Anchors |
| `/tm key` | Toggle Mythic Keys frame |
| `/tm minimap` | Reset minimap settings |
| `/tm panel` | Reset info panel |
| `/tm cursor` | Reset cursor ring |
| `/tm clearcinema` | Clear cinematic skip history |
| `/tm cdm` | Show Cooldown Manager status |

---

## 🔧 Technical Notes (TWW Compatibility)

TomoMod is designed from the ground up for **The War Within** API changes:

- **Secret Values:** Functions like `UnitHealth()`, `GetCooldownTimes()`, `UnitCastingInfo()` return opaque "secret numbers" in TWW. TomoMod handles these by:
  - Using `type()` checks and `issecretvalue()` validation before any comparisons
  - Passing secrets directly to C-side methods (`SetMinMaxValues`, `SetValue`, `SetAlpha`, `SetFormattedText`) which accept them natively
  - Using `GetRemainingDuration(0)` for castbar timers
  - Using `EvaluateColorValueFromBoolean` for interruptible state detection
  - Arithmetic on secrets produces new secrets usable in C-side calls (cooldown timers, aura durations)

- **Taint Prevention:** Zero global `RegisterEvent("UNIT_*")` calls. All unit events use `RegisterUnitEvent` scoped to specific managed units. Nameplates use dynamic per-unit registration on `NAME_PLATE_UNIT_ADDED` / `NAME_PLATE_UNIT_REMOVED`. This prevents addon handlers from tainting Blizzard's secure frame dispatch context.

- **Edit Mode Compatible:** No interference with Blizzard's Edit Mode system. The Cooldown Manager delegates positioning entirely to Blizzard's native layout.

- **Cross-realm Support:** Proper name normalization with `Ambiguate()` for Mythic Keys group tracking.

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

1. Download the latest release
2. Extract `TomoMod` folder into `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or type `/reload`
4. Type `/tm` to open the configuration panel

---

## 💬 Feedback & Issues

Use the CurseForge project page to report bugs or suggest features.
When reporting issues, please include:
- Your class and specialization
- Steps to reproduce the problem
- Any error messages from BugSack/BugGrabber if available

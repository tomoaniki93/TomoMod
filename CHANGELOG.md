## ####################################

## CHANGELOG 2.1.4

- Character Sheet + Inspect
- Quest icon on NamesPlates
- Fix error on LustSound

## ####################################

# CHANGELOG

## 2.1.0

### Critical Fixes
- **Config UI completely rewritten** — all 6 config panels now use correct `TomoModMini_*` globals (was referencing `TomoMod_*` from the full version, causing the entire settings UI to crash on load)
- **Database key fix** — `autoAcceptInvite` DB key now matches the module lookup (was `acceptInvite`, causing the module to never find its settings)

### Removed Non-Existent Module References
- General panel: removed Minimap and InfoPanel sections (not in Mini)
- QOL panel: removed AutoQuest, MythicKeys, SkyRide tabs and TooltipIDs section
- CooldownResource panel: removed Cooldown Manager tab
- UnitFrames panel: removed Boss Frames tab
- Profiles panel: reset list trimmed to only the 10 modules that exist in Mini

### Font & Asset Fixes
- All font paths now point to `TomoModMini\Assets\Fonts\` (was `TomoMod\...`)
- Font dropdowns only list Tomo.ttf + built-in WoW fonts (removed Poppins/Expressway references that don't ship with Mini)

### Init & Slash Commands
- All help text now shows `/tm` consistently (was displaying `/tm`)
- Removed dead module initialization code (10 modules referenced that don't exist in Mini)
- Cleaned up slash command handlers

### Other
- StaticPopup dialog names use `TOMOMODMINI_` prefix (was `TOMOMOD_`)
- All print messages show `TomoModMini` branding
- Stripped test/doc files from bundled libraries

## 2.0.0

- Initial Mini release — lightweight version of TomoMod
- UnitFrames, Nameplates, ResourceBars
- QOL: CursorRing, CinematicSkip, AutoAcceptInvite, AutoSummon, AutoFillDelete, AutoSkipRole, HideCastBar, FastLoot, AutoVendorRepair, HideTalkingHead
- Full profile system with import/export and per-spec switching

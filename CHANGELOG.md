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
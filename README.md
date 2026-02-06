# |cff0cd29fTomo|rMod

**Addon WoW léger et modulaire** — Interface personnalisée (UnitFrames, Nameplates) + 17 modules QOL.
Entièrement compatible **The War Within (TWW) 11.0+** avec gestion native des *secret values*.

**Auteur :** TomoAniki
**Version :** 2.0
**Interface :** 12.0.0+

---

## 🎯 Fonctionnalités

### UnitFrames

Cadres d'unités personnalisés pour **Player**, **Target**, **Focus** et **Pet** avec un look épuré.

- **Barre de vie** avec texture custom, couleurs de classe et couleurs de faction
- **Barre de ressource** (mana, rage, énergie, etc.) collée à la barre de vie
- **Texte de vie** : formats `pourcentage`, `valeur actuelle + pourcentage`, `déficit`
- **Nom + Niveau combinés** : affichage `"90 - Nom du mob"` en haut à gauche de la barre
- **Barre de cast** complète avec timer, icône du sort, et nom du sort
  - 🔴 **Rouge** = sort interruptible
  - ⬜ **Gris** = sort non-interruptible
  - 🟢 **Vert** (flash) = sort interrompu avec succès
- **Auras** (buffs/debuffs) avec icônes, filtrage "seulement les miens"
- **Barre d'absorption** (bouclier)
- **Indicateur de menace** (bordure colorée)
- **Icône de raid target** (crâne, croix, etc.)
- **Statuts** : Mort, Fantôme, Hors ligne, AFK
- **Drag & Drop** : repositionnement libre de chaque cadre
- **Offsets d'éléments** : positionnement fin (X/Y) du nom, niveau, texte de vie, power bar, castbar, et auras pour Player et Target
- **Click-to-target** et menu clic droit fonctionnels
- **Verrouillage/Déverrouillage** via `/tomo lock` et `/tomo unlock`

### Nameplates

Nameplates custom avec remplacement complet des nameplates Blizzard.

- **Barre de vie** avec texture custom et couleurs configurables
- **Texte de vie** : format pourcentage ou valeur
- **Nom** avec taille de police configurable
- **Niveau** avec classification (Élite ★, Boss ☠, Rare ✦)
- **Couleurs hostiles/neutres/friendly/tapped** personnalisables
- **Couleurs de classe** optionnelles
- **Barre de cast** avec coloration d'interruptibilité (Rouge/Gris/Vert)
- **Auras** (debuffs) avec icônes, filtrage "seulement les miens"
- **Indicateur de menace** (bordure colorée)
- **Flèches de ciblage** : indicateurs visuels ◀ ▶ de chaque côté de la nameplate ciblée
- **Alpha sélectionné/non-sélectionné** configurable
- **Mode Tank** avec couleurs de menace dédiées
- **Empilement vertical** configurable :
  - Chevauchement vertical (rapproche les barres les unes des autres)
  - Limite haute écran (empêche les barres de monter trop haut en gros packs)

### Modules QOL (Quality of Life)

17 modules utilitaires activables individuellement :

| Module | Description |
|--------|-------------|
| **AutoVendorRepair** | Vend le junk et répare automatiquement chez un marchand |
| **FastLoot** | Accélère le loot automatique |
| **AutoAcceptInvite** | Accepte automatiquement les invitations de groupe (amis/guilde) |
| **AutoSummon** | Accepte les invocations automatiquement |
| **AutoFillDelete** | Remplit automatiquement "DELETE" dans la boîte de confirmation |
| **CinematicSkip** | Skip automatique des cinématiques déjà vues |
| **HideCastBar** | Masque la barre de cast Blizzard par défaut |
| **HideTalkingHead** | Masque le cadre "Talking Head" |
| **AutoQuest** | Acceptation/rendu automatique des quêtes |
| **CursorRing** | Anneau visuel autour du curseur |
| **Minimap** | Personnalisation de la minimap (taille, bordure) |
| **InfoPanel** | Panneau d'infos sous la minimap (FPS, durabilité, heure) |
| **CooldownManager** | Affichage des cooldowns de combat |
| **CompanionStatus** | Statut du compagnon de classe (Warlock, etc.) |
| **Keystone** | Affiche la clé mythique en cours |
| **MythicKeys** | Gestion des clés mythiques du groupe |
| **SkyRide** | Barre de vitesse de Skyriding |

### Interface de Configuration

Configuration complète accessible via **`/tomo`** ou **`/tomomod`** :

- Interface sombre et épurée avec thème custom
- Panneaux dédiés : Général, Unit Frames, Nameplates, QOL, Profils
- Sliders, checkboxes, dropdowns, color pickers
- Aperçu en temps réel des modifications
- Système de profils (sauvegarde/chargement/suppression)

---

## ⚡ Compatibilité TWW 11.0+

TomoMod v2.0 est **entièrement compatible** avec le système de *secret values* introduit dans The War Within. Toutes les valeurs sensibles retournées par les API Blizzard (vie, mana, noms, niveaux, données d'auras, données de cast) sont traitées exclusivement via des méthodes C-side :

- `SetFormattedText()` au lieu de `string.format()` + `SetText()`
- `SetValue()` / `SetMinMaxValues()` pour les barres de statut
- `SetTexture()` pour les icônes d'auras
- `SetTimerDuration()` pour les castbars
- Filtres C-side (`"HARMFUL|PLAYER"`) pour le filtrage d'auras
- Événements (`UNIT_SPELLCAST_INTERRUPTIBLE` / `NOT_INTERRUPTIBLE`) pour la détection d'interruptibilité
- Isolation de contexte via `C_Timer.After(0)` pour éviter la propagation de taint aux frames Blizzard protégés

**Zéro opération Lua sur les secret values. Zéro taint propagé.**

---

## 📦 Installation

1. Télécharger le fichier `TomoMod.zip`
2. Extraire le dossier `TomoMod` dans `World of Warcraft/_retail_/Interface/AddOns/`
3. Relancer WoW ou `/reload`
4. Taper `/tomo` pour ouvrir la configuration

---

## ⌨️ Commandes Slash

| Commande | Action |
|----------|--------|
| `/tomo` ou `/tomomod` | Ouvrir/fermer la configuration |
| `/tomo lock` | Verrouiller les cadres (désactive le drag) |
| `/tomo unlock` | Déverrouiller les cadres (active le drag) |
| `/tomo np on` | Activer les nameplates custom |
| `/tomo np off` | Désactiver les nameplates custom |

---

## 📋 Changelog

### v2.0 — Refonte complète

**Architecture**
- Réécriture complète de l'addon depuis v1.x
- Nouvelle architecture modulaire : Core → Config → Modules (Interface + QOL)
- Système de base de données avec valeurs par défaut et merge automatique
- Bibliothèque de widgets custom pour l'interface de configuration
- Système d'enregistrement de modules (`TomoMod_RegisterModule`)

**Unit Frames**
- Nouveau moteur UnitFrames complet (Player, Target, Focus, Pet)
- Barres de vie/ressource avec textures custom
- Texte de vie multi-format (%, actuel + %, déficit)
- Système de castbar avec `SetTimerDuration` (TWW-compatible)
- Système d'auras avec `GetAuraSlots` varargs + filtres C-side
- Indicateur de menace, icône de raid, barre d'absorption
- Drag & drop avec sauvegarde de position
- Offsets X/Y par élément (nom, niveau, texte vie, power, castbar, auras)

**Nameplates**
- Remplacement complet des nameplates Blizzard
- Barres de vie avec couleurs hostiles/neutres/amicales/tapped configurables
- Barre de cast avec coloration d'interruptibilité via événements
- Système d'auras avec filtrage C-side
- Indicateur de menace (bordure)
- Flèches de ciblage visuelles ◀ ▶
- Mode Tank avec couleurs de menace dédiées
- Classification des mobs (Élite, Boss, Rare)
- Empilement vertical configurable (CVars `nameplateOverlapV`, `nameplateOtherTopInset`)
- Taille de police du nom configurable

**Configuration**
- Nouvelle interface de configuration avec thème sombre
- Panneaux : Général, Unit Frames (par unité), Nameplates, QOL, Profils
- Color pickers, sliders, checkboxes, dropdowns fonctionnels
- Rafraîchissement en temps réel des frames à chaque modification
- Système de profils complet

**Compatibilité TWW 11.0+**
- Migration complète vers `SetFormattedText()` (C-side) — zéro `string.format()` sur secrets
- `SetValue()` / `SetMinMaxValues()` pour barres de statut — zéro arithmétique Lua
- Isolation de contexte `C_Timer.After(0)` pour les event handlers
- Filtres d'auras C-side (`"HARMFUL|PLAYER"`) — remplace `isFromPlayerOrPlayerPet` (secret)
- Événements `SPELLCAST_INTERRUPTIBLE` / `NOT_INTERRUPTIBLE` — remplace `notInterruptible` (secret)
- `SetRaidTargetIconTexture()` — remplace `raidIconCoords[secretIndex]`
- `SetUnitDebuffByAuraInstanceID()` / `SetUnitBuffByAuraInstanceID()` pour tooltips
- Suppression de `GetQuestDifficultyColor()` sur secret numbers
- Suppression de `DebuffTypeColor` global (retiré en TWW)
- Masquage non-taintant des nameplates Blizzard via `OnUpdate` (pas de hook sur metatable)
- Aucun `ADDON_ACTION_BLOCKED` en fonctionnement normal

**QOL**
- 17 modules QOL préservés depuis v1.x
- Toggle individuel par module dans la configuration
- Minimap, InfoPanel, CursorRing, AutoVendorRepair, FastLoot, etc.

---

### v1.x → v2.0 — Migration

- Les anciens SavedVariables sont automatiquement fusionnés avec les nouveaux défauts
- Les positions de frames sauvegardées sont préservées
- Pas de reset nécessaire — `/reload` suffit

---

## 🐛 Problèmes connus

- Les durées restantes d'auras et le cooldown swipe ne sont pas affichés (les valeurs `expirationTime`/`duration` sont des secret numbers en TWW — impossible de calculer le temps restant côté Lua)
- Le spark de la castbar est masqué (même raison — `remaining/total` est une opération Lua sur secrets)
- Le compteur de stacks d'auras est masqué (impossible de distinguer stacking/non-stacking car `applications` est secret)

---

## 📄 Licence

TomoMod © TomoAniki — Tous droits réservés.

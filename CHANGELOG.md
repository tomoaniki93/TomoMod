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
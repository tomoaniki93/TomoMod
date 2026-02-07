####################
## TomoMod
####################

**Addon WoW léger et modulaire** — Interface personnalisée (UnitFrames, Nameplates, CDM, RessourcesBar) + 17 modules QOL.
Entièrement compatible **Midnight 12.0+** avec gestion native des *secret values*.

**Auteur :** TomoAniki
**Version :** 2.1.4
**Interface :** 12.0.0+

---

## 🎯 Fonctionnalités

### UnitFrames

Cadres d'unités personnalisés pour **Player**, **Target**, **Focus** et **Pet** avec un look épuré.

### Nameplates

Nameplates custom avec remplacement complet des nameplates Blizzard.

### CD & Ressource Bar

Cooldown manager and Ressources barres pour toutes les classes et specialisation

### Modules QOL (Quality of Life)

17 modules utilitaires activables individuellement :

### Interface de Configuration

Configuration complète accessible via **`/tomo`** :

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

## 🐛 Problèmes connus

- Les durées restantes d'auras et le cooldown swipe ne sont pas affichés (les valeurs `expirationTime`/`duration` sont des secret numbers en TWW — impossible de calculer le temps restant côté Lua)
- Le spark de la castbar est masqué (même raison — `remaining/total` est une opération Lua sur secrets)
- Le compteur de stacks d'auras est masqué (impossible de distinguer stacking/non-stacking car `applications` est secret)

---

## 📄 Licence

TomoMod © TomoAniki — Tous droits réservés.

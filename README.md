# NairolFlipper

> **Un spectacle vivant que l'on joue avec une bille.**

**NairolFlipper** est un flipper 2D gratuit, open source et cross-platform où la lumière de spectacle et la musique ne servent pas de décoration : elles constituent le gameplay.

Le joueur ne cherche pas seulement à faire un score. Il **construit un show** : il arme des familles de projecteurs, déclenche des cues, enrichit la musique, maintient un flow, provoque un final multiball puis termine sur un blackout. Chaque partie produit sa propre conduite audiovisuelle.

## Vision

NairolFlipper doit donner la sensation d'être simultanément :

- devant un excellent flipper arcade ;
- derrière une régie lumière ;
- au cœur d'un concert ;
- en train de construire une performance musicale ;
- dans un univers identifiable comme celui de **Nairolf**.

La règle de design la plus importante est :

> **Chaque action de flipper importante doit avoir une conséquence scénique, musicale ou rythmique lisible.**

## Piliers

1. **Le flipper d'abord** : la physique et les sensations doivent être satisfaisantes même sans effets.
2. **La lumière est un système de jeu** : fixtures, palettes, cues, intensité, blackout et final ont des fonctions mécaniques.
3. **La musique réagit au joueur** : des stems musicaux se combinent selon la progression du show.
4. **Une partie raconte un show** : début, montée, rupture, climax, blackout, éventuel encore.
5. **Cross-platform dès le premier commit** : Web, Android, iOS, Windows, macOS et Linux partagent le même cœur.
6. **Gratuit sans piège** : pas de publicité intrusive, pas de pay-to-win, pas de boutique obligatoire.

## Stack imposée

- **Godot 4.7.2 stable**
- **GDScript uniquement**
- rendu **GL Compatibility** par défaut pour maximiser la compatibilité Web/mobile
- architecture 2D
- Git + GitHub
- GitHub Actions pour validation, builds et releases

Ne pas introduire C#, GDExtension, plugin natif ou SDK propriétaire sans décision d'architecture documentée.

## Plateformes cibles

| Plateforme | Cible | Priorité |
|---|---|---|
| Web | navigateur desktop + mobile compatible | P0 |
| Android | APK de test puis distribution | P0 |
| Windows | build natif | P0 |
| iOS / iPadOS | build natif signé | P1 |
| macOS | build natif | P1 |
| Linux | build natif | P1 |
| Stores / Steam | distribution | P2 |
| Consoles | étude ultérieure | Hors MVP |

## Boucle de développement

```text
Spécification / ticket
        ↓
Codex lit AGENTS.md + docs pertinentes
        ↓
Implémentation ciblée
        ↓
Tests + build
        ↓
GitHub Actions
        ↓
Web / APK / desktop artifact
        ↓
Playtest humain
        ↓
Retour précis
        ↓
Correction par Codex
```

## Démarrage pour Codex

Avant toute modification :

1. lire [`AGENTS.md`](AGENTS.md) ;
2. lire [`docs/INDEX.md`](docs/INDEX.md) ;
3. lire les documents indiqués pour le type de tâche ;
4. travailler sur **une seule intention principale** ;
5. exécuter les validations pertinentes ;
6. mettre à jour documentation et backlog lorsque la réalité du projet change.

La première étape de développement est définie dans [`docs/BACKLOG.md`](docs/BACKLOG.md).

## Documentation

- [Vision produit](docs/PRODUCT_VISION.md)
- [Game Design Document](docs/GAME_DESIGN_DOCUMENT.md)
- [Systèmes de gameplay](docs/GAMEPLAY_SYSTEMS.md)
- [Design du plateau](docs/TABLE_DESIGN.md)
- [Direction artistique](docs/ART_DIRECTION.md)
- [Direction musique et audio](docs/AUDIO_MUSIC_DIRECTION.md)
- [Architecture technique](docs/TECHNICAL_ARCHITECTURE.md)
- [Compatibilité plateformes](docs/PLATFORM_MATRIX.md)
- [Roadmap](docs/ROADMAP.md)
- [Workflow Codex](docs/AI_CODEX_WORKFLOW.md)

## État

**Préproduction / cadrage.**

Le premier jalon réussi n'est pas « le jeu complet ». C'est un build Web et un APK Android avec une bille, deux batteurs, des collisions, quelques bumpers, un drain et un score, suffisamment agréable pour permettre une vraie boucle de playtest.

## Licence

Le code est publié sous licence MIT. Les assets doivent respecter la politique décrite dans [`docs/ASSET_LEGAL_POLICY.md`](docs/ASSET_LEGAL_POLICY.md).

---

**NairolFlipper**  
*Build the rig. Run the cues. Play the show.*

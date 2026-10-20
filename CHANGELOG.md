# Changelog

## [Unreleased]

### Added

- Documentation initiale de cadrage du projet.
- Instrumentation locale de session pour les playtests, sans télémétrie réseau.
- Resource data-driven `CueDefinition` et premier cue de démonstration.
- Rampes Warm/Cold data-driven, avec score et Flow sur passage.
- Tests comportementaux Godot pour Flow, Cue, score et réinitialisation de partie.
- Import propre et détection explicite des erreurs Godot dans la CI.
- Premiers SFX originaux de playtest pour les actions principales, lus sur le
  bus SFX avec polyphonie.
- Plateau Table 2.0 vectoriel avec six cibles Rig, Universe Orbit, slingshots,
  rails physiques, outlanes et objectif de complétion visible.
- Bonus de Rig complet et guidage explicite vers la Console.
- Showflow visible Preset → Build → Flow → Final Show → Blackout.
- Final Show à trois billes bonus, score doublé, durée configurable et fin
  automatique lorsqu'une seule bille reste.
- Blackout de transition qui conserve la bille survivante et les vies de session.
- Huit stems musicaux originaux synchronisés, mixés progressivement par le Rig
  et le Showflow.
- Identité scénique vectorielle avec truss, fixtures, faisceaux, grille et runway
  réactifs, sans shader lourd ni asset tiers.

### Fixed

- Références `FlowManager` et `RigDefinition` invalides dans la scène principale.
- Résolution des types GDScript depuis un checkout sans cache `.godot`.
- Décroissance du Flow désormais indépendante du nombre d'images par seconde.
- Multiplicateur de Flow et bonus de Cue correctement appliqués au score.
- Réinitialisation complète de Cue, Rig, audio et contrôles tactiles au restart.
- Orientation Android verrouillée en portrait pour correspondre au plateau.
- Géométrie, angles de repos et activation du flipper droit corrigés.
- Physique de bille alourdie, rebond réduit et lancement dirigé vers le plateau.
- Menu de démarrage et commandes Reset/Quit ajoutés au build de playtest.
- Cycle de partie verrouillé à trois billes avec écran Game Over explicite.
- Collisions des billes inactives désactivées pour supprimer les apparitions fantômes.
- Safety limité à une utilisation par bille et récupération des billes coincées ou hors plateau.

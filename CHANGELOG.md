# Changelog

## [Unreleased]

### Added

- Documentation initiale de cadrage du projet.
- Instrumentation locale de session pour les playtests, sans télémétrie réseau.
- Resource data-driven `CueDefinition` et premier cue de démonstration.
- Rampes Warm/Cold data-driven, avec score et Flow sur passage.
- Tests comportementaux Godot pour Flow, Cue, score et réinitialisation de partie.
- Import propre et détection explicite des erreurs Godot dans la CI.

### Fixed

- Références `FlowManager` et `RigDefinition` invalides dans la scène principale.
- Résolution des types GDScript depuis un checkout sans cache `.godot`.
- Décroissance du Flow désormais indépendante du nombre d'images par seconde.
- Multiplicateur de Flow et bonus de Cue correctement appliqués au score.
- Réinitialisation complète de Cue, Rig, audio et contrôles tactiles au restart.

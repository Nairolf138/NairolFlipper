# Changelog

## [Unreleased]

### Added

- Documentation initiale de cadrage du projet.
- Instrumentation locale de session pour les playtests, sans télémétrie réseau.
- Resource data-driven `CueDefinition` avec conditions répétables et exécution
  séquentielle.
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
- Cue Stack en trois étapes : Color Wash, Universe Chase et Rhythm Drop, chacune
  préparée par des tirs dédiés puis exécutée via la Console.
- Objectif courant permanent et mise en évidence des rampes, de l'orbite ou des
  bumpers encore attendus.
- Passe visuelle Stagecraft vectorielle : stage deck en perspective, routes de
  tir, launcher, drain, truss, haze et footlights cohérents.
- Habillage mécanique des rails, flippers, bumpers, cibles Rig, rampes et Console,
  ainsi qu'un thème partagé pour les menus et commandes de partie.

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
- Parois latérales prolongées jusqu'au drain pour fermer les sorties involontaires.
- Guides supérieurs réorientés vers le centre et retours bas séparés des outlanes
  et du couloir du lanceur.
- Gravité, friction et restitution recalibrées pour une bille plus lourde et une
  descente plus franche, avec forces de jeu compensées.
- Matériaux distincts pour les surfaces passives et les flippers afin d'éviter
  les rebonds uniformes tout en conservant des tirs réactifs.
- Ombre de contact, bord métallique et reflet ajoutés à la bille pour mieux la
  poser visuellement sur le plateau.
- Final Show désormais conditionné par la Cue Stack complète et les six familles
  du Rig, afin que les routes du plateau participent toutes à la progression.
- Groupes Godot des rampes et de la Console corrigés afin que leurs collisions
  atteignent réellement la logique de partie.

# Changelog

## [Unreleased]

### Reprise de jouabilité — PR 30

- Bouton GO lorsque la bille est prête ; suppression du lancement par toucher
  dans le haut du plateau, avec Espace et A manette conservés.
- Couloir de lancement physique continu, courbe de déviation et sortie inclinée.
- Flippers rapprochés, guides latéraux collecteurs et jonctions jusqu'aux pivots.
- Neuf lancements suivis jusqu'au premier renvoi par un flipper, six essais de
  retour et une perte centrale légitime simulés sans sauvetage.
- Correction d'un polygone de tablier qui se croisait ; les erreurs de rendu
  Godot font désormais échouer l'analyse des logs CI.
- Icône de playtest originale configurée pour supprimer l'erreur d'export Android.
- Qualification Alpha suspendue au playtest et aux reprises physique/artistique.

### Alpha 0.1.0 candidate

- Version applicative harmonisée à `0.1.0-alpha.1` dans le projet et les exports.
- Parcours joueur complet couvert du menu jusqu'à la fin de partie, en passant
  par le Rig, la Cue Stack, le Final Show à trois billes et le Blackout.
- Consignes d'action harmonisées en français sans traduire les noms des systèmes
  de jeu : Rig, Cue Stack, Flow, Final Show, Sync, Blackout et Safety.
- Libellés de table obsolètes retirés des écrans joueur.

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
- Sync Bonus à deux niveaux, calé sur le transport musical, avec gains de score
  et Flow, feedback texte/flash/SFX et verrou anti-farm par pulse.
- Horloge visuelle à quatre temps sur le plateau et compteur local de Sync pour
  comparer les futurs playtests sans télémétrie réseau.
- Menu de réglages audio Master/Musique/Effets, avec application immédiate,
  valeurs par défaut et persistance locale multiplateforme.
- Guide How to Play en quatre pages illustrées pour les commandes, le Rig, la
  Cue Stack et le Final Show, navigable au tactile, au clavier et à la manette.
- Réglage persistant des effets lumineux avec modes Complets, Réduits et
  Désactivés, appliqué aux flashes, pulsations, faisceaux et Blackout.

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

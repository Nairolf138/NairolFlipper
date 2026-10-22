# Systèmes de gameplay

## Physique de bille

`RigidBody2D`, collisions fiables, CCD si pertinent, vitesse max configurable, paramètres centralisés. Les valeurs finales viennent du playtest.

Paramètres : masse, gravité, restitution, friction, vitesse max, force launcher, force bumper.

### Réglage Table 2.2

Le profil de playtest privilégie une descente franche et des contacts peu
élastiques : masse `1.4`, gravité `1.55`, friction `0.48` et restitution `0.14`.
Les rails et murs utilisent un matériau passif à faible rebond tandis que les
flippers disposent d'une surface plus vive. Le lanceur, les bumpers et les
slingshots compensent la masse supplémentaire afin de conserver leur portée.

Ces valeurs forment une base mesurable, pas un réglage final. Le temps de chute
est couvert automatiquement ; le contrôle, le plaisir et la perception du poids
doivent être validés sur une tablette réelle.

La PR 30 conserve ce profil de bille mais remplace le lancement diagonal par
une impulsion verticale de `3300`, suivie d'un couloir physique courbe. La masse,
la gravité et le roulement seront réévalués dans la PR 31 ; augmenter la masse
ne suffit pas à simuler une bille roulant sur un plateau incliné.

## Flippers

Deux flippers MVP : activation instantanée, retour rapide, maintien levé, collision reproductible, mêmes actions pour clavier/tactile/manette.

## Bumpers

Trois bumpers rythmiques : Kick, Snare, Tom. Chaque impact donne des points, pousse la bille, flash, sample et petit gain de Flow.

## Cibles Fixture

Six familles de Rig. Une famille complétée change visuellement le plateau, débloque/améliore une règle et avance la conduite.

## Rampes et orbites

- Warm Ramp : Face chaude / ambre.
- Cold Ramp : Face froide / cyan.
- Universe Orbit : continuité.

## Console / Scoop

Élément central représentant la régie : validation de cue, choix de show futur, lock pour Final Show.

## Cue System

Chaque cue possède identifiant, nom localisé, conditions, changements lumière/audio, bonus et durée éventuelle. Data-driven.

### Cue Stack Alpha

La conduite active est ordonnée et lisible : Color Wash, Universe Chase, puis
Rhythm Drop. Une étape comptabilise uniquement ses tirs demandés, peut exiger
plusieurs répétitions, puis attend un passage sur la Console. L'exécution donne
son bonus, applique ses changements audiovisuels et avance vers la cue suivante.

Le Final Show exige à la fois les trois cues exécutées et les six familles du
Rig actives.

## Flow

Proposition : `1x → 2x → 3x → 4x → 6x → 8x`. Monte par variété, rampes, orbites, cues, sync. Décroissance généreuse.

## Sync Bonus

Chaque impact de bumper, cible Rig, rampe, orbite, slingshot ou Console est
comparé au pulse entier le plus proche du transport musical :

- **Perfect Sync** dans une fenêtre de `±0,12 beat` : `+200` points et `+35 Flow` ;
- **Sync** jusqu'à `±0,28 beat` : `+100` points et `+18 Flow` ;
- hors fenêtre : le tir conserve tous ses points, son Flow et sa progression.

Un même pulse ne peut donner qu'un bonus, y compris en multiball. Le timing est
fondé sur l'horloge logique et continue donc à fonctionner lorsque le son est
coupé ou indisponible, sans rendre le gameplay dépendant de la latence audio.
Les valeurs sont exportées dans `SyncBonusManager` pour être affinées après
playtest sur tablette.

## Multiball

Premier multiball narratif : **Final Show**, 3 billes max, spawn espacé, fin quand une seule reste.

## Show Recorder

Post-MVP : enregistrer seulement les événements de haut niveau pour Aftershow Replay, pas toute la physique.

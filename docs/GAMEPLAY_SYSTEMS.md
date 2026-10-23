# Systèmes de gameplay

## Physique de bille

`RigidBody2D`, collisions fiables, CCD si pertinent, vitesse max configurable, paramètres centralisés. Les valeurs finales viennent du playtest.

Paramètres : masse, gravité, restitution, friction, vitesse max, force launcher, force bumper.

### Roulement projeté — PR 31

`PhysicsTuning` définit une pente de `6.5°`, une échelle de `1600 px/m` et une
résistance au roulement de `0.002`. L'accélération d'une sphère pleine est
projetée le long du plateau ; la gravité verticale et l'amortissement linéaire
globaux de Godot ne s'ajoutent plus à ce calcul. La masse normalisée `1.4`
intervient dans les contacts et les impulsions, pas dans l'accélération de pente.

Le lanceur guidé GO est recalibré à `2700`, la restitution de la bille à `0.1`.
Le CCD utilise la forme entière de la bille. Vitesse maximale et résistance sont
appliquées dans le callback physique. Les slingshots renvoient vers l'intérieur.

Ce modèle reste une approximation 2D sans hauteur ni rotation 3D complète.
Voir [ADR-0005](adr/0005-projected-rolling-physics.md). Les mesures automatiques
ne remplacent pas la validation humaine de la sensation de poids.

## Flippers

Deux flippers avec profil `FlipperTuning` partagé : montée de commande sur
`25 ms`, accélération progressive jusqu'à `1050°/s`, maintien levé puis retour
plafonné à `500°/s`. Le contour de collision suit la palette et son extrémité.
La bille peut être retenue, laissée rouler puis frappée à un autre point pour
changer de route. Le watchdog ne récupère pas une bille soutenue par un flipper
maintenu ; il récupère toujours une bille coincée ailleurs.

## Bumpers

Trois bumpers rythmiques : Kick, Snare, Tom. Chaque impact donne des points, pousse la bille, flash, sample et petit gain de Flow.

## Cibles Fixture

Six familles de Rig. Une famille complétée change visuellement le plateau, débloque/améliore une règle et avance la conduite.

## Rampes et orbites

- Warm Ramp : Face chaude / ambre.
- Cold Ramp : Face froide / cyan.
- Universe Orbit : continuité.

Depuis la PR 32, ces objectifs exigent un parcours complet. Une entrée orientée
admet la bille sur un guide à rails continus ; trois jalons ordonnés puis la
sortie valident le tir et émettent les signaux de score/Flow/Cue existants.
Un tir trop faible redescend par l'entrée sans progression. Les retours Warm et
Cold vont vers leur flipper ; l'orbite se joue dans les deux sens et rejoint
l'inlane opposée. Anticiper le retour en levant le flipper permet de retenir
puis de rejouer la bille.

Les guides utilisent des plans de collision propres pour laisser circuler une
bille au-dessous. La bille reste un corps physique mobile, sans suivi de chemin.
Chaque bille possède son état de parcours, y compris en multiball ; reset et
menu rétablissent son plan initial. Les points, largeurs, matériaux et entrées
sont configurés dans `data/routes/`. Limites du modèle 2D : voir ADR 0006.

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

# Systèmes de gameplay

## Physique de bille

`RigidBody2D`, collisions fiables, CCD si pertinent, vitesse max configurable, paramètres centralisés. Les valeurs finales viennent du playtest.

Paramètres : masse, gravité, restitution, friction, vitesse max, force launcher, force bumper.

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

## Flow

Proposition : `1x → 2x → 3x → 4x → 6x → 8x`. Monte par variété, rampes, orbites, cues, sync. Décroissance généreuse.

## Sync Bonus

Bonus visuel/score/Flow près d'un pulse. Jamais de pénalité totale hors tempo.

## Multiball

Premier multiball narratif : **Final Show**, 3 billes max, spawn espacé, fin quand une seule reste.

## Show Recorder

Post-MVP : enregistrer seulement les événements de haut niveau pour Aftershow Replay, pas toute la physique.

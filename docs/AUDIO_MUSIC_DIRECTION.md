# Direction musique et audio

## Principe

La musique est orchestrée indirectement par le joueur.

## Identité

Électronique cinématique, synthés texturés, motif piano simple, basse profonde, percussions franches, tension progressive, respirations, climax massif mais propre. Pas d'imitation exacte d'artiste.

## Architecture

Stems pré-rendus synchronisés : Atmosphere, Piano, Kick, Percussions, Bass, Arp/Synth, Lead, Impact/Final. BPM et longueur de boucle communs.

## Mapping exemple

| Événement | Audio |
|---|---|
| Standby | atmosphere |
| Première cue | piano |
| Rig 2/6 | kick |
| Rig 3/6 | bass |
| Flow élevé | arp |
| Break | retrait kick/bass |
| Final Show | tous stems + impacts |
| Drain | chute / mute bref |
| Blackout | coupure contrôlée |

## SFX

Flippers, bumpers Kick/Snare/Tom, métal, launcher, target, cue, lock, multiball, drain.

## Mix

Priorité : signaux critiques → impacts → musique → ambience. Sliders Master/Music/SFX.

## Sync

Horloge musicale logique indépendante du rendu. Le jeu reste jouable son coupé.

## Web

Ne pas dépendre d'audio procédural ou DSP lourd. Fallback pour tout effet natif.

## Formats

OGG Vorbis préféré lorsque pertinent. Musique finale originale et droits documentés.

# Tests et QA

## Philosophie

Deux catégories obligatoires : tests automatiques de logique et playtest humain des sensations.

## Automatique

Harness Godot headless sans dépendance tierce au départ. Tester ScoreRules, Cue progression, Flow, Save schema, game state. Tests de scène : chargement, création balle, drain, relance, signaux.

## Smoke test

Importer headless, charger scène principale, quitter sans erreur bloquante.

## Builds P0

Web, Android, Windows.

## Playtest

```text
Build:
Plateforme:
Appareil:
Durée:

Sensations:
- bille:
- flippers:
- rythme:
- lisibilité:
- audio:
- performance:

Bugs:
Demandes:
```

Tout bug automatisable corrigé devrait recevoir un test raisonnable.

## Instrumentation locale de playtest

Le nœud `PlaytestRecorder` écrit `user://playtest/latest.json` avec la durée de
session, lancements, impacts de bumpers, drains, ball saves, relances et points
marqués. Cette trace reste locale : aucun réseau, compte ou télémétrie n'est
utilisé. Elle sert à comparer les sensations entre builds pendant un playtest.

Avant release publique : au moins Android réel, iPhone/iPad réel pour iOS, navigateurs récents, Windows natif, macOS/Linux selon disponibilité.

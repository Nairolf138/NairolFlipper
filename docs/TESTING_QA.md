# Tests et QA

## Philosophie

Deux catégories obligatoires : tests automatiques de logique et playtest humain des sensations.

## Automatique

Harness Godot headless sans dépendance tierce au départ. Tester ScoreRules, Cue progression, Flow, Save schema, game state. Tests de scène : chargement, création balle, drain, relance, signaux.

## Smoke test

Importer headless, charger scène principale, quitter sans erreur bloquante.
La CI analyse aussi les logs : un code de sortie `0` de Godot ne suffit pas si
une erreur de parsing, de chargement de scène/script ou de tableau typé est
présente.

## Tests comportementaux Godot

Le runner sans addon `tests/godot/test_runner.gd` exécute réellement les règles
de Flow, le cycle des Cues, le scoring multiplié et le reset complet de session :

```text
godot --headless --display-driver headless --audio-driver Dummy --path . \
  --script res://tests/godot/test_runner.gd
```

Les contrats Python restent utiles pour la structure du dépôt, mais ne remplacent
pas l'exécution Godot.

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

### Android — 19 octobre 2026

Premier test réel sur tablette Android : démarrage et commandes tactiles gauche/
droite fonctionnels. Défauts observés puis couverts par la branche de correction :
orientation paysage imposée autour d'un canvas portrait, flipper droit inversé,
lancement vertical ramenant la bille au drain, rebond trop élevé, absence de menu,
de Reset/Quit et de retour sonore.

Tout bug automatisable corrigé devrait recevoir un test raisonnable.

## Instrumentation locale de playtest

Le nœud `PlaytestRecorder` écrit `user://playtest/latest.json` avec la durée de
session, lancements, impacts de bumpers, drains, ball saves, relances et points
marqués. Cette trace reste locale : aucun réseau, compte ou télémétrie n'est
utilisé. Elle sert à comparer les sensations entre builds pendant un playtest.

Avant release publique : au moins Android réel, iPhone/iPad réel pour iOS, navigateurs récents, Windows natif, macOS/Linux selon disponibilité.

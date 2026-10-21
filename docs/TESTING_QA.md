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

### Android — 20 octobre 2026

Second test réel : orientation, flippers, lancement, sons, score et menu validés.
Après les trois billes, une reprise implicite et une bille non récupérable dans
le coin inférieur gauche ont été observées. La régression est couverte par un
test de trois drains complets, l'écran Game Over, l'absence de redémarrage au
toucher, les collisions inactives et la récupération hors limites.

### Table 2.0 — checklist tablette

- vérifier que la bille circule entre les rails sans rester piégée ;
- confirmer que les deux slingshots renvoient nettement la bille vers le haut ;
- allumer les six cibles et voir le compteur passer de `RIG 0 / 6` à `RIG 6 / 6` ;
- vérifier le message `RIG READY — HIT CONSOLE` et le bonus ;
- traverser l'Universe Orbit et confirmer score, Flow et feedback ;
- noter les tirs trop faciles, impossibles ou masqués par les doigts.

### Final Show — checklist tablette

- confirmer le passage visible de Preset à Build après le lancement ;
- allumer les six familles puis vérifier `SHOW FLOW` ;
- toucher la Console et confirmer que trois billes distinctes entrent en jeu ;
- vérifier que le score reçoit bien le bonus `x2` pendant le Final Show ;
- perdre deux billes et confirmer le Blackout, puis la reprise avec une bille ;
- vérifier que le nombre de billes numérotées n'a pas diminué pendant le multiball ;
- confirmer que la Console ne relance pas un second Final Show dans la même partie.

### Identité audiovisuelle — checklist tablette

- vérifier qu'une atmosphère musicale démarre après `JOUER`, jamais avant ;
- confirmer que de nouvelles couches entrent vers Rig 2/6, 3/6, 4/6 et 5/6 ;
- vérifier que chaque cible allume une fixture durable sur le truss supérieur ;
- confirmer que Flow anime davantage le runway sans masquer la bille ;
- vérifier que Final Show ajoute lead, impact et chase de faisceaux ;
- confirmer que Blackout coupe simultanément musique et faisceaux ;
- signaler toute saturation, craquement, ralentissement ou musique trop forte.

### Table 2.2 — checklist sensation physique

- comparer la vitesse de chute à la build précédente et confirmer la disparition
  de l'impression d'apesanteur ;
- laisser la bille toucher plusieurs rails et vérifier qu'elle ne rebondit plus
  de façon excessive ;
- vérifier que les flippers restent assez rapides pour viser malgré la masse ;
- confirmer que lanceur, bumpers et slingshots renvoient toujours la bille avec
  une portée utile ;
- observer une partie complète et signaler toute zone devenue trop rapide ou
  impossible à contrôler.

### Table 2.3 — checklist Cue Stack

- vérifier que seules les rampes Warm et Cold sont mises en évidence au début ;
- toucher chaque rampe une fois, puis confirmer `CUE READY — HIT CONSOLE` ;
- toucher la Console et vérifier le passage à Universe Chase ;
- traverser l'Universe Orbit deux fois, exécuter la cue, puis toucher quatre
  bumpers pour préparer Rhythm Drop ;
- confirmer que le HUD progresse de `CUE 1 / 3` à `CUE STACK 3 / 3` ;
- compléter uniquement le Rig et vérifier que le Final Show reste verrouillé ;
- compléter le Rig et la Cue Stack, puis confirmer que la Console déclenche le
  Final Show ;
- vérifier que la progression des cues survit à la perte d'une bille et revient
  à zéro après Reset ou Rejouer.

### Table 2.4 — checklist identité Stagecraft

- vérifier que la bille blanche reste immédiatement lisible sur toutes les zones ;
- confirmer que rails, flippers, bumpers, cibles, rampes et Console ressemblent
  à des pièces distinctes, et non à des formes plates interchangeables ;
- identifier sans texte les routes Warm, Cold, Console, launcher et drain ;
- contrôler que les faisceaux, la haze et les footlights restent derrière la
  bille et ne gênent jamais un tir ;
- comparer Standby, Build, Flow, Final Show et Blackout pour confirmer une montée
  d'énergie sans saturation permanente ;
- vérifier boutons et textes des menus en portrait, en particulier l'absence de
  coupe sur les bords d'une tablette ;
- surveiller fluidité, chauffe et batterie pendant une partie complète Android.

### Sync Bonus — checklist tablette

- repérer les quatre témoins de tempo et confirmer qu'ils suivent la musique ;
- toucher plusieurs éléments sur le pulse et obtenir `PERFECT SYNC` ou `SYNC` ;
- vérifier que texte, flash et SFX sont perceptibles sans masquer la bille ;
- provoquer deux contacts presque simultanés et confirmer un seul bonus ;
- jouer volontairement hors tempo et confirmer que score, Flow et objectifs
  continuent normalement ;
- vérifier le comportement pendant le Final Show multiball et après un Blackout ;
- refaire le test avec le volume coupé : le marqueur visuel doit suffire.

Tout bug automatisable corrigé devrait recevoir un test raisonnable.

## Instrumentation locale de playtest

Le nœud `PlaytestRecorder` écrit `user://playtest/latest.json` avec la durée de
session, lancements, impacts de bumpers, drains, ball saves, relances, points
marqués, Sync et Perfect Sync. Cette trace reste locale : aucun réseau, compte ou télémétrie n'est
utilisé. Elle sert à comparer les sensations entre builds pendant un playtest.

Avant release publique : au moins Android réel, iPhone/iPad réel pour iOS, navigateurs récents, Windows natif, macOS/Linux selon disponibilité.

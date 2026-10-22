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
- vérifier le message `RIG PRÊT — TERMINEZ LA CUE STACK` ou l'armement du Final Show selon la progression ;
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
- toucher chaque rampe une fois, puis confirmer `CUE PRÊTE — VISEZ LA CONSOLE` ;
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

### Réglages audio — checklist tablette

- ouvrir `RÉGLAGES` depuis le menu et vérifier que les trois sliders sont
  lisibles et manipulables au doigt en portrait ;
- régler séparément Master, Musique et Effets, puis confirmer que le changement
  est audible immédiatement ;
- mettre Musique à 0 % et vérifier que les SFX restent audibles ;
- mettre Effets à 0 % et vérifier que la musique reste audible ;
- revenir au menu, relancer l'application et confirmer que les trois valeurs
  sont conservées ;
- utiliser `VALEURS PAR DÉFAUT` et confirmer le retour des trois niveaux à 100 %.

### How to Play — checklist tablette

- ouvrir `COMMENT JOUER` depuis le menu et vérifier que textes, schémas et boutons
  restent entièrement visibles en portrait ;
- parcourir les quatre pages avec `SUIVANT` et `PRÉCÉDENT` au doigt ;
- confirmer que les illustrations correspondent aux commandes, au Rig, aux Cues
  et au Final Show réellement présents sur le plateau ;
- terminer le guide puis vérifier le retour au menu sans lancement de partie ;
- vérifier également Retour/Échap et la navigation clavier ou manette.

### Effets lumineux — checklist tablette

- ouvrir `RÉGLAGES`, vérifier que les trois modes sont lisibles et manipulables
  au doigt en portrait ;
- en `COMPLETS`, confirmer le comportement scénique actuel ;
- en `RÉDUITS`, vérifier que flashes, pulsations et Blackout sont nettement plus
  doux sans rendre les objectifs ambigus ;
- en `DÉSACTIVÉS`, confirmer l'absence de flash d'impact et de Blackout plein
  écran, tout en suivant les objectifs, le Rig et le pas actif de l'horloge Sync ;
- fermer puis relancer l'application et confirmer que le choix est conservé ;
- utiliser `VALEURS PAR DÉFAUT` et confirmer le retour à `COMPLETS` et aux trois
  niveaux audio à 100 %.

### Alpha 0.1.0 candidate — parcours complet tablette

- vérifier que l'écran d'accueil affiche `ALPHA 0.1.0` et que les consignes
  d'action sont en français, sans ancien numéro de table visible ;
- ouvrir Réglages et Comment jouer, puis revenir au menu sans démarrer de partie ;
- jouer exactement trois billes et confirmer que Reset, Safety et la fin de
  partie ne créent jamais de quatrième bille ;
- compléter les trois cues et les six familles du Rig, puis déclencher le Final
  Show via la Console ;
- confirmer la présence de trois billes pendant le Final Show, le passage par
  Blackout et le retour en Flow avec une bille survivante ;
- terminer la partie et vérifier l'arrêt de la musique, le score final et les
  actions Rejouer/Menu ;
- noter la version, le modèle Android et toute étape impossible à terminer dans
  le rapport de validation.

Tout bug automatisable corrigé devrait recevoir un test raisonnable.

### PR 30 — validation prioritaire sur tablette

- Depuis Jouer, vérifier GO en bas à droite et l'absence de lancement au toucher
  du haut du plateau ; Espace et A manette doivent rester utilisables.
- Appuyer sur GO : la bille monte dans le couloir, négocie la courbe puis entre
  dans le haut du jeu. Répéter plusieurs lancements, sans toucher les flippers,
  puis en jouant le premier retour.
- Vérifier que GO disparaît pendant le jeu et revient après Safety ou au début
  de la bille suivante ; des appuis répétés ne créent aucune bille supplémentaire.
- Maintenir chaque flipper séparément puis simultanément ; relâcher au-dessus
  d'un bouton ne doit pas laisser de flipper bloqué.
- Observer des retours depuis les deux côtés et viser un renvoi vers le plateau.
  Signaler précisément le côté et la trajectoire de toute perte injuste.
- Vérifier que la bille ne se bloque pas aux jonctions des guides et qu'aucun
  sauvetage automatique n'est nécessaire pendant un lancement normal.
- Une perte centrale reste normale ; le lancement et les retours ne doivent
  plus y conduire systématiquement sans possibilité de jouer.

La validation de cette PR porte sur la géométrie et les commandes. Le roulement,
les vrais parcours de rampes et la refonte artistique restent à réaliser avant
qualification Alpha.

### PR 31 — roulement et tirs sur tablette

- Comparer plusieurs descentes libres : accélération franche vers le bas,
  conservation de la vitesse en traversée et contacts sans rebond excessif.
- Refaire les lancements GO et jouer le premier retour des deux côtés.
- Retenir la bille sur chaque flipper levé pendant au moins cinq secondes :
  aucun sauvetage automatique ni retour au launcher ne doit interrompre le maintien.
- Relâcher brièvement puis réappuyer ; comparer frappe précoce et frappe tardive.
  Vérifier que les deux côtés offrent des visées distinctes et accessibles.
- Vérifier le passage autour des palettes levées, les retours latéraux et les
  slingshots ; signaler le lieu d'un blocage ou d'une perte injuste.
- Une bille réellement coincée ailleurs doit encore être récupérée, même si un
  flipper reste maintenu. Recommencer la partie remet les deux moteurs au repos.
- Noter modèle de tablette, version, vitesse ressentie, précision des tirs et
  contacts problématiques. Les tests numériques ne valident pas le plaisir de jeu.

Les essais Godot mesurent aussi masse indépendante, pente, résistance constante,
arrêt sans inversion, limite de vitesse et cohérence à 60/120 Hz. Les rampes en
hauteur, le glissement transitoire et le spin complet restent hors du modèle 2D.

## Instrumentation locale de playtest

Le nœud `PlaytestRecorder` écrit `user://playtest/latest.json` avec la durée de
session, lancements, impacts de bumpers, drains, ball saves, relances, points
marqués, Sync et Perfect Sync. Cette trace reste locale : aucun réseau, compte ou télémétrie n'est
utilisé. Elle sert à comparer les sensations entre builds pendant un playtest.

Avant release publique : au moins Android réel, iPhone/iPad réel pour iOS, navigateurs récents, Windows natif, macOS/Linux selon disponibilité.

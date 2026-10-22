# UX / UI

## Objectif

Apprendre au joueur à lire le show sans connaître la régie lumière.

## HUD

Score, billes restantes, Flow, cue/objectif courant, mode spécial.

## Hiérarchie

Bille → dangers → objectif → mode → score → décoration. Si l'UI gêne la bille, l'UI perd.

## Mobile

Zones tactiles larges et discrètes : la moitié basse gauche/droite commande
les flippers, tandis qu'un toucher dans la zone haute lance ou relance la
bille. Les commandes Reset et Quit restent en haut du plateau, hors des zones
de flipper sous les pouces.

## Desktop

Clavier/manette ; souris pour menus.

## Menus MVP

```text
Main Menu
├── Play
├── How to Play
├── Settings
│   ├── Audio
│   ├── Graphics
│   ├── Controls
│   └── Accessibility
├── Credits
└── Quit (desktop only)
```

Le menu de playtest fournit Jouer, Comment jouer, Réglages et Quitter. Trois
sliders tactiles règlent Général, Musique et Effets de 0 à 100 %, et le même
panneau propose les effets lumineux Complets, Réduits ou Désactivés. Les
changements sont immédiats, réinitialisables et sauvegardés localement. Graphics,
Controls et Credits restent à compléter dans l'interface finale.

Les consignes d'action sont rédigées en français pour l'Alpha. Les noms de
systèmes qui constituent l'identité du jeu restent canoniques : Rig, Cue,
Cue Stack, Flow, Sync, Final Show, Blackout et Safety.

## Tutoriel

Le guide accessible depuis le menu tient en quatre pages illustrées :

1. lancer dans la zone haute et contrôler les flippers dans les zones basses ;
2. toucher les six familles pour construire le Rig ;
3. suivre les tirs demandés puis passer par la Console pour exécuter les Cues ;
4. compléter Rig + Cue Stack et déclencher le Final Show.

Chaque page contient une seule intention, un schéma vectoriel du plateau et un
objectif court. La navigation fonctionne au tactile, au clavier et à la manette,
et quitter le guide ne démarre jamais implicitement une partie.

## Feedback

Combiner son, flash, texte, animation, vibration optionnelle. Ne jamais dépendre uniquement de vibration ou couleur.

Le Sync Bonus suit cette règle : quatre témoins marquent le tempo sur le plateau,
un flash renforce l'impact et un texte temporaire annonce `SYNC` ou
`PERFECT SYNC` avec les gains de score et Flow. La couleur cyan/ambre reste un
renfort, jamais l'unique distinction entre les deux résultats.

## Conduite du show

Le HUD affiche toujours l'état courant sous la forme `SHOW PRESET`, `SHOW BUILD`,
`SHOW FLOW`, `SHOW FINAL SHOW` ou `SHOW BLACKOUT`. Le Final Show ajoute une
bannière centrale avec le nombre de billes et le multiplicateur, puis un écran
Blackout bref. Les informations restent textuelles en plus des changements de
couleur afin de ne pas dépendre de la perception chromatique.

## Fin de partie

Après la troisième bille consommée, le plateau n'accepte plus les touchers de
jeu. Un écran dédié affiche le score final et propose uniquement Rejouer ou Menu.
Safety annonce explicitement qu'il s'agit de la même bille et demande une
relance depuis le launcher.


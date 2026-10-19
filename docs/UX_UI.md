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

Le premier build de playtest fournit un écran de démarrage avec Play et Quit,
ainsi que Reset et Quit pendant la partie. How to Play, Settings et Credits
restent à implémenter dans l'interface finale.

## Tutoriel

Toucher gauche/droite, lancer, montrer un objectif, laisser jouer.

## Feedback

Combiner son, flash, texte, animation, vibration optionnelle. Ne jamais dépendre uniquement de vibration ou couleur.

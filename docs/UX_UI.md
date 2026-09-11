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
bille. Aucun bouton indispensable n'est ajouté sous les pouces.

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

## Tutoriel

Toucher gauche/droite, lancer, montrer un objectif, laisser jouer.

## Feedback

Combiner son, flash, texte, animation, vibration optionnelle. Ne jamais dépendre uniquement de vibration ou couleur.

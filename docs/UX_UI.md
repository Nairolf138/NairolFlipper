# UX / UI

## Objectif

Apprendre au joueur à lire le show sans connaître la régie lumière.

## HUD

Score, billes restantes, Flow, cue/objectif courant, mode spécial.

## Hiérarchie

Bille → dangers → objectif → mode → score → décoration. Si l'UI gêne la bille, l'UI perd.

## Mobile

Zones tactiles larges et discrètes : la moitié basse gauche/droite commande
les flippers. Un bouton `GO` en bas à droite lance la bille quand elle est prête,
y compris après Safety ou récupération. Il disparaît pendant le jeu ; toucher
le haut du plateau ne lance plus. Espace et A sur manette restent disponibles.
Les commandes Recommencer et Quitter restent en haut du plateau.
La PR 34 remplace Quitter en jeu par **PAUSE**, qui propose Reprendre, Rapport,
Menu (abandon explicite) et Quitter l'application. Échap / Start manette déclenchent aussi Pause.
Une perte de focus ou un passage en arrière-plan suspend la partie ; revenir
dans l'application n'envoie jamais automatiquement la bille en mouvement.

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

1. lancer avec GO et contrôler les flippers dans les zones basses ;
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

RAPPORT DE TEST est disponible depuis le menu, Pause et la fin de partie. Le
texte est consultable / sélectionnable et copiable par un bouton ; aucun partage
réseau automatique. Le rapport ne couvre pas la chauffe ou la sensation, à
ajouter manuellement dans le retour de qualification.

Après la troisième bille consommée, le plateau n'accepte plus les touchers de
jeu. Un écran dédié affiche le score final et propose Rejouer, Menu et Rapport de test.
Safety annonce explicitement qu'il s'agit de la même bille et demande une
relance depuis le launcher.


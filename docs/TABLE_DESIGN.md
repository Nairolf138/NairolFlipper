# Design du plateau

## Orientation

Plateau principal **portrait**, canvas logique `1080 × 1920`. Sur desktop/Web large, table centrée et espaces latéraux pour HUD/art.

## Schéma conceptuel

```text
┌──────────────────────────────────┐
│          UNIVERSE ORBIT          │
│    ╭────────────────────────╮    │
│    │    BEAM      GOBO      │    │
│    │       ○  ○  ○          │    │
│    │     RHYTHM BUMPERS      │    │
│    ╰────╮              ╭────╯    │
│ WARM   /                \   COLD │
│ RAMP  /     CONSOLE      \  RAMP│
│      /        ◎           \      │
│     │ WASH           STROBE│     │
│      \     BLINDER        /      │
│       [L]              [R]       │
│          DRAIN / BLACKOUT        │
│                         LAUNCH → │
└──────────────────────────────────┘
```

## Zones obligatoires

Launcher, deux flippers, drain, outlanes, trois bumpers, deux trajectoires longues, une orbite, Console, cibles Rig.

## Principes

- Lisibilité par silhouette/mouvement/lumière/position, pas couleur seule.
- Depuis les flippers : tir sûr, progression, score, risque.
- Retours apprenables.
- Densité visuelle croissante sans chaos illisible.

## Mobile

Bas gauche = flipper gauche, bas droite = flipper droit, launcher distinct. Tolérer les doigts qui masquent l'écran.

## Caméra

MVP fixe, plateau entier visible. Micro-shake optionnel avec réduction des mouvements.


## Table 2.0 — première boucle jouable

La première refonte greybox matérialise la promesse « construire le show » :

- une **Universe Orbit** haute, lisible et généreuse ;
- six cibles Rig distinctes : Face, Wash, Beam, Pixel, Blinders et Practical ;
- un compteur permanent `RIG 0 / 6` ;
- deux slingshots actifs pour accélérer le bas du plateau ;
- des rails physiques qui dessinent deux outlanes, deux retours et séparent le launcher ;
- un bonus de complétion quand les six familles sont allumées ;
- l'instruction suivante, **RIG READY — HIT CONSOLE**, qui évite de laisser le joueur sans objectif.

Cette version reste vectorielle et sans art final : elle valide d'abord les
trajectoires, la compréhension des objectifs et le rythme sur tablette.

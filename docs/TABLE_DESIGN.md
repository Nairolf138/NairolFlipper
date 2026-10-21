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

## Table 2.1 — trajectoires sûres

Les limites latérales rejoignent désormais la zone de drain afin qu'une bille ne
puisse plus quitter silencieusement le plateau. Les guides supérieurs descendent
vers le centre : une bille lente roule vers le jeu au lieu de se caler contre un
mur dans un angle fermé.

Le bas du plateau distingue trois chemins :

- deux inlanes larges ramènent la bille au-dessus du flipper correspondant ;
- deux outlanes restent des pertes volontaires et lisibles ;
- le couloir du lanceur reste physiquement séparé jusqu'à proximité du drain.

La géométrie conserve une ouverture centrale franche entre les flippers. Les
guides améliorent les retours latéraux sans supprimer le risque principal du
flipper.

## Table 2.3 — Cue Stack

Le plateau transforme ses routes en conduite de spectacle :

1. **Color Wash** demande un passage sur chacune des rampes Warm et Cold ;
2. **Universe Chase** demande deux passages dans l'Universe Orbit ;
3. **Rhythm Drop** demande quatre impacts sur les bumpers rythmiques.

Une cue préparée clignote comme disponible, puis la Console sert de bouton
`GO`. Le HUD affiche le nom, l'objectif et le nombre de tirs réalisés. Les
éléments attendus sont renforcés visuellement et s'éteignent dès que leur part
de l'objectif est acquise.

Le Final Show s'arme uniquement lorsque la Cue Stack et le Rig `6 / 6` sont
terminés. Les deux progressions peuvent être menées en parallèle et persistent
entre les trois billes de la partie.

## Table 2.4 — identité Stagecraft

Le greybox devient une scène de spectacle cohérente sans modifier les
collisions validées :

- le plateau est un **stage deck** sombre, segmenté et dessiné en perspective ;
- trois routes lumineuses distinguent Warm, Cold et Console tout en conservant
  une silhouette lisible en niveaux de gris ;
- les rails ressemblent à des profilés métalliques plutôt qu'à des barres
  blanches posées sur le plateau ;
- bumpers, cibles Rig, rampes et Console reprennent les formes de lentilles,
  flight-cases, faders et signalétique d'une régie live ;
- launcher et drain disposent de leur propre marquage, afin d'indiquer clairement
  l'entrée et la zone de danger ;
- le HUD occupe une baie technique séparée du jeu et les menus utilisent le même
  vocabulaire de cadres sombres et de bordures lumineuses.

Les faisceaux, la haze discrète et les footlights restent derrière les pièces de
jeu et la bille. Ce jalon ne change ni la géométrie physique, ni les règles de la
Cue Stack : il rend leur hiérarchie et l'identité du produit immédiatement
perceptibles.

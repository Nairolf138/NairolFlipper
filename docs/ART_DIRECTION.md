# Direction artistique

## Intention

Un **plateau de flipper transformé en scène de spectacle abstraite**. Le noir sert à donner de la valeur à la lumière.

## Mots-clés

Scène noire, faisceau, métal, verre, haze, console, précision, énergie, néon, contraste, profondeur, élégant, technique, musical.

## À éviter

Cyberpunk générique, arc-en-ciel permanent, imitation exacte d'une console ETC/MA, photoréalisme coûteux, micro-UI, particules servant de cache-misère.

## Palette de départ

| Rôle | Couleur |
|---|---|
| Background | `#05070D` |
| Surface sombre | `#0D1320` |
| Cyan électrique | `#00E5FF` |
| Magenta | `#FF2BD6` |
| Ambre | `#FFB14A` |
| Violet | `#7C4DFF` |
| Blanc froid | `#EAF6FF` |
| Alerte | `#FF3B4D` |

## Grammaire visuelle

Inactif = faible intensité. Disponible = animation lente. Hit = flash court. Complété = changement durable. Climax = familles synchronisées sans saturation constante.

## Fixtures virtuelles

Iconographie originale : anneaux, lentilles, hexagones, volets abstraits, faisceaux géométriques. Pas de copie réaliste obligatoire.

## Faisceaux

Approche 2D légère : sprites dégradés, polygons/meshes 2D, shaders CanvasItem compatibles, transparences limitées. Fallback Low/Medium/High.

## Typographie

Sans serif lisible, chiffres distincts, style technique original, licence libre.

## Logo

Casse canonique : **NairolFlipper**. Peut évoquer trajectoire de bille, faisceau, fader, cue ou onde musicale.

## Première implémentation scénique

Le plateau affiche un truss de six fixtures, des faisceaux géométriques, une
grille technique et un runway animé. Chaque famille active durablement sa
fixture ; Flow augmente l'énergie et Final Show lance une chase plus rapide.
Blackout coupe les faisceaux. Le renderer reste vectoriel, sans texture ni shader
plein écran, pour préserver la lisibilité et les performances mobiles.

## Table 2.4 — langage Stagecraft

La première passe d'identité remplace les grandes formes plates du prototype par
un système visuel commun : métal sombre, verre coloré, repères de gaffer, baies
techniques et signalétique lumineuse. Chaque pièce garde une silhouette propre :

- **rails** : profilé acier, face sombre et arête lumineuse ;
- **flippers** : palette mécanique, pivot apparent et spine métallique ;
- **bumpers** : lentille de projecteur dans un bezel octogonal ;
- **cibles Rig** : module de rack avec témoin d'état persistant ;
- **rampes** : deck sombre encadré par sa couleur Warm ou Cold ;
- **Console** : faceplate et strip `GO`, distincte d'une simple cible de score.

La couleur guide mais ne porte jamais seule l'information : différences de
forme, largeur, position et contraste restent visibles. Toute la passe utilise
les primitives Canvas 2D de Godot ; aucun asset tiers, texture HD, système de
particules ou shader plein écran n'est ajouté.

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
Blackout coupe les faisceaux. Les effets utilisent des primitives Canvas 2D,
sans shader plein écran, pour préserver la lisibilité mobile.

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
forme, largeur, position et contraste restent visibles.

## PR 33 — matériaux et pièces scéniques

La passe précédente restait trop abstraite au playtest. Le nouveau vocabulaire
est matériel : sol de scène mat, profilés acier, caoutchouc crème, verre avec
reflets et console équipée de faders. Six silhouettes originales distinguent
Fresnel à volets, wash LED, tête mobile, barre pixel, blinder double et pratique
protégée. La lumière d'objectif ne doit pas gonfler le corps mécanique.

Les SVG originaux sont importés comme petites textures partagées ; provenance,
licence et tailles dans `assets/textures/stagecraft/README.md`. Pas de marque,
image tierce, shader plein écran ni plugin. Le sol est plafonné à 1024 × 1536.
Le reflet de la bille chromée reste fixe dans le repère du plateau.

Les rampes utilisent les arêtes physiques déjà calculées : montée en acrylique
translucide, retour en wireform ouvert, traverses, colonnes et semelles. Le tri
visuel Warm 2 / Cold 4 / Orbit 6 réserve à chaque bille le plan juste au-dessus
de sa route. Cela reste une approximation 2D, pas une simulation de hauteur 3D.
Les anciennes grandes bandes néon disparaissent. Les pièces basses restent
visibles sous les retours ouverts ; aucun décor ne crée un obstacle fictif.
Les noms et témoins de progression sont des annotations au premier plan : ils
ne disparaissent pas sous un rail, contrairement aux corps matériels des pièces.

Les captures GL en CI servent à inspecter le menu, le départ, le plateau éclairé,
le mode sans effets et les trois plans de bille en 540 × 960 / 1080 × 1920.
Les poses ne prouvent ni la jouabilité ni les performances sur tablette : le
playtest PR 33 reste obligatoire avant la qualification Alpha PR 34.

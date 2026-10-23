# Budget de performance

## Cibles

Mobile natif : 60 FPS cible, aucun freeze de cue/multiball. Web : 60 FPS machine correcte, fallback 30 acceptable si cohérent. Desktop : 60 FPS minimum cible.

## Visuel

Éviter grandes transparences empilées, particules illimitées, shaders plein écran permanents, allocations massives par hit. Préférer pooling, sprites/meshes simples, shaders courts, niveaux Low/Medium/High.

## Audio

Stems compressés raisonnablement, preload des sons essentiels, stream pour musique longue, nombre de players limité.

## Profiling

PR 33 : huit SVG originaux, atlas partagé, source du sol limitée à 1024 × 1536,
empreinte RGBA native de ces assets inférieure à 7 MiB (hors overhead import).
Les rampes préparent leurs tableaux une fois et le dessin statique est mis en
cache par CanvasItem. Pas de géométrie de rampe reconstruite par frame ou hit.
La CI archive les draw calls et mémoire texture de chaque pose ; ces valeurs
ne sont pas des FPS de tablette. Le budget 60 FPS exige toujours une mesure
Android réelle avant PR 34.

Le rapport PR 34 mesure la cadence murale uniquement pendant le jeu, avec
histogramme fixe de 251 cases, p95 à 1 ms plafonné à 250 ms, compteur >50 ms et
moyenne Final Show séparée. Menus / pauses sont exclus. Cela ne mesure pas le
GPU ni la chauffe. Le journal est groupé toutes les cinq secondes au lieu d'être
écrit à chaque contact. Utiliser `ALPHA_QUALIFICATION.md` pour le seuil appareil.

Optimiser sur mesure réelle. Jalons : premier plateau complet, Final Show, première release Web, première release mobile.

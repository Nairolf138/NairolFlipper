# Budget de performance

## Cibles

Mobile natif : 60 FPS cible, aucun freeze de cue/multiball. Web : 60 FPS machine correcte, fallback 30 acceptable si cohérent. Desktop : 60 FPS minimum cible.

## Visuel

Éviter grandes transparences empilées, particules illimitées, shaders plein écran permanents, allocations massives par hit. Préférer pooling, sprites/meshes simples, shaders courts, niveaux Low/Medium/High.

## Audio

Stems compressés raisonnablement, preload des sons essentiels, stream pour musique longue, nombre de players limité.

## Profiling

Optimiser sur mesure réelle. Jalons : premier plateau complet, Final Show, première release Web, première release mobile.

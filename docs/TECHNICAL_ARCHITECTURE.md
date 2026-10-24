# Architecture technique

## Stack

Godot 4.7.2 stable, GDScript, 2D, GL Compatibility, GitHub Actions, stockage local MVP.

## Arborescence cible

```text
assets/{audio,fonts,textures,shaders,branding}
data/{cues,scoring,tuning,localization}
scenes/{app,gameplay,table,ui}
scripts/{app,gameplay,show,audio,platform,ui}
tests/{unit,integration}
docs/
```

## Couches

- App : navigation, lifecycle, pause, settings, sauvegarde.
- Gameplay : bille, flippers, bumpers, targets, lanes, score, lifecycle.
- Show : cues, Rig, Flow, modes.
- Audio : transport, stems, SFX.
- Platform : haptics/lifecycle/capacités optionnelles.
- UI : HUD, menus, overlays.

## Managers

Limiter les autoloads. Globaux possibles : AppState, SettingsService, SaveService, AudioService. Score et CueManager vivent de préférence dans la session.

## Événements

Signaux typés : `ball_drained`, `score_changed`, `rig_family_activated`, `cue_started`, `cue_completed`, `flow_changed`, `final_show_started`.

## Data-driven

Resources : `PhysicsTuning`, `ScoreRules`, `CueDefinition`, `ShowModeDefinition`, `AudioStemSet`.

## Input

Actions : `flipper_left`, `flipper_right`, `launch_ball`, `pause`, puis nudges.

## Sauvegarde

Paramètres, meilleur score, statistiques simples, version de schéma. Jamais considérée comme anti-triche.

## Dépendances

Zéro addon tiers par défaut. Toute dépendance doit résoudre un vrai problème, être multiplateforme, licenciée, documentée par ADR et épinglée.

## Physique

Tick initial : 120 Hz, à valider par profiling.

La bille intègre un roulement projeté dans `_integrate_forces` ; Godot conserve
les collisions et le CCD par forme. `PhysicsTuning` porte pente, échelle,
résistance et impulsions ; `FlipperTuning` porte le moteur des palettes.
Voir [ADR-0005](adr/0005-projected-rolling-physics.md) pour les hypothèses et limites.

`PhysicalRoute` génère rails, deck et portes depuis `PhysicalRouteDefinition`.
Les plans `1/4/8/16` isolent plateau/Warm/Cold/Orbit sans modifier le mouvement
de la bille à l'admission. Les wrappers Ramp/Lane conservent les signaux de jeu,
émis après une traversée complète. Voir [ADR-0006](adr/0006-physical-routes-on-separated-planes.md).

## Renderer

GL Compatibility par défaut. Toute feature avancée exige fallback.

`RouteVisual` prépare une fois le matériau depuis les arêtes de `PhysicalRoute` ;
il ne modifie ni points, ni corps, ni vitesses. `draw_layer` et
`wire_start_point_index` sont exclusivement des données de présentation. La bille
prend `route.z_index + 1` puis restaure son plan initial à la sortie. Les plans
de collision restent indépendants du tri visuel. Les SVG scéniques originaux
sont rasterisés à l'import ; aucune dépendance graphique native n'est ajoutée.

## Plateforme

Le focus perdu / suspendu met l'arbre en pause synchroniquement après flush du
journal et libération des actions. `PlaytestOverlay` reste en `PROCESS_MODE_ALWAYS`
pour reprendre explicitement, ouvrir le rapport ou revenir au menu. Les timers
Final Show, Blackout et respawn utilisent `process_always = false`. La physique,
les plans de route et le transport audio sont conservés ; aucun repositionnement
n'est fait à la reprise. Le retrait de scène libère une pause qu'elle possédait.
Les drains différés déjà en file sont conservés jusqu'à la reprise, avec l'epoch
de la bille ; un reset / relancement invalide le callback de l'ancienne bille.

`PlaytestRecorder` conserve des compteurs en RAM, un histogramme fixe de cadence
et une sauvegarde au plus toutes les cinq secondes en jeu, plus flush explicite
à Pause / Menu / fin / Quitter. Aucun I/O n'est fait à chaque impact. Le rapport
est un texte local en lecture seule ; le presse-papiers n'est écrit qu'après le
geste Copier, avec sélection manuelle en fallback. Aucune donnée n'est envoyée.

`Gameplay → PlatformService → implémentation native/web/no-op` pour les capacités optionnelles.

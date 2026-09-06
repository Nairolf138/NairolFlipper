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

## Renderer

GL Compatibility par défaut. Toute feature avancée exige fallback.

## Plateforme

`Gameplay → PlatformService → implémentation native/web/no-op` pour les capacités optionnelles.

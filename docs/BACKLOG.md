# Backlog initial

Ordre volontaire. Ne pas sauter plusieurs étapes sans raison.

## P0 — Bootstrap

### T001 — Valider le projet Godot ✅

But : ouvrir le dépôt avec Godot 4.7.2 sans erreur. Done : `project.godot` valide, scène bootstrap créée, fenêtre portrait, aucun addon. Validation Godot headless à compléter lorsque l’éditeur sera disponible dans l’environnement.

### T002 — Input Map ✅

Actions `flipper_left`, `flipper_right`, `launch_ball`, `pause` déclarées dans `project.godot` avec raccourcis clavier. La même map pourra être consommée par les contrôles tactiles et manette sans dépendance native.

### T003 — Greybox table ✅

Limites, drain, lane launcher, zones simples. Pas d'art final. La scène principale contient maintenant les limites physiques et un rendu de plateau minimal.

### T004 — Ball ✅

`RigidBody2D`, collision, CCD, tuning, reset. La scène `Ball.tscn` instancie une bille physique avec collision continue et le script expose `reset_ball()`.

### T005 — Flippers ✅

Gauche/droite, press/release, collisions, tuning.

### T006 — Launcher ✅

Placement dans la lane, lancement contrôlé via `launch_ball`, bloqué si aucune bille prête. La bille est immobilisée au démarrage et propulsée une seule fois par l'action `launch_ball`.

### T007 — Bumpers

Trois bumpers : impulse, SFX placeholder, flash, score event.

### T008 — Score + HUD

ScoreManager de session, signal, score visible, reset.

### T009 — Ball lifecycle

3 billes, drain, délai, respawn, game over, restart.

### T010 — Mobile touch

Gauche/droite, launcher, UI non envahissante.

### T011 — Smoke tests

Import, main scene load, score logic, drain lifecycle.

### T012 — CI P0

Validation, Web artifact, Android debug APK, Windows artifact.

## P1 — Feel

T020 Physics tuning resource; T021 Ball max speed/anti-tunneling; T022 Feedback hit; T023 Ball save; T024 Controller support; T025 instrumentation locale de playtest.

## P1 — Show systems

T030 Rig model; T031 CueDefinition; T032 CueManager; T033 Flow; T034 Warm/Cold ramps; T035 Console scoop; T036 First show sequence.

## P1 — Audio

T040 Audio service; T041 SFX buses; T042 Music transport; T043 Stem set; T044 Sync Bonus.

## P2 — Final

T050 Ball lock; T051 Multiball; T052 Final Show; T053 Blackout; T054 Encore prototype.

## Règle

Chaque tâche utilise une Issue avec objectif, non-objectifs, critères d'acceptation et test.

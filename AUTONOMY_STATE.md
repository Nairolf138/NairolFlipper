# AUTONOMY_STATE.md

## Dernière exécution

- Date : 2026-09-11 13:22 UTC / 15:22 Europe/Paris
- Cycle : T010 — Mobile touch
- Statut : implémenté, testé, prêt à livrer sur `hermes-autonomous`
- Temps restant : environ 50 heures avant le 13 septembre 2026 à 18:00 Europe/Paris

## Dépôt

- Branche : `hermes-autonomous`
- Dernier commit de référence avant ce cycle : `c9af90e` (T009 Ball lifecycle)
- Dernier commit : à créer sur `hermes-autonomous`
- Commit fonctionnel du cycle : à créer (`feat: add mobile touch controls`)
- Dépôt distant : `Nairolf138/NairolFlipper`
- Branche `main` : mise à jour par fusion PR #7 après ce cycle

## État actuel

Le dépôt contient maintenant un bootstrap Godot minimal, une table greybox, une bille physique, deux flippers, un launcher et trois bumpers :

- `project.godot` déclare `res://scenes/app/Main.tscn` comme scène principale ;
- `project.godot` déclare `flipper_left` (A), `flipper_right` (D), `launch_ball` (Espace) et `pause` (Échap) ;
- `scenes/app/Main.tscn` contient une racine `Node2D` nommée `Main` ;
- `scenes/app/Main.tscn` contient un plateau visible, quatre corps statiques pour les limites/drain et une lane launcher ;
- `scenes/app/Main.tscn` instancie `scenes/gameplay/Ball.tscn` ;
- `Ball.tscn` utilise un `RigidBody2D`, une collision circulaire et le CCD ;
- `scripts/gameplay/ball.gd` réinitialise position et vitesses via `reset_ball()` ;
- `scenes/gameplay/Bumper.tscn` décrit un bumper réutilisable avec collision et rendu greybox ;
- `scripts/gameplay/bumper.gd` applique une impulsion radiale, émet `bumper_hit` et flash le bumper à l'impact ;
- `scenes/app/Main.tscn` instancie les bumpers Kick, Snare et Tom ;
- `scripts/gameplay/score_manager.gd` accumule les points et émet `score_changed` ;
- `scripts/app/main.gd` connecte les impacts des bumpers au ScoreManager et met à jour `ScoreLabel` ;
- `ScoreManager` et `ScoreLabel` sont présents dans la scène principale ;
- la scène contient trois billes, un drain détectant leur entrée, un respawn temporisé, un compteur de vies, un état game over et un restart ;
- `scripts/app/main.gd` accepte les touchers/drags : flippers en moitié basse, lancement dans la zone haute, sans bouton HUD persistant ;
- aucun addon ou asset externe n’a été ajouté ;
- le projet reste compatible avec l’architecture 2D GL Compatibility documentée.

## Tâches terminées

### T001 — Bootstrap Godot minimal

- Test de contrat ajouté dans `tests/test_bootstrap.py`.
- Test observé en échec avant implémentation.
- Configuration et scène ajoutées.
- Test repassé au vert : `2 passed`.
- Backlog mis à jour.

### T002 — Input Map

- Test de contrat ajouté dans `tests/test_bootstrap.py`.
- Test observé en échec avant l'ajout des actions.
- Quatre actions clavier ajoutées dans `project.godot` : `flipper_left` (A), `flipper_right` (D), `launch_ball` (Espace) et `pause` (Échap).
- Suite complète repassée au vert : `3 passed`.
- Backlog mis à jour.

### T003 — Greybox table

- Test de contrat ajouté dans `tests/test_bootstrap.py` pour les cinq zones de collision.
- Test observé en échec avant l'ajout de la scène greybox.
- Limites gauche/droite/haut, drain et lane launcher ajoutés en scène Godot, sans asset externe.
- Rendu minimal du plateau ajouté avec `Polygon2D`.
- Suite complète repassée au vert : `4 passed`.
- Backlog mis à jour.

### T004 — Ball

- Test de contrat ajouté dans `tests/test_bootstrap.py` pour la scène et le script de bille.
- Test observé en échec avant l’implémentation (`Ball.tscn` absent).
- `Ball.tscn` ajouté avec `RigidBody2D`, collision circulaire, CCD et rendu greybox minimal.
- `ball.gd` ajouté avec position de spawn exportée et `reset_ball()` qui annule les vitesses.
- Suite ciblée repassée au vert : `5 passed`.
- Backlog mis à jour.

### T005 — Flippers ✅

- `Flipper.tscn` ajouté avec `AnimatableBody2D`, collision et rendu greybox.
- `flipper.gd` ajoute l’activation press/release via `Input.is_action_pressed` et une rotation interpolée.
- Deux flippers instanciés dans `Main.tscn`, avec actions clavier gauche/droite.
- Suite complète repassée au vert : `6 passed`.

### T006 — Launcher ✅

- Contrat de test ajouté pour le lancement contrôlé et le verrouillage quand la bille n'est plus prête.
- Test rouge observé avant implémentation.
- La bille démarre immobilisée au centre de la lane launcher.
- `launch_ball` libère la bille et applique une impulsion verticale une seule fois.
- Un second lancement est refusé tant que la bille n'a pas été réinitialisée.

### T007 — Bumpers ✅

- Test de contrat ajouté pour trois instances, collision, impulsion, signal et flash.
- Test rouge observé avant la création de `Bumper.tscn` et `bumper.gd`.
- Bumper réutilisable ajouté en `Area2D`, avec impulsion radiale configurable et valeurs de score propres à chaque instance.
- Les instances Kick, Snare et Tom sont placées dans la scène principale.
- Aucun ScoreManager ni audio n'est ajouté : le signal prépare les prochains jalons sans élargir la tâche.
- Suite complète repassée au vert : `8 passed`.

### T010 — Mobile touch ✅

- Test de contrat ajouté avant implémentation et observé en échec.
- Toucher dans la moitié basse : presse l'action du flipper gauche ou droit.
- Relâchement et glissement : libèrent ou transfèrent proprement l'action tactile.
- Toucher dans la zone haute : lance la bille ou redémarre après game over.
- Documentation UX et backlog mis à jour.
- Suite complète repassée au vert : `12 passed`.

### Tâche suivante probable

### T011 — Smoke tests

Renforcer les tests de chargement et de cycle de jeu avant de préparer T012 CI/builds.

## Tests

- `python3 -m pytest tests/test_bootstrap.py::test_main_scene_declares_score_manager_and_hud -v` → `1 passed` après échec rouge initial attendu.
- `python3 -m pytest tests/test_bootstrap.py::test_score_manager_accumulates_and_resets_points -v` → `1 passed` après échec rouge initial attendu.
- `python3 -m pytest tests/test_bootstrap.py::test_ball_lifecycle_declares_three_balls_drain_and_restart -v` → `1 passed` après échec rouge initial attendu.
- `python3 -m pytest tests/test_bootstrap.py::test_mobile_touch_controls_cover_flippers_and_launcher -v` → `1 passed` après échec rouge initial attendu.
- `python3 -m pytest -q` → `12 passed`.
- Smoke test Godot 4.7.2 ARM64 : réussi avec `--headless --display-driver headless --audio-driver Dummy --path . --quit-after 5`.
- `git diff --check` → réussi.

## Builds

- Godot 4.7.2 ARM64 installé localement sous `/root/.local/opt/godot/4.7.2`.
- Export templates 4.7.2 installés sous `/root/.local/share/godot/export_templates/4.7.2.stable`.
- Aucun export Web/Android/Windows généré : aucun `export_presets.cfg` n’est encore défini.
- CI GitHub accessible via `gh`; aucun workflow de build n’est encore présent dans le dépôt.

## Problèmes connus

- Le dépôt est encore un greybox : le cycle de billes est fonctionnel mais non encore validé par playtest humain.
- Le mode `--headless --editor --quit` crashe sous root/PRoot (signal 11), mais le mode d’exécution headless du projet passe.
- Le contrôle tactile n’a pas encore été validé sur un appareil réel ; il est couvert par contrat statique et par le chargement Godot headless.
- La validation réelle Web/Android/Windows reste à faire via des presets et une CI.

## Blocages

- Aucun blocage sur le chargement/exécution headless du projet.
- T012 reste nécessaire pour créer les presets d’export et la CI Web/Android/Windows.
- Le SDK Android n’a pas encore été vérifié pour produire un APK local.

Ces blocages ne justifient pas l’arrêt du développement des éléments vérifiables par tests statiques et Python.

## Livrables actuellement disponibles

- `project.godot` configuré avec scène principale.
- `scenes/app/Main.tscn` avec limites, drain et lane launcher greybox.
- `tests/test_bootstrap.py` avec contrats bootstrap, input map et greybox.
- `docs/BACKLOG.md` mis à jour.
- Ce journal `AUTONOMY_STATE.md`.

## Prochaine exécution

Reprendre depuis ce fichier, vérifier Git, puis implémenter uniquement T011 — Smoke tests. Le binaire Godot utilisable est `/root/.local/opt/godot/4.7.2/Godot_v4.7.2-stable_linux.arm64`.

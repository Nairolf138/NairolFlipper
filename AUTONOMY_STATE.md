# AUTONOMY_STATE.md

## Dernière exécution

- Date : 2026-09-24 — fenêtre autonome en cours
- Cycle : T025 — instrumentation locale de playtest
- Statut : livré sur `origin/main`, CI verte
- Échéance : 28 septembre 2026 à 13:13 Europe/Paris

## Dépôt

- Branche : `hermes-autonomous`
- Dernier commit vérifié avant ce cycle : `4cc0485` (T024 sur `origin/main`)
- Dernier commit : `db812db` (`feat: add local playtest instrumentation`), vérifié sur `origin/main`
- CI : run `36050205761`, Godot P0 validation, verte
- Dépôt distant : `Nairolf138/NairolFlipper`
- Branche `main` : `db812db`, vérifiée après push

## État actuel

T012 complète le premier filet de livraison cross-platform :

- `export_presets.cfg` déclare Web, Android debug et Windows Desktop, avec chemins d’artefacts reproductibles.
- `.github/workflows/godot.yml` installe Godot 4.7.2 et ses templates, exécute les contrats Python, charge le projet headless et tente les trois exports.
- Aucun secret, keystore ou mot de passe de signature n’est stocké dans les presets.
- Le projet reste compatible avec l’architecture 2D GL Compatibility documentée.

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
- `project.godot` mappe les boutons X/Y/A d'une manette aux actions flippers gauche/droit/lancement ;
- `PlaytestRecorder` enregistre localement la durée et les événements de session dans `user://playtest/latest.json`, sans réseau ;
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

### T012 — CI P0 ✅

- Test de contrat ajouté en premier et observé en échec avant les presets et la workflow.
- `export_presets.cfg` couvre Web, Android debug et Windows Desktop sans secrets.
- Workflow GitHub Actions ajouté : contrats Python, smoke headless et exports des trois plateformes.
- Contrats ciblés puis suite complète repassés au vert : `2 passed`, puis `15 passed`.

### T024 — Controller support ✅

- Contrat ajouté dans `tests/test_bootstrap.py` pour les trois boutons de manette.
- Les boutons X/Y/A sont ajoutés aux actions Godot existantes, sans modifier les contrôles clavier/tactiles.
- Documentation backlog et matrice plateformes mise à jour.
- Suite ciblée : `18 passed`.
- CI GitHub Actions run `35994131378` : contrats Python, smoke headless et exports Web/Android/Windows réussis.

### T025 — Instrumentation locale de playtest

- Contrat ajouté dans `tests/test_bootstrap.py` pour le recorder et ses événements.
- `PlaytestRecorder` ajouté à la scène principale ; il écrit une trace JSON locale après les événements importants et à la fermeture.
- Aucune télémétrie, requête réseau, compte ou dépendance n'est ajouté.
- Contrat ciblé et suite de test exécutés avec succès : `19 passed`.

## Tests

- `cd tests && python3 -m pytest test_bootstrap.py::test_export_presets_cover_p0_platforms_without_secrets test_bootstrap.py::test_ci_validates_contract_and_headless_godot_load -q` → `2 passed`.
- `cd tests && pytest -q test_bootstrap.py --rootdir . --confcutdir .` → `18 passed`.
- Smoke test Godot 4.7.2 ARM64 : réussi avec `--headless --display-driver headless --audio-driver Dummy --path . --quit-after 5`.
- `git diff --check` → réussi.
- `cd tests && python3 -m pytest test_bootstrap.py --rootdir . --confcutdir . -q` → `19 passed` pour T025.
- Smoke Godot local non exécuté : le binaire 4.7.2 n'est pas présent dans cet environnement ; la CI 36050205761 a validé le smoke test et les exports.
- La CI du commit `2973cac` passe Web mais échoue à l’export Android car ETC2/ASTC n’est pas activé ; le correctif active `textures/vram_compression/import_etc2_astc=true` dans `project.godot`.

## Builds

- Godot 4.7.2 ARM64 installé localement sous `/root/.local/opt/godot/4.7.2`.
- Les templates locaux ne sont pas exploitables pour un export : l’export Web a terminé en crash signal 11 sous root/PRoot.
- Les exports Web/Android/Windows sont donc délégués à la workflow GitHub Actions, qui télécharge les templates 4.7.2.

## Problèmes connus

- Le dépôt est encore un greybox : le cycle de billes est fonctionnel mais non encore validé par playtest humain.
- Le smoke test vérifie statiquement le contrat de visibilité et lance le projet headless ; il ne remplace pas un playtest physique.
- Le mode `--headless --editor --quit` et l’export local crashent sous root/PRoot (signal 11), mais le mode d’exécution headless du projet passe.
- Les contrôles tactiles et manette n’ont pas encore été validés sur un appareil réel ; ils sont couverts par contrat statique et par le chargement Godot headless.

## Blocages

- Aucun blocage sur le chargement/exécution headless du projet ni sur la CI T024.
- Les artefacts exportés n’ont pas été vérifiés localement : le binaire Godot local attendu n’est plus disponible ; la CI doit être observée après push.
- La dernière CI a validé Web et échoué Android sur la configuration ETC2/ASTC ; Windows n’a pas été exécuté après l’échec Android.
- Le SDK Android local n’a pas été vérifié pour produire un APK.

Ces limites sont documentées et ne justifient pas l’arrêt des validations statiques.

## Livrables actuellement disponibles

- `export_presets.cfg` avec presets Web, Android debug et Windows Desktop.
- `.github/workflows/godot.yml` avec validation et exports P0.
- `tests/test_bootstrap.py` avec contrats T012 en plus des contrats gameplay.
- `docs/BACKLOG.md` mis à jour.
- Ce journal `AUTONOMY_STATE.md`.

## Prochaine exécution

Prochaine priorité après livraison : T030 — modèle de rig. Les fichiers Python/Git non suivis présents dans l’arbre de travail ne proviennent pas de ce cycle et n’ont pas été modifiés.

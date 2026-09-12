# AUTONOMY_STATE.md

## Dernière exécution

- Date : 2026-09-12 22:00 UTC / 2026-09-13 00:00 Europe/Paris
- Cycle : T012 — correction CI export P0
- Statut : correction préparée, tests locaux verts, livraison en cours sur `hermes-autonomous`
- Temps restant : environ 18 heures avant le 13 septembre 2026 à 18:00 Europe/Paris

## Dépôt

- Branche : `hermes-autonomous`
- Dernier commit de référence avant ce cycle : `53bb1d1` (fusion T011)
- Dernier commit : `6bbff07` (`ci: add Godot P0 export validation`)
- Commit fonctionnel du cycle : à créer (`fix(ci): create export directories before Godot exports`)
- Dépôt distant : `Nairolf138/NairolFlipper`
- Branche `main` : `53bb1d1`, inchangée pendant ce cycle

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

## Tests

- `cd tests && python3 -m pytest test_bootstrap.py::test_export_presets_cover_p0_platforms_without_secrets test_bootstrap.py::test_ci_validates_contract_and_headless_godot_load -q` → `2 passed`.
- `cd tests && python3 -m pytest -q` → `15 passed`.
- Smoke test Godot 4.7.2 ARM64 : réussi avec `--headless --display-driver headless --audio-driver Dummy --path . --quit-after 5`.
- `git diff --check` → réussi.
- La CI des commits `6bbff07` a échoué sur l’export Web avant création de `build/web` ; le correctif ajoute les trois répertoires avant le premier export.

## Builds

- Godot 4.7.2 ARM64 installé localement sous `/root/.local/opt/godot/4.7.2`.
- Les templates locaux ne sont pas exploitables pour un export : l’export Web a terminé en crash signal 11 sous root/PRoot.
- Les exports Web/Android/Windows sont donc délégués à la workflow GitHub Actions, qui télécharge les templates 4.7.2.

## Problèmes connus

- Le dépôt est encore un greybox : le cycle de billes est fonctionnel mais non encore validé par playtest humain.
- Le smoke test vérifie statiquement le contrat de visibilité et lance le projet headless ; il ne remplace pas un playtest physique.
- Le mode `--headless --editor --quit` et l’export local crashent sous root/PRoot (signal 11), mais le mode d’exécution headless du projet passe.
- Le contrôle tactile n’a pas encore été validé sur un appareil réel ; il est couvert par contrat statique et par le chargement Godot headless.

## Blocages

- Aucun blocage sur le chargement/exécution headless du projet.
- Les artefacts exportés n’ont pas été vérifiés localement : le binaire Godot local attendu n’est plus disponible ; la CI doit être observée après push.
- Le SDK Android local n’a pas été vérifié pour produire un APK.

Ces limites sont documentées et ne justifient pas l’arrêt des validations statiques.

## Livrables actuellement disponibles

- `export_presets.cfg` avec presets Web, Android debug et Windows Desktop.
- `.github/workflows/godot.yml` avec validation et exports P0.
- `tests/test_bootstrap.py` avec contrats T012 en plus des contrats gameplay.
- `docs/BACKLOG.md` mis à jour.
- Ce journal `AUTONOMY_STATE.md`.

## Prochaine exécution

Vérifier le push et le résultat de la workflow GitHub Actions. Si la CI est verte, stabiliser/documenter uniquement ; ne pas commencer T020 avant la livraison finale.

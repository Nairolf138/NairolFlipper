# AUTONOMY_STATE.md

## Dernière exécution

- Date : 2026-10-22
- Cycle : T055 — Roulement et contrôle des flippers
- Statut : 42 contrats Python et 24 groupes Godot ; validation tablette requise

## Dépôt

- Branche : `feat/rolling-pinball-physics`
- Base : `13c588b` (fusion de la PR #30 sur `origin/main`)
- Validation : roulement 60/120 Hz, maintien et visée sur deux flippers, neuf lancements et six retours ; CI à exécuter
- CI de la branche : à valider par la pull request
- Dépôt distant : `Nairolf138/NairolFlipper`
- Branche `main` auditée : `13c588b`

## État actuel

Le playtest après PR 29 invalide le statut de candidate Alpha. Après le lanceur
et les retours de T049, T055 remplace la chute amortie par un roulement projeté
et des palettes permettant le maintien puis la visée. Les menus et règles sont
acquis ; les vrais parcours et les graphismes restent les prochains jalons.

T013 consolide l'état livré après T042 :

- références de Resources corrigées dans `Main.tscn` ;
- types GDScript dépendants préchargés pour fonctionner sans cache local ;
- import Godot propre et analyse stricte des logs dans la CI ;
- tests comportementaux Godot pour Flow, Cue, score et restart ;
- décroissance du Flow indépendante du framerate ;
- multiplicateur et bonus de Cue reliés au score ;
- restart complet des états Cue, Rig, audio et tactiles.

Le premier playtest Android ajoute les corrections suivantes :

- orientation portrait imposée sur mobile ;
- flipper droit correctement positionné, orienté et animé ;
- bille moins légère et moins rebondissante, avec un lancement diagonal vers le plateau ;
- écran de démarrage et commandes Reset/Quit ;
- premiers effets sonores joués sur un pool polyphonique relié au bus SFX.

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
- `scripts/app/main.gd` accepte les touchers/drags pour les flippers en moitié basse ; GO apparaît quand une bille est prête, avec Espace/A manette conservés ;
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

### T031 — CueDefinition

- Contrat ajouté dans `tests/test_bootstrap.py` pour la Resource et son premier fichier de données.
- `CueDefinition` ajoute l'identifiant, le nom, les conditions, les changements lumière/audio, le bonus et la durée.
- `data/cues/first_hit.tres` fournit un cue minimal déclenché par `bumper_hit`.
- Contrat ciblé et suite complète exécutés avec succès : `1 passed`, puis `21 passed`.
- Le test lancé depuis la racine du dépôt est pollué par les fichiers Home Assistant non suivis ; la commande documentée depuis `tests/` passe.

## Tests

- `cd tests && python3 -m pytest test_bootstrap.py::test_export_presets_cover_p0_platforms_without_secrets test_bootstrap.py::test_ci_validates_contract_and_headless_godot_load -q` → `2 passed`.
- `cd tests && pytest -q test_bootstrap.py --rootdir . --confcutdir .` → `18 passed`.
- Smoke test Godot 4.7.2 ARM64 : réussi avec `--headless --display-driver headless --audio-driver Dummy --path . --quit-after 5`.
- `git diff --check` → réussi.
- `cd tests && python3 -m pytest test_bootstrap.py::test_cue_definition_declares_data_driven_show_payload -q --rootdir . --confcutdir .` → `1 passed`.
- `cd tests && python3 -m pytest test_bootstrap.py -q --rootdir . --confcutdir .` → `21 passed` pour T031.
- Smoke Godot local non exécuté : le binaire 4.7.2 n'est pas présent dans cet environnement ; la CI 36050205761 a validé le smoke test et les exports.
- La CI du commit `2973cac` passe Web mais échoue à l’export Android car ETC2/ASTC n’est pas activé ; le correctif active `textures/vram_compression/import_etc2_astc=true` dans `project.godot`.

## Builds

- Godot 4.7.2 x86_64 a validé localement l'import propre, les tests comportementaux et le smoke test.
- Les exports Web/Android/Windows restent délégués à GitHub Actions avec les templates 4.7.2.

## Problèmes connus

- Le dépôt reste un greybox : la nouvelle physique et la nouvelle interface doivent être rejouées sur Android réel.
- Les tests comportementaux et le smoke test ne remplacent pas un playtest physique.
- Les contrôles tactiles gauche/droite ont été validés sur Android réel ; la nouvelle orientation portrait et le nouveau lancement restent à confirmer dans l'APK corrigé.

## Blocages

- Aucun blocage local sur l'import, les contrats Python, les tests Godot ou le smoke test.
- Les exports P0 doivent encore être confirmés par la CI de la pull request.
- Les artefacts n'ont pas été testés sur un appareil réel.

## Livrables actuellement disponibles

- `export_presets.cfg` avec presets Web, Android debug et Windows Desktop.
- `.github/workflows/godot.yml` avec import propre, tests comportementaux, smoke et exports P0.
- `tests/test_bootstrap.py` avec 42 contrats de structure.
- `tests/godot/test_runner.gd` avec 24 groupes de validations comportementales.
- `docs/BACKLOG.md` mis à jour.
- Ce journal `AUTONOMY_STATE.md`.

## Prochaine exécution

Valider sur tablette la descente, les contacts, le maintien et les tirs précoces/
tardifs des deux côtés, en conservant GO et les retours PR 30. Puis poursuivre
en PR 32 avec les vrais parcours de rampes et d'orbite, avant la refonte artistique.

### T045 — Réglages audio persistants

- sliders Master, Musique et Effets accessibles depuis le menu et appliqués en direct ;
- conversion perceptuelle des pourcentages vers les bus audio, avec mute à 0 % ;
- fichier local `user://settings.json` versionné, borné et tolérant aux données absentes ou invalides ;
- retour aux valeurs par défaut et persistance au relâchement ou à la fermeture du panneau ;
- 39 contrats validés par le runner direct ; tests Godot et exports délégués à la CI.

### T046 — How to Play illustré

- accès permanent depuis le menu sans lancement automatique de partie ;
- quatre pages courtes couvrant commandes, Rig, Cues/Console et Final Show ;
- schémas vectoriels légers sans asset tiers ni shader ;
- navigation tactile, clavier et manette avec retour explicite au menu ;
- 40 contrats et 18 groupes Godot préparés pour la CI.

### T047 — Effets lumineux accessibles

- réglage tactile `Complets / Réduits / Désactivés` ajouté au panneau Réglages ;
- schéma de sauvegarde local migré en version 2 tout en acceptant les fichiers
  audio de version 1 ;
- flashes d'impact, pulsations d'objectifs, faisceaux, chases, footlights et
  Blackout adaptés sans supprimer les informations de gameplay ;
- 41 contrats et 19 groupes Godot préparés pour la CI.

### T049 — Lancement guidé et retours jouables

- GO contextuel, consignes et guide mis à jour ; Espace/A manette conservés ;
- parois courbes à capsules jointives, matériau de lanceur peu frictionnel,
  impulsion verticale et sortie inclinée ;
- pivots rapprochés, collecteurs latéraux et prolongements vers les flippers ;
- 42 contrats et 22 groupes Godot validés avec Godot 4.7.2 localement, en cadence
  réelle et avec pas fixe ; smoke test et analyse des logs sans erreur ;
- neuf lancements suivis jusqu'au premier renvoi physique, six retours dédiés,
  perte centrale et commandes GUI/tactile/clavier/manette vérifiés ;
- qualification Alpha et sensation physique laissées à la validation humaine.

### T055 — Roulement et contrôle des flippers

- pente 6,5°, résistance au roulement constante et intégrateur 2D documenté en ADR 0005 ;
- moteurs progressifs, retour plus lent, caoutchouc et forme de collision revus ;
- collecteurs dégagés, symétrie droite et slingshots dirigés vers le jeu ;
- maintien sur palette exclu du watchdog ; récupération toujours active ailleurs ;
- 42 contrats et 24 groupes, dont mesure à 60/120 Hz, maintien et deux visées par côté ;
- aucune qualification Alpha avant playtest, parcours physiques et refonte artistique.

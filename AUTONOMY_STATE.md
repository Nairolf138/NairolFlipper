# AUTONOMY_STATE.md

## Dernière exécution

- Date : 2026-09-07 18:11 UTC / 20:11 Europe/Paris
- Cycle : T003 — Greybox table
- Statut : implémenté et validé par tests Python + smoke test Godot
- Temps restant : environ 118 heures avant le 13 septembre 2026 à 18:00 Europe/Paris

## Dépôt

- Branche : `hermes-autonomous`
- Dernier commit de référence avant ce cycle : `0454797` (merge de l'environnement précédent)
- Dernier commit : à créer après validation de ce cycle
- Commit fonctionnel du cycle : à créer après validation de ce cycle
- Dépôt distant : `Nairolf138/NairolFlipper`
- Branche `main` : non modifiée par ce cycle

## État actuel

Le dépôt contient maintenant un bootstrap Godot minimal, une table greybox et les actions clavier MVP :

- `project.godot` déclare `res://scenes/app/Main.tscn` comme scène principale ;
- `project.godot` déclare `flipper_left` (A), `flipper_right` (D), `launch_ball` (Espace) et `pause` (Échap) ;
- `scenes/app/Main.tscn` contient une racine `Node2D` nommée `Main` ;
- `scenes/app/Main.tscn` contient un plateau visible, quatre corps statiques pour les limites/drain et une lane launcher ;
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

## Tâche suivante probable

### T004 — Ball

Ajouter une bille `RigidBody2D` avec collision, CCD et un reset testable. Ne pas commencer les flippers dans le même cycle.

## Tests

- `python3 -m pytest tests/test_bootstrap.py -q` → `4 passed`.
- `python3 -m pytest -q` → `4 passed`.
- Smoke test Godot 4.7.2 ARM64 : réussi avec `--headless --display-driver headless --audio-driver Dummy --path . --quit-after 5`.
- `git diff --check` → réussi.

## Builds

- Godot 4.7.2 ARM64 installé localement sous `/root/.local/opt/godot/4.7.2`.
- Export templates 4.7.2 installés sous `/root/.local/share/godot/export_templates/4.7.2.stable`.
- Aucun export Web/Android/Windows généré : aucun `export_presets.cfg` n’est encore défini.
- CI GitHub accessible via `gh`; aucun workflow de build n’est encore présent dans le dépôt.

## Problèmes connus

- Le dépôt est encore un greybox : aucune bille ni mécanique de flipper n’est implémentée.
- Le mode `--headless --editor --quit` crashe sous root/PRoot (signal 11), mais le mode d’exécution headless du projet passe.
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

Reprendre depuis ce fichier, vérifier Git, puis implémenter uniquement T004 — Ball. Le binaire Godot utilisable est `/root/.local/opt/godot/4.7.2/Godot_v4.7.2-stable_linux.arm64`.

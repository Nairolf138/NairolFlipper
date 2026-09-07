# AUTONOMY_STATE.md

## Dernière exécution

- Date : 2026-09-07 02:02 UTC / 04:02 Europe/Paris
- Cycle : T002 — Input Map
- Statut : terminé, tests verts, livraison de branche en préparation
- Temps restant : environ 157 heures avant le 13 septembre 2026 à 18:00 Europe/Paris

## Dépôt

- Branche : `hermes-autonomous`
- Dernier commit de référence avant ce cycle : `ed12104` (merge de T001)
- Dernier commit : à créer sur `hermes-autonomous`
- Commit fonctionnel du cycle : à créer sur `hermes-autonomous`
- Dépôt distant : `Nairolf138/NairolFlipper`
- Branche `main` : non modifiée par ce cycle

## État actuel

Le dépôt contient maintenant un bootstrap Godot minimal avec les actions clavier MVP :

- `project.godot` déclare `res://scenes/app/Main.tscn` comme scène principale ;
- `project.godot` déclare `flipper_left` (A), `flipper_right` (D), `launch_ball` (Espace) et `pause` (Échap) ;
- `scenes/app/Main.tscn` contient une racine `Node2D` nommée `Main` ;
- aucun addon ou asset externe n’a été ajouté ;
- le projet reste compatible avec l’architecture 2D GL Compatibility documentée.

## Tâche terminée

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

## Tâche suivante probable

### T003 — Greybox table

Créer les limites, le drain et la lane launcher en greybox 2D, sans art final.

## Tests

- `python3 -m pytest tests/test_bootstrap.py -q` → `3 passed`.
- `python3 -m pytest -q` → `3 passed`.
- Smoke test Godot headless : non exécuté, binaire Godot absent de l’environnement.

## Builds

- Aucun build généré.
- Godot 4.7.2 n’est pas installé ou accessible dans le PATH actuel.
- CI GitHub non vérifiée : `gh` demande une authentification et aucun jeton n’a été utilisé.

## Problèmes connus

- Le projet est encore un squelette : aucune mécanique de flipper n’est implémentée.
- La scène bootstrap n’a pas pu être ouverte par l’éditeur Godot dans cet environnement.
- La validation réelle Web/Android/Windows reste à faire.

## Blocages

- Validation Godot headless bloquée par l’absence de Godot 4.7.2.
- État CI GitHub non accessible via `gh` non authentifié.

Ces blocages ne justifient pas l’arrêt du développement des éléments vérifiables par tests statiques et Python.

## Livrables actuellement disponibles

- `project.godot` configuré avec scène principale.
- `scenes/app/Main.tscn`.
- `tests/test_bootstrap.py`.
- `docs/BACKLOG.md` mis à jour.
- Ce journal `AUTONOMY_STATE.md`.

## Prochaine exécution

Reprendre depuis ce fichier, vérifier Git, puis implémenter uniquement T003 — Greybox table. Ne pas commencer T004 tant que les limites, le drain, la lane launcher et leurs tests ne sont pas terminés.

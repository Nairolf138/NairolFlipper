# AGENTS.md — Instructions pour agents de code

Ce fichier est la politique racine du dépôt **NairolFlipper**.

## 1. Lire avant de coder

Pour toute tâche :

1. lire `docs/INDEX.md` ;
2. lire les documents associés à la tâche ;
3. vérifier le code existant avant de créer un nouveau système ;
4. ne pas supposer qu'une idée du README est déjà implémentée.

Les documents de `docs/` décrivent l'intention produit. Le code réel décrit l'état implémenté. En cas d'écart, signaler l'écart et corriger la documentation si la décision a changé.

## 2. Contraintes non négociables

- Godot **4.7.2 stable** tant qu'une ADR n'autorise pas une migration.
- **GDScript uniquement**.
- Jeu 2D.
- Cross-platform-first : Web, Android, Windows doivent rester fonctionnels pendant le développement.
- iOS, macOS et Linux ne doivent pas être rendus impossibles par une décision locale.
- Pas de C#, GDExtension, SDK natif ou plugin tiers sans ADR.
- Pas de secret, clé, certificat, mot de passe ou token dans Git.
- Pas d'asset dont la licence n'est pas connue.
- Ne pas copier l'interface, les logos, sons ou assets d'une console lumière ou d'une marque existante.
- Ne pas ajouter de télémétrie, publicité, compte utilisateur ou backend sans demande explicite.

## 3. Philosophie d'implémentation

Priorité : jouabilité, lisibilité, robustesse, compatibilité, performance, esthétique, sophistication.

Créer la solution la plus simple qui respecte l'architecture. Éviter les gros scripts monolithiques, singletons pour tout, chemins de nœuds fragiles, dépendances circulaires, nombres magiques non documentés, features spéculatives et refactors massifs inutiles.

## 4. Style Godot / GDScript

- GDScript typé autant que raisonnablement possible.
- `snake_case` pour variables/fonctions/fichiers de scripts.
- `PascalCase` pour classes et scènes réutilisables.
- Signaux pour découpler les événements de gameplay.
- Resources `.tres` / classes `Resource` pour les données configurables.
- Les réglages de gameplay doivent être centralisés ou exportés.
- Les commentaires expliquent le pourquoi.

Voir `docs/CODING_STANDARDS.md`.

## 5. Cross-platform

Chaque nouvelle feature doit considérer clavier, tactile, manette si applicable, Web, fallback graphique/audio et dépendances OS.

Les features natives optionnelles passent par un adaptateur et ne sont jamais nécessaires au gameplay.

Voir `docs/PLATFORM_MATRIX.md`.

## 6. Audio Web

Ne pas rendre le gameplay dépendant d'audio procédural, d'effets DSP indisponibles sur Web ou d'une latence parfaite. Le système musical principal repose sur des stems pré-rendus synchronisés.

## 7. Définition de fin de tâche

Une tâche n'est terminée que si le projet se charge, la feature fonctionne, les tests pertinents passent, les régressions évidentes sont vérifiées, la documentation impactée est à jour et le diff reste centré.

Voir `docs/DEFINITION_OF_DONE.md`.

## 8. Travail par petites étapes

Ne pas implémenter plusieurs jalons en une seule tâche sauf demande explicite.

Boucle :

```text
coder → construire → tester → observer → corriger
```

## 9. Modifications de design

Si une demande change un principe important : modifier le document de design, ajouter/modifier une ADR si l'architecture change, mettre à jour backlog/roadmap si nécessaire.

## 10. Compte rendu

À la fin d'une tâche, résumer : changements, fichiers principaux, tests, limites/risques, build à tester humainement. Ne jamais prétendre qu'un appareil a été testé si ce n'est pas le cas.

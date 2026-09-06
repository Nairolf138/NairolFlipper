# Workflow de développement avec Codex

## But

Codex agit comme développeur principal assisté. Le game designer valide les sensations et arbitrages.

## Avant une tâche

Lire `AGENTS.md`, `docs/INDEX.md`, document de domaine, code concerné, puis travailler sur une seule définition de réussite.

## Cycle

```text
SPEC → IMPLEMENT → TEST → BUILD → REPORT → PLAYTEST HUMAIN → FEEDBACK → FIX
```

## Non-spéculation

Ne pas ajouter spontanément backend, analytics, compte, achats, framework ou abstraction spéculative.

## Feedback humain

Le feedback de playtest prime sur une valeur théorique. Ajuster les paramètres configurables avant de réinventer le système.

## ADR

Créer une ADR pour changement moteur/version majeure, dépendance, langage, renderer, stratégie audio, backend, plugin natif ou contrainte cross-platform fondamentale.

## Rapport final

Résumé, fichiers principaux, tests, points à vérifier en playtest, risques/limites.

## Priorité des instructions

1. demande humaine explicite ;
2. `AGENTS.md` ;
3. ADR acceptées ;
4. docs de design ;
5. conventions générales.

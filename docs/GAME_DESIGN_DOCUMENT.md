# Game Design Document

## Boucle principale

```text
Lancer la bille
→ toucher / orbiter / ramper / verrouiller
→ construire Rig + Flow + score
→ compléter des objectifs
→ déclencher une Cue
→ musique et lumière gagnent en intensité
→ atteindre Final Show
→ multiball + climax
→ Blackout
→ Encore éventuel / fin de bille
```

## États d'une partie

1. Standby
2. Preset
3. Build
4. Flow
5. Break
6. Final Show
7. Blackout
8. Encore

## Ressources

- **Score** : mesure arcade principale.
- **Flow** : multiplicateur d'enchaînement.
- **Rig** : état des familles Face, Wash, Beam, Gobo, Strobe, Blinder.
- **Cue Progress** : progression vers prochaine cue.
- **Sync** : bonus facultatif près d'un pulse musical.

## Rôles des familles

| Famille | Fonction |
|---|---|
| Face | stabilité / score sûr |
| Wash | couleur / progression globale |
| Beam | rapidité / orbites |
| Gobo | précision |
| Strobe | burst risque-récompense |
| Blinder | gros impact / final |

## Balles

MVP : 3 billes par partie, configurable.

## Perte de bille

Réduire des layers, bref blackout, résumé de bille, score conservé, retour rapide au launcher.

## Ball Save

Nom thématique : **Safety**.

## Nudge / Tilt

Post-MVP. TILT coupe le scoring jusqu'au drain et déclenche un blackout visuel.

## Final Show

Débloqué après suffisamment de familles et de cues. Multiball, multiplicateur, rig complet, musique full stems, VFX renforcés mais lisibles.

## Encore

Rare, clair, mérité. Exemples : objectifs bonus de Final Show, Flow élevé, survie multiball.

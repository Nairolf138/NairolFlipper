# Roadmap

La roadmap décrit des résultats, pas des dates.

## Reprise après le playtest PR 29

Les règles, menus et réglages fonctionnent, mais le playtest invalide la
qualification Alpha : pertes précoces, lanceur non guidé, sensation de chute
libre et habillage encore abstrait.

| PR | Résultat attendu | Validation |
|---|---|---|
| 30 | GO, lancement guidé et retours jouables vers les flippers | Trajectoires physiques puis tablette |
| 31 | Pente/roulement et réponse des flippers calibrés | Contrôle, maintien et tirs visés sur tablette |
| 32 | Rampes Warm/Cold et orbite avec entrées, parcours et sorties | Parcours physiques reproductibles |
| 33 | Pièces scéniques reconnaissables et rendu cohérent en 2,5D | Lisibilité et performance tablette |
| 34 | Qualification Alpha après équilibrage et non-régression | Parcours jouable complet sur appareils cibles |

Chaque étape demande son playtest avant de conclure sur la jouabilité. Les
tests de règles par appels directs ne remplacent pas ces observations.

PR 30 à 32 implémentées : la PR 32 couvre les parcours sur de vrais corps Godot,
dont des tirs de flipper, les retours, les demi-tours et le multiball. Les plans
logiques restent une approximation de hauteur 2D. La PR 33 ajoute les pièces
scéniques originales, les matériaux des routes et leur tri visuel, avec captures
GL reproductibles. La prochaine étape est le playtest artistique / performance,
puis la qualification Alpha PR 34 ; elle n'est pas acquise par les tests CI.

PR 34 prépare le candidat traçable et le dossier de qualification : pause réelle
en arrière-plan (y compris les trois chronos de jeu), rapport local consultable /
copiable, mesures de cadence en jeu et builds P0 téléchargeables. Les critères et
preuves manquantes sont suivis dans `ALPHA_QUALIFICATION.md`. Aucun équilibrage
de sensation ni statut « Alpha qualifiée » ne peut être conclu sans ce playtest.

## M0 — Repository Ready

Cadrage présent, projet Godot ouvrable, conventions, backlog.

## M1 — Greybox Pinball

Web + Android + Windows buildables, 1 bille, 2 flippers, launcher, murs, drain, 3 bumpers, score, restart.

## M2 — Good Hands

Physique agréable, tuning externalisé, inputs tactile/clavier/manette, ball save, feedback propre.

## M3 — Living Rig

Familles lumière, CueManager, premiers VFX, progression visuelle.

## M4 — Reactive Music

Transport musical, stems, SFX, Sync Bonus.

## M5 — Show Mode

Preset → Build → Flow → Break → Final → Blackout, objectifs lisibles, Final Show multiball.

## M6 — Identity

Direction artistique, UI, musique originale, niveaux qualité, accessibilité.

## M7 — Cross-platform Alpha

Web, Android, Windows, Linux, macOS, iOS, settings/sauvegarde, performance acceptable.

## M8 — Public Beta

Onboarding, équilibrage, crédits/licences, release automation, retours externes.

## M9 — 1.0

Expérience complète, identité Nairolf nette, aucun blocage majeur, builds reproductibles.

## Post-1.0

Aftershow Replay, plusieurs tables/shows, challenges, daily seed offline, leaderboards opt-in, setlists, palettes, intégrations communautaires.

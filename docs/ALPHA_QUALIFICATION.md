# Qualification Alpha — PR 34

**Statut : candidat de test, qualification appareil en attente.**
Fusionner une PR ne vaut pas validation de sensation ou de performance. Aucun
playtest tablette des PR 30 à 33 n'a été rapporté depuis la reprise après PR 29.
Le numéro logiciel reste `0.1.0-alpha.1` ; le SHA source visible distingue les
builds. Il ne s'agit pas d'une version finale 1.0.

## Ce qui peut être établi automatiquement

| Contrôle | Preuve |
|---|---|
| Import et smoke Godot 4.7.2 sans erreur | Logs CI contrôlés |
| Règles et parcours physiques | Runner historique, dont tirs / retours PR 30–32 |
| Pause en rampe, reprise et chronos | `qualification_runner.gd` — vraie admission physique puis interruption |
| Journal sans écritures par impact | Test de rafale, flush différé, persistance et percentile |
| Interface sans découpe aux formats contrôlés | Captures GL 540×960, 1080×1920 et tablette 768×1024 à inspecter |
| Exports Web / Android / Windows | Artifacts téléchargeables ; SHA-256 dans `manifest.json` |
| Identité de l'APK réellement empaquetée | JSON de build relu directement dans le ZIP APK |

Les captures sont des poses, pas des parties jouées. Le parcours Showflow
historique utilise des appels directs pour les règles ; il ne démontre pas qu'un
humain peut terminer la conduite. Les essais de rampe sont physiques mais leurs
conditions de départ sont contrôlées. Aucun de ces tests ne certifie le plaisir
de jeu, le contrôle tactile, la chauffe ou un appareil cible.

## Parcours tablette à réaliser avant de qualifier l'Alpha

1. Installer l'APK de **cette PR** et relever le SHA dans le menu / rapport.
2. Jouer trois parties complètes, dont une session d'au moins dix minutes.
   Vérifier GO, premier retour jouable, maintien puis frappe sur chaque flipper,
   Warm / Cold et orbite dans les deux sens. Une perte centrale est normale ;
   une perte systématique impossible à jouer est bloquante.
3. Terminer les trois Cues et les six familles du Rig, exécuter la Console,
   atteindre le Final Show, observer Blackout et revenir au jeu avec une bille.
4. Vérifier trois billes numérotées, aucun quatrième lancement, Rejouer et Menu.
   Noter toute récupération de bille hors plateau ou coincée : le watchdog ne
   doit pas dissimuler un mauvais parcours ou un rail ouvert.
5. En pleine rampe puis en Final Show, quitter temporairement l'application.
   Au retour : écran Pause, bille et progression conservées, aucun chrono
   consommé, reprise **manuelle**, aucune palette bloquée. Essayer aussi PAUSE.
6. Vérifier les modes lumineux Complets / Réduits / Désactivés, les sons,
   les réglages après relance, la bille et les objectifs aux croisements.
7. Depuis PAUSE → RAPPORT DE TEST, copier le rapport et le joindre au retour.
   Ajouter manuellement modèle de tablette, durée, sensation, chauffe et bugs.

## Critères de sortie

| Porte | État actuel | Acceptation |
|---|---|---|
| Automatique | À lire sur la CI du commit testé | Tous les contrôles verts et artifacts cohérents |
| Jouabilité Android | En attente | Parcours ci-dessus réalisable, aucun blocage ou drain systématique |
| Sensation / identité | En attente | Bille perçue comme roulant ; pièces et objectifs compréhensibles |
| Cadence Android | En attente | Cible 60 i/s ; moyenne ≥55 i/s, p95 ≤33 ms, moins de 1 % d'images >50 ms sur dix minutes et Final Show sans gel |
| Interruption mobile | En attente | Aucun mouvement / chrono en pause, reprise sans perte ni action coincée |
| Smoke Web et Windows réels | En attente | Démarrage, audio après geste, GO, contrôles, pause et fin de partie |

La cadence locale mesure l'intervalle mural entre frames traitées en jeu, pas
le temps GPU. Le p95 a une précision de 1 ms et un plafond à 250 ms. Les frames
de menu, de pause et l'intervalle de retour au jeu sont exclus. Final Show dispose
d'une moyenne et d'un compteur >50 ms séparés pour éviter de masquer un creux
dans la moyenne générale. Ne pas interpréter les mesures headless, à cadence
forcée, ni celles du renderer logiciel CI comme un benchmark Android.

Une porte en échec demande correction puis nouveau playtest du SHA corrigé.
Ne pas ajuster aveuglément la physique sans trajectoire / retour reproductible.
Ne pas annoncer « Alpha qualifiée » ni publier de tag de release tant que les
preuves humaines manquent. La CI conserve volontairement `alpha_qualified: false`
et `device_playtest: pending` dans le manifeste.

## Retour à fournir

```text
SHA source et numéro de build :
Modèle / OS :
Durée et nombre de parties :
Premier retour, maintien et visées :
Cues / Rig / Final Show atteints :
Sensation de poids et roulement :
Lisibilité / sons / réglages :
Pause et retour depuis arrière-plan :
Fluidité et chauffe :
Blocage / perte injuste (côté, lieu, action) :
Rapport copié :
```

# Backlog initial

Ordre volontaire. Ne pas sauter plusieurs étapes sans raison.

## P0 — Bootstrap

### T001 — Valider le projet Godot ✅

But : ouvrir le dépôt avec Godot 4.7.2 sans erreur. Done : `project.godot` valide, scène bootstrap créée, fenêtre portrait, aucun addon. Validation Godot headless à compléter lorsque l’éditeur sera disponible dans l’environnement.

### T002 — Input Map ✅

Actions `flipper_left`, `flipper_right`, `launch_ball`, `pause` déclarées dans `project.godot` avec raccourcis clavier. La même map pourra être consommée par les contrôles tactiles et manette sans dépendance native.

### T003 — Greybox table ✅

Limites, drain, lane launcher, zones simples. Pas d'art final. La scène principale contient maintenant les limites physiques et un rendu de plateau minimal.

### T004 — Ball ✅

`RigidBody2D`, collision, CCD, tuning, reset. La scène `Ball.tscn` instancie une bille physique avec collision continue et le script expose `reset_ball()`.

### T005 — Flippers ✅

Gauche/droite, press/release, collisions, tuning.

### T006 — Launcher ✅

Placement dans la lane, lancement contrôlé via `launch_ball`, bloqué si aucune bille prête. La bille est immobilisée au démarrage et propulsée une seule fois par l'action `launch_ball`.

### T007 — Bumpers ✅

Trois bumpers : impulse, SFX placeholder, flash, score event. Les bumpers Kick, Snare et Tom émettent un signal de hit pour le futur ScoreManager ; aucun scoring global ni audio n'est ajouté à ce jalon.

### T008 — Score + HUD ✅

ScoreManager de session, signal connecté aux trois bumpers, score visible dans le HUD, reset au démarrage.

### T009 — Ball lifecycle ✅

Trois billes, drain détecté par `Area2D`, délai de respawn, game over et restart via `launch_ball`. Le score est remis à zéro au restart.

### T010 — Mobile touch ✅

Zones tactiles portrait : moitié basse gauche/droite pour les flippers, zone
haute pour lancer ou relancer. Les drags peuvent changer de flipper sans
ajouter de boutons persistants au HUD.

### T011 — Smoke tests ✅

Import, main scene load, score logic, drain lifecycle. Les contrats Python couvrent
désormais le cycle de visibilité des billes et le projet est lancé en headless avec
Godot 4.7.2.

### T012 — CI P0 ✅

Presets d’export Web, Android debug et Windows ajoutés avec artefacts nommés. Une workflow GitHub Actions épinglée sur Godot 4.7.2 exécute les contrats Python, le smoke test headless et les trois exports. Les secrets de signature Android restent hors du dépôt.

### T013 — Consolidation chargement et session ✅

La scène principale charge depuis un checkout propre sans dépendre d'un cache
`.godot`. La CI importe le projet, exécute des tests comportementaux Godot et
rejette explicitement les erreurs de parsing/chargement. Le Flow décroît à la
vitesse configurée, son multiplicateur s'applique au score, les bonus de Cue sont
comptabilisés et un restart réinitialise les états Cue, Rig et audio.


### T014 — Cycle de partie robuste ✅

Le second playtest Android a révélé une reprise silencieuse après la troisième
bille et une bille fantôme dans le coin inférieur gauche. La session utilise
désormais des états explicites, désactive les collisions des billes inactives,
affiche un écran Game Over avec score final et n'autorise une nouvelle partie que
depuis Rejouer. Safety est limité à une fois par bille et une bille coincée ou
sortie du plateau revient au launcher sans consommer de vie.

### T015 — Table 2.0 greybox ✅

Le plateau quitte la démonstration vide pour proposer une première boucle
d'objectifs. Six cibles allument les familles du Rig, une Universe Orbit et deux
slingshots enrichissent les tirs, des rails physiques créent retours et outlanes,
et le HUD mène explicitement de `RIG 0 / 6` vers la Console. La direction
artistique finale et le Final Show restent hors de cette tâche.

## P1 — Feel

T020 Physics tuning resource ✅; T021 Ball max speed/anti-tunneling ✅; T022 Feedback hit ✅; T023 Ball save ✅; T024 Controller support ✅; T025 instrumentation locale de playtest ✅.

T020 centralise les paramètres de bille dans `data/tuning/PhysicsTuning.tres`, appliqués par `Ball`.
T021 limite la vitesse de la bille via le tuning partagé et active le CCD dans `Ball.tscn`.
T022 fournit un flash visuel temporisé sur chaque bumper et conserve le signal de hit pour le score.
T023 ajoute Safety : une bille lancée peut être sauvée une fois pendant la fenêtre configurée, puis replacée au launcher.
T024 mappe les boutons X/Y d'une manette aux flippers gauche/droit et A au lancement, en conservant les actions clavier et tactiles communes.
T025 enregistre localement les événements et la durée d'une session dans `user://playtest/latest.json`, sans réseau ni compte.

### T026 — Trajectoires sûres ✅

Les parois latérales ferment le plateau jusqu'au drain, les guides supérieurs
renvoient une bille lente vers le centre et les rails bas séparent clairement
les retours jouables des outlanes. Le couloir du lanceur ne croise plus le retour
droit. La sensation de poids et le réglage fin des contacts restent le jalon
suivant et demandent un playtest sur tablette.

### T027 — Sensation de plateau incliné ✅

La bille descend plus franchement, conserve davantage de traction et perd le
rebond uniforme qui la faisait paraître en apesanteur. Rails et murs absorbent
les contacts tandis que les flippers gardent une surface plus dynamique et une
activation plus rapide. Les forces du lanceur, des bumpers et des slingshots
sont recalibrées pour la nouvelle masse. Une ombre de contact et un reflet
simple renforcent la lecture de la bille sans asset supplémentaire.

### T028 — Cue Stack jouable ✅

Trois cues imposent des tirs variés avant le Final Show : les rampes Warm et
Cold pour Color Wash, deux passages d'Universe Orbit pour Universe Chase, puis
quatre impacts de bumpers pour Rhythm Drop. Chaque cue armée doit être exécutée
sur la Console comme un vrai `GO`. Le HUD indique la progression et le plateau
met en évidence les tirs encore nécessaires. Le Final Show exige désormais la
Cue Stack et les six familles du Rig.

### T029 — Passe visuelle Stagecraft ✅

Le plateau quitte son apparence de greybox générique pour adopter l'identité
« scène de spectacle jouable » : deck en perspective, routes de tir balisées,
rails métalliques, lentilles de projecteurs, palettes mécaniques, launcher et
drain signalés. HUD et menus partagent un thème de régie sombre à accents
lumineux. La passe reste entièrement vectorielle, conserve les collisions et ne
rajoute ni shader plein écran ni asset tiers, afin de tenir le budget Android/Web.

## P1 — Show systems

### T030 Rig model ✅; T031 CueDefinition ✅; T032 CueManager ✅; T033 Flow ✅; T034 Warm/Cold ramps ✅; T035 Console scoop ✅; T036 First show sequence ✅.

T030 ajoute six familles de fixtures data-driven (`RigDefinition`) et un
`RigModel` de session qui émet `rig_family_activated` sans imposer de rendu.

T031 ajoute la Resource `CueDefinition` et un premier cue de démonstration,
avec conditions, changements lumière/audio, bonus et durée configurables.

T032 ajoute l'exécuteur de session `CueManager`, qui vérifie les conditions,
émet les changements lumière/audio et clôture automatiquement les cues temporisés
avec leur bonus, sans dépendre d'un renderer ou d'un service audio.

T033 ajoute `FlowManager`, une progression locale et tolérante de `x1` à `x8`
avec décroissance lente, signaux de changement et affichage HUD. Les impacts de
bumpers alimentent le Flow sans rendre le score dépendant du système de show.

T034 ajoute deux rampes `Area2D` data-driven : Warm (ambre) et Cold (cyan).
Chaque passage est signalé une fois, attribue score et Flow, puis réarme le
capteur après un court délai pour éviter les doubles impacts physiques.

T035 ajoute un scoop Console `Area2D` data-driven : un passage attribue score
et Flow, valide le cue courant et réarme le capteur après un court délai. Le
premier cue exige maintenant un impact bumper puis une validation Console ; les
consommateurs lumière/audio restent découplés par les signaux de `CueManager`.

T036 ajoute le premier Showflow réellement jouable : Preset au lancement,
Build pendant la construction du Rig, Flow lorsque les six familles sont
actives, puis Final Show via la Console et Blackout. L'état courant est toujours
visible dans le HUD et un restart remet la conduite à Preset.

## P1 — Audio

T040 Audio service ✅; T041 SFX buses ✅; T042 Music transport ✅; T043 Stem set ✅; T044 Sync Bonus ✅; T045 Audio settings ✅.

T040 ajoute un service audio logique multiplateforme : mix Master/Music/SFX,
états de stems et demandes de SFX sont consommables par les cues sans rendre le
gameplay dépendant d'un périphérique audio ou d'assets sonores.

T042 ajoute une horloge musicale logique configurable (BPM et longueur de boucle),
avec démarrage, arrêt, seek et signaux de progression/boucle. Elle reste
indépendante de la présence d'un lecteur audio ou d'un asset.

T041 relie les événements de gameplay à un pool de lecteurs sur le bus SFX.
Des sons provisoires originaux couvrent flippers, lanceur, bumpers, rampes,
Console, Cue, Safety et drain afin que les playtests Web/mobile ne soient plus
silencieux.

T043 ajoute huit stems originaux pré-rendus et synchronisés sur une boucle de
16 temps à 120 BPM. Atmosphère, piano, kick, percussions, basse et arp entrent
progressivement avec le Rig ; lead et impact rejoignent le mix au Final Show.
Un renderer 2D léger traduit la même progression en truss, faisceaux et runway.

T044 relie les impacts du plateau à l'horloge musicale. Une fenêtre serrée donne
Perfect Sync et une fenêtre plus large donne Sync ; les deux ajoutent score et
Flow avec texte, flash et SFX dédiés. Un pulse ne peut être récompensé qu'une
fois et un tir hors tempo ne perd jamais ses gains normaux. Les témoins à quatre
temps restent visibles même si le mix audio est coupé.

T045 ajoute au menu trois réglages tactiles Master/Musique/Effets. Leur effet est
immédiat, les valeurs peuvent être réinitialisées et elles sont sauvegardées
localement avec un schéma versionné et un fallback sûr en cas de fichier absent
ou invalide.

## P2 — Final

T050 Ball lock; T051 Multiball ✅; T052 Final Show ✅; T053 Blackout ✅; T054 Encore prototype.

T051–T053 livrent un premier climax testable : la Console lance trois billes
bonus sans consommer les trois billes de la session, double le scoring actif et
termine le mode lorsqu'une seule bille subsiste ou lorsque le chrono expire. Un
Blackout bref ramène ensuite la partie en Flow. Le lock physique et l'Encore
restent volontairement hors de cette étape.

## Règle

Chaque tâche utilise une Issue avec objectif, non-objectifs, critères d'acceptation et test.

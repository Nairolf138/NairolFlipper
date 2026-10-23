# Tests

- `python3 -m pytest tests/ -q` vérifie les contrats de structure.
- `godot --headless --display-driver headless --audio-driver Dummy --path . --script res://tests/godot/test_runner.gd` exécute les comportements Flow, Cue, score, session, audio et persistance locale.
- Le smoke test de la scène principale reste obligatoire après un import propre.

Le runner Godot n'utilise aucun addon externe.

Il exécute 27 groupes. La PR 31 ajoute des mesures sur de vraies billes : pente,
accélération indépendante de la masse, résistance constante, arrêt, vitesse
plafonnée et comparaison 60/120 Hz. Les deux flippers sont testés en maintien
puis relâchement/réactivation à deux positions de frappe avec visées distinctes.
Le maintien légitime ne doit pas déclencher le watchdog, qui reste actif ailleurs.

La PR 32 ajoute trois groupes : parcours physiques Warm/Cold et orbite dans les
deux sens, isolation/cycle de vie en multiball, puis quatre parcours visés depuis de vraies
billes retenues et relâchées sur les flippers. Les essais vérifient les contacts
de rails, sorties, retours jouables, demi-tours faibles et progression de Cue
par les signaux de scène. Les passages sous un guide ou à contresens ne scorent
pas. Reset et menu doivent rétablir le plan de collision et la profondeur.

Les régressions de la PR 30 suivent de vrais corps physiques : neuf lancements
(trois positions et trois forces), passage par la courbe puis premier retour
frappé en jeu ; six retours latéraux/proches du centre et une perte centrale
légitime. Les sauvetages sont désactivés pour les essais de retour.
Le pilote peut retenir puis relâcher/refrapper une bille avec les actions d'entrée,
sans modifier sa position ou sa vitesse pendant le jeu.
GO est pressé via la GUI ; les deux touches flipper, Espace et A manette sont
également vérifiés. Le parcours Showflow historique teste les règles par appels
directs et ne constitue pas une preuve de jouabilité.

Pour comparer rapidement les trajectoires : ajouter `--fixed-fps 120` avant
`--path .`. Ajouter `-- --trace-launch` à la fin affiche positions et vitesses
du lanceur. La CI conserve aussi un passage à cadence réelle.
`-- --trace-physics` affiche les mesures de maintien et de frappe.
`-- --routes-only` limite le runner aux trois nouveaux groupes ;
`-- --trace-routes` affiche leurs trajectoires. `-- --scan-routes` balaie les
points de frappe à des fins de diagnostic, sans modifier la bille en vol.

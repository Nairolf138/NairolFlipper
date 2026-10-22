# Tests

- `python3 -m pytest tests/ -q` vérifie les contrats de structure.
- `godot --headless --display-driver headless --audio-driver Dummy --path . --script res://tests/godot/test_runner.gd` exécute les comportements Flow, Cue, score, session, audio et persistance locale.
- Le smoke test de la scène principale reste obligatoire après un import propre.

Le runner Godot n'utilise aucun addon externe.

Les régressions de la PR 30 suivent de vrais corps physiques : neuf lancements
(trois positions et trois forces), passage par la courbe puis premier retour
frappé en jeu ; six retours latéraux/proches du centre et une perte centrale
légitime. Les sauvetages sont désactivés pour les essais de retour.
GO est pressé via la GUI ; les deux touches flipper, Espace et A manette sont
également vérifiés. Le parcours Showflow historique teste les règles par appels
directs et ne constitue pas une preuve de jouabilité.

Pour comparer rapidement les trajectoires : ajouter `--fixed-fps 120` avant
`--path .`. Ajouter `-- --trace-launch` à la fin affiche positions et vitesses
du lanceur. La CI conserve aussi un passage à cadence réelle.

# Tests

- `python3 -m pytest tests/ -q` vérifie les contrats de structure.
- `godot --headless --display-driver headless --audio-driver Dummy --path . --script res://tests/godot/test_runner.gd` exécute les comportements Flow, Cue, score et reset de session.
- Le smoke test de la scène principale reste obligatoire après un import propre.

Le runner Godot n'utilise aucun addon externe.

# Standards de code

## GDScript

Typage dès que cela améliore sécurité et lisibilité.

```gdscript
signal score_changed(total: int, delta: int)
@export var bumper_impulse: float = 620.0
var score: int = 0

func add_score(amount: int) -> void:
    if amount <= 0:
        return
    score += amount
    score_changed.emit(score, amount)
```

## Nommage

Scripts/variables/fonctions : `snake_case`. Constantes : `UPPER_SNAKE_CASE`. Classes/scènes : `PascalCase`. Signaux : événement clair comme `ball_drained`.

## Principes

Fonctions petites, early returns, pas de logique scoring dispersée, préférer signaux/dépendances explicites/groupes/Resources, éviter chaînes `get_parent().get_parent()`, tuning exporté ou centralisé, pas de recherche de nœud répétée par frame, logs utiles, pas de `print()` haute fréquence.

Un TODO explique ce qui manque, pourquoi et quand il disparaît.

Mettre à jour les docs lorsqu'une règle durable change.

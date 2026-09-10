extends Node2D

@onready var score_manager = $ScoreManager
@onready var score_label: Label = $ScoreLabel


func _ready() -> void:
	for bumper in get_tree().get_nodes_in_group("score_bumpers"):
		bumper.bumper_hit.connect(_on_bumper_hit)
	score_manager.score_changed.connect(_on_score_changed)
	score_manager.reset_score()


func _on_bumper_hit(points: int, _bumper_name: StringName) -> void:
	score_manager.add_points(points)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE %06d" % new_score

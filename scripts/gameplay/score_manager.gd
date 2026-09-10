class_name ScoreManager
extends Node

signal score_changed(new_score: int)

var score: int = 0


func add_points(points: int) -> void:
	score += points
	score_changed.emit(score)


func reset_score() -> void:
	score = 0
	score_changed.emit(score)

class_name HowToPlayPanel
extends ColorRect

const HowToPlayDiagramNode = preload("res://scripts/ui/how_to_play_diagram.gd")

signal closed

const PAGES: Array[Dictionary] = [
	{
		"eyebrow": "GUIDE RAPIDE  //  1 / 4",
		"title": "LANCEZ ET JOUEZ",
		"body": "Appuyez sur GO pour lancer la bille dans le couloir guidé. Maintenez le bas gauche ou droit pour actionner chaque flipper.",
		"objective": "OBJECTIF  •  Gardez la bille en jeu et visez les éléments éclairés.",
	},
	{
		"eyebrow": "GUIDE RAPIDE  //  2 / 4",
		"title": "CONSTRUISEZ LE RIG",
		"body": "Touchez les six cibles FACE, WASH, BEAM, PIXEL, BLIND et PRAT. pour allumer les familles de projecteurs.",
		"objective": "OBJECTIF  •  Faites passer le compteur de RIG 0 / 6 à RIG 6 / 6.",
	},
	{
		"eyebrow": "GUIDE RAPIDE  //  3 / 4",
		"title": "EXÉCUTEZ LES CUES",
		"body": "Suivez la route mise en évidence, réalisez les tirs demandés, puis envoyez la bille dans la Console pour jouer la Cue.",
		"objective": "OBJECTIF  •  Terminez les trois étapes de la CUE STACK.",
	},
	{
		"eyebrow": "GUIDE RAPIDE  //  4 / 4",
		"title": "LANCEZ LE FINAL SHOW",
		"body": "Rig complet + Cue Stack complète : frappez la Console pour déclencher le multiball. Les tirs sur le tempo donnent un bonus facultatif.",
		"objective": "OBJECTIF  •  Construisez votre show, gardez le Flow et faites le meilleur score.",
	},
]

@onready var eyebrow_label: Label = $Menu/Eyebrow
@onready var title_label: Label = $Menu/Title
@onready var diagram: HowToPlayDiagramNode = $Menu/Diagram
@onready var body_label: Label = $Menu/Body
@onready var objective_label: Label = $Menu/Objective
@onready var progress_label: Label = $Menu/Progress
@onready var previous_button: Button = $Menu/Navigation/PreviousButton
@onready var next_button: Button = $Menu/Navigation/NextButton
@onready var back_button: Button = $Menu/BackButton

var current_page: int = 0


func _ready() -> void:
	previous_button.pressed.connect(show_previous_page)
	next_button.pressed.connect(show_next_page)
	back_button.pressed.connect(close_panel)
	_show_page(0)


func open_panel() -> void:
	_show_page(0)
	show()
	next_button.grab_focus()


func close_panel() -> void:
	hide()
	closed.emit()


func show_previous_page() -> void:
	if current_page <= 0:
		return
	_show_page(current_page - 1)


func show_next_page() -> void:
	if current_page >= PAGES.size() - 1:
		close_panel()
		return
	_show_page(current_page + 1)


func _show_page(page_index: int) -> void:
	current_page = clampi(page_index, 0, PAGES.size() - 1)
	var page: Dictionary = PAGES[current_page]
	eyebrow_label.text = String(page["eyebrow"])
	title_label.text = String(page["title"])
	body_label.text = String(page["body"])
	objective_label.text = String(page["objective"])
	diagram.set_page(current_page)
	previous_button.disabled = current_page == 0
	next_button.text = "TERMINER" if current_page == PAGES.size() - 1 else "SUIVANT"
	var markers: Array[String] = []
	for index in PAGES.size():
		markers.append("●" if index == current_page else "○")
	progress_label.text = "  ".join(markers)

extends ColorRect

signal resume_requested
signal menu_requested
signal quit_requested
signal report_requested
signal report_closed

@onready var pause_menu: VBoxContainer = $Panel/PauseMenu
@onready var report_menu: VBoxContainer = $Panel/ReportMenu
@onready var report: TextEdit = $Panel/ReportMenu/Report
@onready var copy_button: Button = $Panel/ReportMenu/CopyButton
@onready var return_button: Button = $Panel/ReportMenu/BackButton
var _can_resume := false


func _ready() -> void:
	$Panel/PauseMenu/ResumeButton.pressed.connect(func() -> void: resume_requested.emit())
	$Panel/PauseMenu/ReportButton.pressed.connect(func() -> void: report_requested.emit())
	$Panel/PauseMenu/MenuButton.pressed.connect(func() -> void: menu_requested.emit())
	$Panel/PauseMenu/QuitButton.pressed.connect(func() -> void: quit_requested.emit())
	copy_button.pressed.connect(_copy_report)
	return_button.pressed.connect(_back)


func show_pause() -> void:
	_can_resume = true
	report_menu.hide()
	pause_menu.show()
	show()
	$Panel/PauseMenu/ResumeButton.grab_focus()


func show_report(text: String, can_resume: bool) -> void:
	_can_resume = can_resume
	report.text = text
	report.scroll_vertical = 0
	copy_button.text = "COPIER LE RAPPORT"
	pause_menu.hide()
	report_menu.show()
	show()
	return_button.grab_focus()


func _copy_report() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(report.text)
		copy_button.text = "RAPPORT COPIÉ"
	else:
		report.select_all()
		report.grab_focus()
		copy_button.text = "TEXTE SÉLECTIONNÉ — COPIE MANUELLE"


func _back() -> void:
	if _can_resume and report_menu.visible:
		show_pause()
	elif _can_resume:
		resume_requested.emit()
	else:
		hide()
		report_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_back()
		get_viewport().set_input_as_handled()

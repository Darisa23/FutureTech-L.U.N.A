extends Node

var _last_correctans := 0.0
var _in_quiz := false
var _correct_this_round := false

func _ready():
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	if self.name == "ConceptIntro1":
		Dialogic.start('dialogo_modulo1')
	elif self.name == "ConceptIntro2":
		Dialogic.start('dialogo_modulo2')

func _on_timeline_ended():
	Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	_in_quiz = true
	_last_correctans = 0.0
	Dialogic.VAR.variable_was_set.connect(_on_variable_set)
	Dialogic.Choices.choice_selected.connect(_on_choice_selected)
	Dialogic.signal_event.connect(_on_quiz_signal)
	if self.name == "ConceptIntro1":
		Dialogic.start('preguntas_modulo1')
	elif self.name == "ConceptIntro2":
		Dialogic.start('preguntas_modulo2')

func _on_choice_selected(_info: Dictionary) -> void:
	if not _in_quiz:
		return
	_correct_this_round = false
	await get_tree().process_frame
	await get_tree().process_frame
	if not _in_quiz:
		return
	Dialogic.paused = true
	if not _correct_this_round:
		shake_textbox()
		flash_screen(Color(1, 0.1, 0.1, 1.0))
	else:
		flash_screen(Color(0.0, 1.0, 0.8, 1.0))
	await get_tree().create_timer(0.8).timeout
	Dialogic.paused = false

func _on_variable_set(info: Dictionary) -> void:
	if not _in_quiz:
		return
	if info.variable == "correctans" and float(info.new_value) > _last_correctans:
		_last_correctans = float(info.new_value)
		_correct_this_round = true

func _on_quiz_signal(arg: String) -> void:
	_in_quiz = false
	if Dialogic.signal_event.is_connected(_on_quiz_signal):
		Dialogic.signal_event.disconnect(_on_quiz_signal)
	if Dialogic.VAR.variable_was_set.is_connected(_on_variable_set):
		Dialogic.VAR.variable_was_set.disconnect(_on_variable_set)
	if Dialogic.Choices.choice_selected.is_connected(_on_choice_selected):
		Dialogic.Choices.choice_selected.disconnect(_on_choice_selected)
	if arg == "fail":
		_restart_quiz()
	else:
		if self.name == "ConceptIntro1":
			get_tree().change_scene_to_file("res://Scenes/arc1/module_1_layers.tscn")
		elif self.name == "ConceptIntro2":
			get_tree().change_scene_to_file("res://Scenes/arc1/module_2_weights.tscn")

func _restart_quiz() -> void:
	_in_quiz = true
	_last_correctans = 0.0
	_correct_this_round = false
	Dialogic.VAR.variable_was_set.connect(_on_variable_set)
	Dialogic.Choices.choice_selected.connect(_on_choice_selected)
	Dialogic.signal_event.connect(_on_quiz_signal)
	if self.name == "ConceptIntro1":
		Dialogic.start('preguntas_modulo1')
	elif self.name == "ConceptIntro2":
		Dialogic.start('preguntas_modulo2')

func flash_screen(flash_color: Color) -> void:
	var overlay = get_node("Background/GlitchOverlay")
	if overlay == null:
		push_warning("No se encontró GlitchOverlay")
		return
	var mat = overlay.material as ShaderMaterial
	if mat == null:
		push_warning("GlitchOverlay no tiene ShaderMaterial")
		return
	mat.set_shader_parameter("color", flash_color)
	overlay.modulate.a = 0.0
	overlay.visible = true
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.15)
	tween.tween_interval(0.2)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): overlay.visible = false)

func shake_textbox(duration := 0.5, intensity := 8.0) -> void:
	var shake_layout = get_tree().root.get_node("DialogicLayout_Styledialog")
	if shake_layout == null:
		push_warning("No se encontró el layout de Dialogic")
		return
	var shake_origin := (shake_layout as CanvasLayer).offset
	var shake_tween := create_tween()
	var shake_steps := int(duration / 0.04)
	for i in shake_steps:
		shake_tween.tween_property(shake_layout, "offset",
			shake_origin + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)),
			0.04)
	shake_tween.tween_property(shake_layout, "offset", shake_origin, 0.06)

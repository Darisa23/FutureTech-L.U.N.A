extends Node

func _ready():
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	if self.name == "ConceptIntro1":
		Dialogic.start('dialogo_modulo1')
	elif self.name == "ConceptIntro2":
		Dialogic.start('dialogo_modulo2')
		

func _on_timeline_ended():
	# Desconectamos para no repetir lógica con el siguiente timeline
	Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	# Ahora corre las preguntas
	Dialogic.timeline_ended.connect(_on_questions_ended)
	if self.name == "ConceptIntro1":
		Dialogic.start('preguntas_modulo1')
	elif self.name == "ConceptIntro2":
		Dialogic.start('preguntas_modulo2')

func _on_questions_ended():
	Dialogic.timeline_ended.disconnect(_on_questions_ended)
	# Cambia a la escena del minijuego
	if self.name == "ConceptIntro1":
		get_tree().change_scene_to_file("res://Scenes/arc1/module_1_layers.tscn")
	elif self.name == "ConceptIntro2":
		get_tree().change_scene_to_file("res://Scenes/arc1/module_2_weights.tscn")
